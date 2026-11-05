import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'meridian_interaction.dart';
import 'meridian_layout.dart';
import 'meridian_theme.dart';
import 'meridian_tokens.g.dart';

// ---------------------------------------------------------------- press

/// Scales [child] to `press-scale` while [pressed] (60 ms, exit curve) and
/// springs it back (`spring-snappy`) on release (MM-02).
///
/// [MeridianInteraction] builds it behind `pressScale: true`. Reduce motion
/// or `enabled: false` keeps the scale at 1.
class MeridianPressScale extends StatefulWidget {
  const MeridianPressScale({
    super.key,
    required this.pressed,
    required this.child,
    this.enabled = true,
  });

  final bool pressed;
  final bool enabled;
  final Widget child;

  @override
  State<MeridianPressScale> createState() => MeridianPressScaleState();
}

/// The state of a [MeridianPressScale]; [pulse] plays a keyboard press.
class MeridianPressScaleState extends State<MeridianPressScale>
    with SingleTickerProviderStateMixin {
  late final MeridianSpringController _scale = MeridianSpringController(
    vsync: this,
    value: 1,
  );
  var _pulse = 0;

  bool get _active => widget.enabled && !MeridianMotion.reduced(context);

  @override
  void didUpdateWidget(MeridianPressScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_active) {
      _scale.jumpTo(1);
      return;
    }
    if (widget.pressed != oldWidget.pressed) {
      widget.pressed ? _pressIn() : _release();
    }
  }

  void _pressIn() {
    _scale.animateToTimed(
      MeridianMotion.pressScale(context),
      duration: MeridianDurations.press,
      curve: MeridianDurations.pressCurve,
    );
  }

  void _release() => _scale.animateTo(1, spring: MeridianSprings.snappy);

  /// A 60 ms press and release, for keyboard activation.
  void pulse() {
    if (!mounted || !_active) return;
    final run = ++_pulse;
    _scale
        .animateToTimed(
          MeridianMotion.pressScale(context),
          duration: MeridianDurations.press,
          curve: MeridianDurations.pressCurve,
        )
        .whenCompleteOrCancel(() {
          if (!mounted || run != _pulse || widget.pressed) return;
          _release();
        });
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _scale.animation,
    builder: (context, child) =>
        Transform.scale(scale: _scale.value, child: child),
    child: widget.child,
  );
}

// ---------------------------------------------------------------- swap

/// How a [MeridianSwap] brings in its new child.
enum MeridianSwapStyle {
  /// Crossfade.
  fade,

  /// The new child rises `rise` px and fades in over `motion-select`; the
  /// old one fades out over `motion-exit`, moving half as far up.
  rise,

  /// A full line: the new child comes from below for a positive
  /// `direction`, from above for a negative one (`motion-quick`).
  roll,

  /// The new child scales 0.8 → 1 and fades in over `motion-select`.
  scale,

  /// The new child slides `rise` px (default `rise-overlay`) in from the
  /// trailing edge and fades in over `motion-quick`; the old one fades out
  /// over `motion-exit` (row hover actions, MM-21).
  slide,
}

/// Crossfades between children keyed by [swapKey], with an optional rise,
/// roll or scale. Only the two most recent children are kept; the old one
/// is excluded from semantics and hit testing while it leaves.
///
/// Under reduce motion every style becomes a crossfade of at most 100 ms.
class MeridianSwap extends StatefulWidget {
  const MeridianSwap({
    super.key,
    required this.swapKey,
    required this.child,
    this.style = MeridianSwapStyle.fade,
    this.direction = 1,
    this.rise,
    this.skipIfFasterThan,
    this.alignment = AlignmentDirectional.centerStart,
    this.duration,
    this.fit = StackFit.loose,
  });

  final Object? swapKey;
  final Widget child;
  final MeridianSwapStyle style;

  /// For [MeridianSwapStyle.roll]: positive rolls up (the new child comes
  /// from below), negative rolls down.
  final int direction;

  /// For [MeridianSwapStyle.rise]: the distance, `rise-content` by default.
  final double? rise;

  /// When the key changes again within this time, swap instantly (keyboard
  /// scrubbing; MM-74 uses 150 ms).
  final Duration? skipIfFasterThan;

  final AlignmentGeometry alignment;

  /// Overrides the incoming duration of the style.
  final Duration? duration;

  /// How the children are sized: [StackFit.expand] for content that fills
  /// its parent (an island's list).
  final StackFit fit;

  @override
  State<MeridianSwap> createState() => _MeridianSwapState();
}

class _SwapEntry {
  _SwapEntry(this.key, this.child, this.controller, this.style, this.direction);

  final Object? key;
  Widget child;
  final AnimationController controller;
  final MeridianSwapStyle style;
  final int direction;
  final GlobalKey slot = GlobalKey();
  CurvedAnimation? _incomingCurve;
  CurvedAnimation? _outgoingCurve;

