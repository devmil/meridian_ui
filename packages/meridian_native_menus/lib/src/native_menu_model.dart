import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show SingleActivator;
import 'package:meridian_ui/meridian_ui.dart';

/// One element of a native menu, converted from a [MeridianMenuEntry].
///
/// The tree is plain data, so it can be tested and sent to a host without a
/// platform: [nativeMenuFromMeridian] builds it and [encodeHostMenu] turns it
/// into the method-channel protocol of the macOS and Windows hosts.
@immutable
sealed class NativeMenuNode {
  const NativeMenuNode();
}

/// A hairline between groups.
final class NativeMenuSeparator extends NativeMenuNode {
  const NativeMenuSeparator();
}

/// A command, or a section header ([header]) that cannot be chosen.
final class NativeMenuAction extends NativeMenuNode {
  const NativeMenuAction({
    required this.id,
    required this.title,
    this.enabled = true,
    this.checked,
    this.danger = false,
    this.icon,
    this.shortcut,
    this.header = false,
    this.onSelected,
  });

  /// Unique within one menu, from 1; the host reports it when chosen.
  final int id;
  final String title;
  final bool enabled;

  /// `true` shows a check; `null` leaves room for none.
  final bool? checked;
  final bool danger;

  /// A Meridian icon name.
  final String? icon;
  final NativeMenuShortcut? shortcut;

  /// Names the group of items below it; never enabled.
  final bool header;

  /// Runs after the menu has closed when this action was chosen.
  final VoidCallback? onSelected;
}

/// An item that opens [children] beside the menu.
final class NativeMenuSubmenu extends NativeMenuNode {
  const NativeMenuSubmenu({
    required this.title,
    required this.children,
    this.icon,
    this.enabled = true,
  });

  final String title;
  final List<NativeMenuNode> children;
  final String? icon;
  final bool enabled;
}

/// The key combination a menu item shows, parsed from Meridian keycaps
/// (`['⌘', '⇧', 'F']`, `['Ctrl', 'Shift', 'F']`).
@immutable
class NativeMenuShortcut {
  const NativeMenuShortcut({
    required this.key,
    this.control = false,
    this.alt = false,
    this.shift = false,
    this.meta = false,
  });

  /// The key's label: an upper-case letter or digit, `F1`…`F24`, or a named
  /// key (`Enter`, `Tab`, `Space`, `Backspace`, `Delete`, `Esc`, `Up`,
  /// `Down`, `Left`, `Right`, `Home`, `End`, `PageUp`, `PageDown`).
  final String key;
  final bool control, alt, shift, meta;

  static const _meta = {'⌘', 'cmd', 'command', 'meta', 'win', 'super'};
  static const _control = {'⌃', 'ctrl', 'control'};
  static const _alt = {'⌥', 'alt', 'option', 'opt'};
  static const _shift = {'⇧', 'shift'};
  static const _named = {
    '↵': 'Enter',
    '⏎': 'Enter',
    'enter': 'Enter',
    'return': 'Enter',
    '⇥': 'Tab',
    'tab': 'Tab',
    'space': 'Space',
    '␣': 'Space',
    '⌫': 'Backspace',
    'backspace': 'Backspace',
    '⌦': 'Delete',
    'del': 'Delete',
    'delete': 'Delete',
    '⎋': 'Esc',
    'esc': 'Esc',
    'escape': 'Esc',
    '↑': 'Up',
    'up': 'Up',
    '↓': 'Down',
    'down': 'Down',
    '←': 'Left',
    'left': 'Left',
    '→': 'Right',
    'right': 'Right',
    'home': 'Home',
    'end': 'End',
    'pageup': 'PageUp',
    'pagedown': 'PageDown',
  };

