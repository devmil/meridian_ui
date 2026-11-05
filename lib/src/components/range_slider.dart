import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';

/// The ordered endpoints of a range, independent of Material's slider types.
@immutable
class MeridianRangeValues {
  const MeridianRangeValues(this.start, this.end) : assert(start <= end);

  final double start;
  final double end;

  @override
  bool operator ==(Object other) =>
      other is MeridianRangeValues && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Two independently focusable and accessible handles selecting an interval.
/// Endpoints never cross. Consumers own the values and their announcement.
class MeridianRangeSlider extends StatefulWidget {
  const MeridianRangeSlider({
    required this.startLabel,
    required this.endLabel,
    required this.values,
    required this.onChanged,
    super.key,
    this.min = 0,
    this.max = 1,
    this.step,
    this.valueLabel,
    this.onChangeEnd,
  }) : assert(min <= max),
       assert(step == null || step > 0);

  final String startLabel;
  final String endLabel;
  final MeridianRangeValues values;
  final ValueChanged<MeridianRangeValues>? onChanged;
  final ValueChanged<MeridianRangeValues>? onChangeEnd;
  final double min;
  final double max;
  final double? step;
  final String Function(double value)? valueLabel;

  @override
  State<MeridianRangeSlider> createState() => _MeridianRangeSliderState();
}

class _MeridianRangeSliderState extends State<MeridianRangeSlider> {
  final _focus = [FocusNode(), FocusNode()];
  final _visible = [false, false];
  final _hovered = [false, false];
  var _selected = 0;
  var _active = false;
  var _pointerFocused = false;
  MeridianRangeValues? _last;

  bool get _enabled => widget.onChanged != null && widget.max > widget.min;
  double get _span => widget.max - widget.min;
  double get _step => widget.step ?? _span / 20;
  MeridianRangeValues get _values => MeridianRangeValues(
    widget.values.start.clamp(widget.min, widget.max),
    widget.values.end.clamp(widget.min, widget.max),
  );

  @override
  void didUpdateWidget(covariant MeridianRangeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _active = false;
      _last = null;
      _hovered.fillRange(0, 2, false);
    }
  }

  @override
  void dispose() {
    for (final focus in _focus) {
      focus.dispose();
    }
    super.dispose();
  }

  double _snap(double value) {
    var next = value.clamp(widget.min, widget.max);
    if (widget.step case final step?) {
      next = (widget.min + ((next - widget.min) / step).round() * step).clamp(
        widget.min,
        widget.max,
      );
    }
    return next;
  }

  MeridianRangeValues _next(int index, double value) {
    final values = _values;
    return index == 0
        ? MeridianRangeValues(
            _snap(value).clamp(widget.min, values.end),
            values.end,
          )
        : MeridianRangeValues(
            values.start,
            _snap(value).clamp(values.start, widget.max),
          );
  }

  void _set(int index, double value, {bool commit = false}) {
    if (!_enabled) return;
    final next = _next(index, value);
    _last = next;
    widget.onChanged?.call(next);
    if (commit) widget.onChangeEnd?.call(next);
  }

  String _announce(double value) =>
      widget.valueLabel?.call(value) ??
      '${(_span <= 0 ? 0 : (value - widget.min) / _span * 100).round()}%';

  double _value(int index) => index == 0 ? _values.start : _values.end;

  void _begin(double value) {
    final startDistance = (value - _values.start).abs();
    final endDistance = (value - _values.end).abs();
    // Keep the most recently focused handle when endpoints coincide.
    if (startDistance != endDistance) {
      _selected = startDistance < endDistance ? 0 : 1;
    }
    _last = null;
    _pointerFocused = true;
    _focus[_selected].requestFocus();
    setState(() {
      _active = true;
      _visible.fillRange(0, 2, false);
    });
  }

  void _end({bool commit = true}) {
    final last = _last;
    setState(() => _active = false);
    _last = null;
    if (_enabled && commit && last != null) widget.onChangeEnd?.call(last);
  }

