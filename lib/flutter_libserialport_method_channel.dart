import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_libserialport_platform_interface.dart';

/// An implementation of [FlutterLibserialportPlatform] that uses method channels.
class MethodChannelFlutterLibserialport extends FlutterLibserialportPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_libserialport');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
