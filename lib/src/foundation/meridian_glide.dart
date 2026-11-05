import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'meridian_theme.dart';
import 'meridian_tokens.g.dart';

// ---------------------------------------------------------------- glide

/// Paints one indicator (a rounded fill, rule or tile) under a set of items
/// and springs it to the selected item's rect (`spring-snappy`): the
/// segmented tile, the tab rule (MM-14, MM-26).
///
/// The first placement and layout changes (resize, font load, an item
/// opening) move the indicator without animation, unless a selection change
/// is in flight. Reduce motion jumps. With [MeridianReveal] this is the only
/// widget that animates size (the indicator only).
class MeridianGlide extends StatefulWidget {
  /// Lays [itemCount] items out along [axis] and glides [indicator] to the
  /// item at [selectedIndex].
  MeridianGlide({
    super.key,
    required int? selectedIndex,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    required this.indicator,
    Axis axis = Axis.horizontal,
    this.spring,
    double spacing = 0,
  }) : selection = selectedIndex,
       foreground = false,
       child = Builder(
         builder: (context) => Flex(
           direction: axis,
           mainAxisSize: MainAxisSize.min,
           spacing: spacing,
           children: [
             for (var i = 0; i < itemCount; i++)
               MeridianGlideTarget(
                 selected: i == selectedIndex,
                 child: itemBuilder(context, i),
               ),
           ],
         ),
       );

  /// Glides [indicator] to the [MeridianGlideTarget] in [child] that is
  /// `selected`. Use it when the items need their own layout (flexible
  /// segments, a scrolling tab strip). [selection] identifies the selected
  /// item; a change of it glides, anything else only moves the indicator.
  const MeridianGlide.custom({
    super.key,
    required this.selection,
    required Widget this.child,
    required this.indicator,
    this.spring,
    this.foreground = false,
  });

  /// The selected index or value.
  final Object? selection;
  final Widget indicator;

  /// Default `spring-snappy`.
  final SpringDescription? spring;
  final Widget? child;

  /// A travelling mark instead of a resting indicator (a check moving
  /// between rows, MM-25): the indicator is painted over the items and only
  /// while it travels, and the selected target hides its own child until
  /// it lands.
  final bool foreground;

  @override
  State<MeridianGlide> createState() => _MeridianGlideState();
}

/// Marks one item of a [MeridianGlide.custom]; the indicator sits on the
/// item that is [selected].
class MeridianGlideTarget extends StatelessWidget {
  const MeridianGlideTarget({
    super.key,
    required this.selected,
    required Widget this.child,
  }) : builder = null;

  /// Builds the item with the ink it needs where the indicator is:
  /// `onIndicator` is true while the indicator covers most of this item,
  /// so a row whose text inverts on the fill (light on an accent highlight)
  /// changes ink with the gliding fill rather than with the selection.
  const MeridianGlideTarget.builder({
    super.key,
    required this.selected,
    required Widget Function(BuildContext context, bool onIndicator)
    this.builder,
  }) : child = null;

  final bool selected;
  final Widget? child;
  final Widget Function(BuildContext context, bool onIndicator)? builder;

  @override
  Widget build(BuildContext context) => switch (builder) {
    null => _GlideTargetBox(selected: selected, child: child),
    final builder => _InkedGlideTarget(selected: selected, builder: builder),
  };
}

class _GlideTargetBox extends SingleChildRenderObjectWidget {
  const _GlideTargetBox({
    required this.selected,
    this.onCovered,
    required super.child,
  });

  final bool selected;
  final ValueChanged<bool>? onCovered;

  @override
  RenderProxyBox createRenderObject(BuildContext context) =>
      _RenderGlideTarget(_GlideScope.of(context), selected)
        ..onCovered = onCovered;

  @override
  void updateRenderObject(BuildContext context, RenderProxyBox renderObject) {
    (renderObject as _RenderGlideTarget)
      ..flight = _GlideScope.of(context)
      ..selected = selected
      ..onCovered = onCovered;
  }
}

class _InkedGlideTarget extends StatefulWidget {
  const _InkedGlideTarget({required this.selected, required this.builder});

