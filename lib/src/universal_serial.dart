import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:usb_serial/usb_serial.dart';

typedef DeviceList = List<UartDevice>;

class UartDevice {
  late final int? deviceId;
  late final String deviceName;
  late final int? interfaceCount;
  late final String? manufacturerName;
  late final int? pid;
  late final String? productName;
  late final String? serial;
  late final int? vid;
  late String? description;
  late String? macAddress;
  late int? busNumber;
  late int? transport;

  UartDevice(
      {required this.deviceName,
      this.deviceId,
      this.interfaceCount,
      this.manufacturerName,
      this.pid,
      this.productName,
      this.serial,
      this.vid,

      ///
      this.description,
      this.macAddress,
      this.busNumber,
      this.transport});

  @override
  String toString() {
    return "UartDevice: $deviceName, ${vid!.toRadixString(16)}-${pid!.toRadixString(16)} $productName, $manufacturerName $serial";
  }

  factory UartDevice._fromUsbDevice(UsbDevice device) {
    return UartDevice(
      deviceName: device.deviceName,
      deviceId: device.deviceId,
      interfaceCount: device.interfaceCount,
      manufacturerName: device.manufacturerName,
      pid: device.pid,
      productName: device.productName,
      serial: device.serial,
      vid: device.vid,
    );
  }

  factory UartDevice._fromPort(SerialPort port) {
    final device = UartDevice(
      deviceName: port.name ?? "",
      manufacturerName: port.manufacturer,
      productName: port.productName,
      serial: port.serialNumber,
      pid: port.productId,
      vid: port.vendorId,
      deviceId: port.deviceNumber, //* ????
      //* interfaceCount:
    );
    return device;
  }

  UsbDevice _toUsbDevice() {
    final device = UsbDevice(deviceName, vid, pid, productName,
        manufacturerName, deviceId, serial, interfaceCount);
    return device;
  }
}

class UartConfig {
  final int baudRate;
  final int dataBits;
  final int stopBits;
  final int parity;
  final int? dtr;
  final int? rts;

  UartConfig(
      {required this.baudRate,
      required this.dataBits,
      required this.stopBits,
      required this.parity,
      this.dtr,
      this.rts});
}

enum BaudRates {
  bps_9600(9600),
  bps_14400(14400),
  bps_19200(19200),
  bps_38400(38400),
  bps_57600(57600),
  bps_115200(115200),
  bps_128000(128000),
  bps_256000(256000);

  const BaudRates(this.value);

  final int value;
}

enum DataBits {
  /// Constant to configure port with 5 databits.
  bits_5(UsbPort.DATABITS_5),

  /// Constant to configure port with 6 databits.
  bits_6(UsbPort.DATABITS_6),

  /// Constant to configure port with 7 databits.
  bits_7(UsbPort.DATABITS_7),

  /// Constant to configure port with 8 databits.
  bits_8(UsbPort.DATABITS_5);

  final int value;

  const DataBits(this.value);
}

enum StopBits {
  /// Constant to configure port with 1 stop bits
  bits_1(UsbPort.STOPBITS_1),

  /// Constant to configure port with 1.5 stop bits
  bits_1_5(UsbPort.STOPBITS_1_5),

  /// Constant to configure port with 2 stop bits
  bits_2(UsbPort.STOPBITS_2);

  final int value;

  const StopBits(this.value);
}

enum Parities {
  /// Constant to configure port with parity none
  none(UsbPort.PARITY_NONE),

  /// Constant to configure port with event parity.
  even(UsbPort.PARITY_EVEN),

  /// Constant to configure port with odd parity.
  odd(UsbPort.PARITY_ODD),

  /// Constant to configure port with mark parity.
  mark(UsbPort.PARITY_MARK),

  /// Constant to configure port with space parity.
  space(UsbPort.PARITY_SPACE);

  final int value;

  const Parities(this.value);
}

abstract class UniversalSerialPort {
  factory UniversalSerialPort.getSerialPort() {
    return Platform.isAndroid ? _UsbPortWrapper() : _SerialPortWrapper();
  }

  Future<DeviceList> get availablePorts;
  Future<bool> connect(
    UartDevice device, {
    String type = "",
    int interface = -1,
  });

  Future<bool> open(UartConfig config);
  Future<bool> close();
  bool get isConnected;
  bool get isOpen;
  Stream<Uint8List>? get inputStream;
}

class _SerialPortWrapper implements UniversalSerialPort {
  SerialPort? _instance;
  SerialPortReader? _reader;
  UartDevice? _device;
  bool _isConnected = false;
  bool _isOpen = false;
  StreamSubscription<Uint8List>? _streamSubscription;

