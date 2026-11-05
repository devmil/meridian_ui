import Cocoa
import FlutterMacOS

/// Presents Meridian menus as `NSMenu`s at a point in the engine's view,
/// without requiring a pointer event, so keyboard-opened menus work too.
/// Registered once per engine, so every window gets its own presenter.
public class MeridianNativeMenusPlugin: NSObject, FlutterPlugin {
  private weak var registrar: FlutterPluginRegistrar?
  private var selectedID: Int?

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "meridian_native_menus", binaryMessenger: registrar.messenger)
    let instance = MeridianNativeMenusPlugin(registrar: registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "show" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let view = registrar?.view,
          let request = call.arguments as? [String: Any],
          let x = request["x"] as? Double,
          let y = request["y"] as? Double,
          x.isFinite, y.isFinite,
          let items = request["items"] as? [[String: Any]] else {
      // Never echo menu labels or platform text.
      result(FlutterError(code: "native_menu_invalid_request", message: nil, details: nil))
      return
    }
    selectedID = nil
    let menu = makeMenu(items)
    let position = NSPoint(x: x, y: view.isFlipped ? y : view.bounds.height - y)
    menu.popUp(positioning: nil, at: position, in: view)
    let selectedID = self.selectedID
    DispatchQueue.main.async {
      result(selectedID)
    }
  }

  private func makeMenu(_ entries: [[String: Any]]) -> NSMenu {
    let menu = NSMenu()
    menu.autoenablesItems = false
    for entry in entries {
      if entry["separator"] as? Bool == true {
        menu.addItem(.separator())
        continue
      }
      let title = entry["title"] as? String ?? ""
      if entry["header"] as? Bool == true, #available(macOS 14.0, *) {
        menu.addItem(.sectionHeader(title: title))
        continue
      }
      let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
      item.image = menuIcon(entry["icon"] as? [String: Any])
      if let children = entry["items"] as? [[String: Any]] {
        item.submenu = makeMenu(children)
      } else if let id = entry["id"] as? Int {
        item.tag = id
        item.target = self
        item.action = #selector(selectItem(_:))
      }
      item.isEnabled = entry["enabled"] as? Bool ?? true
      item.state = entry["checked"] as? Bool == true ? .on : .off
      if let shortcut = entry["shortcut"] as? String {
        setShortcut(shortcut, on: item)
      }
      menu.addItem(item)
    }
    return menu
  }

  /// An alpha mask from Flutter as a template image, which AppKit draws in
  /// the menu's own text colour for every appearance and highlight state.
  private func menuIcon(_ icon: [String: Any]?) -> NSImage? {
    guard let icon,
          let width = icon["width"] as? Int, let height = icon["height"] as? Int,
          let scale = icon["scale"] as? Double, scale.isFinite, scale > 0,
          let pixels = (icon["rgba"] as? FlutterStandardTypedData)?.data,
          (1...256).contains(width), (1...256).contains(height),
          pixels.count == width * height * 4,
          let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bitmapFormat: .alphaNonpremultiplied,
            bytesPerRow: width * 4, bitsPerPixel: 32),
          let target = bitmap.bitmapData else {
      return nil
    }
    pixels.copyBytes(to: target, count: pixels.count)
    let size = NSSize(width: Double(width) / scale, height: Double(height) / scale)
    bitmap.size = size
    let image = NSImage(size: size)
    image.addRepresentation(bitmap)
    image.isTemplate = true
    return image
  }

  /// `Ctrl+Alt+Shift+Win+K`: `Win` is the Command key.
  private func setShortcut(_ shortcut: String, on item: NSMenuItem) {
    let parts = shortcut.split(separator: "+").map(String.init)
    guard let key = parts.last else { return }
    var modifiers: NSEvent.ModifierFlags = []
    for part in parts.dropLast() {
      switch part {
      case "Ctrl": modifiers.insert(.control)
      case "Alt": modifiers.insert(.option)
      case "Shift": modifiers.insert(.shift)
      case "Win": modifiers.insert(.command)
      default: break
      }
    }
    let named: [String: UInt32] = [
      "F1": 0xF704, "F2": 0xF705, "F3": 0xF706, "F4": 0xF707,
      "F5": 0xF708, "F6": 0xF709, "F7": 0xF70A, "F8": 0xF70B,
      "F9": 0xF70C, "F10": 0xF70D, "F11": 0xF70E, "F12": 0xF70F,
      "Up": 0xF700, "Down": 0xF701, "Left": 0xF702, "Right": 0xF703,
      "Home": 0xF729, "End": 0xF72B, "PageUp": 0xF72C, "PageDown": 0xF72D,
      "Delete": 0xF728, "Enter": 0x0D, "Tab": 0x09, "Space": 0x20,
      "Backspace": 0x08, "Esc": 0x1B,
    ]
    if let code = named[key], let scalar = UnicodeScalar(code) {
      item.keyEquivalent = String(Character(scalar))
    } else if key.count == 1 {
      item.keyEquivalent = key.lowercased()
    } else {
      return
    }
    item.keyEquivalentModifierMask = modifiers
  }

  @objc private func selectItem(_ sender: NSMenuItem) {
    selectedID = sender.tag
  }
}