  final bool selected;
  final Widget Function(BuildContext context, bool onIndicator) builder;

  @override
  State<_InkedGlideTarget> createState() => _InkedGlideTargetState();
}

class _InkedGlideTargetState extends State<_InkedGlideTarget> {
  /// Whether the indicator covered this item at the glide's last layout.
  late bool _covered = widget.selected;

  void _setCovered(bool value) {
    if (mounted && value != _covered) setState(() => _covered = value);
  }

  @override
  Widget build(BuildContext context) {
    // At rest, and when the indicator jumps, it sits on the selected item.
    // While it glides, the glide's layout tells which item it covers.
    final gliding = _GlideScope.of(context)?.gliding ?? false;
    return _GlideTargetBox(
      selected: widget.selected,
      onCovered: _setCovered,
      child: widget.builder(context, gliding ? _covered : widget.selected),
    );
  }
}

class _RenderGlideTarget extends RenderProxyBox {
  _RenderGlideTarget(this._flight, this._selected);

  _GlideFlight? _flight;
  set flight(_GlideFlight? value) {
    if (value == _flight) return;
    _release();
    if (attached) {
      _flight?.removeListener(markNeedsPaint);
      _flight?.inked.remove(this);
    }
    _flight = value;
    if (attached) {
      _flight?.addListener(markNeedsPaint);
      _registerInk();
    }
    _claim();
  }

  /// Told after a frame whether the indicator covers this item.
  ValueChanged<bool>? _onCovered;
  set onCovered(ValueChanged<bool>? value) {
    _onCovered = value;
    if (attached) _registerInk();
  }

  /// The coverage last reported to [_onCovered].
  bool? reportedCovered;

  void _registerInk() {
    final inked = _flight?.inked;
    if (inked == null) return;
    _onCovered == null ? inked.remove(this) : inked.add(this);
  }

  void reportCovered(bool value) {
    if (attached) _onCovered?.call(value);
  }

  /// A travelling mark is on its way here: its own copy waits.
  bool get _waiting {
    final flight = _flight;
    return flight != null &&
        flight.travelling &&
        flight.t < 1 &&
        identical(flight.target, this);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_waiting) return;
    super.paint(context, offset);
  }

  bool _selected;
  set selected(bool value) {
    if (value == _selected) return;
    _selected = value;
    value ? _claim() : _release();
  }

  /// This box's size after its last layout, readable by the glide.
  Size? measured;

  void _claim() {
    final flight = _flight;
    if (!_selected || !attached || flight == null) return;
    flight.target = this;
    // Another item took the selection: glide there from where the
    // indicator is now. (The previous item may already be gone.)
    final wasChangingTarget = flight.changingTarget;
    flight.changingTarget = true;
    try {
      final painted = flight.paintedTarget;
      if (painted != null && !identical(painted, this)) {
        flight.onRetarget?.call();
      }
      flight.notifyListeners();
    } finally {
      flight.changingTarget = wasChangingTarget;
    }
  }

  void _release() {
    if (identical(_flight?.target, this)) _flight?.target = null;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _flight?.addListener(markNeedsPaint);
    _registerInk();
    _claim();
  }

  @override
  void detach() {
    _release();
    _flight?.removeListener(markNeedsPaint);
    _flight?.inked.remove(this);
    super.detach();
  }

  @override
  void performLayout() {
    super.performLayout();
    if (measured == size) return;
    measured = size;
    if (_selected && _flight != null) {
      final flight = _flight!;
      final changing = flight.changingTarget;
      flight.changingTarget = true;
      try {
        flight.notifyListeners();
      } finally {
        flight.changingTarget = changing;
      }
    }
  }
}

class _GlideScope extends InheritedWidget {
  const _GlideScope({required this.flight, required super.child});

  final _GlideFlight flight;

  static _GlideFlight? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GlideScope>()?.flight;

  @override
  bool updateShouldNotify(_GlideScope oldWidget) => flight != oldWidget.flight;
}

/// The indicator's flight, shared between the state, the targets and the
/// render object.
class _GlideFlight extends ChangeNotifier {
  Rect? from;
  double t = 1;
  _RenderGlideTarget? target;
  VoidCallback? onRetarget;
  bool changingTarget = false;