  KeyEventResult _key(int index, KeyEvent event) {
    if (!_enabled || (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    _pointerFocused = false;
    setState(() => _visible[index] = true);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final forward = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final back = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    if (key == forward || key == LogicalKeyboardKey.arrowUp) {
      _set(index, _value(index) + _step, commit: true);
    } else if (key == back || key == LogicalKeyboardKey.arrowDown) {
      _set(index, _value(index) - _step, commit: true);
    } else if (key == LogicalKeyboardKey.home) {
      _set(index, index == 0 ? widget.min : _values.start, commit: true);
    } else if (key == LogicalKeyboardKey.end) {
      _set(index, index == 0 ? _values.end : widget.max, commit: true);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.meridian;
    final colors = theme.colors;
    final thumb = theme.density.isTouch
        ? MeridianLayout.sliderThumbTouch
        : MeridianLayout.sliderThumb;
    final height = math.max(
      theme.density.controlExtent,
      theme.density.minTarget,
    );
    final rtl = Directionality.of(context) == TextDirection.rtl;
    const pill = BorderRadius.all(Radius.circular(MeridianRadiusScale.pill));
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MeridianLayout.sliderDefaultWidth;
        final travel = math.max(0.0, width - thumb);
        double fraction(double value) =>
            _span <= 0 ? 0 : ((value - widget.min) / _span).clamp(0.0, 1.0);
        double position(double value) =>
            travel * (rtl ? 1 - fraction(value) : fraction(value));
        double valueAt(double dx) {
          if (travel <= 0) return widget.min;
          final part = ((dx - thumb / 2) / travel).clamp(0.0, 1.0);
          return widget.min + (rtl ? 1 - part : part) * _span;
        }

        final a = position(_values.start) + thumb / 2;
        final b = position(_values.end) + thumb / 2;
        Widget handle(int index) {
          final value = _value(index);
          final raised =
              _enabled && (_hovered[index] || (_active && _selected == index));
          final hitWidth = math.min(
            width,
            math.max(thumb, theme.density.minTarget),
          );
          final hitLeft = (position(value) + thumb / 2 - hitWidth / 2)
              .clamp(0.0, math.max(0.0, width - hitWidth))
              .toDouble();
          return Positioned(
            left: hitLeft,
            child: Semantics(
              container: true,
              label: index == 0 ? widget.startLabel : widget.endLabel,
              slider: true,
              enabled: _enabled,
              value: _announce(value),
              increasedValue: _announce(
                index == 0
                    ? _next(index, value + _step).start
                    : _next(index, value + _step).end,
              ),
              decreasedValue: _announce(
                index == 0
                    ? _next(index, value - _step).start
                    : _next(index, value - _step).end,
              ),
              onIncrease: _enabled
                  ? () => _set(index, value + _step, commit: true)
                  : null,
              onDecrease: _enabled
                  ? () => _set(index, value - _step, commit: true)
                  : null,
              child: Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onKeyEvent: (_, event) => _key(index, event),
                child: FocusableActionDetector(
                  focusNode: _focus[index],
                  enabled: _enabled,
                  onFocusChange: (focused) {
                    if (focused) _selected = index;
                  },
                  onShowFocusHighlight: (visible) => setState(
                    () => _visible[index] = visible && !_pointerFocused,
                  ),
                  onShowHoverHighlight: (hovered) =>
                      setState(() => _hovered[index] = hovered),
                  child: SizedBox(
                    width: hitWidth,
                    height: height,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Positioned(
                          left: position(value) - hitLeft,
                          child: CustomPaint(
                            foregroundPainter: MeridianFocusRingPainter(
                              visible: _enabled && _visible[index],
                              color: colors.focus,
                              radius: pill,
                            ),
                            child: MeridianAnimatedValue(
                              value: raised && !MeridianMotion.reduced(context)
                                  ? MeridianLayout.sliderThumbActiveScale
                                  : 1,
                              duration: MeridianDurations.quick,
                              curve: MeridianDurations.quickCurve,
                              builder: (context, scale, child) =>
                                  Transform.scale(scale: scale, child: child),
                              child: Container(
                                width: thumb,
                                height: thumb,
                                decoration: BoxDecoration(
                                  color:
                                      _enabled && _active && _selected == index
                                      ? meridianPressed(colors.pane, colors.ink)
                                      : colors.pane,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _enabled
                                        ? colors.accent
                                        : colors.inkFaint,
                                    width: raised
                                        ? MeridianLayout.sliderThumbBorderActive
                                        : MeridianLayout.sliderThumbBorder,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return MouseRegion(
          cursor: _enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragDown: _enabled
                ? (d) => _begin(valueAt(d.localPosition.dx))
                : null,
            onHorizontalDragUpdate: _enabled
                ? (d) => _set(_selected, valueAt(d.localPosition.dx))
                : null,
            onHorizontalDragEnd: _enabled ? (_) => _end() : null,
            onHorizontalDragCancel: _enabled ? () => _end(commit: false) : null,
            onTapUp: _enabled
                ? (d) {
                    _set(_selected, valueAt(d.localPosition.dx));
                    _end();
                  }
                : null,
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: thumb / 2,
                    right: thumb / 2,
                    child: Container(
                      height: MeridianLayout.sliderTrack,
                      decoration: BoxDecoration(
                        color: colors.lineStrong,
                        borderRadius: pill,
                      ),
                    ),
                  ),
                  Positioned(
                    left: math.min(a, b),
                    width: (b - a).abs(),
                    child: Container(
                      height: MeridianLayout.sliderTrack,
                      decoration: BoxDecoration(
                        color: _enabled ? colors.accent : colors.inkFaint,
                        borderRadius: pill,
                      ),
                    ),
                  ),
                  // Focus traversal and semantic order remain start, then end.
                  handle(0), handle(1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
