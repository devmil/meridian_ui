#include "include/meridian_native_menus/meridian_native_menus_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "meridian_native_menus_plugin.h"

void MeridianNativeMenusPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  meridian_native_menus::MeridianNativeMenusPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
