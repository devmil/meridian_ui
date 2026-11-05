import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'meridian_layout.dart';
import 'meridian_theme.dart';

/// Pointer, keyboard and focus state shared by every Meridian control.
@immutable
class MeridianInteractionState {
  const MeridianInteractionState({
    required this.hovered,
    required this.pressed,
    required this.focused,
    required this.enabled,
  });

  final bool hovered;
  final bool pressed;

  /// Keyboard focus that should be painted (never set by a pointer press).
  final bool focused;
  final bool enabled;

  /// [hoverFill] while hovered, and hover plus 4% `ink` while pressed:
  /// Meridian's pressed state. Returns [rest] otherwise; a fully
  /// transparent [rest] comes back as [meridianClear] of [hoverFill], so the
  /// hover fades in and out without passing through grey.
  Color fill({
    required Color rest,
    required Color hoverFill,
    required Color ink,
  }) {
    if (rest.a == 0) rest = meridianClear(hoverFill);
    if (!enabled) return rest;
    if (pressed) {
      return Color.alphaBlend(
        ink.withValues(alpha: MeridianOpacity.pressedOverlay),
        hoverFill,
      );
    }
    return hovered ? hoverFill : rest;
  }
}

/// [color] with zero alpha: "no fill" that animates cleanly into [color].
///
/// Use it instead of `Colors.transparent` for any fill, edge or rule that
/// animates. `Colors.transparent` is transparent *black*: a transition from
/// it to a light colour passes through translucent dark grey, which reads as
/// a dark flash on hover.
Color meridianClear(Color color) => color.withValues(alpha: 0);

/// [base] with Meridian's 4% `ink` pressed overlay on top.
Color meridianPressed(Color base, Color ink) => Color.alphaBlend(
  ink.withValues(alpha: MeridianOpacity.pressedOverlay),
  base,
);

/// Whether the most recent input was the keyboard, as the web's
/// `:focus-visible`.
///
/// Focus rings follow it: a control that gets focus back after the menu or
/// dialog it opened closes shows its ring only when that surface was driven
/// by the keyboard, not after a mouse click. (Flutter's desktop highlight
/// mode is always traditional, so it cannot tell the two apart.)
abstract final class MeridianInputModality {
  static var _users = 0;
  static final _keyboard = ValueNotifier<bool>(false);

  /// The last key down came after the last pointer down.
  static bool get keyboard => _keyboard.value;

  /// Notifies when [keyboard] changes, while the modality is retained.
  ///
  /// An affordance revealed by hover or keyboard focus listens to it, so a
  /// pointer press anywhere hides what only keyboard focus was showing.
  static ValueListenable<bool> get changes => _keyboard;

  static bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent) _keyboard.value = true;
    return false;
  }

  static void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent) _keyboard.value = false;
  }

  /// Listens to keys and pointers while at least one control needs it.
  /// Pair every call with [release].
  static void retain() {
    if (_users++ > 0) return;
    HardwareKeyboard.instance.addHandler(_onKey);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  static void release() {
    if (--_users > 0) return;
    HardwareKeyboard.instance.removeHandler(_onKey);
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
  }
}

/// A modifier that reveals keyboard hints while it is held.
enum MeridianModifier { meta, control, alt }

/// The command modifiers (⌘, Ctrl, ⌥) currently held down. Shift is left
/// out: it is held while typing capitals and must not flash hints.
///
/// Listens to the keyboard only while something listens to it.
class MeridianHeldModifiers extends ChangeNotifier
    implements ValueListenable<Set<MeridianModifier>> {
  MeridianHeldModifiers._();

  static final instance = MeridianHeldModifiers._();

  var _value = const <MeridianModifier>{};
  var _keys = const <LogicalKeyboardKey>{};

  @override
  Set<MeridianModifier> get value => _value;

  /// Every key held down while a command modifier is held (empty
  /// otherwise), so a keycap can show its whole chord pressed (MM-17).
  Set<LogicalKeyboardKey> get keys => _keys;

  bool _onKey(KeyEvent event) {
    final pressed = HardwareKeyboard.instance;
    final next = <MeridianModifier>{
      if (pressed.isMetaPressed) MeridianModifier.meta,
      if (pressed.isControlPressed) MeridianModifier.control,
      if (pressed.isAltPressed) MeridianModifier.alt,
    };
    final keys = next.isEmpty
        ? const <LogicalKeyboardKey>{}
        : {...pressed.logicalKeysPressed};
    if (!setEquals(next, _value) || !setEquals(keys, _keys)) {
      _value = next;
      _keys = keys;
      notifyListeners();
    }
    return false;
  }

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) HardwareKeyboard.instance.addHandler(_onKey);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      HardwareKeyboard.instance.removeHandler(_onKey);
      _value = const {};
      _keys = const {};
    }
  }

  @override
  // The shared instance lives as long as the app.
  // ignore: must_call_super
  void dispose() {}
}