  @override
  Future<DeviceList> get availablePorts async {
    final list = await Future<DeviceList>(
        () => SerialPort.availablePorts.map((portName) {
              final port = SerialPort(portName);
              final device = UartDevice._fromPort(port);
              port.dispose();
              return device;
            }).toList());
    return list;
  }

  @override
  Future<bool> connect(
    UartDevice device, {
    String type = "",
    int interface = -1,
  }) async {
    final succes = await Future<bool>(() async {
      if (isConnected &&
          _instance != null &&
          (device.deviceName == _instance!.name ||
              device.deviceName == _device?.deviceName)) return true;
      await close();

      _instance = SerialPort(device.deviceName);
      if (SerialPort.lastError != null) {
        if (SerialPort.lastError!.errorCode == 2 &&
            SerialPort.lastError!.message == "No such file or directory") {
          if (kDebugMode) {
            print('[WARN] ${SerialPort.lastError!.message}');
          }
          return true;
        }
        return false;
      }

      return true;
    });
    _isConnected = succes;
    if (_isConnected) _device = device;
    return succes;
  }

  //@override
  Future<bool> _close() async {
    if (_reader != null) {
      await _reader!.close();
    }
    _instance?.close();
    _isOpen = false;
    _device = null;
    return !_isOpen;
  }

  void _dispose() {
    _isConnected = false;
    _isOpen = false;
    _instance?.dispose();
    _instance = null;
    _device = null;
    //_reader?.dispose();
    _reader = null;
  }

  @override
  Future<bool> close() async {
    final success = await _close();
    _dispose();
    return success;
  }

  @override
  bool get isOpen => _isOpen;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<bool> open(UartConfig config) async {
    final success = Future<bool>(() {
      if (_instance == null || !_isConnected) {
        return false;
      }
      if (_isOpen) return true;
      return _instance != null &&
          _instance!.open(mode: SerialPortMode.readWrite);
    });
    _isOpen = await success;
    if (_isOpen) {
      final srcConfig = SerialPortConfig();

      srcConfig.baudRate = config.baudRate;
      srcConfig.bits = config.dataBits;
      srcConfig.parity = config.parity;
      srcConfig.stopBits = config.stopBits;
      srcConfig.dtr = config.dtr ?? -1;
      srcConfig.rts = config.rts ?? -1;
      srcConfig.xonXoff = -1;
      srcConfig.cts = -1;
      srcConfig.dsr = -1;

      _instance!.config = srcConfig;
    }
    return _isOpen;
  }

  bool _startRead() {
    if (!_isConnected || !_isOpen || _instance == null) return false;
    if (_streamSubscription != null) {
      _streamSubscription!.cancel();
      _streamSubscription = null;
    }
    if (_reader != null) {
      _reader!.close();
    }
    _reader = SerialPortReader(_instance!);
    return true;
  }

  @override
  Stream<Uint8List>? get inputStream {
    _startRead();
    return _reader?.stream;
  }
}

class _UsbPortWrapper implements UniversalSerialPort {
  UsbPort? _instance;
  UartDevice? _device;
  bool _isConnected = false;
  bool _isOpen = false;

  @override
  Future<DeviceList> get availablePorts async {
    return (await UsbSerial.listDevices())
        .map((device) => UartDevice._fromUsbDevice(device))
        .toList();
  }

  @override
  Future<bool> close() async {
    throw UnimplementedError();
  }

  @override
  Future<bool> connect(
    UartDevice device, {
    String type = "",
    int interface = -1,
  }) async {
    if (isConnected &&
        _instance != null &&
        _device != null &&
        device.deviceId == _device!.deviceId) return true;
    close();
    _instance = await UsbSerial.createFromDeviceId(device.deviceId);
    _isConnected = _instance != null;
    if (_isConnected) {
      _device = device;
    }
    return _isConnected;
  }

  @override
  bool get isConnected => _isConnected;

  @override
  bool get isOpen => _isOpen;

  @override
  Future<bool> open(UartConfig config) async {
    if (!_isConnected || _instance == null) {
      _isOpen = false;
      return _isOpen;
    }
    _isOpen = await _instance?.open() ?? false;
    if (_isOpen) {
      if (config.dtr != null && config.dtr! > 0) await _instance!.setDTR(true);
      if (config.rts != null && config.rts! > 0) await _instance!.setRTS(true);
      _instance!.setPortParameters(
          config.baudRate, config.dataBits, config.stopBits, config.parity);
    }
    return _isOpen;
  }

  @override
  Stream<Uint8List>? get inputStream {
    return _instance?.inputStream;
  }
}