  /// The shortcut [keycaps] describe, or `null` when they name no single
  /// key a native menu can show.
  static NativeMenuShortcut? fromKeycaps(List<String>? keycaps) {
    if (keycaps == null || keycaps.isEmpty) return null;
    var control = false, alt = false, shift = false, meta = false;
    String? key;
    for (final raw in keycaps) {
      final cap = raw.trim();
      final lower = cap.toLowerCase();
      if (_meta.contains(lower)) {
        meta = true;
      } else if (_control.contains(lower)) {
        control = true;
      } else if (_alt.contains(lower)) {
        alt = true;
      } else if (_shift.contains(lower)) {
        shift = true;
      } else {
        if (key != null) return null; // A chord of two keys.
        key = _keyLabel(cap);
        if (key == null) return null;
      }
    }
    if (key == null) return null;
    return NativeMenuShortcut(
      key: key,
      control: control,
      alt: alt,
      shift: shift,
      meta: meta,
    );
  }

  static String? _keyLabel(String cap) {
    final named = _named[cap.toLowerCase()];
    if (named != null) return named;
    if (RegExp(r'^[fF]([1-9]|1[0-9]|2[0-4])$').hasMatch(cap)) {
      return cap.toUpperCase();
    }
    if (cap.runes.length == 1) return cap.toUpperCase();
    return null;
  }

  /// The host protocol's form: modifiers in a fixed order, then the key
  /// (`Ctrl+Alt+Shift+Win+K`; the macOS host shows `Win` as ⌘).
  String get hostLabel => [
    if (control) 'Ctrl',
    if (alt) 'Alt',
    if (shift) 'Shift',
    if (meta) 'Win',
    key,
  ].join('+');

  /// The activator for a Flutter-side native menu (Linux), or `null` for a
  /// key without a logical key.
  SingleActivator? get activator {
    final logical = switch (key) {
      'Enter' => LogicalKeyboardKey.enter,
      'Tab' => LogicalKeyboardKey.tab,
      'Space' => LogicalKeyboardKey.space,
      'Backspace' => LogicalKeyboardKey.backspace,
      'Delete' => LogicalKeyboardKey.delete,
      'Esc' => LogicalKeyboardKey.escape,
      'Up' => LogicalKeyboardKey.arrowUp,
      'Down' => LogicalKeyboardKey.arrowDown,
      'Left' => LogicalKeyboardKey.arrowLeft,
      'Right' => LogicalKeyboardKey.arrowRight,
      'Home' => LogicalKeyboardKey.home,
      'End' => LogicalKeyboardKey.end,
      'PageUp' => LogicalKeyboardKey.pageUp,
      'PageDown' => LogicalKeyboardKey.pageDown,
      _ when key.length > 1 && key.startsWith('F') =>
        _functionKeys[int.parse(key.substring(1)) - 1],
      _ => LogicalKeyboardKey.findKeyByKeyId(key.toLowerCase().runes.single),
    };
    if (logical == null) return null;
    return SingleActivator(
      logical,
      control: control,
      alt: alt,
      shift: shift,
      meta: meta,
    );
  }

  static final _functionKeys = [
    LogicalKeyboardKey.f1,
    LogicalKeyboardKey.f2,
    LogicalKeyboardKey.f3,
    LogicalKeyboardKey.f4,
    LogicalKeyboardKey.f5,
    LogicalKeyboardKey.f6,
    LogicalKeyboardKey.f7,
    LogicalKeyboardKey.f8,
    LogicalKeyboardKey.f9,
    LogicalKeyboardKey.f10,
    LogicalKeyboardKey.f11,
    LogicalKeyboardKey.f12,
    LogicalKeyboardKey.f13,
    LogicalKeyboardKey.f14,
    LogicalKeyboardKey.f15,
    LogicalKeyboardKey.f16,
    LogicalKeyboardKey.f17,
    LogicalKeyboardKey.f18,
    LogicalKeyboardKey.f19,
    LogicalKeyboardKey.f20,
    LogicalKeyboardKey.f21,
    LogicalKeyboardKey.f22,
    LogicalKeyboardKey.f23,
    LogicalKeyboardKey.f24,
  ];

  @override
  bool operator ==(Object other) =>
      other is NativeMenuShortcut &&
      other.key == key &&
      other.control == control &&
      other.alt == alt &&
      other.shift == shift &&
      other.meta == meta;

  @override
  int get hashCode => Object.hash(key, control, alt, shift, meta);

  @override
  String toString() => hostLabel;
}