  CurvedAnimation curve({required bool incoming}) {
    final timing = incoming
        ? (style == MeridianSwapStyle.roll || style == MeridianSwapStyle.slide
              ? MeridianDurations.quickCurve
              : MeridianDurations.selectCurve)
        : (style == MeridianSwapStyle.roll
              ? MeridianDurations.quickCurve
              : MeridianDurations.exitCurve);
    if (incoming) {
      return _incomingCurve ??= CurvedAnimation(
        parent: controller,
        curve: timing,
        reverseCurve: timing.flipped,
      );
    }
    return _outgoingCurve ??= CurvedAnimation(
      parent: controller,
      curve: timing,
      reverseCurve: timing.flipped,
    );
  }

  void dispose() {
    _incomingCurve?.dispose();
    _outgoingCurve?.dispose();
    controller.dispose();
  }
}

class _MeridianSwapState extends State<MeridianSwap>
    with TickerProviderStateMixin {
  late _SwapEntry _current = _entry(widget.swapKey, widget.child, 1);
  _SwapEntry? _leaving;
  Duration? _lastSwap;

  _SwapEntry _entry(Object? key, Widget child, double value) => _SwapEntry(
    key,
    child,
    AnimationController(vsync: this, value: value),
    widget.style,
    widget.direction,
  );

  @override
  void didUpdateWidget(MeridianSwap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.swapKey == _current.key) {
      _current.child = widget.child;
      return;
    }
    // Frame time: it follows the test clock and `timeDilation`.
    final now = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    final skip = widget.skipIfFasterThan;
    final fast =
        skip != null &&
        _lastSwap != null &&
        now - _lastSwap! < skip * timeDilation;
    _lastSwap = now;
    _leaving?.dispose();
    _leaving = null;
    final reduced = MeridianMotion.reduced(context);
    if (fast) {
      _current.dispose();
      _current = _entry(widget.swapKey, widget.child, 1);
      return;
    }
    final outgoing = _current;
    final incoming = _entry(widget.swapKey, widget.child, 0);
    _current = incoming;
    _leaving = outgoing;
    final style = widget.style;
    final inDuration = reduced
        ? MeridianMotion.fade(context, MeridianDurations.select)
        : widget.duration ??
              (style == MeridianSwapStyle.roll ||
                      style == MeridianSwapStyle.slide
                  ? MeridianDurations.quick
                  : MeridianDurations.select);
    final outDuration = reduced
        ? MeridianMotion.fade(context, MeridianDurations.exit)
        : style == MeridianSwapStyle.roll
        ? inDuration
        : MeridianDurations.exit;
    incoming.controller.duration = inDuration;
    outgoing.controller.duration = outDuration;
    incoming.controller.forward();
    outgoing.controller.reverse().whenCompleteOrCancel(() {
      if (!mounted || _leaving != outgoing) return;
      setState(() => _leaving = null);
      outgoing.dispose();
    });
  }

  @override
  void dispose() {
    _current.dispose();
    _leaving?.dispose();
    super.dispose();
  }

  Widget _build(_SwapEntry entry, {required bool incoming}) {
    final reduced = MeridianMotion.reduced(context);
    final controller = entry.controller;
    final rise = widget.rise ?? MeridianMotionScales.riseContent;
    Widget child = KeyedSubtree(key: entry.slot, child: entry.child);
    if (!incoming) {
      child = IgnorePointer(child: ExcludeSemantics(child: child));
    }
    if (reduced || entry.style == MeridianSwapStyle.fade) {
      return FadeTransition(opacity: controller, child: child);
    }
    final t = entry.curve(incoming: incoming);
    return AnimatedBuilder(
      animation: t,
      child: child,
      builder: (context, child) {
        final v = t.value;
        switch (entry.style) {
          case MeridianSwapStyle.rise:
            final dy = incoming ? rise * (1 - v) : -rise / 2 * (1 - v);
            return Opacity(
              opacity: v.clamp(0, 1),
              child: Transform.translate(offset: Offset(0, dy), child: child),
            );
          case MeridianSwapStyle.roll:
            final sign = entry.direction >= 0 ? 1.0 : -1.0;
            final dy = incoming ? sign * (1 - v) : -sign * (1 - v);
            return Opacity(
              opacity: v.clamp(0, 1),
              child: FractionalTranslation(
                translation: Offset(0, dy),
                child: child,
              ),
            );
          case MeridianSwapStyle.slide:
            final distance = widget.rise ?? MeridianMotionScales.riseOverlay;
            final rtl = Directionality.of(context) == TextDirection.rtl;
            final dx = incoming ? distance * (1 - v) * (rtl ? -1 : 1) : 0.0;
            return Opacity(
              opacity: v.clamp(0, 1),
              child: Transform.translate(offset: Offset(dx, 0), child: child),
            );
          case MeridianSwapStyle.scale:
            return Opacity(
              opacity: v.clamp(0, 1),
              child: Transform.scale(
                scale: incoming ? 0.8 + 0.2 * v : 1,
                child: child,
              ),
            );
          case MeridianSwapStyle.fade:
            return Opacity(opacity: v.clamp(0, 1), child: child);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaving = _leaving;
    final stack = Stack(
      alignment: widget.alignment,
      fit: widget.fit,
      children: [
        if (leaving != null) _build(leaving, incoming: false),
        _build(_current, incoming: true),
      ],
    );
    return widget.style == MeridianSwapStyle.roll && leaving != null
        ? ClipRect(child: stack)
        : stack;
  }
}

// ---------------------------------------------------------------- numbers

/// A number that rolls digit by digit when its value changes (MM-70).
///
/// Unchanged characters stay still; changed ones roll up for an increase
/// and down for a decrease over `motion-quick`, each starting 12 ms after
/// the one to its right. With [popOnIncrease] the whole number pops
/// (`pop-scale` → 1 on `spring-pop`) when it grows. Semantics carry only
/// the final value. Reduce motion changes it instantly.
class MeridianRollingNumber extends StatefulWidget {
  const MeridianRollingNumber({
    super.key,
    required this.value,
    this.style,
    this.popOnIncrease = false,
    this.format,
    this.semanticsLabel,
  });

  final int value;
  final TextStyle? style;
  final bool popOnIncrease;
  final String Function(int value)? format;

  /// Replaces the value as the semantics label.
  final String? semanticsLabel;

  @override
  State<MeridianRollingNumber> createState() => _MeridianRollingNumberState();
}

/// The delay between successive digits of a [MeridianRollingNumber]:
/// 12 ms, two thirds of `motion-stagger`.
final _digitStagger = MeridianDurations.stagger * (2 / 3);

class _MeridianRollingNumberState extends State<MeridianRollingNumber>
    with TickerProviderStateMixin {
  late final AnimationController _roll = AnimationController(vsync: this);
  late final MeridianSpringController _pop = MeridianSpringController(
    vsync: this,
    value: 1,
  );
  String? _from;
  var _up = true;

  String _text(int value) => widget.format?.call(value) ?? '$value';

  @override
  void didUpdateWidget(MeridianRollingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    if (MeridianMotion.reduced(context)) {
      _from = null;
      _roll.value = 1;
      _pop.jumpTo(1);
      return;
    }
    final from = _text(oldWidget.value);
    final to = _text(widget.value);
    _up = widget.value > oldWidget.value;
    _from = from;
    final columns = math.max(from.length, to.length);
    _roll.duration = MeridianDurations.quick + _digitStagger * (columns - 1);
    _roll.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted && _roll.value == 1) setState(() => _from = null);
    });
    if (widget.popOnIncrease && _up) {
      _pop.jumpTo(MeridianMotionScales.pop);
      _pop.animateTo(1, spring: MeridianSprings.pop);
    }
  }

  @override
  void dispose() {
    _roll.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = (widget.style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: const [ui.FontFeature.tabularFigures()],
    );
    final to = _text(widget.value);
    final from = _from;
    Widget number;
    if (from == null) {
      number = Text(to, style: base, maxLines: 1, softWrap: false);
    } else {
      final columns = math.max(from.length, to.length);
      final newText = to.padLeft(columns);
      final oldText = from.padLeft(columns);
      final quick = MeridianDurations.quick.inMicroseconds;
      final total = _roll.duration!.inMicroseconds;
      number = AnimatedBuilder(
        animation: _roll,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < columns; i++)
              _digit(
                base,
                oldText[i].trim(),
                newText[i].trim(),
                ((_roll.value * total -
                            _digitStagger.inMicroseconds * (columns - 1 - i)) /
                        quick)
                    .clamp(0.0, 1.0),
              ),
          ],
        ),
      );
    }
    return Semantics(
      label: widget.semanticsLabel ?? to,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _pop.animation,
        builder: (context, child) =>
            Transform.scale(scale: _pop.value, child: child),
        child: number,
      ),
    );
  }

  Widget _digit(TextStyle style, String old, String next, double linear) {
    if (old == next) return Text(next, style: style);
    final t = MeridianDurations.quickCurve.transform(linear);
    final sign = _up ? 1.0 : -1.0;
    return ClipRect(
      child: Stack(
        children: [
          Opacity(
            opacity: t,
            child: FractionalTranslation(
              translation: Offset(0, sign * (1 - t)),
              child: Text(next, style: style),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 1 - t,
              child: FractionalTranslation(
                translation: Offset(0, -sign * t),
                child: Text(old, style: style, softWrap: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- reveal

/// Insert and remove with `motion-layout` (MM-22, MM-24, MM-65).
///
/// Insert: the size grows from 0 over `motion-layout` while the child fades
/// in over `motion-select`. Remove: the child fades out over `motion-exit`,
/// then the size collapses over `motion-layout`. While collapsed the child
/// is not built, so it takes no focus and no semantics. Reduce motion is
/// instant.
///
/// Together with [MeridianGlide] this is the only widget that animates
/// size.
class MeridianReveal extends StatefulWidget {
  const MeridianReveal({
    super.key,
    required this.visible,
    required this.child,
    this.axis = Axis.vertical,
    this.fadeOnly = false,
    this.appear = false,
    this.duration,
    this.onHidden,
    this.axisAlignment = -1,
  });

  final bool visible;
  final Widget child;
  final Axis axis;

  /// Fade without changing size.
  final bool fadeOnly;

  /// Animate in on the first build when [visible] (a row that was just
  /// inserted). Otherwise the first build shows the resting state.
  final bool appear;

  /// Overrides `motion-layout` for the size change.
  final Duration? duration;

  /// Called when a hide has finished collapsing.
  final VoidCallback? onHidden;

  /// Where the child sits while the size changes: -1 start, 1 end.
  final double axisAlignment;

  @override
  State<MeridianReveal> createState() => _MeridianRevealState();
}

class _MeridianRevealState extends State<MeridianReveal>
    with TickerProviderStateMixin {
  late final AnimationController _size = AnimationController(
    vsync: this,
    value: widget.visible && !widget.appear ? 1 : 0,
  );
  late final AnimationController _fade = AnimationController(
    vsync: this,
    value: widget.visible && !widget.appear ? 1 : 0,
  );
  var _run = 0;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (widget.visible && widget.appear) _show();
    }
  }

  @override
  void didUpdateWidget(MeridianReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      widget.visible ? _show() : _hide();
    }
  }

  void _show() {
    _run++;
    final layout = MeridianMotion.of(
      context,
      widget.duration ?? MeridianDurations.layout,
    );
    _size.animateTo(1, duration: layout, curve: MeridianDurations.layoutCurve);
    _fade.animateTo(
      1,
      duration: MeridianMotion.of(context, MeridianDurations.select),
      curve: MeridianDurations.selectCurve,
    );
  }

  Future<void> _hide() async {
    final run = ++_run;
    final layout = MeridianMotion.of(
      context,
      widget.duration ?? MeridianDurations.layout,
    );
    final exit = MeridianMotion.of(context, MeridianDurations.exit);
    await _fade
        .animateTo(0, duration: exit, curve: MeridianDurations.exitCurve)
        .orCancel
        .catchError((Object _) {});
    if (!mounted || run != _run) return;
    await _size
        .animateTo(0, duration: layout, curve: MeridianDurations.layoutCurve)
        .orCancel
        .catchError((Object _) {});
    if (!mounted || run != _run) return;
    setState(() {});
    widget.onHidden?.call();
  }

  @override
  void dispose() {
    _size.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_size, _fade]),
      child: widget.child,
      builder: (context, child) {
        final collapsed = widget.fadeOnly ? _fade.value == 0 : _size.value == 0;
        if (!widget.visible && collapsed && !_size.isAnimating) {
          return const SizedBox.shrink();
        }
        Widget content = Opacity(opacity: _fade.value, child: child);
        if (!widget.visible) {
          content = IgnorePointer(child: ExcludeSemantics(child: content));
        }
        if (widget.fadeOnly || _size.value == 1) {
          // Same structure at rest and while moving: an unclipped align.
          return ClipRect(
            clipBehavior: _size.value == 1 ? Clip.none : Clip.hardEdge,
            child: Align(
              alignment: _alignment,
              widthFactor: 1,
              heightFactor: 1,
              child: content,
            ),
          );
        }
        final factor = math.max(0.0, _size.value);
        return ClipRect(
          child: Align(
            alignment: _alignment,
            widthFactor: widget.axis == Axis.horizontal ? factor : null,
            heightFactor: widget.axis == Axis.vertical ? factor : null,
            child: content,
          ),
        );
      },
    );
  }

  AlignmentDirectional get _alignment => widget.axis == Axis.vertical
      ? AlignmentDirectional(-1, widget.axisAlignment)
      : AlignmentDirectional(widget.axisAlignment, 0);
}

/// Keeps a removed row painted while it fades and collapses
/// (`motion-exit` + `motion-layout`), then calls [onRemoved] so the app can
/// drop it (MM-22).
class MeridianRemovingRow extends StatefulWidget {
  const MeridianRemovingRow({
    super.key,
    required this.child,
    required this.onRemoved,
    this.axis = Axis.vertical,
    this.delay = Duration.zero,
  });

  final Widget child;
  final VoidCallback onRemoved;
  final Axis axis;

  /// Wait before starting the removal; useful for a short bottom-up batch.
  final Duration delay;

  @override
  State<MeridianRemovingRow> createState() => _MeridianRemovingRowState();
}

class _MeridianRemovingRowState extends State<MeridianRemovingRow> {
  var _visible = true;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.delay == Duration.zero || MeridianMotion.reduced(context)) {
        setState(() => _visible = false);
      } else {
        _delayTimer = Timer(widget.delay, () {
          if (mounted) setState(() => _visible = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MeridianReveal(
    visible: _visible,
    axis: widget.axis,
    onHidden: widget.onRemoved,
    child: widget.child,
  );
}

// ---------------------------------------------------------------- entrance

/// A one-time fade and rise (`rise-content`, `motion-select`) when a keyed
/// item first appears (MM-24, MM-67).
///
/// [index] staggers the start by `motion-stagger`, at most
/// `stagger-max` − 1 steps. Keys are remembered in [MeridianMotionMemory], so
/// a recycled list row shows its child at rest. Reduce motion: no entrance.
class MeridianEntrance extends StatefulWidget {
  const MeridianEntrance({
    super.key,
    required this.entranceKey,
    required this.child,
    this.index = 0,
    this.rise,
    this.delay = Duration.zero,
  });

  final Object entranceKey;
  final Widget child;
  final int index;
  final double? rise;
  final Duration delay;

  @override
  State<MeridianEntrance> createState() => _MeridianEntranceState();
}

class _MeridianEntranceState extends State<MeridianEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1,
  );
  Animation<double> _t = kAlwaysCompleteAnimation;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final first = MeridianMotionMemory.of(context).markSeen(widget.entranceKey);
    if (!first || MeridianMotion.reduced(context)) return;
    final stagger =
        MeridianDurations.stagger *
        math.min(widget.index, MeridianMotionScales.staggerMax - 1);
    final wait = widget.delay + stagger;
    final total = wait + MeridianDurations.select;
    _controller.duration = total;
    _t = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        wait.inMicroseconds / total.inMicroseconds,
        1,
        curve: MeridianDurations.selectCurve,
      ),
    );
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rise = widget.rise ?? MeridianMotionScales.riseContent;
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, rise * (1 - _t.value)),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- stroke

/// Paints the first [progress] share of [path]'s length, contour by contour
/// in order, with round caps and joins like Lucide.
class MeridianStrokePainter extends CustomPainter {
  MeridianStrokePainter({
    required this.path,
    required this.color,
    required this.progress,
    this.strokeWidth = 2,
  });

  final Path Function(Size size) path;
  final Color color;
  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final full = path(size);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (progress >= 1) {
      canvas.drawPath(full, paint);
      return;
    }
    final metrics = full.computeMetrics().toList();
    final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var remaining = total * progress;
    for (final metric in metrics) {
      if (remaining <= 0) break;
      final length = math.min(remaining, metric.length);
      canvas.drawPath(metric.extractPath(0, length), paint);
      remaining -= length;
    }
  }

  @override
  bool shouldRepaint(MeridianStrokePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.path != path;
}

/// Draws [path] progressively: check marks, strike-throughs, rings.
class MeridianStroke extends StatelessWidget {
  const MeridianStroke({
    super.key,
    required this.path,
    required this.color,
    required this.progress,
    this.strokeWidth = 2,
    this.size,
  });

  final Path Function(Size size) path;
  final Color color;
  final double progress;
  final double strokeWidth;
  final Size? size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: size ?? Size.zero,
    painter: MeridianStrokePainter(
      path: path,
      color: color,
      progress: progress,
      strokeWidth: strokeWidth,
    ),
  );
}