  /// The glide shows a travelling mark (see [MeridianGlide.foreground]).
  bool travelling = false;

  /// The glide's [MeridianGlide.selection].
  Object? selection;

  /// Targets that want to know whether the indicator covers them.
  final Set<_RenderGlideTarget> inked = {};

  /// The indicator is on its way to a selected item.
  bool get gliding => t < 1 && from != null && selection != null;

  /// The rect the indicator was last painted at, and for which target.
  Rect? painted;
  _RenderGlideTarget? paintedTarget;

  void update(double value) {
    t = value;
    notifyListeners();
  }

  @override
  // ignore: unnecessary_overrides
  void notifyListeners() => super.notifyListeners();
}

class _MeridianGlideState extends State<MeridianGlide>
    with SingleTickerProviderStateMixin {
  late final MeridianSpringController _t = MeridianSpringController(
    vsync: this,
    value: 1,
  )..addListener(_tick);
  late final _flight = _GlideFlight()..onRetarget = _retarget;

  /// A flight started in this frame; cleared after it.
  var _started = false;

  void _tick() => _flight.update(_t.value);

  @override
  void didUpdateWidget(MeridianGlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selection != oldWidget.selection) _retarget();
  }

  /// Springs from the painted rect to the selected item. Called for a new
  /// [MeridianGlide.selection] and when another target claims the
  /// selection; both can happen in one frame, which starts one flight.
  void _retarget() {
    if (!mounted || _started) return;
    _started = true;
    SchedulerBinding.instance.addPostFrameCallback((_) => _started = false);
    final painted = _flight.painted;
    if (painted == null || MeridianMotion.reduced(context)) {
      _flight.from = null;
      _t.jumpTo(1);
      return;
    }
    // Retarget from wherever the indicator is now.
    _flight.from = painted;
    _t.jumpTo(0);
    _t.animateTo(1, spring: widget.spring ?? MeridianSprings.snappy);
  }

  @override
  void dispose() {
    _t.dispose();
    _flight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _GlideScope(
    flight: _flight
      ..travelling = widget.foreground
      ..selection = widget.selection,
    child: _GlideLayout(
      flight: _flight,
      foreground: widget.foreground,
      indicator: IgnorePointer(child: widget.indicator),
      content: widget.child!,
    ),
  );
}

enum _GlideSlot { indicator, content }

class _GlideLayout
    extends SlottedMultiChildRenderObjectWidget<_GlideSlot, RenderBox> {
  const _GlideLayout({
    required this.flight,
    required this.foreground,
    required this.indicator,
    required this.content,
  });

  final _GlideFlight flight;
  final bool foreground;
  final Widget indicator;
  final Widget content;

  @override
  Iterable<_GlideSlot> get slots => _GlideSlot.values;

  @override
  Widget? childForSlot(_GlideSlot slot) => switch (slot) {
    _GlideSlot.indicator => indicator,
    _GlideSlot.content => content,
  };

  @override
  _RenderGlide createRenderObject(BuildContext context) =>
      _RenderGlide(flight)..foreground = foreground;

  @override
  void updateRenderObject(BuildContext context, _RenderGlide renderObject) {
    renderObject
      ..flight = flight
      ..foreground = foreground;
  }
}

