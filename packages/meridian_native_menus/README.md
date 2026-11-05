# meridian_native_menus

Meridian's companion package for apps that show the operating system's own
menus. It renders Meridian's menu model (`MeridianMenuEntry`) as native
context and action menus, so a Meridian app keeps one menu model while its
menus look and behave like the platform's.

Apps that are happy with Meridian's own menus do not need this package;
`meridian_ui` does not depend on it.

| Platform | How the menu is shown |
|---|---|
| macOS | `NSMenu` from this package's host plugin (system appearance, template icons, key equivalents, section headers on macOS 14+) |
| Windows | Win32 popup menu from this package's host plugin (system menu colours, `&` escaped, shortcut text after a tab) |
| Linux | `super_native_extensions` (GTK) |
| Other | Not supported: `MeridianNativeMenus.scope` leaves Meridian's own menus in place |

The macOS and Windows hosts need no pointer event, so menus opened from the
keyboard (Shift+F10, the menu key, Enter on a menu button) appear at their
anchor. The plugin registers once per Flutter engine, so secondary windows
(for example from `desktop_multi_window`) get their own presenter as long as
they register the generated plugins.

## Install

```yaml
dependencies:
  meridian_ui:
    git:
      url: https://github.com/devmil/meridian_ui.git
      ref: <commit sha>
  meridian_native_menus:
    git:
      url: https://github.com/devmil/meridian_ui.git
      ref: <the same commit sha>
      path: packages/meridian_native_menus
```

Pin both packages to the same commit. Then install the presenter at every
app root, inside the `MaterialApp` builder so menus see the theme:

```dart
MaterialApp(
  theme: buildMeridianTheme(brand: MeridianBrands.gitlama, brightness: Brightness.light),
  builder: (context, child) => MeridianNativeMenus.scope(child: child!),
  home: const MeridianGround(child: HomeScreen()),
);
```

On Linux, call `await MeridianNativeMenus.prepare();` once at start-up (it is
also called before each menu): the GTK menu anchors to the last button press,
which only the plugin's drag context records.

## What it provides

- `MeridianNativeMenus.scope(child:)` installs a `MeridianMenuPresenter` with
  `MeridianNativeMenus.present` and `nativeTextContextMenuBuilder` on
  supported platforms. Every `MeridianMenuAnchor`, `MeridianSelect`, split
  button, `showMeridianMenu` and `showMeridianContextMenu` call and the
  cut/copy/paste menu of every `MeridianTextField` below it is then native.
  A menu holding a `MeridianMenuCustom` block stays a Meridian menu, because
  an operating-system menu cannot show a widget.
- `MeridianNativeMenus.show(context, entries, position)` shows entries at a
  global position and completes with whether an item was chosen.
- `MeridianNativeContextMenuRegion(entries: (position) => [...], child:)`:
  a secondary click, the context-menu key or Shift+F10 opens the native menu;
  when it closes without a choice, focus returns to where it was.
- `nativeTextContextMenuBuilder` for `TextField`, `SelectableText` and other
  `contextMenuBuilder`s outside Meridian's text field.
- The pure model: `nativeMenuFromMeridian`, `NativeMenuNode`
  (`NativeMenuAction`, `NativeMenuSubmenu`, `NativeMenuSeparator`),
  `NativeMenuShortcut.fromKeycaps` and `encodeHostMenu` (the host protocol).

## Behaviour

- Items keep their label, icon (Meridian/Lucide icons, drawn as template or
  tinted images in the system's menu colour), enabled and checked states,
  `danger` (destructive style on Linux; the hosts have none), submenus,
  headers and dividers. Leading, trailing and doubled dividers are dropped.
  `MeridianMenuItem.hint` and `leading` widgets are not shown.
- Keycap shortcuts (`['⌘', '⇧', 'F']`, `['Ctrl', 'Shift', 'F']`) become the
  item's key equivalent; chords of two keys are not shown.
- A chosen item's `onSelected` runs after the menu has closed and only while
  the context that opened it is still mounted, so follow-up dialogs open
  normally.
- Failures throw `MeridianNativeMenuException` with a stable `code`
  (`native_menu_platform_unsupported`, `native_menu_unavailable`,
  `native_menu_host_failed`); labels and platform messages are never part
  of an error. A Flutter-drawn menu is never substituted silently.

## Host protocol

Channel `meridian_native_menus`, method `show` with `x` and `y` (logical
pixels in the view) and `items`: a list of `{separator: true}`,
`{title, enabled, icon?, items}` (a submenu) or `{id, title, enabled,
checked, header?, danger?, shortcut?, icon?}`. `shortcut` is
`Ctrl+Alt+Shift+Win+Key` (`Win` is Command on macOS); `icon` is
`{width, height, scale, rgba}` with straight RGBA bytes whose alpha is the
mask. The host returns the chosen `id`, or `null`.

## Tests

`flutter test` covers the model, the host protocol (mocked channel on macOS
and Windows), the presenter, the context-menu region (pointer, keyboard,
focus restoration, disabled) and the text menu, with
`MeridianNativeMenus.debugShowOverride` in place of the platform. The
native hosts are exercised only by running an app on macOS and Windows.