/// The single hover, press and focus layer for Meridian controls.
///
/// No ripple, no splash. Enter and Space activate. The 2px focus ring shows
/// for keyboard focus only; a pointer press focuses without the ring. At
/// touch density the hit area grows to the 48px minimum target.
class MeridianInteraction extends StatefulWidget {
  const MeridianInteraction({
    super.key,
    this.child,
    this.builder,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.onSecondaryTapUp,
    this.canRequestFocus = true,
    this.focusOnPointer = true,
    this.autofocus = false,
    this.focusNode,
    this.borderRadius = BorderRadius.zero,
    this.cursor,
    this.expandHitTarget = true,
    this.pressScale = false,
  }) : assert(child != null || builder != null);

  final Widget? child;
  final Widget Function(BuildContext context, MeridianInteractionState state)?
  builder;
  final VoidCallback? onTap;

  /// Pointer activation after an immediate first tap. Keyboard activation stays single.
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final GestureTapUpCallback? onSecondaryTapUp;
  final bool canRequestFocus;

  /// Take focus on a pointer press. Toolbar commands set this to false:
  /// clicking them leaves focus where the person was working, and a dialog
  /// they open hands focus back there. The keyboard can still reach them.
  final bool focusOnPointer;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Radius of the focus ring; match the control's own radius.
  final BorderRadius borderRadius;
  final MouseCursor? cursor;

  /// Grow the hit area to the density's minimum target.
  final bool expandHitTarget;

  /// Scale the control to `press-scale` while it is pressed and spring it
  /// back on release; keyboard activation plays a short press (MM-02).
  final bool pressScale;

  @override
  State<MeridianInteraction> createState() => _MeridianInteractionState();
}

class _MeridianInteractionState extends State<MeridianInteraction> {
  FocusNode? _ownedFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ??
      (_ownedFocusNode ??= FocusNode(debugLabel: 'meridian-interaction'));
  FocusNode? _listened;
  var _hovered = false;
  var _pressed = false;

  /// Focused in keyboard highlight mode, as FocusableActionDetector reports
  /// it. That includes focus on a descendant (a row's hover action), so the
  /// ring additionally requires primary focus.
  var _highlight = false;
  var _pointerFocused = false;
  final _press = GlobalKey<MeridianPressScaleState>();

  bool get _focusVisible =>
      _highlight &&
      !_pointerFocused &&
      _focusNode.hasPrimaryFocus &&
      MeridianInputModality.keyboard;

  Timer? _doubleTapWindow;

  void _handleTap() {
    if (widget.onDoubleTap != null && (_doubleTapWindow?.isActive ?? false)) {
      _doubleTapWindow!.cancel();
      _doubleTapWindow = null;
      widget.onDoubleTap!();
      return;
    }
    widget.onTap?.call();
    if (mounted && widget.onDoubleTap != null) {
      _doubleTapWindow?.cancel();
      _doubleTapWindow = Timer(kDoubleTapTimeout, () {});
    }
  }

  bool get _tappable => widget.onTap != null || widget.onDoubleTap != null;

  bool get _enabled =>
      widget.onDoubleTap != null ||
      widget.onTap != null ||
      widget.onLongPress != null ||
      widget.onSecondaryTap != null ||
      widget.onSecondaryTapUp != null;

