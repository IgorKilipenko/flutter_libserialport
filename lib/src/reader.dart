/*
 * Based on libserialport (https://sigrok.org/wiki/Libserialport).
 *
 * Copyright (C) 2010-2012 Bert Vermeulen <bert@biot.com>
 * Copyright (C) 2010-2015 Uwe Hermann <uwe@hermann-uwe.de>
 * Copyright (C) 2013-2015 Martin Ling <martin-libserialport@earth.li>
 * Copyright (C) 2013 Matthias Heidbrink <m-sigrok@heidbrink.biz>
 * Copyright (C) 2014 Aurelien Jacobs <aurel@gnuage.org>
 * Copyright (C) 2020 J-P Nurmi <jpnurmi@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as pkg_ffi;
import 'package:flutter_libserialport/src/bindings.dart';
import 'package:flutter_libserialport/src/dylib.dart';
import 'package:flutter_libserialport/src/error.dart';
import 'package:flutter_libserialport/src/port.dart';
import 'package:flutter_libserialport/src/util.dart';

const int _kReadEvents = sp_event.SP_EVENT_RX_READY | sp_event.SP_EVENT_ERROR;

class _SerialPortReaderArgs {
  final int address;
  final int timeout;
  final SendPort sendPort;
  _SerialPortReaderArgs(
      {required this.address, required this.timeout, required this.sendPort});
}

class IsolateError {
  final dynamic errorr;
  IsolateError(this.errorr);
}

/// Asynchronous serial port reader.
///
/// Provides a [stream] that can be listened to asynchronously to receive data
/// whenever available.
///
/// The [stream] will attempt to open a given [port] for reading. If the stream
/// fails to open the port, it will emit [SerialPortError]. If the port is
/// successfully opened, the stream will begin emitting [Uint8List] data events.
///
/// **Note:** The reader must be closed using [close()] when done with reading.
class SerialPortReader {
  static const stopFlag = "stop";
  static const startFlag = "start";
  static const closeFlag = "close";
  static const doneFlag = "done";
  final SerialPort _port;
  final int _timeout;
  Isolate? _isolate;
  ReceivePort? _receiver;
  StreamController<Uint8List>? __controller;
  SendPort? _controlPort;
  Stream? _streamOfMesssage;

  /// Creates a reader for the port. Optional [timeout] parameter can be
  /// provided to specify a time im milliseconds between attempts to read after
  /// a failure to open the [port] for reading. If not given, [timeout] defaults
  /// to 500ms.
  SerialPortReader(SerialPort port, {int? timeout})
      : _port = port,
        _timeout = timeout ?? 500;

  /// Gets the port the reader operates on.
  SerialPort get port => _port;

  /// Gets a stream of data.
  Stream<Uint8List> get stream => _controller.stream;

  StreamController<Uint8List> get _controller {
    return __controller ??= StreamController<Uint8List>(
      onListen: _startRead,
      onCancel: _cancelRead,
      onPause: _cancelRead,
      onResume: _startRead,
    );
  }

  void _startRead() {
    _receiver = ReceivePort();
    final args = _SerialPortReaderArgs(
      address: _port.address,
      timeout: _timeout,
      sendPort: _receiver!.sendPort,
    );
    Isolate.spawn(
      _background,
      args,
      debugName: toString(),
    ).then((value) {
      _isolate = value;
      _streamOfMesssage = _receiver!.asBroadcastStream();
      _streamOfMesssage!.first.then((value) {
        _controlPort = value;
        _controlPort!.send(startFlag);
        _streamOfMesssage!.listen((data) {
          if (data is SerialPortError || data is IsolateError) {
            _controller.addError(data);
          } else if (data is Uint8List) {
            _controller.add(data);
          }
        });
      });
    });
  }

  Future<bool> _waitCloseReceiver() async {
    while (_receiver != null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return _receiver == null;
  }

  Future<bool> _waitStopBackground() async {
    if (_streamOfMesssage == null) return false;
    final result = await _streamOfMesssage!
        .firstWhere((msg) => msg == stopFlag /*|| msg == doneFlag*/)
        .timeout(const Duration(milliseconds: 2000), onTimeout: () => null);
    return result != null && (result == stopFlag || result == doneFlag );
  }

  /// Closes the stream.
  Future<void> close() async {
    await __controller?.close();
    final success = await _waitCloseReceiver();
    if (!success) {
      print("[WARN] Reader not closed.");
    }
    __controller = null;
    _controlPort = null;
  }

  Future<void> _cancelRead() async {
    _controlPort?.send(stopFlag);
    await _waitStopBackground();
    if (_controlPort != null) {
      _controlPort = null;
    }

    _receiver?.close();
    _receiver = null;
    /*_isolate?.kill(priority: Isolate.immediate);
    _isolate = null;*/
    //await Future<void>.delayed(const Duration(milliseconds: 1000));
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
  }

  static Future<void> _background(_SerialPortReaderArgs args) async {
    final controlPort = ReceivePort();
    Stream streamOfControlMesssage = controlPort.asBroadcastStream();
    args.sendPort.send(controlPort.sendPort);

    bool stopEvents = false;
    bool isEnabled = false;
    bool isClosed = false;

    streamOfControlMesssage.handleError((error) {
      args.sendPort.send(IsolateError(error));
    }).listen((message) {
      if (message == startFlag) {
        stopEvents = false;
        isClosed = false;
        if (!isEnabled) {
          isEnabled = true;
          _waitRead(args, () => !stopEvents, onDone: () {
            isEnabled = false;
            args.sendPort.send(stopEvents ? stopFlag : doneFlag);
          });
        }
        args.sendPort.send(startFlag);
      } else if (message == stopFlag) {
        stopEvents = true;
      } else if (message == closeFlag) {
        stopEvents = true;
        isClosed = true;
      }
    });

    await Future(() async {
      while (!isClosed) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      args.sendPort.send(closeFlag);
      controlPort.close();
      return;
    });
  }

  static Future<void> _waitRead(
      _SerialPortReaderArgs args, bool Function() continueCallback,
      {void Function()? onDone}) async {
    bool stopEvents = !continueCallback();

    final port = ffi.Pointer<sp_port>.fromAddress(args.address);
    final events = _createEvents(port, _kReadEvents);
    var bytes = 0;
    while (bytes >= 0 && !stopEvents) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      stopEvents = !continueCallback();
      if (stopEvents) {
        continue;
      }

      bytes = _waitEvents(port, events, args.timeout);
      if (bytes > 0) {
        final data = Util.read(bytes, (ffi.Pointer<ffi.Uint8> ptr) {
          return dylib.sp_nonblocking_read(port, ptr.cast(), bytes);
        });
        args.sendPort.send(data);
      } else if (bytes < 0) {
        args.sendPort.send(SerialPort.lastError);
      }
    }
    _releaseEvents(events);
    if (onDone != null) {
      onDone();
    }
    //await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  static ffi.Pointer<ffi.Pointer<sp_event_set>> _createEvents(
    ffi.Pointer<sp_port> port,
    int mask,
  ) {
    final events = pkg_ffi.calloc<ffi.Pointer<sp_event_set>>();
    dylib.sp_new_event_set(events);
    dylib.sp_add_port_events(events.value, port, mask);
    return events;
  }

  static int _waitEvents(
    ffi.Pointer<sp_port> port,
    ffi.Pointer<ffi.Pointer<sp_event_set>> events,
    int timeout,
  ) {
    dylib.sp_wait(events.value, timeout);
    return dylib.sp_input_waiting(port);
  }

  static void _releaseEvents(ffi.Pointer<ffi.Pointer<sp_event_set>> events) {
    dylib.sp_free_event_set(events.value);
  }
}