class _RenderGlide extends RenderBox
    with SlottedContainerRenderObjectMixin<_GlideSlot, RenderBox> {
  _RenderGlide(this._flight);

  _GlideFlight _flight;
  set flight(_GlideFlight value) {
    if (value == _flight) return;
    if (attached) {
      _flight.removeListener(_flightChanged);
      value.addListener(_flightChanged);
    }
    _flight = value;
    markNeedsLayout();
  }

  bool _layoutUpdatePending = false;

  void _flightChanged() {
    // A sliver may attach/recycle its selected target during its own layout.
    // Invalidating this ancestor at that point violates Flutter's layout lock.
    if (_flight.changingTarget &&
        SchedulerBinding.instance.schedulerPhase ==
            SchedulerPhase.persistentCallbacks) {
      if (_layoutUpdatePending) return;
      _layoutUpdatePending = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _layoutUpdatePending = false;
        if (attached) markNeedsLayout();
      });
    } else {
      markNeedsLayout();
    }
  }

  Rect? _rect;

  bool _foreground = false;
  set foreground(bool value) {
    if (value == _foreground) return;
    _foreground = value;
    markNeedsPaint();
  }

  RenderBox? get _indicator => childForSlot(_GlideSlot.indicator);
  RenderBox? get _content => childForSlot(_GlideSlot.content);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _flight.addListener(_flightChanged);
  }

  @override
  void detach() {
    _flight.removeListener(_flightChanged);
    super.detach();
  }

  @override
  Iterable<RenderBox> get children => [?_indicator, ?_content];

  Rect? _measure() => _rectOf(_flight.target);

  /// [target]'s rect in this box, from its last layout.
  Rect? _rectOf(_RenderGlideTarget? target) {
    final size = target?.measured;
    if (target == null || size == null || !target.attached) return null;
    // Walk up to this box through each parent's paint transform (layout
    // offsets, scroll positions). Transforms that scale or rotate (a
    // pressed item's scale) are left out: they read their own size, which
    // is not allowed during layout, and the indicator should not scale
    // with a press.
    final transform = Matrix4.identity();
    RenderObject node = target;
    while (node != this) {
      final parent = node.parent;
      if (parent == null) return null;
      if (parent is! RenderTransform &&
          parent is! RenderFittedBox &&
          parent is! RenderRotatedBox) {
        parent.applyPaintTransform(node, transform);
      }
      node = parent;
    }
    final offset = MatrixUtils.transformPoint(transform, Offset.zero);
    return offset & size;
  }

  @override
  void performLayout() {
    final content = _content!;
    content.layout(constraints, parentUsesSize: true);
    size = content.size;
    (content.parentData! as BoxParentData).offset = Offset.zero;
    final target = _measure();
    final from = _flight.from;
    Rect? rect;
    if (target != null) {
      rect = from != null && _flight.t < 1
          ? Rect.lerp(from, target, _flight.t)
          : target;
    }
    _rect = rect;
    _flight.painted = rect;
    if (rect != null) _flight.paintedTarget = _flight.target;
    _reportCoverage(rect);
    final indicator = _indicator!;
    if (rect == null) {
      indicator.layout(BoxConstraints.tight(Size.zero));
    } else {
      indicator.layout(
        BoxConstraints.tight(
          Size(math.max(0, rect.width), math.max(0, rect.height)),
        ),
      );
      (indicator.parentData! as BoxParentData).offset = rect.topLeft;
    }
  }

  /// Tells inked targets whether [indicator] covers most of them. They
  /// rebuild after this frame; layout cannot rebuild them.
  void _reportCoverage(Rect? indicator) {
    final changed = <(_RenderGlideTarget, bool)>[];
    for (final target in _flight.inked) {
      final rect = _rectOf(target);
      var covered = false;
      if (indicator != null && rect != null && !rect.isEmpty) {
        final overlap = indicator.intersect(rect);
        covered =
            overlap.width > 0 &&
            overlap.height > 0 &&
            overlap.width * overlap.height * 2 >= rect.width * rect.height;
      }
      if (target.reportedCovered == covered) continue;
      target.reportedCovered = covered;
      changed.add((target, covered));
    }
    if (changed.isEmpty) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      for (final (target, covered) in changed) {
        target.reportCovered(covered);
      }
    });
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _content?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _content?.getMaxIntrinsicWidth(height) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _content?.getMinIntrinsicHeight(width) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _content?.getMaxIntrinsicHeight(width) ?? 0;

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      _content?.getDistanceToActualBaseline(baseline);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _content?.getDryLayout(constraints) ?? constraints.smallest;

  @override
  void paint(PaintingContext context, Offset offset) {
    final indicator = _indicator;
    void paintIndicator() {
      if (_rect != null && indicator != null) {
        context.paintChild(
          indicator,
          offset + (indicator.parentData! as BoxParentData).offset,
        );
      }
    }

    if (!_foreground) paintIndicator();
    context.paintChild(_content!, offset);
    // A travelling mark shows only on its way.
    if (_foreground && _flight.t < 1 && _flight.from != null) {
      paintIndicator();
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final content = _content;
    if (content == null) return false;
    return result.addWithPaintOffset(
      offset: Offset.zero,
      position: position,
      hitTest: (result, transformed) =>
          content.hitTest(result, position: transformed),
    );
  }
}

