import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meridian_ui/meridian_ui.dart';
import 'package:super_context_menu/super_context_menu.dart';
import 'package:super_native_extensions/raw_drag_drop.dart' as native_drag;
import 'package:super_native_extensions/raw_menu.dart' as native;

import 'native_menu_model.dart';

/// A native menu could not be shown. [code] is stable and never holds menu
/// labels or platform messages.
class MeridianNativeMenuException implements Exception {
  const MeridianNativeMenuException(this.code);

  /// `native_menu_platform_unsupported`, `native_menu_unavailable` or
  /// `native_menu_host_failed`.
  final String code;

  @override
  String toString() => 'MeridianNativeMenuException($code)';
}

/// Shows Meridian menus as the operating system's own menus.
///
/// macOS and Windows use this package's host plugin (an `NSMenu`, a Win32
/// popup menu), which needs no pointer event, so menus opened from the
/// keyboard work too. Linux uses `super_native_extensions`. Other platforms
/// are not supported: install the presenter with [MeridianNativeMenus.scope],
/// which leaves Meridian's own menus in place there.
///
/// A chosen item's callback runs after the menu has closed, only while the
/// context that opened it is still mounted. An unsupported platform or a
/// host failure throws a [MeridianNativeMenuException]; a Flutter-drawn
/// menu is never substituted.
abstract final class MeridianNativeMenus {
  /// The host plugin's channel.
  static const channel = MethodChannel('meridian_native_menus');

  /// Replaces the platform: receives the menu and the position (global
  /// logical pixels) and returns the chosen action's id, or `null`.
  @visibleForTesting
  static Future<int?> Function(
    BuildContext context,
    List<NativeMenuNode> nodes,
    Offset position,
  )?
  debugShowOverride;

  /// Overrides the platform check, for tests.
  @visibleForTesting
  static bool? debugSupportedOverride;

