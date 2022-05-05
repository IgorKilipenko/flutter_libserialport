#import "FlutterLibserialportPlugin.h"
#if __has_include(<flutter_libserialport/flutter_libserialport-Swift.h>)
#import <flutter_libserialport/flutter_libserialport-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_libserialport-Swift.h"
#endif

@implementation FlutterLibserialportPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterLibserialportPlugin registerWithRegistrar:registrar];
}
@end
