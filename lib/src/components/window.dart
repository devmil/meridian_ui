import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import 'tooltip.dart';

/// Resizes the islands on either side of the gutter it sits in: a sidebar,
/// an inspector, a split between two lists.
///
/// It is the `space-3` gap itself, invisible at rest; hover shows a 2px
/// `line-strong` rule, dragging turns it `accent`, keyboard focus `focus`.
/// Dragging reports the pointer's movement along [direction] to [onDrag];
/// the arrow keys move it by [keyboardStep]; a double click or Enter calls
/// [onReset] (back to the default size).
class MeridianResizeHandle extends StatefulWidget {
  const MeridianResizeHandle({
    required this.semanticLabel,
    required this.onDrag,
    super.key,
    this.direction = Axis.horizontal,
    this.onDragStart,
    this.onDragEnd,
    this.onReset,
    this.thickness = MeridianSpace.space3,
    this.keyboardStep = MeridianLayout.resizeKeyboardStep,
  });

  /// What it resizes ("Resize inspector").
  final String semanticLabel;

  /// The pointer's (or arrow key's) movement along [direction], in logical
  /// pixels. Positive is right or down; the consumer decides which island
  /// grows.
  final ValueChanged<double> onDrag;

  /// [Axis.horizontal] for a vertical gutter between side-by-side islands,
  /// [Axis.vertical] for a horizontal gutter between stacked ones.
  final Axis direction;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  /// Restores the default size.
  final VoidCallback? onReset;

  /// The gutter width. Keep the island gap.
  final double thickness;

  /// How far one arrow key press moves the handle.
  final double keyboardStep;

  @override
  State<MeridianResizeHandle> createState() => _MeridianResizeHandleState();
}

