#include "meridian_native_menus_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/standard_method_codec.h>

#include <cmath>
#include <cstdint>
#include <stdexcept>
#include <string>
#include <vector>

namespace meridian_native_menus {

namespace {
using Value = flutter::EncodableValue;
using Map = flutter::EncodableMap;
using List = flutter::EncodableList;

const Value& Field(const Map& map, const char* key) {
  const auto it = map.find(Value(key));
  if (it == map.end()) throw std::invalid_argument("native_menu_field_missing");
  return it->second;
}

bool OptionalBool(const Map& map, const char* key, bool fallback) {
  const auto it = map.find(Value(key));
  if (it == map.end()) return fallback;
  const auto* value = std::get_if<bool>(&it->second);
  return value ? *value : fallback;
}

std::wstring Wide(const std::string& text) {
  const int size = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
                                       text.data(), static_cast<int>(text.size()),
                                       nullptr, 0);
  if (size == 0 && !text.empty()) {
    throw std::invalid_argument("native_menu_title_invalid");
  }
  std::wstring result(size, L'\0');
  MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text.data(),
                      static_cast<int>(text.size()), result.data(), size);
  // User-controlled ampersands must not turn into Win32 mnemonic markers.
  for (size_t i = 0; (i = result.find(L'&', i)) != std::wstring::npos; i += 2) {
    result.insert(i, 1, L'&');
  }
  return result;
}

struct OwnedMenu {
  HMENU handle = CreatePopupMenu();
  OwnedMenu() {
    if (!handle) throw std::runtime_error("native_menu_create_failed");
  }
  ~OwnedMenu() {
    if (handle) DestroyMenu(handle);
  }
  OwnedMenu(const OwnedMenu&) = delete;
  OwnedMenu& operator=(const OwnedMenu&) = delete;
};

// Bitmaps must outlive the menu that shows them.
struct OwnedBitmaps {
  std::vector<HBITMAP> handles;
  OwnedBitmaps() = default;
  ~OwnedBitmaps() {
    for (const auto handle : handles) DeleteObject(handle);
  }
  OwnedBitmaps(const OwnedBitmaps&) = delete;
  OwnedBitmaps& operator=(const OwnedBitmaps&) = delete;
};

// An alpha mask from Flutter, tinted with the system menu text colour. A menu
// never fails for an icon: an unusable one is left out.
HBITMAP MenuIcon(const Map& item, bool enabled) {
  const auto found = item.find(Value("icon"));
  if (found == item.end()) return nullptr;
  const auto* icon = std::get_if<Map>(&found->second);
  if (!icon) return nullptr;
  const auto width_field = icon->find(Value("width"));
  const auto height_field = icon->find(Value("height"));
  const auto pixels_field = icon->find(Value("rgba"));
  if (width_field == icon->end() || height_field == icon->end() ||
      pixels_field == icon->end()) {
    return nullptr;
  }
  const auto* width = std::get_if<int32_t>(&width_field->second);
  const auto* height = std::get_if<int32_t>(&height_field->second);
  const auto* pixels = std::get_if<std::vector<uint8_t>>(&pixels_field->second);
  if (!width || !height || !pixels || *width < 1 || *width > 256 ||
      *height < 1 || *height > 256 ||
      pixels->size() != static_cast<size_t>(*width) * *height * 4) {
    return nullptr;
  }
  BITMAPINFO info{};
  info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  info.bmiHeader.biWidth = *width;
  info.bmiHeader.biHeight = -*height;  // Top-down rows, as Flutter sends them.
  info.bmiHeader.biPlanes = 1;
  info.bmiHeader.biBitCount = 32;
  info.bmiHeader.biCompression = BI_RGB;
  void* bits = nullptr;
  const HBITMAP bitmap =
      CreateDIBSection(nullptr, &info, DIB_RGB_COLORS, &bits, nullptr, 0);
  if (!bitmap || !bits) {
    if (bitmap) DeleteObject(bitmap);
    return nullptr;
  }
  const COLORREF color = GetSysColor(enabled ? COLOR_MENUTEXT : COLOR_GRAYTEXT);
  auto* target = static_cast<uint8_t*>(bits);
  for (size_t i = 0; i < pixels->size(); i += 4) {
    const unsigned alpha = (*pixels)[i + 3];
    // Menu bitmaps are premultiplied BGRA.
    target[i] = static_cast<uint8_t>(GetBValue(color) * alpha / 255);
    target[i + 1] = static_cast<uint8_t>(GetGValue(color) * alpha / 255);
    target[i + 2] = static_cast<uint8_t>(GetRValue(color) * alpha / 255);
    target[i + 3] = static_cast<uint8_t>(alpha);
  }
  return bitmap;
}

