import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/meridian_icons.g.dart';
import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import '../foundation/overlay_motion.dart';
import 'display.dart';

/// One entry of a Meridian menu.
sealed class MeridianMenuEntry {
  const MeridianMenuEntry();
}

/// A command in a menu. Put the object's name in the label ("Move
/// Quarterly report to archive"). Destructive items go last, after a
/// divider, with [danger].
///
/// An item with [children] opens a submenu: on hover after a short pause,
/// with → or Enter, or with a click. ← and Escape close it again.
final class MeridianMenuItem extends MeridianMenuEntry {
  const MeridianMenuItem({
    required this.label,
    this.onSelected,
    this.icon,
    this.leading,
    this.shortcut,
    this.hint,
    this.danger = false,
    this.checked,
    this.children,
    this.labelStyle,
  });

  final String label;

  /// Runs after the menu has closed. `null` disables the item (unless it
  /// has [children]).
  final VoidCallback? onSelected;
  final String? icon;

  /// A picture in the icon slot instead of [icon]: a label's colour dot, an
  /// avatar. Keep it to the density's icon size.
  final Widget? leading;
  final List<String>? shortcut;

  /// Secondary text at the right edge (a count, a path).
  final String? hint;
  final bool danger;

  /// Radio or check state; `true` shows a check mark in the icon slot.
  final bool? checked;

  /// The entries of this item's submenu.
  final List<MeridianMenuEntry>? children;

  /// Merged over the label's `body` style, for an item that previews itself
  /// (a font family set in that font).
  final TextStyle? labelStyle;

  /// Whether the item opens a submenu.
  bool get hasSubmenu => children?.isNotEmpty ?? false;

  bool get enabled => onSelected != null || hasSubmenu;
}

/// A hairline between groups.
final class MeridianMenuDivider extends MeridianMenuEntry {
  const MeridianMenuDivider();
}

/// An `overline` group header.
final class MeridianMenuHeader extends MeridianMenuEntry {
  const MeridianMenuHeader(this.label);

  final String label;
}

/// Content of the app's own that is not a command, such as the person a
/// contact menu is about (avatar, name, address) above its commands. It is
/// skipped by the arrow keys and type-ahead. Keep it short: menus are for
/// commands.
final class MeridianMenuCustom extends MeridianMenuEntry {
  const MeridianMenuCustom(this.child);

  final Widget child;
}

/// Whether [entries] hold a [MeridianMenuCustom] block, in a submenu too.
bool _holdsCustom(List<MeridianMenuEntry> entries) => entries.any(
  (entry) => switch (entry) {
    MeridianMenuCustom() => true,
    MeridianMenuItem(:final children?) => _holdsCustom(children),
    _ => false,
  },
);

/// Whether a key that opens menus (Enter, Space, an arrow) is down right
/// now, that is, whether the keyboard is opening this menu.
bool _keyboardIsOpening() {
  final keys = HardwareKeyboard.instance.logicalKeysPressed;
  return keys.contains(LogicalKeyboardKey.enter) ||
      keys.contains(LogicalKeyboardKey.numpadEnter) ||
      keys.contains(LogicalKeyboardKey.space) ||
      keys.contains(LogicalKeyboardKey.arrowDown) ||
      keys.contains(LogicalKeyboardKey.arrowUp);
}

/// How long the pointer rests on an item before its submenu opens, and on
/// another item before an open submenu closes.
const _submenuDelay = Duration(milliseconds: 200);

/// How long typed letters add up to one type-ahead query.
const _typeAheadWindow = Duration(milliseconds: 800);

/// The floating menu surface: `raised`, `radius-xl`, `shadow-float`, rows at
/// the density's row height. Arrow keys, Home and End move the highlight
/// (solid `accent`), typing a label's first letters jumps to it, Enter runs
/// it, Escape closes. Items with children open submenus beside their row.
/// Usually shown through [MeridianMenuAnchor] or [showMeridianMenu]; use it
/// directly for a docked menu.
class MeridianMenuSurface extends StatefulWidget {
  const MeridianMenuSurface({
    required this.entries,
    required this.onSelected,
    super.key,
    this.width,
    this.autofocus = true,
    this.onDismiss,
    this.initialHighlight = false,
  });

  final List<MeridianMenuEntry> entries;

  /// Called with the chosen item, also for items chosen in a submenu.
  final ValueChanged<MeridianMenuItem> onSelected;
  final double? width;
  final bool autofocus;