  /// Whether this platform shows native menus: macOS, Windows and Linux
  /// desktops.
  static bool get isSupported =>
      debugSupportedOverride ??
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux));

  /// Installs the native presenter for every Meridian menu and the native
  /// text-editing menu of every `MeridianTextField` below it, where
  /// [isSupported]; elsewhere [child] keeps Meridian's own menus.
  ///
  /// Put it at each app root (and each secondary window's root), inside the
  /// `MaterialApp` builder so menus see the theme.
  static Widget scope({required Widget child}) => isSupported
      ? MeridianMenuPresenter(
          present: present,
          textContextMenuBuilder: nativeTextContextMenuBuilder,
          child: child,
        )
      : child;

  /// On Linux the plugin anchors a menu to the last button press, which only
  /// its drag context records. Create that context once per engine before
  /// the first press, or every menu fails with `mouseEventNotFound`. Call it
  /// at start-up; [show] calls it too.
  static Future<void> prepare() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.linux) return;
    if (debugShowOverride != null) return;
    try {
      await native_drag.DragContext.instance();
    } on Object {
      // Menus report their own failure when the plugin is unavailable.
    }
  }

  /// A [MeridianMenuPresent]: shows [entries] below [anchor] (at the point
  /// of a zero-size anchor, for a context menu).
  static Future<void> present(
    BuildContext context, {
    required Rect anchor,
    required List<MeridianMenuEntry> entries,
  }) async {
    await show(context, entries, anchor.bottomLeft);
  }

  /// Shows [entries] at [position] (global logical pixels). Completes with
  /// whether an item was chosen, after its callback ran.
  static Future<bool> show(
    BuildContext context,
    List<MeridianMenuEntry> entries,
    Offset position,
  ) async {
    final nodes = nativeMenuFromMeridian(entries);
    if (nodes.isEmpty) return false;
    final int? id;
    final override = debugShowOverride;
    if (override != null) {
      id = await override(context, nodes, position);
    } else if (!isSupported) {
      throw const MeridianNativeMenuException(
        'native_menu_platform_unsupported',
      );
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      id = await _showLinux(context, nodes, position);
    } else {
      id = await _showHost(context, nodes, position);
    }
    if (id == null || !context.mounted) return false;
    final action = findNativeMenuAction(nodes, id);
    if (action == null || !action.enabled || action.header) return false;
    action.onSelected?.call();
    return action.onSelected != null;
  }

  static Future<int?> _showHost(
    BuildContext context,
    List<NativeMenuNode> nodes,
    Offset position,
  ) async {
    final icons = await _hostIcons(
      nativeMenuIcons(nodes),
      MeridianTheme.of(context).icons,
      MediaQuery.devicePixelRatioOf(context),
    );
    if (!context.mounted) return null;
    try {
      return await channel.invokeMethod<int>('show', {
        'x': position.dx,
        'y': position.dy,
        'items': encodeHostMenu(nodes, icons: icons),
      });
    } on PlatformException {
      throw const MeridianNativeMenuException('native_menu_host_failed');
    } on MissingPluginException {
      throw const MeridianNativeMenuException('native_menu_unavailable');
    }
  }

  static Future<int?> _showLinux(
    BuildContext context,
    List<NativeMenuNode> nodes,
    Offset position,
  ) async {
    final icons = MeridianTheme.of(context).icons;
    final iconTheme = IconTheme.of(context);
    final options = native.MenuSerializationOptions(
      iconTheme: iconTheme,
      destructiveIconTheme: iconTheme.copyWith(
        color: MeridianTheme.of(context).colors.danger,
      ),
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    await prepare();
    final menuContext = await native.MenuContext.instance();
    if (!context.mounted) return null;
    // The plugin can announce a selection while the OS menu still owns
    // input. Report it only once menu tracking has ended.
    int? selected;
    final handle = await menuContext.registerMenu(
      Menu(children: _pluginElements(nodes, icons, (id) => selected = id)),
      options,
    );
    try {
      if (!context.mounted) return null;
      final result = await menuContext.showContextMenu(
        native.DesktopContextMenuRequest(
          menu: handle,
          position: position,
          iconTheme: iconTheme,
          writingToolsConfiguration: null,
          fallback: () => throw const MeridianNativeMenuException(
            'native_menu_unavailable',
          ),
        ),
      );
      return result.itemSelected ? selected : null;
    } finally {
      handle.dispose();
    }
  }

  static List<MenuElement> _pluginElements(
    List<NativeMenuNode> nodes,
    MeridianIconSet icons,
    ValueChanged<int> onSelected,
  ) => [
    for (final node in nodes)
      switch (node) {
        NativeMenuSeparator() => MenuSeparator(),
        NativeMenuSubmenu() => Menu(
          title: node.title,
          image: _pluginImage(node.icon, icons),
          children: node.enabled
              ? _pluginElements(node.children, icons, onSelected)
              : const [],
        ),
        NativeMenuAction() => MenuAction(
          title: node.title,
          image: _pluginImage(node.icon, icons),
          activator: node.shortcut?.activator,
          attributes: MenuActionAttributes(
            disabled: !node.enabled || node.header,
            destructive: node.danger,
          ),
          state: switch (node.checked) {
            true => MenuActionState.checkOn,
            false => MenuActionState.checkOff,
            null => MenuActionState.none,
          },
          callback: () => onSelected(node.id),
        ),
      },
  ];

  /// The plugin draws an icon in the colour of its own menu theme.
  static MenuImage? _pluginImage(String? name, MeridianIconSet icons) =>
      name == null
      ? null
      : MenuImage.withImage(
          (theme, devicePixelRatio) => _iconImage(
            icons.assetFor(name),
            devicePixelRatio.toDouble(),
            theme.color,
          ),
        );

  static final Map<String, Map<String, Object>> _hostIconCache = {};

  /// The icons as alpha masks by name. The host tints them with its own
  /// menu text colour, so they follow the system appearance.
  static Future<Map<String, Map<String, Object>>> _hostIcons(
    Set<String> names,
    MeridianIconSet icons,
    double devicePixelRatio,
  ) async {
    final result = <String, Map<String, Object>>{};
    for (final name in names) {
      final asset = icons.assetFor(name);
      final key = '$asset@$devicePixelRatio';
      var encoded = _hostIconCache[key];
      if (encoded == null) {
        // Only the alpha of a mask counts.
        final picture = await _iconImage(asset, devicePixelRatio, null);
        final bytes = await picture?.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        );
        if (picture == null || bytes == null) continue;
        encoded = _hostIconCache[key] = {
          'width': picture.width,
          'height': picture.height,
          'scale': devicePixelRatio,
          'rgba': bytes.buffer.asUint8List(),
        };
        picture.dispose();
      }
      result[name] = encoded;
    }
    return result;
  }

  /// A menu never fails for a missing or unreadable icon.
  static Future<ui.Image?> _iconImage(
    String asset,
    double devicePixelRatio,
    Color? color,
  ) async {
    try {
      final extent = (MeridianSize.icon * devicePixelRatio).round();
      final info = await vg.loadPicture(SvgAssetLoader(asset), null);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..scale(extent / info.size.width, extent / info.size.height);
      if (color != null) {
        canvas.saveLayer(
          null,
          Paint()..colorFilter = ColorFilter.mode(color, BlendMode.srcIn),
        );
      }
      canvas.drawPicture(info.picture);
      if (color != null) canvas.restore();
      final picture = recorder.endRecording();
      try {
        return await picture.toImage(extent, extent);
      } finally {
        picture.dispose();
        info.picture.dispose();
      }
    } on Object {
      return null;
    }
  }
}