void SetMenuIcon(HMENU menu, const Map& item, bool enabled,
                 OwnedBitmaps& bitmaps) {
  const HBITMAP bitmap = MenuIcon(item, enabled);
  if (!bitmap) return;
  bitmaps.handles.push_back(bitmap);
  MENUITEMINFOW info{};
  info.cbSize = sizeof(info);
  info.fMask = MIIM_BITMAP;
  info.hbmpItem = bitmap;
  // The item was appended last.
  SetMenuItemInfoW(menu, GetMenuItemCount(menu) - 1, TRUE, &info);
}

void FillMenu(HMENU menu, const List& entries, OwnedBitmaps& bitmaps) {
  for (const auto& entry : entries) {
    const auto& item = std::get<Map>(entry);
    if (item.find(Value("separator")) != item.end()) {
      if (!AppendMenuW(menu, MF_SEPARATOR, 0, nullptr)) {
        throw std::runtime_error("native_menu_append_failed");
      }
      continue;
    }
    auto title = Wide(std::get<std::string>(Field(item, "title")));
    const auto children = item.find(Value("items"));
    if (children != item.end()) {
      const bool enabled = OptionalBool(item, "enabled", true);
      OwnedMenu submenu;
      FillMenu(submenu.handle, std::get<List>(children->second), bitmaps);
      UINT flags = MF_POPUP | MF_STRING;
      if (!enabled) flags |= MF_GRAYED;
      if (!AppendMenuW(menu, flags,
                       reinterpret_cast<UINT_PTR>(submenu.handle),
                       title.c_str())) {
        throw std::runtime_error("native_menu_append_failed");
      }
      submenu.handle = nullptr;  // The parent owns it now.
      SetMenuIcon(menu, item, enabled, bitmaps);
      continue;
    }
    UINT flags = MF_STRING;
    const bool enabled = std::get<bool>(Field(item, "enabled"));
    if (!enabled) flags |= MF_GRAYED;
    if (std::get<bool>(Field(item, "checked"))) flags |= MF_CHECKED;
    const auto shortcut = item.find(Value("shortcut"));
    if (shortcut != item.end()) {
      title += L"\t" + Wide(std::get<std::string>(shortcut->second));
    }
    const auto id = std::get<int32_t>(Field(item, "id"));
    if (id <= 0 ||
        !AppendMenuW(menu, flags, static_cast<UINT_PTR>(id), title.c_str())) {
      throw std::invalid_argument("native_menu_item_invalid");
    }
    SetMenuIcon(menu, item, enabled, bitmaps);
  }
}
}  // namespace

// static
void MeridianNativeMenusPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<Value>>(
      registrar->messenger(), "meridian_native_menus",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<MeridianNativeMenusPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

MeridianNativeMenusPlugin::MeridianNativeMenusPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {}

MeridianNativeMenusPlugin::~MeridianNativeMenusPlugin() {}

void MeridianNativeMenusPlugin::HandleMethodCall(
    const flutter::MethodCall<Value>& call,
    std::unique_ptr<flutter::MethodResult<Value>> result) {
  if (call.method_name() != "show") {
    result->NotImplemented();
    return;
  }
  try {
    // GetNativeWindow is not const, so the view pointer must not be either.
    flutter::FlutterView* flutter_view = registrar_->GetView();
    if (!flutter_view) throw std::runtime_error("native_menu_no_view");
    const HWND view = flutter_view->GetNativeWindow();
    if (!call.arguments()) throw std::invalid_argument("native_menu_arguments");
    const auto& args = std::get<Map>(*call.arguments());
    const double x = std::get<double>(Field(args, "x"));
    const double y = std::get<double>(Field(args, "y"));
    if (!std::isfinite(x) || !std::isfinite(y) || std::abs(x) > 100000 ||
        std::abs(y) > 100000) {
      throw std::invalid_argument("native_menu_position");
    }
    OwnedBitmaps bitmaps;
    OwnedMenu menu;
    FillMenu(menu.handle, std::get<List>(Field(args, "items")), bitmaps);
    const double scale = GetDpiForWindow(view) / 96.0;
    POINT position{static_cast<LONG>(std::lround(x * scale)),
                   static_cast<LONG>(std::lround(y * scale))};
    if (!ClientToScreen(view, &position)) {
      throw std::runtime_error("native_menu_position_failed");
    }
    const HWND owner = GetAncestor(view, GA_ROOT);
    SetForegroundWindow(owner);
    const auto selected = TrackPopupMenuEx(
        menu.handle, TPM_RETURNCMD | TPM_NONOTIFY | TPM_RIGHTBUTTON,
        position.x, position.y, owner, nullptr);
    PostMessage(owner, WM_NULL, 0, 0);
    if (selected == 0) {
      result->Success();
    } else {
      result->Success(Value(static_cast<int32_t>(selected)));
    }
  } catch (...) {
    // Do not expose menu labels or native exception text.
    result->Error("native_menu_failed");
  }
}

}  // namespace meridian_native_menus