// ---------------------------------------------------------------- selection

/// Tells rows under a [MeridianSelectionGlide] that the selection bar is
/// painted for them: they paint their selected fill transparent and keep
/// their selected text and icon colours.
class MeridianSelectionGlideScope extends InheritedWidget {
  const MeridianSelectionGlideScope({
    super.key,
    required this.active,
    required super.child,
  });

  final bool active;

  /// Whether a selection glide paints the selected fill here.
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<MeridianSelectionGlideScope>()
          ?.active ??
      false;

  @override
  bool updateShouldNotify(MeridianSelectionGlideScope oldWidget) =>
      active != oldWidget.active;
}

/// [MeridianGlide] for fixed-extent scrolling lists (MM-20).
///
/// Paints [indicator] in a layer under [child] (the scroll view) at
/// `padding.top + selectedIndex × itemExtent − offset`, so it scrolls with
/// the rows at every frame. A new index springs there on `spring-snappy`.
/// Jumps longer than `glide-max-rows`, or from or to a row outside the
/// viewport, place the bar at once and fade it in over `motion-quick`.
class MeridianSelectionGlide extends StatefulWidget {
  const MeridianSelectionGlide({
    super.key,
    required this.controller,
    required this.itemExtent,
    required this.selectedIndex,
    required this.child,
    required this.indicator,
    this.padding = EdgeInsets.zero,
  });

  final ScrollController controller;
  final double itemExtent;
  final int? selectedIndex;
  final Widget child;
  final Widget indicator;

  /// The list's own padding, so the bar lines up with the rows.
  final EdgeInsets padding;

  @override
  State<MeridianSelectionGlide> createState() => _MeridianSelectionGlideState();
}

class _MeridianSelectionGlideState extends State<MeridianSelectionGlide>
    with TickerProviderStateMixin {
  late final MeridianSpringController _index = MeridianSpringController(
    vsync: this,
    value: (widget.selectedIndex ?? 0).toDouble(),
  );
  late final AnimationController _fade = AnimationController(
    vsync: this,
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scrolled);
  }

  @override
  void didUpdateWidget(MeridianSelectionGlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_scrolled);
      widget.controller.addListener(_scrolled);
    }
    final from = oldWidget.selectedIndex;
    final to = widget.selectedIndex;
    if (to == null || from == to) return;
    if (from == null || MeridianMotion.reduced(context)) {
      _index.jumpTo(to.toDouble());
      _fade.value = 1;
      return;
    }
    final glide =
        (to - from).abs() <= MeridianMotionScales.glideMaxRows &&
        _visible(_index.value) &&
        _visible(to.toDouble());
    if (glide) {
      _index.animateTo(to.toDouble(), spring: MeridianSprings.snappy);
    } else {
      _index.jumpTo(to.toDouble());
      _fade
        ..value = 0
        ..animateTo(
          1,
          duration: MeridianDurations.quick,
          curve: MeridianDurations.quickCurve,
        );
    }
  }

  bool _visible(double index) {
    final controller = widget.controller;
    if (!controller.hasClients) return true;
    final position = controller.position;
    if (!position.hasViewportDimension) return true;
    final top =
        widget.padding.top + index * widget.itemExtent - position.pixels;
    return top + widget.itemExtent > 0 && top < position.viewportDimension;
  }

  void _scrolled() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scrolled);
    _index.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedIndex;
    return MeridianSelectionGlideScope(
      active: selected != null,
      child: Stack(
        children: [
          if (selected != null)
            Positioned.fill(
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_index.animation, _fade]),
                  builder: (context, child) {
                    final controller = widget.controller;
                    final offset = controller.hasClients
                        ? controller.position.pixels
                        : controller.initialScrollOffset;
                    final top =
                        widget.padding.top +
                        _index.value * widget.itemExtent -
                        offset;
                    return Stack(
                      children: [
                        Positioned(
                          left: widget.padding.left,
                          right: widget.padding.right,
                          top: top,
                          height: widget.itemExtent,
                          child: Opacity(opacity: _fade.value, child: child),
                        ),
                      ],
                    );
                  },
                  child: IgnorePointer(child: widget.indicator),
                ),
              ),
            ),
          widget.child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- lift

