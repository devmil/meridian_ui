import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../foundation/meridian_layout.dart';
import '../foundation/meridian_localizations.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import 'window.dart';

/// Which pane of a [MeridianSplitPane] keeps a fixed size while the other
/// takes the rest.
enum MeridianSplitPinned { first, second }

/// Two panes side by side ([axis] horizontal) or stacked (vertical), with
/// a [MeridianResizeHandle] in the `space-3` gap between them.
///
/// Sizes come in one of two forms:
///
/// - a **ratio**: [ratio] is the first pane's share of the space both
///   panes share (the gap excluded). Leave it `null` to let the split pane
///   keep its own, starting at [initialRatio]. [onRatioChanged] follows the
///   drag; [onRatioChangeEnd] gets the final ratio when a drag or key press
///   ends, the moment to persist it.
/// - an **extent**: with [extent] and [onExtentChanged], the [pinned] pane
///   is [extent] logical pixels and the other takes the rest (a sidebar, a
///   detail pane under a list).
///
/// Neither pane gets smaller than its minimum ([firstMinExtent],
/// [secondMinExtent]); when both minimums do not fit, they shrink evenly.
/// The handle follows the pointer, steps by [keyboardStep] with the arrow
/// keys, and restores the default on double click or Enter ([onReset];
/// an uncontrolled ratio returns to [initialRatio]). It is announced as an
/// adjustable control named [semanticLabel] whose value is the first
/// pane's share. Right-to-left layouts mirror the drag.
class MeridianSplitPane extends StatefulWidget {
  const MeridianSplitPane({
    required this.first,
    required this.second,
    super.key,
    this.axis = Axis.horizontal,
    this.ratio,
    this.initialRatio = 0.5,
    this.onRatioChanged,
    this.onRatioChangeEnd,
    this.extent,
    this.onExtentChanged,
    this.onExtentChangeEnd,
    this.pinned = MeridianSplitPinned.first,
    this.firstMinExtent = MeridianLayout.splitPaneMinExtent,
    this.secondMinExtent = MeridianLayout.splitPaneMinExtent,
    this.onReset,
    this.semanticLabel,
    this.keyboardStep = MeridianLayout.resizeKeyboardStep,
    this.thickness = MeridianSpace.space3,
    this.divider = false,
    this.focusable = true,
    this.handleKey,
  }) : assert(initialRatio >= 0 && initialRatio <= 1),
       assert(extent == null || onExtentChanged != null);

  final Widget first;
  final Widget second;

  /// [Axis.horizontal]: [first] at the start, [second] at the end.
  /// [Axis.vertical]: [first] above [second].
  final Axis axis;

  /// The first pane's share (0 to 1) of the space both panes share.
  final double? ratio;
  final double initialRatio;
  final ValueChanged<double>? onRatioChanged;
  final ValueChanged<double>? onRatioChangeEnd;

  /// The [pinned] pane's size in logical pixels; switches to extent sizing.
  final double? extent;
  final ValueChanged<double>? onExtentChanged;
  final ValueChanged<double>? onExtentChangeEnd;
  final MeridianSplitPinned pinned;

  final double firstMinExtent;
  final double secondMinExtent;

  /// Double click or Enter on the handle: restore the default size.
  final VoidCallback? onReset;

  /// What the handle resizes ("Resize inspector"). Defaults to the
  /// localized "Resize panes".
  final String? semanticLabel;
  final double keyboardStep;

  /// The gap between the panes.
  final double thickness;

  /// Draw a `line` hairline in the gap at rest, for panes inside one island
  /// that have no gap of `ground` between them.
  final bool divider;

  /// Whether the handle takes keyboard focus (Tab). Off keeps it out of
  /// the Tab order; it stays adjustable for assistive technology.
  final bool focusable;
  final Key? handleKey;

  @override
  State<MeridianSplitPane> createState() => _MeridianSplitPaneState();
}

class _MeridianSplitPaneState extends State<MeridianSplitPane> {
  late double _ownRatio = widget.initialRatio;
  var _dragging = false;

  bool get _byExtent => widget.onExtentChanged != null;
  double get _ratio => (widget.ratio ?? _ownRatio).clamp(0.0, 1.0);

  /// The minimums that fit [usable], shrunk evenly when both do not.
  (double, double) _minimums(double usable) {
    var first = math.max(0.0, widget.firstMinExtent);
    var second = math.max(0.0, widget.secondMinExtent);
    if (first + second > usable) {
      final scale = usable <= 0 ? 0.0 : usable / (first + second);
      first *= scale;
      second *= scale;
    }
    return (first, second);
  }