  /// Called on Escape. A docked menu uses it to close itself; menus shown
  /// with [showMeridianMenu] close on Escape on their own.
  final VoidCallback? onDismiss;

  /// Highlight the checked item (or else the first enabled item) when the
  /// surface appears. Menus opened from the keyboard do this.
  final bool initialHighlight;

  @override
  State<MeridianMenuSurface> createState() => _MeridianMenuSurfaceState();
}

class _MeridianMenuSurfaceState extends State<MeridianMenuSurface> {
  int? _highlight;
  int? _pressed;
  final _focus = FocusNode(debugLabel: 'meridian-menu');
  final _rowKeys = <int, GlobalKey>{};
  final _submenu = OverlayPortalController(debugLabel: 'meridian-submenu');

  /// The item whose submenu is open, and whether the keyboard opened it.
  int? _open;
  var _openedByKeyboard = false;
  Timer? _hoverTimer;
  var _typed = '';
  Timer? _typeTimer;

  List<int> get _enabled => [
    for (var i = 0; i < widget.entries.length; i++)
      if (widget.entries[i] case final MeridianMenuItem item when item.enabled)
        i,
  ];

  GlobalKey _keyFor(int index) =>
      _rowKeys.putIfAbsent(index, () => GlobalKey(debugLabel: 'menu-$index'));

  @override
  void initState() {
    super.initState();
    if (!widget.initialHighlight) return;
    final enabled = _enabled;
    if (enabled.isEmpty) return;
    final checked = enabled.where(
      (i) => (widget.entries[i] as MeridianMenuItem).checked ?? false,
    );
    final index = checked.isEmpty ? enabled.first : checked.first;
    _highlight = index;
    _reveal(index, forward: true);
  }