/// Drag feedback: `lift-scale` and `shadow-float` while [lifted], settling
/// back on `spring-gentle` when dropped (MM-28, NM-52, NM-70). Reduce motion
/// keeps the shadow and drops the scale.
class MeridianLift extends StatefulWidget {
  const MeridianLift({
    super.key,
    required this.lifted,
    required this.child,
    this.borderRadius,
  });

  final bool lifted;
  final Widget child;
  final BorderRadius? borderRadius;

  @override
  State<MeridianLift> createState() => _MeridianLiftState();
}

class _MeridianLiftState extends State<MeridianLift>
    with SingleTickerProviderStateMixin {
  late final MeridianSpringController _lift = MeridianSpringController(
    vsync: this,
  );
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.lifted) _animate();
  }

  @override
  void didUpdateWidget(MeridianLift oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lifted != oldWidget.lifted) _animate();
  }

  void _animate() => _lift.animateTo(
    widget.lifted ? 1 : 0,
    spring: MeridianSprings.gentle,
    reduced: MeridianMotion.reduced(context),
  );

  @override
  void dispose() {
    _lift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final reduced = MeridianMotion.reduced(context);
    final radius =
        widget.borderRadius ?? BorderRadius.circular(meridian.radius.sm);
    return AnimatedBuilder(
      animation: _lift.animation,
      child: widget.child,
      builder: (context, child) {
        final p = _lift.value;
        final shadow = [
          for (final s in meridian.shadows.shadowFloat)
            s.copyWith(
              color: s.color.withValues(alpha: s.color.a * p.clamp(0.0, 1.0)),
            ),
        ];
        return Transform.scale(
          scale: reduced ? 1 : 1 + (MeridianMotionScales.lift - 1) * p,
          child: DecoratedBox(
            decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow),
            child: child,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- travel

class _TravelCapture {
  _TravelCapture(this.source, this.rect, this.image, this.at);

  final State source;
  final Rect rect;
  final ui.Image image;
  final Duration at;
}

/// How long a capture waits for its destination.
const _captureLifetime = MeridianDurations.celebrate;

final Map<Object, _TravelCapture> _captures = {};
final Map<OverlayState, _MeridianTravelState> _flying = {};
final Stopwatch _travelClock = Stopwatch()..start();

/// Flies a snapshot of a widget from one global rect to its new place
/// (`spring-gentle`, about `motion-highlight`): an item moving between
/// lists or into a new home (NH-1, NH-4).
///
/// Wrap both the source and the destination. Before the state change that
/// moves the item, call [MeridianTravel.capture] with a context at or below
/// the source; the next [MeridianTravel] with the same [travelKey] that
/// builds (another instance than the source) flies in from there. Its real
/// child stays hidden, but keeps semantics and focus, until the flight
/// lands. One flight per overlay: a new one lands the previous one at once.
/// A capture older than about 500 ms is dropped. Reduce motion: no flight.
class MeridianTravel extends StatefulWidget {
  const MeridianTravel({
    super.key,
    required this.travelKey,
    required this.child,
    this.decoration,
  });

  final Object travelKey;
  final Widget child;

  /// Painted behind the flying snapshot (a raised row: `raised` fill and
  /// `shadow-float`).
  final Decoration? decoration;

  /// Records the source's rect and image for [travelKey].
  static void capture(BuildContext sourceContext, Object travelKey) {
    if (MeridianMotion.reduced(sourceContext)) return;
    final state =
        sourceContext is StatefulElement &&
            sourceContext.state is _MeridianTravelState
        ? sourceContext.state as _MeridianTravelState
        : sourceContext.findAncestorStateOfType<_MeridianTravelState>();
    if (state == null || !state.mounted) return;
    final boundary = state._boundary.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary ||
        !boundary.hasSize ||
        !boundary.attached) {
      return;
    }
    try {
      final ratio = MediaQuery.maybeDevicePixelRatioOf(sourceContext) ?? 1;
      final image = boundary.toImageSync(pixelRatio: ratio);
      final origin = boundary.localToGlobal(Offset.zero);
      _captures.remove(travelKey)?.image.dispose();
      _captures[travelKey] = _TravelCapture(
        state,
        origin & boundary.size,
        image,
        _travelClock.elapsed,
      );
    } on Object {
      // Not painted yet: no flight.
    }
  }

  /// Whether a flight is on screen (tests).
  static bool get flying => _flying.isNotEmpty;

  @override
  State<MeridianTravel> createState() => _MeridianTravelState();
}

class _MeridianTravelState extends State<MeridianTravel>
    with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey(debugLabel: 'meridian-travel');
  late final MeridianSpringController _t = MeridianSpringController(
    vsync: this,
    value: 1,
  );
  OverlayEntry? _entry;
  OverlayState? _overlay;
  _TravelCapture? _capture;
  var _hidden = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(MeridianTravel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _check();
  }

  void _check() {
    if (!_captures.containsKey(widget.travelKey)) return;
    SchedulerBinding.instance.addPostFrameCallback((_) => _consume());
  }

  void _consume() {
    if (!mounted) return;
    final capture = _captures[widget.travelKey];
    if (capture == null || identical(capture.source, this)) return;
    if (_travelClock.elapsed - capture.at > _captureLifetime) {
      _captures.remove(widget.travelKey)?.image.dispose();
      return;
    }
    final box = _boundary.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final to = box.localToGlobal(Offset.zero) & box.size;
    _captures.remove(widget.travelKey);
    if ((to.topLeft - capture.rect.topLeft).distance < 1 ||
        MeridianMotion.reduced(context)) {
      capture.image.dispose();
      return;
    }
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      capture.image.dispose();
      return;
    }
    _flying[overlay]?._land();
    _flying[overlay] = this;
    _overlay = overlay;
    _capture = capture;
    _entry = OverlayEntry(builder: _buildFlight);
    overlay.insert(_entry!);
    setState(() => _hidden = true);
    _t.jumpTo(0);
    _t.animateTo(1, spring: MeridianSprings.gentle).whenCompleteOrCancel(() {
      if (_t.value >= 0.999) _land();
    });
  }

  Widget _buildFlight(BuildContext overlayContext) {
    final capture = _capture;
    if (capture == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _t.animation,
        builder: (context, _) {
          final box = _boundary.currentContext?.findRenderObject();
          if (box is! RenderBox || !box.attached) {
            return const SizedBox.shrink();
          }
          final overlayBox = overlayContext.findRenderObject() as RenderBox?;
          final to = box.localToGlobal(Offset.zero) & box.size;
          final rect = Rect.lerp(capture.rect, to, _t.value)!;
          final local = overlayBox == null
              ? rect
              : rect.shift(-overlayBox.localToGlobal(Offset.zero));
          return Stack(
            children: [
              Positioned.fromRect(
                rect: local,
                child: DecoratedBox(
                  decoration: widget.decoration ?? const BoxDecoration(),
                  child: RawImage(
                    image: capture.image,
                    fit: BoxFit.fill,
                    width: local.width,
                    height: local.height,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _land({bool rebuild = true}) {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    _capture?.image.dispose();
    _capture = null;
    if (_overlay != null && identical(_flying[_overlay], this)) {
      _flying.remove(_overlay);
    }
    _overlay = null;
    if (rebuild && mounted && _hidden) setState(() => _hidden = false);
  }

  @override
  void dispose() {
    _land(rebuild: false);
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: _boundary,
    child: Opacity(
      opacity: _hidden ? 0 : 1,
      alwaysIncludeSemantics: true,
      child: widget.child,
    ),
  );
}