/// The native menu of Meridian menu [entries]. Items keep their label,
/// icon, shortcut, enabled, checked and destructive state; items with
/// children become submenus; headers become section headers and dividers
/// separators. [MeridianMenuCustom] blocks cannot be shown by an operating
/// system menu and are left out (Meridian draws a menu holding one itself).
/// Item [MeridianMenuItem.hint]s are left out too: native menus have no
/// place for them.
List<NativeMenuNode> nativeMenuFromMeridian(List<MeridianMenuEntry> entries) {
  var next = 0;
  List<NativeMenuNode> convert(List<MeridianMenuEntry> entries) => [
    for (final entry in entries)
      ?switch (entry) {
        MeridianMenuCustom() => null,
        MeridianMenuDivider() => const NativeMenuSeparator(),
        MeridianMenuHeader(:final label) => NativeMenuAction(
          id: ++next,
          title: label,
          enabled: false,
          header: true,
        ),
        MeridianMenuItem(:final children?) when entry.hasSubmenu =>
          NativeMenuSubmenu(
            title: entry.label,
            icon: entry.icon,
            children: convert(children),
          ),
        MeridianMenuItem() => NativeMenuAction(
          id: ++next,
          title: entry.label,
          enabled: entry.enabled,
          checked: entry.checked,
          danger: entry.danger,
          icon: entry.icon,
          shortcut: NativeMenuShortcut.fromKeycaps(entry.shortcut),
          onSelected: entry.onSelected,
        ),
      },
  ];
  return _trimSeparators(convert(entries));
}

/// Native menus show leading, trailing and doubled separators as gaps.
List<NativeMenuNode> _trimSeparators(List<NativeMenuNode> nodes) {
  final result = <NativeMenuNode>[];
  for (final node in nodes) {
    if (node is NativeMenuSeparator &&
        (result.isEmpty || result.last is NativeMenuSeparator)) {
      continue;
    }
    result.add(
      node is NativeMenuSubmenu
          ? NativeMenuSubmenu(
              title: node.title,
              icon: node.icon,
              enabled: node.enabled,
              children: _trimSeparators(node.children),
            )
          : node,
    );
  }
  while (result.isNotEmpty && result.last is NativeMenuSeparator) {
    result.removeLast();
  }
  return result;
}

/// The action with [id] in [nodes], at any depth.
NativeMenuAction? findNativeMenuAction(List<NativeMenuNode> nodes, int id) {
  for (final node in nodes) {
    switch (node) {
      case NativeMenuAction(id: final found) when found == id:
        return node;
      case NativeMenuSubmenu(:final children):
        final found = findNativeMenuAction(children, id);
        if (found != null) return found;
      default:
        break;
    }
  }
  return null;
}

/// The macOS and Windows host protocol for [nodes]: a list of maps with
/// `separator`, or `title` and `items` (a submenu), or `id`, `title`,
/// `enabled`, `checked`, optional `header`, `danger`, `shortcut` and
/// `icon`. [icons] holds alpha masks by the icon names in the menu.
List<Map<String, Object?>> encodeHostMenu(
  List<NativeMenuNode> nodes, {
  Map<String, Map<String, Object>> icons = const {},
}) => [
  for (final node in nodes)
    switch (node) {
      NativeMenuSeparator() => {'separator': true},
      NativeMenuSubmenu() => {
        'title': node.title,
        'icon': ?icons[node.icon],
        'enabled': node.enabled,
        'items': encodeHostMenu(node.children, icons: icons),
      },
      NativeMenuAction() => {
        'id': node.id,
        'title': node.title,
        if (node.header) 'header': true,
        if (node.danger) 'danger': true,
        'icon': ?icons[node.icon],
        'shortcut': ?node.shortcut?.hostLabel,
        'enabled': node.enabled && !node.header,
        'checked': node.checked ?? false,
      },
    },
];

/// The icon names used anywhere in [nodes].
Set<String> nativeMenuIcons(List<NativeMenuNode> nodes) => {
  for (final node in nodes)
    ...switch (node) {
      NativeMenuAction(:final icon?) => {icon},
      NativeMenuSubmenu(:final icon, :final children) => {
        ?icon,
        ...nativeMenuIcons(children),
      },
      _ => const <String>{},
    },
};
