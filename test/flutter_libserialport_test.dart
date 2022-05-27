import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/flutter_test.dart' as testing;
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:flutter_libserialport/flutter_libserialport_platform_interface.dart';
import 'package:flutter_libserialport/flutter_libserialport_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter_libserialport/src/dylib.dart';
import 'package:flutter_libserialport/src/libserialport.dart';

class MockFlutterLibserialportPlatform
    with MockPlatformInterfaceMixin
    implements FlutterLibserialportPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterLibserialportPlatform initialPlatform =
      FlutterLibserialportPlatform.instance;

  test('$MethodChannelFlutterLibserialport is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterLibserialport>());
  });

  test('getPlatformVersion', () async {
    FlutterLibserialport flutterLibserialportPlugin = FlutterLibserialport();
    MockFlutterLibserialportPlatform fakePlatform =
        MockFlutterLibserialportPlatform();
    FlutterLibserialportPlatform.instance = fakePlatform;

    expect(await flutterLibserialportPlugin.getPlatformVersion(), '42');
  });

  group('Test utils Native', () {
    test('utils_getLocaleName', () {
      final localePtr = dylib.utils_geCurrenttLocaleName();
      expect(localePtr.address, testing.isNot(0), reason: 'Loacle is null pointer');
      if (kDebugMode) {
        print('Locale name : ${localePtr.toDartString()}');
      }
    });
  });
}
