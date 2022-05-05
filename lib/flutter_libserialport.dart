
import 'flutter_libserialport_platform_interface.dart';

export 'package:libserialport/libserialport.dart';

class FlutterLibserialport {
  Future<String?> getPlatformVersion() {
    return FlutterLibserialportPlatform.instance.getPlatformVersion();
  }
}
