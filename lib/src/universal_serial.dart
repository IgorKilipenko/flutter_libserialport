import 'dart:io';

import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:usb_serial/usb_serial.dart';

//UniversalSerial

abstract class UniversalSerial {
  factory UniversalSerial.getSerialPort() {
    return Platform.isAndroid ? _UsbPortWrapper() : _SerialPortWrapper();
  }
  Future<List<UartDevice>> get availablePorts;
  Future<bool> connect(
    UartDevice device, {
    String type = "",
    int interface = -1,
  });
  Future<bool> open();
  bool close();
  bool get isConnected;
  bool get isOpen;
}

class _SerialPortWrapper implements UniversalSerial {
  SerialPort? _instance;
  UartDevice? _device;
  bool _isConnected = false;
  bool _isOpen = false;

  @override
  Future<List<UartDevice>> get availablePorts async {
    final list = await Future<List<UartDevice>>(() => SerialPort.availablePorts
        .map((portName) => UartDevice(deviceName: portName))
        .toList());
    return list;
  }

  @override
  Future<bool> connect(
    UartDevice device, {
    String type = "",
    int interface = -1,
  }) async {
    final succes = await Future<bool>(() {
      if (isConnected &&
          _instance != null &&
          (device.deviceName == _instance!.name || device.deviceName == _device?.deviceName)) return true;
      close();
      _dispose();

      if (SerialPort.lastError != null) {
        _isConnected = false;
        return false;
      }
      _instance = SerialPort(device.deviceName);
      _device = device;
      _isConnected = true;
      return true;
    });
    return succes;
  }

  @override
  bool close() {
    if (_instance != null) {
      if (_instance!.close()) {
        _isConnected = false;
        _isOpen = false;
      }
    }
    _device = null;
    return !_isOpen;
  }

  //@override
  void _dispose() {
    _isConnected = false;
    _isOpen = false;
    _instance?.dispose();
    _instance = null;
    _device = null;
  }

  @override
  bool get isOpen => _isOpen;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<bool> open() async {
    final success = Future<bool>(() {
      if (_instance == null || !_isConnected) {
        return false;
      }
      if (_isOpen) return true;
      return _instance != null &&
          _instance!.open(mode: SerialPortMode.readWrite);
    });
    _isOpen = await success;
    return _isOpen;
  }
}

class UartDevice {
  late final int? deviceId;
  late final String deviceName;
  late final int? interfaceCount;
  late final String? manufacturerName;
  late final int? pid;
  late final String? productName;
  late final String? serial;
  late final int? vid;

  UartDevice({
    required this.deviceName,
    this.deviceId,
    this.interfaceCount,
    this.manufacturerName,
    this.pid,
    this.productName,
    this.serial,
    this.vid,
  });

  factory UartDevice.fromUsbDevice(UsbDevice device) {
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
}

class _UsbPortWrapper implements UniversalSerial {
  UsbPort? _instance;
  UartDevice? _device;
  bool _isConnected = false;
  bool _isOpen = false;

  @override
  Future<List<UartDevice>> get availablePorts async {
    return (await UsbSerial.listDevices())
        .map((device) => UartDevice.fromUsbDevice(device))
        .toList();
  }

  @override
  bool close() {
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
  Future<bool> open() async {
    if (!_isConnected || _instance == null) {
      _isOpen = false;
      return _isOpen;
    }
    _isOpen = await _instance?.open() ?? false;
    return _isOpen;
  }
}