/// The icons [MeridianStrokeIcon] can draw: Lucide 1.37.0 geometry on its
/// 24 × 24 grid, copied from `assets/icons/<name>.svg`.
final Map<String, Path Function()> _strokeIcons = {
  'check': () => Path()
    ..moveTo(20, 6)
    ..lineTo(9, 17)
    ..relativeLineTo(-5, -5),
  'x': () => Path()
    ..moveTo(18, 6)
    ..lineTo(6, 18)
    ..moveTo(6, 6)
    ..relativeLineTo(12, 12),
  'minus': () => Path()
    ..moveTo(5, 12)
    ..relativeLineTo(14, 0),
  'circle-check': () => Path()
    ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 10))
    ..moveTo(16, 9)
    ..relativeLineTo(-5.5, 5.5)
    ..lineTo(8, 12),
};

/// The names [MeridianStrokeIcon] can draw.
Iterable<String> get meridianStrokeIconNames => _strokeIcons.keys;

/// The 24 × 24 Lucide path of a stroke icon, scaled to [size].
Path meridianStrokeIconPath(String icon, Size size) {
  final build = _strokeIcons[icon];
  if (build == null) {
    throw ArgumentError.value(icon, 'icon', 'not a stroke icon');
  }
  final scale = size.shortestSide / 24;
  return build().transform(Matrix4.diagonal3Values(scale, scale, 1).storage);
}

