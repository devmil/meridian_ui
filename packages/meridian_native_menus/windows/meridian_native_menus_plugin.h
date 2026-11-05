#ifndef FLUTTER_PLUGIN_MERIDIAN_NATIVE_MENUS_PLUGIN_H_
#define FLUTTER_PLUGIN_MERIDIAN_NATIVE_MENUS_PLUGIN_H_

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace meridian_native_menus {

// Presents Meridian menus as Win32 popup menus at a point in the engine's
// view. Registered once per engine, so every window gets its own presenter.
class MeridianNativeMenusPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit MeridianNativeMenusPlugin(flutter::PluginRegistrarWindows* registrar);
  virtual ~MeridianNativeMenusPlugin();

  MeridianNativeMenusPlugin(const MeridianNativeMenusPlugin&) = delete;
  MeridianNativeMenusPlugin& operator=(const MeridianNativeMenusPlugin&) = delete;

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  flutter::PluginRegistrarWindows* registrar_;
};

}  // namespace meridian_native_menus

#endif  // FLUTTER_PLUGIN_MERIDIAN_NATIVE_MENUS_PLUGIN_H_