class _MeridianResizeHandleState extends State<MeridianResizeHandle>
    with SingleTickerProviderStateMixin {
  var _hovered = false;
  var _dragging = false;
  var _focused = false;

  /// The hover line: grows from the centre 150 ms into a hover (MM-75).
  late final AnimationController _grow = AnimationController(vsync: this);
  Timer? _hoverDelay;

  void _setHovered(bool value) {
    setState(() => _hovered = value);
    _hoverDelay?.cancel();
    if (value) {
      _hoverDelay = Timer(MeridianDurations.spinnerDelay * timeDilation, () {
        if (!mounted || !_hovered) return;
        _grow.animateTo(
          1,
          duration: MeridianMotion.of(context, MeridianDurations.quick),
          curve: MeridianDurations.quickCurve,
        );
      });
    } else {
      _grow.animateTo(
        0,
        duration: MeridianMotion.of(context, MeridianDurations.exit),
        curve: MeridianDurations.exitCurve,
      );
    }
  }

  @override
  void dispose() {
    _hoverDelay?.cancel();
    _grow.dispose();
    super.dispose();
  }

  bool get _horizontal => widget.direction == Axis.horizontal;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final (back, forward) = _horizontal
        ? (LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowRight)
        : (LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.arrowDown);
    if (key == back) {
      widget.onDrag(-widget.keyboardStep);
      return KeyEventResult.handled;
    }
    if (key == forward) {
      widget.onDrag(widget.keyboardStep);
      return KeyEventResult.handled;
    }
    if ((key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) &&
        widget.onReset != null) {
      widget.onReset!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _setDragging(bool value) {
    if (_dragging == value) return;
    setState(() => _dragging = value);
    value ? widget.onDragStart?.call() : widget.onDragEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = MeridianTheme.of(context).colors;
    final keyboardFocus =
        _focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    final rule = _dragging
        ? colors.accent
        : keyboardFocus
        ? colors.focus
        : _hovered
        ? colors.accent
        : meridianClear(colors.accent);
    final full = _dragging || keyboardFocus;
    void update(DragUpdateDetails details) =>
        widget.onDrag(_horizontal ? details.delta.dx : details.delta.dy);
    return Semantics(
      label: widget.semanticLabel,
      slider: true,
      child: Focus(
        onKeyEvent: _onKey,
        onFocusChange: (value) => setState(() => _focused = value),
        child: MouseRegion(
          cursor: _horizontal
              ? SystemMouseCursors.resizeColumn
              : SystemMouseCursors.resizeRow,
          onEnter: (_) => _setHovered(true),
          onExit: (_) => _setHovered(false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // The divider follows the pointer from where it went down,
            // not from where the drag slop was crossed.
            dragStartBehavior: DragStartBehavior.down,
            onDoubleTap: widget.onReset,
            onHorizontalDragStart: _horizontal
                ? (_) => _setDragging(true)
                : null,
            onHorizontalDragUpdate: _horizontal ? update : null,
            onHorizontalDragEnd: _horizontal
                ? (_) => _setDragging(false)
                : null,
            onHorizontalDragCancel: _horizontal
                ? () => _setDragging(false)
                : null,
            onVerticalDragStart: _horizontal ? null : (_) => _setDragging(true),
            onVerticalDragUpdate: _horizontal ? null : update,
            onVerticalDragEnd: _horizontal ? null : (_) => _setDragging(false),
            onVerticalDragCancel: _horizontal
                ? null
                : () => _setDragging(false),
            child: SizedBox(
              width: _horizontal ? widget.thickness : null,
              height: _horizontal ? null : widget.thickness,
              child: Center(
                child: AnimatedBuilder(
                  animation: _grow,
                  builder: (context, child) {
                    final t = full ? 1.0 : _grow.value;
                    return Transform(
                      alignment: Alignment.center,
                      transform: _horizontal
                          ? Matrix4.diagonal3Values(1, t, 1)
                          : Matrix4.diagonal3Values(t, 1, 1),
                      child: child,
                    );
                  },
                  child: AnimatedContainer(
                    duration: meridianHoverDuration(
                      context,
                      _hovered || _dragging,
                    ),
                    width: _horizontal ? MeridianLayout.resizeRule : null,
                    height: _horizontal ? null : MeridianLayout.resizeRule,
                    margin: _horizontal
                        ? const EdgeInsets.symmetric(
                            vertical: MeridianSpace.space5,
                          )
                        : const EdgeInsets.symmetric(
                            horizontal: MeridianSpace.space5,
                          ),
                    decoration: BoxDecoration(
                      color: rule,
                      borderRadius: BorderRadius.circular(
                        MeridianRadiusScale.pill,
                      ),
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
}

/// The window's bottom strip on `ground`: live state and totals ("Polling
/// every second", "412 processes"), never commands. `caption` text in
/// `ink-muted` with tabular figures; [leading] items start at the left,
/// [trailing] ones end at the right, `space-5` apart. Plain [Text] items
/// and [MeridianStatusBarItem]s swap with a rise when they change.
class MeridianStatusBar extends StatelessWidget {
  const MeridianStatusBar({
    super.key,
    this.leading = const [],
    this.trailing = const [],
  });

  final List<Widget> leading;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    List<Widget> spaced(List<Widget> items) => [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: MeridianSpace.space5),
        items[i],
      ],
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: MeridianLayout.statusBarHeight,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MeridianSpace.space5),
        child: DefaultTextStyle.merge(
          style: MeridianTextStyles.numeric(
            meridian.text.caption.copyWith(color: colors.inkMuted),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: IconTheme.merge(
            data: IconThemeData(
              color: colors.inkMuted,
              size: meridian.density.iconSmallSize,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      for (var i = 0; i < leading.length; i++) ...[
                        if (i > 0) const SizedBox(width: MeridianSpace.space5),
                        Flexible(child: _swapping(leading[i])),
                      ],
                    ],
                  ),
                ),
                ...spaced([for (final item in trailing) _swapping(item)]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One item of a [MeridianStatusBar]: an optional small [icon] before a
/// one-line [label] that swaps with a 3px rise when it changes (MM-76) and
/// ellipsizes at [maxWidth]. With [onPressed] it is a quiet button (the
/// app's About, the branch, the host), announced under [semanticLabel] or
/// [label] with [tooltip] on hover.
class MeridianStatusBarItem extends StatelessWidget {
  const MeridianStatusBarItem({
    required this.label,
    super.key,
    this.icon,
    this.leading,
    this.maxWidth,
    this.onPressed,
    this.tooltip,
    this.semanticLabel,
  });

  final String label;

  /// A Lucide icon at the small icon size, in `ink-muted`.
  final String? icon;

  /// A widget before the label (a status dot, a brand mark); wins over
  /// [icon].
  final Widget? leading;

  /// The widest the item gets before its label ellipsizes.
  final double? maxWidth;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final leading =
        this.leading ??
        switch (icon) {
          final icon? => MeridianIcon(
            icon,
            size: MeridianIconSize.small,
            color: colors.inkMuted,
          ),
          null => null,
        };
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[
          leading,
          const SizedBox(width: MeridianSpace.space2),
        ],
        Flexible(
          child: MeridianSwap(
            swapKey: label,
            style: MeridianSwapStyle.rise,
            rise: MeridianLayout.statusBarRise,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
    if (maxWidth case final maxWidth?) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: content,
      );
    }
    final onPressed = this.onPressed;
    if (onPressed == null) {
      return Semantics(
        label: semanticLabel,
        excludeSemantics: semanticLabel != null,
        child: content,
      );
    }
    final radius = BorderRadius.circular(meridian.radius.sm);
    final button = Semantics(
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      onTap: onPressed,
      child: MeridianInteraction(
        onTap: onPressed,
        borderRadius: radius,
        builder: (context, state) => AnimatedContainer(
          duration: meridianHoverDuration(
            context,
            state.hovered || state.pressed,
          ),
          padding: const EdgeInsets.symmetric(horizontal: MeridianSpace.space2),
          decoration: BoxDecoration(
            color: state.fill(
              rest: meridianClear(MeridianSurfaceScope.hoverFillOf(context)),
              hoverFill: MeridianSurfaceScope.hoverFillOf(context),
              ink: colors.ink,
            ),
            borderRadius: radius,
          ),
          child: content,
        ),
      ),
    );
    final tooltip = this.tooltip;
    return tooltip == null
        ? button
        : MeridianTooltip(
            message: tooltip,
            excludeFromSemantics: true,
            child: button,
          );
  }
}

/// A status bar text that swaps with a 3 px rise when it changes (MM-76).
Widget _swapping(Widget item) => item is Text
    ? MeridianSwap(
        swapKey: item.data ?? item.textSpan?.toPlainText(),
        style: MeridianSwapStyle.rise,
        rise: MeridianLayout.statusBarRise,
        child: item,
      )
    : item;