/// Draws an icon's strokes progressively (MM-04, MM-11, NM-62).
///
/// When [drawn] turns true the strokes draw over [duration] (default
/// `motion-quick`) after [delay]; when it turns false they erase over
/// `motion-exit`. [appear] draws on the first build. Reduce motion shows the
/// full icon at once.
class MeridianStrokeIcon extends StatefulWidget {
  const MeridianStrokeIcon(
    this.icon, {
    super.key,
    this.drawn = true,
    this.duration,
    this.delay = Duration.zero,
    this.color,
    this.size,
    this.appear = false,
  });

  final String icon;
  final bool drawn;
  final Duration? duration;
  final Duration delay;
  final Color? color;
  final double? size;
  final bool appear;

  @override
  State<MeridianStrokeIcon> createState() => _MeridianStrokeIconState();
}

class _MeridianStrokeIconState extends State<MeridianStrokeIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    value: widget.drawn && !widget.appear ? 1 : 0,
  );
  var _started = false;

  @override
  void initState() {
    super.initState();
    assert(
      _strokeIcons.containsKey(widget.icon),
      'Unknown stroke icon "${widget.icon}"; use one of '
      '${_strokeIcons.keys.join(', ')}.',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.drawn && widget.appear) _draw();
  }

  @override
  void didUpdateWidget(MeridianStrokeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.drawn != oldWidget.drawn) {
      widget.drawn ? _draw() : _erase();
    }
  }

  void _draw() {
    if (MeridianMotion.reduced(context)) {
      _progress.value = 1;
      return;
    }
    final draw = widget.duration ?? MeridianDurations.quick;
    final total = widget.delay + draw;
    // The delay is the start of one run, so nothing is left pending when
    // the icon goes away.
    _progress.animateTo(
      1,
      duration: total,
      curve: Interval(
        widget.delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: MeridianDurations.quickCurve,
      ),
    );
  }

  void _erase() {
    _progress.animateTo(
      0,
      duration: MeridianMotion.of(context, MeridianDurations.exit),
      curve: MeridianDurations.exitCurve,
    );
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final size = widget.size ?? meridian.density.iconSize;
    final color =
        widget.color ?? IconTheme.of(context).color ?? meridian.colors.ink;
    return SizedBox.square(
      dimension: size,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) => CustomPaint(
          painter: MeridianStrokePainter(
            path: (s) => meridianStrokeIconPath(widget.icon, s),
            color: color,
            progress: _progress.value,
            strokeWidth: 2 * size / 24,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- shake

/// How far a [MeridianShake] moves.
enum MeridianShakeStrength {
  /// `shake-field`: 3 px over 240 ms (MM-09).
  field,

  /// `shake-surface`: 4 px over 280 ms (MM-47).
  surface,
}

/// Shakes [child] horizontally once each time [trigger] increases:
/// 0, −a, a, −a, a, −a, 0, linear between the points. Reduce motion: none.
class MeridianShake extends StatefulWidget {
  const MeridianShake({
    super.key,
    required this.trigger,
    required this.child,
    this.strength = MeridianShakeStrength.field,
  });

  final int trigger;
  final Widget child;
  final MeridianShakeStrength strength;

  @override
  State<MeridianShake> createState() => _MeridianShakeState();
}

class _MeridianShakeState extends State<MeridianShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1,
  );

  @override
  void didUpdateWidget(MeridianShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger > oldWidget.trigger &&
        !MeridianMotion.reduced(context)) {
      _controller.duration = widget.strength == MeridianShakeStrength.field
          ? MeridianDurations.shakeField
          : MeridianDurations.shakeSurface;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The offset at [t] (0–1) for amplitude [a].
  static double offsetAt(double t, double a) {
    const points = [0.0, -1.0, 1.0, -1.0, 1.0, -1.0, 0.0];
    final segments = points.length - 1;
    final x = (t.clamp(0.0, 1.0)) * segments;
    final i = math.min(x.floor(), segments - 1);
    final f = x - i;
    return a * (points[i] + (points[i + 1] - points[i]) * f);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.strength == MeridianShakeStrength.field
        ? MeridianMotionScales.shakeField
        : MeridianMotionScales.shakeSurface;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(offsetAt(_controller.value, a), 0),
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------- pulse

/// A halo behind [child] that grows to `pulse-scale` × [size] while it
/// fades from [startOpacity] to 0, looping every `motion-pulse` while
/// [active] (MM-69). Loops pause while tickers are muted (`TickerMode`).
///
/// With [once] it plays one loop each time [active] becomes true. With
/// [spread] it is a ring around the child instead of a disc: its edge grows
/// from the child's edge to [spread] px outside it (NH-5's Continue halo).
///
/// Reduce motion: a static disc at `pulse-scale` × with
/// `MeridianOpacity.staticHalo`, or nothing for [once] and rings.
class MeridianPulse extends StatefulWidget {
  const MeridianPulse({
    super.key,
    required this.active,
    required this.color,
    this.size = 0,
    this.child,
    this.once = false,
    this.spread,
    this.borderRadius = BorderRadius.zero,
    this.startOpacity = MeridianOpacity.pulseStart,
  });

  final bool active;
  final Color color;

  /// The disc's diameter at rest.
  final double size;
  final Widget? child;
  final bool once;
  final double? spread;
  final BorderRadius borderRadius;
  final double startOpacity;

  @override
  State<MeridianPulse> createState() => _MeridianPulseState();
}

class _MeridianPulseState extends State<MeridianPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MeridianDurations.pulse,
  );
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (widget.active) _start();
    }
  }

  @override
  void didUpdateWidget(MeridianPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _start();
    } else if (!widget.active && oldWidget.active && !widget.once) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  void _start() {
    if (MeridianMotion.reduced(context)) return;
    if (widget.once) {
      _controller.forward(from: 0);
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MeridianMotion.reduced(context);
    final ring = widget.spread != null;
    Widget halo;
    if (reduced) {
      halo = widget.active && !widget.once && !ring
          ? _disc(MeridianMotionScales.pulseScale, MeridianOpacity.staticHalo)
          : const SizedBox.shrink();
    } else {
      halo = AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final running = _controller.isAnimating || _controller.value > 0;
          if (!running || _controller.value >= 1) {
            return const SizedBox.shrink();
          }
          final t = MeridianDurations.pulseCurve.transform(_controller.value);
          final opacity = widget.startOpacity * (1 - t);
          if (ring) {
            final grow = widget.spread! * t;
            return Positioned(
              left: -grow,
              top: -grow,
              right: -grow,
              bottom: -grow,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: widget.borderRadius.add(
                      BorderRadius.circular(grow),
                    ),
                    border: Border.all(
                      color: widget.color.withValues(
                        alpha: widget.color.a * opacity,
                      ),
                      width: math.max(MeridianLayout.hairline, grow),
                    ),
                  ),
                ),
              ),
            );
          }
          return _disc(1 + (MeridianMotionScales.pulseScale - 1) * t, opacity);
        },
      );
    }
    final child = widget.child;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [if (!ring) halo, ?child, if (ring) halo],
    );
  }

  Widget _disc(double scale, double opacity) => IgnorePointer(
    child: Transform.scale(
      scale: scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: widget.color.a * opacity),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------- attention

/// Tints its child `accent-soft` and fades it back over `motion-attention`
/// (exit-soft) each time [trigger] increases (MM-23).
///
/// With [memoryKey], a trigger plays only once per `(memoryKey, trigger)` in
/// [MeridianMotionMemory]: a recycled list row does not replay it, and a
/// row first built with an unseen positive trigger plays it. Reduce motion
/// holds the tint 300 ms and removes it.
class MeridianAttention extends StatefulWidget {
  const MeridianAttention({
    super.key,
    required this.trigger,
    required this.child,
    this.borderRadius,
    this.delay = Duration.zero,
    this.memoryKey,
    this.color,
  });

  final int trigger;
  final Widget child;
  final BorderRadius? borderRadius;
  final Duration delay;
  final Object? memoryKey;

  /// The tint; `accent-soft` by default.
  final Color? color;

  @override
  State<MeridianAttention> createState() => MeridianAttentionState();
}

/// The reduce-motion hold of a [MeridianAttention].
const _reducedAttentionHold = MeridianDurations.highlight;

/// The state of a [MeridianAttention]. [progress] is the tint's strength
/// (1 full, 0 gone).
class MeridianAttentionState extends State<MeridianAttention>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1,
  );
  var _started = false;
  var _reduced = false;

  /// The tint's current strength, 0 (none) to 1 (full `accent-soft`).
  double get progress {
    if (!_controller.isAnimating && _controller.value >= 1) return 0;
    final total = _controller.duration?.inMicroseconds ?? 0;
    if (total == 0) return 0;
    final elapsed = _controller.value * total;
    final delay = widget.delay.inMicroseconds;
    if (elapsed < delay) return 0;
    if (_reduced) return 1;
    final t = (elapsed - delay) / (total - delay);
    return 1 - MeridianDurations.attentionCurve.transform(t.clamp(0.0, 1.0));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.memoryKey != null && widget.trigger > 0) {
      _maybePlay();
    }
  }

  @override
  void didUpdateWidget(MeridianAttention oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger > oldWidget.trigger) _maybePlay();
  }

  void _maybePlay() {
    final key = widget.memoryKey;
    if (key != null &&
        !MeridianMotionMemory.of(context).markSeen((key, widget.trigger))) {
      return;
    }
    _reduced = MeridianMotion.reduced(context);
    _controller.duration =
        widget.delay +
        (_reduced ? _reducedAttentionHold : MeridianDurations.attention);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = widget.color ?? MeridianTheme.of(context).colors.accentSoft;
    final radius =
        widget.borderRadius ??
        BorderRadius.circular(MeridianTheme.of(context).radius.sm);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final strength = progress;
        return DecoratedBox(
          // No fill at rest, so the tint never shows under the child's own.
          decoration: BoxDecoration(
            color: strength <= 0
                ? null
                : Color.lerp(meridianClear(tint), tint, strength),
            borderRadius: radius,
          ),
          child: child,
        );
      },
    );
  }
}