  @override
  void initState() {
    MeridianInputModality.retain();
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(covariant MeridianInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    _listen();
    if (!_enabled || widget.onDoubleTap == null) {
      _doubleTapWindow?.cancel();
    }
    if (!_enabled) {
      _hovered = false;
      _pressed = false;
      _highlight = false;
    }
  }

  @override
  void dispose() {
    _doubleTapWindow?.cancel();
    MeridianInputModality.release();
    _listened?.removeListener(_onFocusChanged);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  /// Rebuilds when primary focus moves between this node and a descendant.
  void _listen() {
    final node = _focusNode;
    if (identical(node, _listened)) return;
    _listened?.removeListener(_onFocusChanged);
    _listened = node..addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && _pointerFocused) {
      setState(() => _pointerFocused = false);
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final state = MeridianInteractionState(
      hovered: _hovered,
      pressed: _pressed,
      focused: _focusVisible,
      enabled: _enabled,
    );
    final content = widget.builder?.call(context, state) ?? widget.child!;
    final minTarget = widget.expandHitTarget ? meridian.density.minTarget : 0.0;
    Widget target = CustomPaint(
      foregroundPainter: MeridianFocusRingPainter(
        visible: _focusVisible,
        color: meridian.colors.focus,
        radius: widget.borderRadius,
      ),
      child: content,
    );
    if (widget.pressScale) {
      target = MeridianPressScale(
        key: _press,
        pressed: _pressed && _enabled,
        enabled: _enabled,
        child: target,
      );
    }
    if (minTarget > 0) {
      // The growth sits inside the gesture detector so the added margin is
      // hit-testable; the ring still hugs the visible control.
      target = _MinTarget(extent: minTarget, child: target);
    }
    // FocusableActionDetector owns the node's canRequestFocus (it follows
    // `enabled`). Setting it here as well made the two fight on every
    // build, and each flip notified the node and rebuilt this widget.
    // ExcludeFocus keeps a non-focusable control out of focus instead.
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: ExcludeFocus(
        excluding: !widget.canRequestFocus,
        child: FocusableActionDetector(
          enabled: _enabled,
          autofocus: widget.autofocus,
          focusNode: _focusNode,
          mouseCursor:
              widget.cursor ??
              (_enabled ? SystemMouseCursors.click : SystemMouseCursors.basic),
          onShowHoverHighlight: (value) {
            if (_hovered != value) setState(() => _hovered = value && _enabled);
          },
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                if (widget.onTap != null) _press.currentState?.pulse();
                widget.onTap?.call();
                return null;
              },
            ),
          },
          onFocusChange: (focused) {
            if (!focused) _pointerFocused = false;
          },
          onShowFocusHighlight: (value) {
            if (_highlight != value) setState(() => _highlight = value);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: !_tappable
                ? null
                : (_) {
                    _pointerFocused = true;
                    if (widget.canRequestFocus && widget.focusOnPointer) {
                      _focusNode.requestFocus();
                    }
                    _setPressed(true);
                  },
            onTapUp: !_tappable ? null : (_) => _setPressed(false),
            onTapCancel: !_tappable ? null : () => _setPressed(false),
            onTap: _tappable ? _handleTap : null,
            onLongPress: widget.onLongPress,
            onSecondaryTap: widget.onSecondaryTap,
            onSecondaryTapUp: widget.onSecondaryTapUp,
            child: target,
          ),
        ),
      ),
    );
  }
}

/// Grows to at least [extent] in both axes around its centred child.
///
/// Unlike `ConstrainedBox` + `Center`, the child receives the incoming
/// constraints unchanged, so a control stretched to full width by its parent
/// (stacked dialog buttons) stays full width.
class _MinTarget extends SingleChildRenderObjectWidget {
  const _MinTarget({required this.extent, super.child});

  final double extent;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMinTarget(extent);

  @override
  void updateRenderObject(BuildContext context, _RenderMinTarget renderObject) {
    renderObject.extent = extent;
  }
}

class _RenderMinTarget extends RenderShiftedBox {
  _RenderMinTarget(this._extent) : super(null);

  double _extent;
  set extent(double value) {
    if (value == _extent) return;
    _extent = value;
    markNeedsLayout();
  }

  Size _grow(BoxConstraints constraints, Size child) => constraints.constrain(
    Size(math.max(child.width, _extent), math.max(child.height, _extent)),
  );

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(_extent, child?.getMinIntrinsicWidth(height) ?? 0);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(_extent, child?.getMaxIntrinsicWidth(height) ?? 0);

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(_extent, child?.getMinIntrinsicHeight(width) ?? 0);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(_extent, child?.getMaxIntrinsicHeight(width) ?? 0);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final childSize = child?.getDryLayout(constraints) ?? Size.zero;
    return _grow(constraints, childSize);
  }

  @override
  double? computeDryBaseline(
    covariant BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final box = child;
    if (box == null) return null;
    final childSize = box.getDryLayout(constraints);
    final result = box.getDryBaseline(constraints, baseline);
    if (result == null) return null;
    final size = _grow(constraints, childSize);
    return result + (size.height - childSize.height) / 2;
  }

  @override
  void performLayout() {
    final box = child;
    if (box == null) {
      size = _grow(constraints, Size.zero);
      return;
    }
    box.layout(constraints, parentUsesSize: true);
    size = _grow(constraints, box.size);
    (box.parentData! as BoxParentData).offset = Alignment.center.alongOffset(
      size - box.size as Offset,
    );
  }
}