  /// The first pane's extent in [usable].
  double _firstExtent(double usable) {
    final (minFirst, minSecond) = _minimums(usable);
    final max = math.max(minFirst, usable - minSecond);
    final double wanted;
    if (_byExtent) {
      final extent = widget.extent ?? usable * widget.initialRatio;
      wanted = widget.pinned == MeridianSplitPinned.first
          ? extent
          : usable - extent;
    } else {
      wanted = usable * _ratio;
    }
    return wanted.clamp(minFirst, max);
  }

  void _resize(double usable, double delta, {required bool end}) {
    if (usable <= 0) return;
    final (minFirst, minSecond) = _minimums(usable);
    final max = math.max(minFirst, usable - minSecond);
    final first = (_firstExtent(usable) + delta).clamp(minFirst, max);
    if (_byExtent) {
      final extent = widget.pinned == MeridianSplitPinned.first
          ? first
          : usable - first;
      widget.onExtentChanged?.call(extent);
      if (end) widget.onExtentChangeEnd?.call(extent);
    } else {
      final ratio = first / usable;
      if (widget.ratio == null) setState(() => _ownRatio = ratio);
      widget.onRatioChanged?.call(ratio);
      if (end) widget.onRatioChangeEnd?.call(ratio);
    }
  }

  void _endDrag(double usable) {
    _dragging = false;
    if (_byExtent) {
      final first = _firstExtent(usable);
      widget.onExtentChangeEnd?.call(
        widget.pinned == MeridianSplitPinned.first ? first : usable - first,
      );
    } else {
      widget.onRatioChangeEnd?.call(_firstExtent(usable) / usable);
    }
  }

  void _reset() {
    final reset = widget.onReset;
    if (reset != null) {
      reset();
      return;
    }
    if (!_byExtent) {
      if (widget.ratio == null) {
        setState(() => _ownRatio = widget.initialRatio);
      }
      widget.onRatioChanged?.call(widget.initialRatio);
      widget.onRatioChangeEnd?.call(widget.initialRatio);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MeridianLocalizations.of(context);
    final colors = MeridianTheme.of(context).colors;
    final horizontal = widget.axis == Axis.horizontal;
    final rtl = horizontal && Directionality.of(context) == TextDirection.rtl;
    final label = widget.semanticLabel ?? l10n.splitPaneResize;
    return LayoutBuilder(
      builder: (context, constraints) {
        final extent = horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;
        assert(
          extent.isFinite,
          'A MeridianSplitPane needs a bounded ${horizontal ? 'width' : 'height'}.',
        );
        final usable = math.max(0.0, extent - widget.thickness);
        final first = _firstExtent(usable);
        final share = usable <= 0 ? 0 : (first / usable * 100).round();
        final step = widget.keyboardStep;
        int shareAfter(double delta) {
          if (usable <= 0) return 0;
          final (minFirst, minSecond) = _minimums(usable);
          final max = math.max(minFirst, usable - minSecond);
          return ((first + delta).clamp(minFirst, max) / usable * 100).round();
        }

        Widget handle = MeridianResizeHandle(
          key: widget.handleKey,
          semanticLabel: label,
          // The handle's axis is the direction it moves.
          direction: horizontal ? Axis.horizontal : Axis.vertical,
          thickness: widget.thickness,
          keyboardStep: step,
          onDragStart: () => _dragging = true,
          onDragEnd: () => _endDrag(usable),
          onDrag: (delta) =>
              _resize(usable, rtl ? -delta : delta, end: !_dragging),
          onReset: _reset,
        );
        if (!widget.focusable) handle = ExcludeFocus(child: handle);
        if (widget.divider) {
          handle = Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Center(
                  child: horizontal
                      ? SizedBox(
                          width: MeridianLayout.hairline,
                          height: double.infinity,
                          child: ColoredBox(color: colors.line),
                        )
                      : SizedBox(
                          height: MeridianLayout.hairline,
                          width: double.infinity,
                          child: ColoredBox(color: colors.line),
                        ),
                ),
              ),
              handle,
            ],
          );
        }
        handle = Semantics(
          label: label,
          slider: true,
          value: l10n.percent(share),
          increasedValue: l10n.percent(shareAfter(step)),
          decreasedValue: l10n.percent(shareAfter(-step)),
          onIncrease: () => _resize(usable, step, end: true),
          onDecrease: () => _resize(usable, -step, end: true),
          child: ExcludeSemantics(
            child: SizedBox(
              width: horizontal ? widget.thickness : double.infinity,
              height: horizontal ? double.infinity : widget.thickness,
              child: handle,
            ),
          ),
        );
        final children = [
          SizedBox(
            width: horizontal ? first : null,
            height: horizontal ? null : first,
            child: widget.first,
          ),
          handle,
          Expanded(child: widget.second),
        ];
        return horizontal
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              );
      },
    );
  }
}
