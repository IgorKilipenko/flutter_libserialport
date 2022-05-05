#include "include/flutter_libserialport/flutter_libserialport_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_libserialport_plugin.h"

void FlutterLibserialportPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_libserialport::FlutterLibserialportPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
