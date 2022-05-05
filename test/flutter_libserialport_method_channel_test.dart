import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_libserialport/flutter_libserialport_method_channel.dart';

void main() {
  MethodChannelFlutterLibserialport platform = MethodChannelFlutterLibserialport();
  const MethodChannel channel = MethodChannel('flutter_libserialport');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