/// A native right-click and keyboard context menu around [child]: a
/// secondary click, the context-menu key or Shift+F10 asks [entries] for
/// the menu at that position (global logical pixels) and shows it. When the
/// menu closes without a choice, focus returns to where it was.
///
/// Without native menus (see [MeridianNativeMenus.isSupported]) it shows
/// Meridian's own context menu.
class MeridianNativeContextMenuRegion extends StatefulWidget {
  const MeridianNativeContextMenuRegion({
    required this.entries,
    required this.child,
    super.key,
    this.enabled = true,
  });

  /// The menu for a request at a position; `null` or empty shows none.
  final FutureOr<List<MeridianMenuEntry>?> Function(Offset position) entries;
  final Widget child;
  final bool enabled;

  @override
  State<MeridianNativeContextMenuRegion> createState() =>
      _MeridianNativeContextMenuRegionState();
}

class _MeridianNativeContextMenuRegionState
    extends State<MeridianNativeContextMenuRegion> {
  var _showing = false;

  Future<void> _open(Offset position) async {
    if (_showing || !widget.enabled) return;
    _showing = true;
    final focus = FocusManager.instance.primaryFocus;
    try {
      final entries = await widget.entries(position);
      if (!mounted || entries == null || entries.isEmpty) return;
      final bool chosen;
      if (MeridianNativeMenus.isSupported ||
          MeridianNativeMenus.debugShowOverride != null) {
        chosen = await MeridianNativeMenus.show(context, entries, position);
      } else {
        await showMeridianContextMenu(
          context,
          globalPosition: position,
          entries: entries,
        );
        chosen = true;
      }
      if (mounted && !chosen && focus?.context != null) focus!.requestFocus();
    } finally {
      _showing = false;
    }
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: (_, event) {
      if (event is KeyDownEvent &&
          widget.enabled &&
          (event.logicalKey == LogicalKeyboardKey.contextMenu ||
              (event.logicalKey == LogicalKeyboardKey.f10 &&
                  HardwareKeyboard.instance.isShiftPressed))) {
        final box = context.findRenderObject();
        if (box is RenderBox && box.hasSize) {
          unawaited(_open(box.localToGlobal(Offset(0, box.size.height))));
        }
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapUp: widget.enabled
          ? (details) => unawaited(_open(details.globalPosition))
          : null,
      child: widget.child,
    ),
  );
}

/// The cut, copy, paste and select-all menu of a text field or selectable
/// text as a native menu: Flutter's editing actions and localized labels,
/// shown by [MeridianNativeMenus]. Pass it as `contextMenuBuilder`;
/// [MeridianNativeMenus.scope] installs it for every `MeridianTextField`.
Widget nativeTextContextMenuBuilder(
  BuildContext context,
  MeridianTextMenuRequest request,
) => _NativeTextMenu(request: request);

class _NativeTextMenu extends StatefulWidget {
  const _NativeTextMenu({required this.request});

  final MeridianTextMenuRequest request;

  @override
  State<_NativeTextMenu> createState() => _NativeTextMenuState();
}

class _NativeTextMenuState extends State<_NativeTextMenu> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_open()));
  }

  Future<void> _open() async {
    if (!mounted) return;
    final request = widget.request;
    try {
      await MeridianNativeMenus.show(context, [
        for (final item in request.items)
          MeridianMenuItem(
            label: meridianTextMenuLabel(context, item),
            onSelected: item.onPressed == null
                ? null
                : () {
                    if (mounted) item.onPressed?.call();
                  },
          ),
      ], request.anchors.primaryAnchor);
    } finally {
      if (mounted) request.hide();
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
