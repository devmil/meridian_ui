import 'dart:collection';

import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'meridian_theme.dart';
import 'meridian_tokens.g.dart';

/// Motion helpers that honour the platform's reduce-motion setting
/// (design/project/guides/40-motion.md).
abstract final class MeridianMotion {
  /// [duration], or zero when animations are disabled. For movement.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;

  /// For a crossfade that replaces movement: [duration], or at most
  /// [MeridianDurations.reducedFade] (100 ms) under reduce motion.
  static Duration fade(BuildContext context, Duration duration) {
    if (!reduced(context)) return duration;
    return duration < MeridianDurations.reducedFade
        ? duration
        : MeridianDurations.reducedFade;
  }

  /// [curve], or [Curves.linear] under reduce motion.
  static Curve curve(BuildContext context, Curve curve) =>
      reduced(context) ? Curves.linear : curve;

  /// Whether movement should be replaced with a fade or nothing.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) == true;

  /// Press-in scale for the current density: `press-scale`, or
  /// `press-touch` at touch density.
  static double pressScale(BuildContext context) =>
      MeridianTheme.of(context).density.isTouch
      ? MeridianMotionScales.pressTouch
      : MeridianMotionScales.press;
}

/// The hover fill duration (MM-01): `motion-hover` into the hovered state,
/// the slower `motion-hover-out` back to rest. Zero under reduce motion.
Duration meridianHoverDuration(BuildContext context, bool hovered) =>
    MeridianMotion.of(
      context,
      hovered ? MeridianDurations.hover : MeridianDurations.hoverOut,
    );

/// Remembers one-time effects that already played, so a recycled list row
/// never replays its entrance, attention tint or travel.
final class MeridianMotionMemory {
  MeridianMotionMemory({this.capacity = 2048});

  /// How many keys are remembered; the least recently seen is forgotten
  /// first.
  final int capacity;

  final LinkedHashMap<Object, void> _seen = LinkedHashMap<Object, void>();

  static final MeridianMotionMemory _default = MeridianMotionMemory();

  /// Records [key] and returns true the first time it is seen.
  bool markSeen(Object key) {
    if (_seen.containsKey(key)) {
      // Refresh recency.
      _seen.remove(key);
      _seen[key] = null;
      return false;
    }
    _seen[key] = null;
    while (_seen.length > capacity) {
      _seen.remove(_seen.keys.first);
    }
    return true;
  }

  /// Whether [key] was recorded.
  bool hasSeen(Object key) => _seen.containsKey(key);

  /// Forgets [key], so its effect may play again.
  void forget(Object key) => _seen.remove(key);

  /// The nearest [MeridianMotionScope]'s memory, or a process-wide default.
  static MeridianMotionMemory of(BuildContext context) =>
      context
          .getInheritedWidgetOfExactType<_MeridianMotionMemoryScope>()
          ?.memory ??
      _default;
}

/// Gives its subtree its own [MeridianMotionMemory] (a test, a window, or a
/// region whose effects must not be suppressed by another region's).
class MeridianMotionScope extends StatefulWidget {
  const MeridianMotionScope({super.key, required this.child});

  final Widget child;

  @override
  State<MeridianMotionScope> createState() => _MeridianMotionScopeState();
}

class _MeridianMotionScopeState extends State<MeridianMotionScope> {
  final MeridianMotionMemory _memory = MeridianMotionMemory();

  @override
  Widget build(BuildContext context) =>
      _MeridianMotionMemoryScope(memory: _memory, child: widget.child);
}

class _MeridianMotionMemoryScope extends InheritedWidget {
  const _MeridianMotionMemoryScope({
    required this.memory,
    required super.child,
  });

  final MeridianMotionMemory memory;

  @override
  bool updateShouldNotify(_MeridianMotionMemoryScope oldWidget) =>
      memory != oldWidget.memory;
}

/// A value driven by springs and timed moves that always retargets from its
/// current value and velocity.
final class MeridianSpringController {
  MeridianSpringController({required TickerProvider vsync, double value = 0})
    : _controller = AnimationController.unbounded(vsync: vsync, value: value);

  final AnimationController _controller;

  static const Tolerance _tolerance = Tolerance(
    distance: 0.001,
    velocity: 0.01,
  );

  /// Unbounded; listen to it or pass it to an [AnimatedBuilder].
  Animation<double> get animation => _controller.view;

  double get value => _controller.value;

  /// Whether a spring or timed move is running.
  bool get isAnimating => _controller.isAnimating;

  /// The value a running move is heading to, or [value].
  double get target => _target ?? _controller.value;
  double? _target;