/// Paints Meridian's focus ring: 2px, 1px outside the control.
class MeridianFocusRingPainter extends CustomPainter {
  const MeridianFocusRingPainter({
    required this.visible,
    required this.color,
    required this.radius,
  });

  final bool visible;
  final Color color;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible) return;
    const offset =
        MeridianLayout.focusRingOffset + MeridianLayout.focusRingWidth / 2;
    final rect = (Offset.zero & size).inflate(offset);
    canvas.drawRRect(
      radius.toRRect(rect),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = MeridianLayout.focusRingWidth,
    );
  }

  @override
  bool shouldRepaint(covariant MeridianFocusRingPainter oldDelegate) =>
      visible != oldDelegate.visible ||
      color != oldDelegate.color ||
      radius != oldDelegate.radius;
}

/// Icon sizes. The actual extent follows the density: touch icons are
/// larger.
enum MeridianIconSize { small, regular, toolbar }

/// A single-ink Lucide icon from Meridian's set (or the app's own, see
/// `MeridianIconSet`). Decorative: pair it with a label or give the control
/// a semantic label.
class MeridianIcon extends StatelessWidget {
  const MeridianIcon(
    this.name, {
    super.key,
    this.size = MeridianIconSize.regular,
    this.extent,
    this.color,
  });

  /// Lucide name, for example `circle-check`, or a name registered in the
  /// app's `MeridianIconSet`.
  final String name;
  final MeridianIconSize size;

  /// An explicit extent in logical pixels; overrides [size].
  final double? extent;

  /// Defaults to the ambient [IconTheme] colour (Meridian sets it to `ink`).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final density = meridian.density;
    final dimension =
        extent ??
        switch (size) {
          MeridianIconSize.small => density.iconSmallSize,
          MeridianIconSize.regular => density.iconSize,
          MeridianIconSize.toolbar => density.isTouch ? 22.0 : 18.0,
        };
    return SvgPicture.asset(
      meridian.icons.assetFor(name),
      width: dimension,
      height: dimension,
      colorFilter: ColorFilter.mode(
        color ?? IconTheme.of(context).color ?? meridian.colors.ink,
        BlendMode.srcIn,
      ),
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) =>
          SizedBox.square(dimension: dimension),
    );
  }
}

/// Tells descendants what surface they sit on and whether their island has
/// keyboard focus, so rows can pick the right selection and hover paint.
class MeridianSurfaceScope extends InheritedWidget {
  const MeridianSurfaceScope({
    required super.child,
    super.key,
    this.focused = false,
    this.onGround = false,
    this.fill,
  });

  /// Keeps the enclosing scope's [focused] and [onGround] and sets the
  /// [fill] behind [child]: a row's hover or selection bar, a field's well.
  static Widget withFill(
    BuildContext context, {
    required Color? fill,
    required Widget child,
  }) {
    final parent = maybeOf(context);
    return MeridianSurfaceScope(
      focused: parent?.focused ?? false,
      onGround: parent?.onGround ?? false,
      fill: fill,
      child: child,
    );
  }

  /// The enclosing island owns keyboard focus: selection is solid `accent`.
  final bool focused;

  /// The content sits on `ground` (sidebar, toolbar) rather than an island.
  final bool onGround;

  /// The paint behind the content when it is not the plain surface: a
  /// hovered or selected row, a field's well. Controls inside it hover by
  /// darkening it (see [hoverFillOf]); a fixed `pane-hover` would vanish on
  /// a row that is itself hovered.
  final Color? fill;

  static MeridianSurfaceScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MeridianSurfaceScope>();

