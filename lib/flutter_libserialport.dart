
import 'package:flutter_libserialport/flutter_libserialport_platform_interface.dart';

export 'package:flutter_libserialport/src/libserialport.dart';
//export 'src/config.dart' show SerialPortConfig;
//export 'src/enums.dart';
//export 'src/error.dart';
//export 'src/port.dart' show SerialPort;
//export 'src/reader.dart' show SerialPortReader;

class FlutterLibserialport {
  Future<String?> getPlatformVersion() {
    return FlutterLibserialportPlatform.instance.getPlatformVersion();
  }
}