// ---------------------------------------------------------------- resize

/// Follows its child's size over `motion-layout` (a button whose label or
/// icon slot changes, MM-03). The first layout and reduce motion take the
/// new size at once. Built on the same size animation as [MeridianReveal].
class MeridianResize extends StatefulWidget {
  const MeridianResize({
    super.key,
    required this.child,
    this.alignment = AlignmentDirectional.centerStart,
    this.duration,
  });

  final Widget child;
  final AlignmentGeometry alignment;

  /// Overrides `motion-layout`.
  final Duration? duration;

  @override
  State<MeridianResize> createState() => _MeridianResizeState();
}

class _MeridianResizeState extends State<MeridianResize> {
  // Reduced motion swaps the layout wrapper without replacing the child's
  // controller, focus, or state. Only one branch mounts this key at a time.
  final _childKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final duration = MeridianMotion.of(
      context,
      widget.duration ?? MeridianDurations.layout,
    );
    final child = KeyedSubtree(key: _childKey, child: widget.child);
    // AnimatedSize with zero duration can dirty itself inside performLayout.
    // Immediate geometry needs no controller or scheduled layout frames.
    if (duration == Duration.zero) return child;
    return AnimatedSize(
      duration: duration,
      curve: MeridianDurations.layoutCurve,
      alignment: widget.alignment,
      child: child,
    );
  }
}