  /// Springs from the current value and velocity to [target]. With
  /// [reduced] it jumps.
  TickerFuture animateTo(
    double target, {
    required SpringDescription spring,
    bool reduced = false,
    double? velocity,
  }) {
    _target = target;
    if (reduced) {
      _controller.value = target;
      return TickerFuture.complete();
    }
    final run = _controller.animateWith(
      SpringSimulation(
        spring,
        _controller.value,
        target,
        velocity ?? _controller.velocity,
        tolerance: _tolerance,
      ),
    );
    // A spring stops within its tolerance; land exactly on the target.
    run.then((_) {
      if (!_disposed && _target == target && !_controller.isAnimating) {
        _controller.value = target;
      }
    });
    return run;
  }

  /// Timed move from the current value (press-in and other curve moves).
  TickerFuture animateToTimed(
    double target, {
    required Duration duration,
    required Curve curve,
  }) {
    _target = target;
    if (duration == Duration.zero) {
      _controller.value = target;
      return TickerFuture.complete();
    }
    return _controller.animateTo(target, duration: duration, curve: curve);
  }

  void jumpTo(double value) {
    _target = value;
    _controller.value = value;
  }

  void addListener(VoidCallback listener) => _controller.addListener(listener);

  void removeListener(VoidCallback listener) =>
      _controller.removeListener(listener);

  var _disposed = false;

  void dispose() {
    _disposed = true;
    _controller.dispose();
  }
}

/// Springs or tweens a `double` to [value] and builds with the current one.
///
/// The first build shows [value] without animating. A new [value] animates
/// from where the animation is now, never from the old target. Under reduce
/// motion it jumps.
class MeridianAnimatedValue extends StatefulWidget {
  const MeridianAnimatedValue({
    super.key,
    required this.value,
    required this.builder,
    this.spring,
    this.duration,
    this.curve,
    this.child,
  });

  /// The target.
  final double value;

  /// Springs to the target when set.
  final SpringDescription? spring;

  /// Otherwise a timed tween (default `motion-select`).
  final Duration? duration;

  /// The tween's curve (default the standard curve).
  final Curve? curve;

  final ValueWidgetBuilder<double> builder;
  final Widget? child;

  @override
  State<MeridianAnimatedValue> createState() => _MeridianAnimatedValueState();
}

class _MeridianAnimatedValueState extends State<MeridianAnimatedValue>
    with SingleTickerProviderStateMixin {
  late final MeridianSpringController _value = MeridianSpringController(
    vsync: this,
    value: widget.value,
  );

  @override
  void didUpdateWidget(MeridianAnimatedValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;
    final reduced = MeridianMotion.reduced(context);
    final spring = widget.spring;
    if (spring != null) {
      _value.animateTo(widget.value, spring: spring, reduced: reduced);
    } else {
      _value.animateToTimed(
        widget.value,
        duration: MeridianMotion.of(
          context,
          widget.duration ?? MeridianDurations.select,
        ),
        curve: widget.curve ?? MeridianCurves.standard,
      );
    }
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _value.animation,
    builder: (context, child) => widget.builder(context, _value.value, child),
    child: widget.child,
  );
}

/// Schedules [callback] after the current frame, unless [state] is gone.
void meridianAfterFrame(State state, VoidCallback callback) {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (state.mounted) callback();
  });
}

/// Whether the app's window has focus (MM-78). Selections drawn in solid
/// `accent` fall back to `accent-soft` while it does not, crossfading over
/// `motion-select`. [MeridianGround] installs the scope; without one the
/// window counts as focused.
abstract final class MeridianWindowFocus {
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_MeridianWindowFocusScope>()
          ?.focused ??
      true;
}

/// Follows the app lifecycle and tells [MeridianWindowFocus.of] whether the
/// window has focus: `resumed` is focused, `inactive`, `hidden` and
/// `paused` are not.
class MeridianWindowFocusScope extends StatefulWidget {
  const MeridianWindowFocusScope({super.key, required this.child});

  final Widget child;

  @override
  State<MeridianWindowFocusScope> createState() =>
      _MeridianWindowFocusScopeState();
}

class _MeridianWindowFocusScopeState extends State<MeridianWindowFocusScope> {
  late final AppLifecycleListener _listener = AppLifecycleListener(
    onStateChange: _changed,
  );
  late var _focused = _isFocused(SchedulerBinding.instance.lifecycleState);

  static bool _isFocused(AppLifecycleState? state) =>
      state == null || state == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    _listener;
  }

  void _changed(AppLifecycleState state) {
    final focused = _isFocused(state);
    if (focused != _focused && mounted) setState(() => _focused = focused);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _MeridianWindowFocusScope(focused: _focused, child: widget.child);
}

class _MeridianWindowFocusScope extends InheritedWidget {
  const _MeridianWindowFocusScope({
    required this.focused,
    required super.child,
  });

  final bool focused;

  @override
  bool updateShouldNotify(_MeridianWindowFocusScope oldWidget) =>
      focused != oldWidget.focused;
}