  var _dependenciesResolved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dependenciesResolved) return;
    _dependenciesResolved = true;
    // Autofocus only applies when nothing in the route has focus, and the
    // parent menu does: a submenu opened from the keyboard takes it.
    if (widget.autofocus && _isSubmenu) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant MeridianMenuSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    final length = widget.entries.length;
    if (_highlight case final index? when index >= length) _highlight = null;
    if (_pressed case final index? when index >= length) _pressed = null;
    if (_open case final index?
        when index >= length ||
            !(widget.entries[index] is MeridianMenuItem &&
                (widget.entries[index] as MeridianMenuItem).hasSubmenu)) {
      _closeSubmenu(refocus: false);
    }
    _rowKeys.removeWhere((index, _) => index >= length);
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _typeTimer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  /// Scrolls row [index] into view after the next layout.
  void _reveal(int index, {required bool forward}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rowContext = _rowKeys[index]?.currentContext;
      if (rowContext == null) return;
      Scrollable.ensureVisible(
        rowContext,
        alignmentPolicy: forward
            ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
            : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    });
  }

  void _highlightTo(int index, {required bool forward}) {
    setState(() => _highlight = index);
    _reveal(index, forward: forward);
  }

  void _move(int delta) {
    final enabled = _enabled;
    if (enabled.isEmpty) return;
    final current = _highlight == null ? -1 : enabled.indexOf(_highlight!);
    final next = current < 0
        ? (delta > 0 ? 0 : enabled.length - 1)
        : (current + delta) % enabled.length;
    _highlightTo(enabled[next], forward: delta > 0);
  }

  void _openSubmenu(int index, {required bool keyboard}) {
    _hoverTimer?.cancel();
    // A submenu the pointer opened takes the keyboard on → or Enter.
    if (_open == index && _submenu.isShowing && !keyboard) return;
    setState(() {
      _open = index;
      _openedByKeyboard = keyboard;
      _highlight = index;
    });
    _submenu.show();
  }

  void _closeSubmenu({bool refocus = true}) {
    _hoverTimer?.cancel();
    if (_open == null) return;
    if (_submenu.isShowing) _submenu.hide();
    if (mounted) setState(() => _open = null);
    if (refocus && mounted) _focus.requestFocus();
  }

  /// Runs [item]: opens its submenu or reports it chosen.
  void _choose(int index, MeridianMenuItem item, {required bool keyboard}) {
    if (!item.enabled) return;
    if (item.hasSubmenu) {
      _openSubmenu(index, keyboard: keyboard);
      return;
    }
    widget.onSelected(item);
  }

  KeyEventResult _activate(KeyEvent event) {
    // A held key must not run a second item or pop the page beneath.
    if (event is KeyRepeatEvent) return KeyEventResult.handled;
    final index = _highlight;
    if (index == null || index >= widget.entries.length) {
      return KeyEventResult.ignored;
    }
    if (widget.entries[index] case final MeridianMenuItem item
        when item.enabled) {
      _choose(index, item, keyboard: true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Jumps to the next item whose label starts with the letters typed in
  /// the last moment.
  KeyEventResult _typeAhead(KeyEvent event) {
    final character = event.character;
    final keyboard = HardwareKeyboard.instance;
    if (event is! KeyDownEvent ||
        character == null ||
        character.trim().isEmpty ||
        character.runes.length != 1 ||
        keyboard.isMetaPressed ||
        keyboard.isControlPressed ||
        keyboard.isAltPressed) {
      return KeyEventResult.ignored;
    }
    _typeTimer?.cancel();
    _typeTimer = Timer(_typeAheadWindow, () => _typed = '');
    final repeat = _typed.length == 1 && _typed == character.toLowerCase();
    _typed = repeat ? _typed : _typed + character.toLowerCase();
    final enabled = _enabled;
    if (enabled.isEmpty) return KeyEventResult.handled;
    final current = _highlight == null ? -1 : enabled.indexOf(_highlight!);
    // A fresh letter searches after the highlight; a longer query may stay.
    final start = _typed.length == 1 ? current + 1 : math.max(current, 0);
    for (var step = 0; step < enabled.length; step++) {
      final index = enabled[(start + step) % enabled.length];
      final item = widget.entries[index] as MeridianMenuItem;
      if (item.label.toLowerCase().startsWith(_typed)) {
        _highlightTo(index, forward: true);
        break;
      }
    }
    return KeyEventResult.handled;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final opensSubmenu = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final closesSubmenu = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    final key = event.logicalKey;
    if (key == opensSubmenu) {
      final index = _highlight;
      if (index == null) return KeyEventResult.ignored;
      if (widget.entries[index] case final MeridianMenuItem item
          when item.enabled && item.hasSubmenu) {
        _openSubmenu(index, keyboard: true);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (key == closesSubmenu) {
      // A submenu closes itself; the root menu ignores the key.
      final dismiss = widget.onDismiss;
      if (dismiss == null || !_isSubmenu) return KeyEventResult.ignored;
      dismiss();
      return KeyEventResult.handled;
    }
    switch (key) {
      case LogicalKeyboardKey.arrowDown:
        _move(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _move(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        final enabled = _enabled;
        if (enabled.isNotEmpty) _highlightTo(enabled.first, forward: false);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        final enabled = _enabled;
        if (enabled.isNotEmpty) _highlightTo(enabled.last, forward: true);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        final dismiss = widget.onDismiss;
        if (dismiss == null) return KeyEventResult.ignored;
        dismiss();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
      case LogicalKeyboardKey.space:
        return _activate(event);
      default:
        return _typeAhead(event);
    }
  }

  /// Whether this surface is a submenu of another surface.
  bool get _isSubmenu => _SubmenuScope.of(context);

  /// The open submenu, placed beside its row in the overlay.
  Widget _submenuSurface(BuildContext overlayContext) {
    final index = _open;
    final row = index == null ? null : _rowKeys[index]?.currentContext;
    final overlay = Overlay.of(overlayContext).context.findRenderObject();
    if (index == null ||
        row == null ||
        overlay is! RenderBox ||
        widget.entries[index] is! MeridianMenuItem) {
      return const SizedBox.shrink();
    }
    final box = row.findRenderObject()! as RenderBox;
    final rect = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
    final item = widget.entries[index] as MeridianMenuItem;
    return _SubmenuScope(
      child: CustomSingleChildLayout(
        delegate: _SubmenuLayout(
          row: rect,
          padding: MediaQuery.paddingOf(overlayContext),
          textDirection: Directionality.of(context),
        ),
        child: MouseRegion(
          // Reaching the submenu keeps it open.
          onEnter: (_) => _hoverTimer?.cancel(),
          // It enters from its side (MM-43).
          child: MeridianOverlayEntrance(
            key: ValueKey(('submenu', index)),
            offset: Offset(
              Directionality.of(context) == TextDirection.rtl
                  ? MeridianMotionScales.riseOverlay
                  : -MeridianMotionScales.riseOverlay,
              0,
            ),
            alignment: AlignmentDirectional.centerStart,
            child: MeridianMenuSurface(
              key: ValueKey((index, _openedByKeyboard)),
              entries: item.children!,
              initialHighlight: _openedByKeyboard,
              autofocus: _openedByKeyboard,
              onSelected: widget.onSelected,
              onDismiss: _closeSubmenu,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final radius = BorderRadius.circular(meridian.radius.xl);
    final reserveIcon = widget.entries.any(
      (e) =>
          e is MeridianMenuItem &&
          (e.icon != null || e.leading != null || e.checked != null),
    );
    return OverlayPortal(
      controller: _submenu,
      overlayChildBuilder: _submenuSurface,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: Focus(
          focusNode: _focus,
          autofocus: widget.autofocus,
          onKeyEvent: _onKey,
          child: Container(
            width: widget.width,
            constraints: const BoxConstraints(
              minWidth: MeridianLayout.menuMinWidth,
              maxWidth: MeridianLayout.menuMaxWidth,
              maxHeight: MeridianLayout.menuMaxHeight,
            ),
            decoration: BoxDecoration(
              color: colors.raised,
              borderRadius: radius,
              boxShadow: meridian.shadows.shadowFloat,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: MeridianTextScope(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(MeridianSpace.space2),
                  child: IntrinsicWidth(
                    // The highlight sits on its row at once (MM-42): a menu
                    // follows the pointer without trailing it.
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < widget.entries.length; i++)
                          _entry(context, i, reserveIcon),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _entry(BuildContext context, int index, bool reserveIcon) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final text = meridian.text;
    return switch (widget.entries[index]) {
      MeridianMenuDivider() => Padding(
        padding: const EdgeInsets.symmetric(
          vertical: MeridianSpace.space2,
          horizontal: MeridianSpace.space4,
        ),
        child: MeridianHairline(color: colors.line),
      ),
      MeridianMenuHeader(:final label) => Padding(
        padding: const EdgeInsets.fromLTRB(
          MeridianSpace.space4,
          MeridianSpace.space3,
          MeridianSpace.space4,
          MeridianSpace.space2,
        ),
        child: Semantics(
          header: true,
          child: Text(
            label.toUpperCase(),
            style: text.overline.copyWith(color: colors.inkMuted),
          ),
        ),
      ),
      MeridianMenuCustom(:final child) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MeridianSpace.space4,
          vertical: MeridianSpace.space3,
        ),
        child: DefaultTextStyle.merge(
          style: text.body.copyWith(decoration: TextDecoration.none),
          child: child,
        ),
      ),
      final MeridianMenuItem item => KeyedSubtree(
        key: _keyFor(index),
        child: _item(context, index, item, reserveIcon),
      ),
    };
  }

  void _setPressed(int? index) {
    if (_pressed != index) setState(() => _pressed = index);
  }

  /// The pointer came to rest on row [index]: its submenu opens, another
  /// item's closes, both after [_submenuDelay].
  void _hover(int index, MeridianMenuItem item) {
    if (!item.enabled) return;
    setState(() => _highlight = index);
    _hoverTimer?.cancel();
    if (item.hasSubmenu && _open != index) {
      _hoverTimer = Timer(_submenuDelay, () {
        if (mounted && _highlight == index) {
          _openSubmenu(index, keyboard: false);
        }
      });
    } else if (!item.hasSubmenu && _open != null) {
      _hoverTimer = Timer(_submenuDelay, () {
        if (mounted && _highlight == index) _closeSubmenu();
      });
    }
  }

  Widget _item(
    BuildContext context,
    int index,
    MeridianMenuItem item,
    bool reserveIcon,
  ) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    // The fill sits on the highlighted row, or on the row whose submenu is
    // open while nothing else is highlighted.
    final highlighted = (_highlight ?? _open) == index && item.enabled;
    final pressed = _pressed == index && item.enabled;
    final base = highlighted ? colors.accent : meridianClear(colors.accent);
    final fill = pressed
        ? Color.alphaBlend(
            colors.ink.withValues(alpha: MeridianOpacity.pressedOverlay),
            base,
          )
        : base;
    final radius = BorderRadius.circular(meridian.radius.sm);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    Widget row({required bool onAccent}) {
      final ink = !item.enabled
          ? colors.inkFaint
          : onAccent
          ? colors.onAccent
          : item.danger
          ? colors.danger
          : colors.ink;
      final iconInk = !item.enabled
          ? colors.inkFaint
          : onAccent
          ? colors.onAccent
          : item.danger
          ? colors.danger
          : colors.inkMuted;
      final Widget? leading = (item.checked ?? false)
          ? MeridianIcon(MeridianIcons.check, color: iconInk)
          : item.leading ??
                switch (item.icon) {
                  final name? => MeridianIcon(name, color: iconInk),
                  null => null,
                };
      return Container(
        height: meridian.density.rowExtent,
        padding: const EdgeInsets.symmetric(horizontal: MeridianSpace.space4),
        decoration: BoxDecoration(color: fill, borderRadius: radius),
        child: Row(
          children: [
            if (reserveIcon) ...[
              SizedBox.square(
                dimension: meridian.density.iconSize,
                child: Center(child: leading),
              ),
              const SizedBox(width: MeridianSpace.space4),
            ],
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: meridian.text.body
                    .merge(item.labelStyle)
                    .copyWith(color: ink),
              ),
            ),
            if (item.hint case final hint?) ...[
              const SizedBox(width: MeridianSpace.space5),
              Text(
                hint,
                style: meridian.text.caption.copyWith(
                  color: onAccent ? colors.onAccentMuted : colors.inkMuted,
                ),
              ),
            ],
            if (item.shortcut case final keys? when keys.isNotEmpty) ...[
              const SizedBox(width: MeridianSpace.space5),
              MeridianKbd(keys: keys, onAccent: onAccent),
            ],
            if (item.hasSubmenu) ...[
              const SizedBox(width: MeridianSpace.space4),
              MeridianIcon(
                rtl ? MeridianIcons.chevronLeft : MeridianIcons.chevronRight,
                size: MeridianIconSize.small,
                color: iconInk,
              ),
            ],
          ],
        ),
      );
    }

    return Semantics(
      excludeSemantics: true,
      button: true,
      enabled: item.enabled,
      checked: item.checked,
      expanded: item.hasSubmenu ? _open == index : null,
      label: item.label,
      onTap: item.enabled ? () => _choose(index, item, keyboard: false) : null,
      child: MouseRegion(
        cursor: item.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => _hover(index, item),
        onExit: (_) {
          if (_highlight != index && _pressed != index) return;
          setState(() {
            // An open submenu keeps its row highlighted.
            if (_highlight == index && _open != index) _highlight = null;
            if (_pressed == index) _pressed = null;
          });
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: item.enabled ? (_) => _setPressed(index) : null,
          onTapUp: item.enabled ? (_) => _setPressed(null) : null,
          onTapCancel: item.enabled ? () => _setPressed(null) : null,
          onTap: item.enabled
              ? () => _choose(index, item, keyboard: false)
              : null,
          child: row(onAccent: highlighted),
        ),
      ),
    );
  }
}

/// Marks the surfaces below it as submenus (← closes them).
class _SubmenuScope extends InheritedWidget {
  const _SubmenuScope({required super.child});

  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_SubmenuScope>() != null;

  @override
  bool updateShouldNotify(_SubmenuScope oldWidget) => false;
}

/// Places a submenu beside its [row]: after it in the reading direction,
/// before it when there is no room, its first item level with the row.
class _SubmenuLayout extends SingleChildLayoutDelegate {
  _SubmenuLayout({
    required this.row,
    required this.padding,
    required this.textDirection,
  });

  final Rect row;
  final EdgeInsets padding;
  final TextDirection textDirection;
  static const _margin = MeridianSpace.space4;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        Size(
          math.max(
            0.0,
            constraints.maxWidth - padding.horizontal - _margin * 2,
          ),
          math.max(0.0, constraints.maxHeight - padding.vertical - _margin * 2),
        ),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final minX = padding.left + _margin;
    final maxX = math.max(
      minX,
      size.width - padding.right - _margin - childSize.width,
    );
    // The surface's own padding lines its first row up with [row].
    final after = row.right + MeridianSpace.space2;
    final before = row.left - MeridianSpace.space2 - childSize.width;
    final ltr = textDirection == TextDirection.ltr;
    final double x;
    if (ltr) {
      x = after <= maxX || before < minX ? after : before;
    } else {
      x = before >= minX || after > maxX ? before : after;
    }
    final minY = padding.top + _margin;
    final maxY = math.max(
      minY,
      size.height - padding.bottom - _margin - childSize.height,
    );
    final y = row.top - MeridianSpace.space2;
    return Offset(x.clamp(minX, maxX), y.clamp(minY, maxY));
  }

  @override
  bool shouldRelayout(_SubmenuLayout oldDelegate) =>
      row != oldDelegate.row ||
      padding != oldDelegate.padding ||
      textDirection != oldDelegate.textDirection;
}

/// Wraps a trigger that opens a menu below it (above when there is no
/// room). [builder] receives the `open` callback to call from the trigger.
/// The menu is anchored to everything [builder] returns, so a split button
/// returns the whole button and calls `open` from its caret.
class MeridianMenuAnchor extends StatelessWidget {
  const MeridianMenuAnchor({
    required this.entries,
    required this.builder,
    super.key,
    this.width,
    this.onOpenChanged,
  });

  final List<MeridianMenuEntry> entries;
  final Widget Function(BuildContext context, VoidCallback open) builder;

  /// Menu width; defaults to the content, at least the trigger's width.
  final double? width;

  /// Called with `true` when the menu opens and `false` once it has closed
  /// (a select's chevron turns while it is open, MM-16).
  final ValueChanged<bool>? onOpenChanged;

  @override
  Widget build(BuildContext context) => Builder(
    builder: (anchorContext) => builder(anchorContext, () async {
      if (!anchorContext.mounted) return;
      final box = anchorContext.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final origin = box.localToGlobal(Offset.zero);
      onOpenChanged?.call(true);
      try {
        await showMeridianMenu(
          anchorContext,
          anchor: origin & box.size,
          entries: entries,
          width: width,
          minWidth: box.size.width,
        );
      } finally {
        onOpenChanged?.call(false);
      }
    }),
  );
}

/// Presents a menu instead of the Flutter [MeridianMenuSurface]. It must
/// complete once the menu has closed and run the chosen item's
/// `onSelected` after that.
typedef MeridianMenuPresent =
    Future<void> Function(
      BuildContext context, {
      required Rect anchor,
      required List<MeridianMenuEntry> entries,
    });

/// Routes every Meridian menu (menu anchors, split toolbar buttons,
/// selects and context menus) to [present], for apps that must show the
/// operating system's native menus. A menu with a [MeridianMenuCustom]
/// block stays a Meridian menu, since a native menu cannot show it. The entries stay Meridian's menu model:
/// order, groups, checked state, shortcuts and destructive items.
///
/// [textContextMenuBuilder] does the same for the cut, copy and paste menu
/// of every `MeridianTextField`.
class MeridianMenuPresenter extends InheritedWidget {
  const MeridianMenuPresenter({
    required this.present,
    required super.child,
    super.key,
    this.textContextMenuBuilder,
  });

  final MeridianMenuPresent present;

  /// The text editing context menu of Meridian text fields. `null` keeps
  /// Flutter's adaptive toolbar.
  final EditableTextContextMenuBuilder? textContextMenuBuilder;

  static MeridianMenuPresenter? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MeridianMenuPresenter>();

  @override
  bool updateShouldNotify(MeridianMenuPresenter oldWidget) =>
      present != oldWidget.present ||
      textContextMenuBuilder != oldWidget.textContextMenuBuilder;
}

/// Opens a menu at [anchor] (a global rect: the trigger, or a zero-size rect
/// at the pointer for a context menu). Completes when the menu closes; the
/// chosen item's `onSelected` runs after it has closed.
///
/// [initialHighlight] highlights the checked (or first) item on open. When
/// `null` it is on if a key (Enter, Space, an arrow) is opening the menu.
///
/// Under a [MeridianMenuPresenter] the presenter shows the menu instead,
/// unless it holds a [MeridianMenuCustom] block (at any depth): an operating
/// system menu cannot show one, so Meridian draws that menu itself.
Future<void> showMeridianMenu(
  BuildContext context, {
  required Rect anchor,
  required List<MeridianMenuEntry> entries,
  double? width,
  double minWidth = 0,
  bool? initialHighlight,
}) async {
  final presenter = MeridianMenuPresenter.maybeOf(context);
  if (presenter != null && !_holdsCustom(entries)) {
    return presenter.present(context, anchor: anchor, entries: entries);
  }
  final navigator = Navigator.of(context, rootNavigator: true);
  final theme = Theme.of(context);
  final route = _MeridianMenuRoute(
    anchor: anchor,
    entries: entries,
    width: width,
    minWidth: minWidth,
    theme: theme,
    initialHighlight: initialHighlight ?? _keyboardIsOpening(),
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    reduced: MeridianMotion.reduced(context),
  );
  final selected = await navigator.push<MeridianMenuItem>(route);
  // Route.popped resolves before its reverse transition and overlay teardown.
  // Follow-up dialogs/native UI must wait for the actual menu lifetime to end.
  await route.completed;
  if (context.mounted) selected?.onSelected?.call();
}

/// Opens a context menu at the pointer position [globalPosition].
Future<void> showMeridianContextMenu(
  BuildContext context, {
  required Offset globalPosition,
  required List<MeridianMenuEntry> entries,
}) => showMeridianMenu(
  context,
  anchor: globalPosition & Size.zero,
  entries: entries,
);

class _MeridianMenuRoute extends PopupRoute<MeridianMenuItem> {
  _MeridianMenuRoute({
    required this.anchor,
    required this.entries,
    required this.width,
    required this.minWidth,
    required this.theme,
    required this.initialHighlight,
    required this.barrierLabel,
    required this.reduced,
  });

  final Rect anchor;
  final List<MeridianMenuEntry> entries;
  final double? width;
  final double minWidth;
  final ThemeData theme;
  final bool initialHighlight;

  /// Reduce motion at the time the menu opened: a short fade instead.
  final bool reduced;

  @override
  final String barrierLabel;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration =>
      reduced ? MeridianDurations.reducedFade : MeridianDurations.overlay;

  @override
  Duration get reverseTransitionDuration =>
      reduced ? MeridianDurations.reducedFade : MeridianDurations.exit;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final padding = MediaQuery.paddingOf(context);
    return Theme(
      data: theme,
      child: CustomSingleChildLayout(
        delegate: _MenuLayout(
          anchor: anchor,
          padding: padding,
          textDirection: Directionality.of(context),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minWidth),
          child: MeridianMenuSurface(
            entries: entries,
            width: width,
            initialHighlight: initialHighlight,
            onSelected: (item) => Navigator.of(context).pop(item),
            onDismiss: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => meridianOverlayTransition(
    context,
    animation,
    child,
    offset: _opensAbove(context, anchor)
        ? const Offset(0, MeridianMotionScales.riseOverlay)
        : const Offset(0, -MeridianMotionScales.riseOverlay),
    alignment: _opensAbove(context, anchor)
        ? AlignmentDirectional.bottomStart
        : AlignmentDirectional.topStart,
  );
}

/// Whether a menu or popover at [anchor] will open above it (the lower
/// part of the window has no room): it then grows upwards from its anchor.
bool _opensAbove(BuildContext context, Rect anchor) =>
    anchor.center.dy > MediaQuery.sizeOf(context).height * 0.6;

class _MenuLayout extends SingleChildLayoutDelegate {
  _MenuLayout({
    required this.anchor,
    required this.padding,
    required this.textDirection,
  });

  final Rect anchor;
  final EdgeInsets padding;
  final TextDirection textDirection;
  static const _gap = MeridianSpace.space2;
  static const _margin = MeridianSpace.space4;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        Size(
          math.max(
            0.0,
            constraints.maxWidth - padding.horizontal - _margin * 2,
          ),
          math.max(0.0, constraints.maxHeight - padding.vertical - _margin * 2),
        ),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final ltr = textDirection == TextDirection.ltr;
    final x = ltr ? anchor.left : anchor.right - childSize.width;
    final minX = padding.left + _margin;
    final maxX = math.max(
      minX,
      size.width - padding.right - _margin - childSize.width,
    );
    final below = anchor.bottom + _gap;
    final above = anchor.top - _gap - childSize.height;
    final minY = padding.top + _margin;
    final maxY = math.max(
      minY,
      size.height - padding.bottom - _margin - childSize.height,
    );
    final y = below <= maxY || above < minY ? below : above;
    return Offset(x.clamp(minX, maxX), y.clamp(minY, maxY));
  }

  @override
  bool shouldRelayout(_MenuLayout oldDelegate) =>
      anchor != oldDelegate.anchor ||
      padding != oldDelegate.padding ||
      textDirection != oldDelegate.textDirection;
}

/// The floating surface of a popover: `raised`, `radius-xl`,
/// `shadow-float`, like a menu, holding content of the app's own.
class MeridianPopoverSurface extends StatelessWidget {
  const MeridianPopoverSurface({
    required this.child,
    super.key,
    this.width,
    this.maxHeight = MeridianLayout.popoverMaxHeight,
  });

  final Widget child;
  final double? width;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final radius = BorderRadius.circular(meridian.radius.xl);
    return Container(
      width: width,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: meridian.colors.raised,
        borderRadius: radius,
        boxShadow: meridian.shadows.shadowFloat,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: MeridianTextScope(child: child),
      ),
    );
  }
}

/// Opens a popover at [anchor] (a global rect, usually the trigger): a
/// [MeridianPopoverSurface] with [builder]'s content below the anchor, or
/// above it when there is no room, growing from it as it fades in (MM-40).
///
/// Popovers hold small, focused tasks that a menu cannot: a filterable
/// folder picker, a set of options with Apply. A click outside or Escape
/// closes it, and focus returns to the trigger. Completes with the value
/// passed to `Navigator.pop` after the reverse transition and overlay removal
/// finish. Callers can then resize the host or open follow-up UI safely; they
/// must still check their invoking context before using it after this await.
Future<T?> showMeridianPopover<T>(
  BuildContext context, {
  required Rect anchor,
  required WidgetBuilder builder,
  double? width,
  double maxHeight = MeridianLayout.popoverMaxHeight,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = _MeridianPopoverRoute<T>(
    anchor: anchor,
    builder: builder,
    width: width,
    maxHeight: maxHeight,
    themes: InheritedTheme.capture(from: context, to: navigator.context),
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    reduced: MeridianMotion.reduced(context),
  );
  final result = await navigator.push<T>(route);
  await route.completed;
  return result;
}

/// Wraps a trigger that opens a popover below it. [builder] receives the
/// `open` callback to call from the trigger; [popoverBuilder] builds the
/// content.
class MeridianPopoverAnchor extends StatelessWidget {
  const MeridianPopoverAnchor({
    required this.builder,
    required this.popoverBuilder,
    super.key,
    this.width,
    this.maxHeight = MeridianLayout.popoverMaxHeight,
  });

  final Widget Function(BuildContext context, VoidCallback open) builder;
  final WidgetBuilder popoverBuilder;
  final double? width;
  final double maxHeight;

  @override
  Widget build(BuildContext context) => Builder(
    builder: (anchorContext) => builder(anchorContext, () {
      if (!anchorContext.mounted) return;
      final box = anchorContext.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      showMeridianPopover<void>(
        anchorContext,
        anchor: box.localToGlobal(Offset.zero) & box.size,
        builder: popoverBuilder,
        width: width,
        maxHeight: maxHeight,
      );
    }),
  );
}

class _MeridianPopoverRoute<T> extends PopupRoute<T> {
  _MeridianPopoverRoute({
    required this.anchor,
    required this.builder,
    required this.width,
    required this.maxHeight,
    required this.themes,
    required this.barrierLabel,
    required this.reduced,
  });

  final Rect anchor;
  final WidgetBuilder builder;
  final double? width;
  final double maxHeight;
  final CapturedThemes themes;
  final bool reduced;

  @override
  final String barrierLabel;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration =>
      reduced ? MeridianDurations.reducedFade : MeridianDurations.overlay;

  @override
  Duration get reverseTransitionDuration =>
      reduced ? MeridianDurations.reducedFade : MeridianDurations.exit;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => themes.wrap(
    CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: CustomSingleChildLayout(
        delegate: _MenuLayout(
          anchor: anchor,
          padding: MediaQuery.paddingOf(context),
          textDirection: Directionality.of(context),
        ),
        child: FocusScope(
          autofocus: true,
          child: MeridianPopoverSurface(
            width: width,
            maxHeight: maxHeight,
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => meridianOverlayTransition(
    context,
    animation,
    child,
    offset: _opensAbove(context, anchor)
        ? const Offset(0, MeridianMotionScales.riseOverlay)
        : const Offset(0, -MeridianMotionScales.riseOverlay),
    alignment: _opensAbove(context, anchor)
        ? AlignmentDirectional.bottomStart
        : AlignmentDirectional.topStart,
  );
}
