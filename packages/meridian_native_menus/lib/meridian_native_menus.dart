/// Native operating-system menus for Meridian apps.
///
/// Wrap each app root in [MeridianNativeMenus.scope] (inside the
/// `MaterialApp` builder): every Meridian menu (menu anchors, selects, split
/// buttons, context menus) and the text-editing menu of every
/// `MeridianTextField` then show as the platform's own menus on macOS,
/// Windows and Linux. Other platforms keep Meridian's menus.
library;

export 'src/native_menu_model.dart';
export 'src/native_menus.dart';