  /// The hover fill of a quiet control (icon button, quiet button) here:
  /// the surface's [fill] with the pressed overlay, else `ground-hover` on
  /// ground and `pane-hover` in an island.
  static Color hoverFillOf(BuildContext context, {bool? onGround}) {
    final colors = MeridianTheme.of(context).colors;
    final scope = maybeOf(context);
    final ground = onGround ?? scope?.onGround ?? false;
    final fill = scope?.fill;
    if (fill == colors.pane) return colors.paneHover;
    if (fill == colors.ground) return colors.groundHover;
    if (fill == colors.accent) {
      // A solid accent selection brightens, like a primary button.
      return Color.alphaBlend(
        colors.onAccent.withValues(alpha: MeridianOpacity.primaryHoverOverlay),
        fill!,
      );
    }
    if (fill != null && fill.a > 0) {
      final base = ground ? colors.ground : colors.pane;
      return meridianPressed(Color.alphaBlend(fill, base), colors.ink);
    }
    return ground ? colors.groundHover : colors.paneHover;
  }

  @override
  bool updateShouldNotify(MeridianSurfaceScope oldWidget) =>
      focused != oldWidget.focused ||
      onGround != oldWidget.onGround ||
      fill != oldWidget.fill;
}

/// The fill and ink of a row for its selection and hover state.
@immutable
class MeridianRowColors {
  const MeridianRowColors({
    required this.fill,
    required this.primary,
    required this.secondary,
    required this.icon,
    required this.strong,
  });

  final Color fill;
  final Color primary;
  final Color secondary;
  final Color icon;

  /// Solid `accent` selection (the island has focus).
  final bool strong;

  factory MeridianRowColors.resolve(
    BuildContext context, {
    required bool selected,
    required bool hovered,
    bool? focused,
    bool? onGround,
  }) {
    final theme = MeridianTheme.of(context);
    final colors = theme.colors;
    final scope = MeridianSurfaceScope.maybeOf(context);
    final strong =
        selected &&
        theme.selection == MeridianSelectionStyle.strong &&
        (focused ?? scope?.focused ?? false) &&
        MeridianWindowFocus.of(context);
    final ground = onGround ?? scope?.onGround ?? false;
    return MeridianRowColors(
      fill: selected
          ? (strong ? colors.accent : colors.accentSoft)
          : hovered
          ? (ground ? colors.groundHover : colors.paneHover)
          : meridianClear(ground ? colors.groundHover : colors.paneHover),
      primary: strong ? colors.onAccent : colors.ink,
      secondary: strong ? colors.onAccentMuted : colors.inkMuted,
      icon: strong ? colors.onAccent : colors.inkMuted,
      strong: strong,
    );
  }
}

/// A 1px `line` divider.
class MeridianHairline extends StatelessWidget {
  const MeridianHairline({
    super.key,
    this.axis = Axis.horizontal,
    this.color,
    this.indent = 0,
  });

  final Axis axis;
  final Color? color;
  final double indent;

  @override
  Widget build(BuildContext context) {
    // LimitedBox + expand: fills the cross axis when bounded, never
    // collapses to zero inside a loose Row or Column.
    final line = ColoredBox(
      color: color ?? MeridianTheme.of(context).colors.line,
      child: const LimitedBox(
        maxWidth: 0,
        maxHeight: 0,
        child: SizedBox.expand(),
      ),
    );
    return Padding(
      padding: axis == Axis.horizontal
          ? EdgeInsetsDirectional.only(start: indent)
          : EdgeInsets.only(top: indent),
      child: SizedBox(
        width: axis == Axis.vertical ? MeridianLayout.hairline : null,
        height: axis == Axis.horizontal ? MeridianLayout.hairline : null,
        child: line,
      ),
    );
  }
}

/// Resets the ambient text style to Meridian `body` in `ink` and provides a
/// transparent [Material] ancestor (for [TextField], [Tooltip], scrollbars).
///
/// [MeridianGround] and every overlay surface (menus, toasts, dialogs,
/// sheets, panels) wrap their content in it, so text never inherits
/// Flutter's fallback error style.
class MeridianTextScope extends StatelessWidget {
  const MeridianTextScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    return Material(
      type: MaterialType.transparency,
      textStyle: meridian.text.body,
      child: IconTheme.merge(
        data: IconThemeData(color: meridian.colors.ink),
        child: child,
      ),
    );
  }
}

/// Duration helper used by components: the token, or zero with reduce motion.
Duration meridianDuration(BuildContext context, Duration duration) =>
    MeridianMotion.of(context, duration);
