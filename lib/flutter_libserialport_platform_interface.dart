import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_libserialport_method_channel.dart';

abstract class FlutterLibserialportPlatform extends PlatformInterface {
  /// Constructs a FlutterLibserialportPlatform.
  FlutterLibserialportPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterLibserialportPlatform _instance = MethodChannelFlutterLibserialport();

  /// The default instance of [FlutterLibserialportPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterLibserialport].
  static FlutterLibserialportPlatform get instance => _instance;
  
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterLibserialportPlatform] when
  /// they register themselves.
  static set instance(FlutterLibserialportPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