// ---------------------------------------------------------------- nudge

/// The direction a toolbar icon nudges when activated (MM-07).
enum MeridianNudge { none, up, down, left, right, rotate }

/// Nudges [child] once each time [trigger] increases: `nudge` px in
/// [direction] over `motion-nudge`, then springs back (`spring-snappy`);
/// [MeridianNudge.rotate] turns it once on `spring-snappy`. Never delays
/// the command. Reduce motion: none.
class MeridianNudgeIcon extends StatefulWidget {
  const MeridianNudgeIcon({
    super.key,
    required this.trigger,
    required this.direction,
    required this.child,
  });

  final int trigger;
  final MeridianNudge direction;
  final Widget child;

  @override
  State<MeridianNudgeIcon> createState() => _MeridianNudgeIconState();
}

class _MeridianNudgeIconState extends State<MeridianNudgeIcon>
    with SingleTickerProviderStateMixin {
  late final MeridianSpringController _value = MeridianSpringController(
    vsync: this,
  );
  var _run = 0;

  @override
  void didUpdateWidget(MeridianNudgeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger > oldWidget.trigger) _play();
  }

  Future<void> _play() async {
    if (widget.direction == MeridianNudge.none ||
        MeridianMotion.reduced(context)) {
      return;
    }
    final run = ++_run;
    if (widget.direction == MeridianNudge.rotate) {
      // One full turn from wherever it is now, ending at rest (a whole turn).
      final target = _value.target.roundToDouble() + 1;
      _value.animateTo(target, spring: MeridianSprings.snappy);
      return;
    }
    await _value
        .animateToTimed(
          1,
          duration: MeridianDurations.nudge,
          curve: MeridianDurations.nudgeCurve,
        )
        .orCancel
        .catchError((Object _) {});
    if (!mounted || run != _run) return;
    _value.animateTo(0, spring: MeridianSprings.snappy);
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _value.animation,
    child: widget.child,
    builder: (context, child) {
      final v = _value.value;
      const n = MeridianMotionScales.nudge;
      return switch (widget.direction) {
        MeridianNudge.none => child!,
        MeridianNudge.rotate => Transform.rotate(
          angle: v * 2 * math.pi,
          child: child,
        ),
        MeridianNudge.up => Transform.translate(
          offset: Offset(0, -n * v),
          child: child,
        ),
        MeridianNudge.down => Transform.translate(
          offset: Offset(0, n * v),
          child: child,
        ),
        MeridianNudge.left => Transform.translate(
          offset: Offset(-n * v, 0),
          child: child,
        ),
        MeridianNudge.right => Transform.translate(
          offset: Offset(n * v, 0),
          child: child,
        ),
      };
    },
  );
}

/// Rotates [child] to [turns] over `motion-quick` (MM-05 chevrons).
class MeridianTurns extends StatelessWidget {
  const MeridianTurns({super.key, required this.turns, required this.child});

  final double turns;
  final Widget child;

  @override
  Widget build(BuildContext context) => MeridianAnimatedValue(
    value: turns,
    duration: MeridianDurations.quick,
    curve: MeridianDurations.quickCurve,
    child: child,
    builder: (context, t, child) =>
        Transform.rotate(angle: t * 2 * math.pi, child: child),
  );
}
