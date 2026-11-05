import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../foundation/meridian_icons.g.dart';
import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_localizations.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';

/// One step of a [MeridianSteps] line.
@immutable
class MeridianStep {
  const MeridianStep({required this.label, this.key});

  /// The step's name: one or two words ("Pick", "Review").
  final String label;

  /// Identifies the step's marker, for tests and for an app that tracks
  /// its steps by key.
  final Key? key;
}

/// Where a step stands relative to [MeridianSteps.current].
enum _StepState { done, current, upcoming }

/// A compact line of named steps: which are done, which is current and
/// which are still to come ("Pick → Review → Resolve → Continue").
///
/// Each step is a small marker and its label, joined by a short hairline.
/// Done steps show a `success` check and a muted label; the current step a
/// filled `accent` marker with its number and a `body-strong` label;
/// upcoming steps an outlined marker with their number and a muted label.
///
/// When the line is narrower than every label needs, the labels of all but
/// the current step hide (their markers stay) and the current label
/// ellipsizes; past the markers themselves the line clips. Every step keeps
/// its label, state and position ("2 of 4") for assistive technology.
/// Steps are not interactive.
class MeridianSteps extends StatelessWidget {
  const MeridianSteps({
    super.key,
    required this.steps,
    required this.current,
    this.semanticLabel,
  }) : assert(current >= 0);

  /// The steps in order; at least one.
  final List<MeridianStep> steps;

  /// The active step's index. Steps before it are done, steps after it are
  /// upcoming; `steps.length` marks every step done.
  final int current;

  /// Names the whole line for assistive technology ("Resolve conflicts").
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    assert(steps.isNotEmpty, 'MeridianSteps needs at least one step.');
    assert(
      current <= steps.length,
      'current must be at most steps.length (all done).',
    );
    final strings = MeridianLocalizations.of(context);
    final total = steps.length;
    final children = <Widget>[];
    for (var i = 0; i < total; i++) {
      final step = steps[i];
      final state = i < current
          ? _StepState.done
          : i == current
          ? _StepState.current
          : _StepState.upcoming;
      final stateName = switch (state) {
        _StepState.done => strings.stepDone,
        _StepState.current => strings.stepCurrent,
        _StepState.upcoming => strings.stepUpcoming,
      };
      children
        ..add(
          KeyedSubtree(
            key: step.key,
            child: Semantics(
              container: true,
              label:
                  '${step.label}, $stateName, '
                  '${strings.stepPosition(i + 1, total)}',
              child: ExcludeSemantics(
                child: _StepMarker(number: i + 1, state: state),
              ),
            ),
          ),
        )
        ..add(
          ExcludeSemantics(
            child: _StepLabel(label: step.label, state: state),
          ),
        );
    }
    for (var i = 0; i < total - 1; i++) {
      children.add(const _StepConnector());
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: _StepsLayout(
        stepCount: total,
        current: current,
        children: children,
      ),
    );
  }
}

class _StepMarker extends StatelessWidget {
  const _StepMarker({required this.number, required this.state});

  final int number;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final touch = meridian.density.isTouch;
    final extent = touch
        ? MeridianLayout.stepMarkerTouch
        : MeridianLayout.stepMarker;
    // An upcoming marker is an outline only: no fill.
    final (Color? fill, Color edge, Color ink) = switch (state) {
      _StepState.done => (colors.successBg, colors.successBg, colors.success),
      _StepState.current => (colors.accent, colors.accent, colors.onAccent),
      _StepState.upcoming => (null, colors.lineStrong, colors.inkMuted),
    };
    final Widget content = state == _StepState.done
        ? MeridianIcon(
            MeridianIcons.check,
            extent: touch
                ? MeridianLayout.stepCheckIconTouch
                : MeridianLayout.stepCheckIcon,
            color: ink,
          )
        : Text(
            '$number',
            maxLines: 1,
            style: TextStyle(
              fontFamily: meridian.brand.fonts.sans,
              fontSize: MeridianLayout.countFontSize,
              height: MeridianLayout.countLineHeight,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: ink,
            ),
          );
    return Container(
      // Minimums, not a fixed size: large text grows the marker.
      constraints: BoxConstraints(minWidth: extent, minHeight: extent),
      padding: const EdgeInsets.symmetric(
        horizontal: MeridianLayout.stepMarkerPaddingX,
      ),
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: edge, width: MeridianLayout.hairline),
        borderRadius: BorderRadius.circular(MeridianRadiusScale.pill),
      ),
      child: Center(widthFactor: 1, heightFactor: 1, child: content),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.label, required this.state});

  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final style = state == _StepState.current
        ? meridian.text.bodyStrong.copyWith(color: meridian.colors.ink)
        : meridian.text.body.copyWith(color: meridian.colors.inkMuted);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: MeridianSpace.space2),
      child: Text(
        label,
        style: style,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: MeridianSpace.space3),
    child: SizedBox(
      width: MeridianLayout.stepConnectorLength,
      height: MeridianLayout.hairline,
      child: ColoredBox(color: MeridianTheme.of(context).colors.lineStrong),
    ),
  );
}

/// Lays out `marker, label` per step, then the connectors, as one row: all
/// labels when they fit, otherwise only the current label (ellipsized).
class _StepsLayout extends MultiChildRenderObjectWidget {
  const _StepsLayout({
    required this.stepCount,
    required this.current,
    required super.children,
  });

  final int stepCount;
  final int current;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSteps(
    stepCount: stepCount,
    current: current,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, _RenderSteps renderObject) {
    renderObject
      ..stepCount = stepCount
      ..current = current
      ..textDirection = Directionality.of(context);
  }
}

class _StepsParentData extends ContainerBoxParentData<RenderBox> {
  bool shown = true;
}

class _RenderSteps extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _StepsParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _StepsParentData> {
  _RenderSteps({
    required int stepCount,
    required int current,
    required TextDirection textDirection,
  }) : _stepCount = stepCount,
       _current = current,
       _textDirection = textDirection;

  int _stepCount;
  set stepCount(int value) {
    if (value == _stepCount) return;
    _stepCount = value;
    markNeedsLayout();
  }

  int _current;
  set current(int value) {
    if (value == _current) return;
    _current = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// Wider than the row even with every label but the current one hidden.
  var _overflows = false;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _StepsParentData) {
      child.parentData = _StepsParentData();
    }
  }

  RenderBox _marker(List<RenderBox> all, int i) => all[2 * i];
  RenderBox _label(List<RenderBox> all, int i) => all[2 * i + 1];
  RenderBox _connector(List<RenderBox> all, int i) => all[2 * _stepCount + i];

  /// The children in reading order, with each step's label after its
  /// marker.
  Iterable<RenderBox> _ordered(List<RenderBox> all) sync* {
    for (var i = 0; i < _stepCount; i++) {
      yield _marker(all, i);
      yield _label(all, i);
      if (i < _stepCount - 1) yield _connector(all, i);
    }
  }

  bool get _valid => childCount == 3 * _stepCount - 1 && _stepCount > 0;

  /// Markers and connectors: what the line needs without any label.
  double _fixedWidth(List<RenderBox> all, double height) {
    var width = 0.0;
    for (var i = 0; i < _stepCount; i++) {
      width += _marker(all, i).getMaxIntrinsicWidth(height);
      if (i < _stepCount - 1) {
        width += _connector(all, i).getMaxIntrinsicWidth(height);
      }
    }
    return width;
  }

  double _labelsWidth(List<RenderBox> all, double height) {
    var width = 0.0;
    for (var i = 0; i < _stepCount; i++) {
      width += _label(all, i).getMaxIntrinsicWidth(height);
    }
    return width;
  }

  /// The width each label may take: its natural width when every label
  /// fits, otherwise only the current label with the space that is left.
  /// A hidden label gets `null`.
  List<double?> _plan(List<RenderBox> all, double maxWidth) {
    const height = double.infinity;
    final fixed = _fixedWidth(all, height);
    final labels = _labelsWidth(all, height);
    if (fixed + labels <= maxWidth) {
      return [
        for (var i = 0; i < _stepCount; i++)
          _label(all, i).getMaxIntrinsicWidth(height),
      ];
    }
    return [
      for (var i = 0; i < _stepCount; i++)
        if (i == _current)
          math.min(
            _label(all, i).getMaxIntrinsicWidth(height),
            math.max(0.0, maxWidth - fixed),
          )
        else
          null,
    ];
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _valid ? _fixedWidth(getChildrenAsList(), height) : 0;

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (!_valid) return 0;
    final all = getChildrenAsList();
    return _fixedWidth(all, height) + _labelsWidth(all, height);
  }

  @override
  double computeMinIntrinsicHeight(double width) => getChildrenAsList().fold(
    0.0,
    (height, child) =>
        math.max(height, child.getMinIntrinsicHeight(double.infinity)),
  );

  @override
  double computeMaxIntrinsicHeight(double width) => getChildrenAsList().fold(
    0.0,
    (height, child) =>
        math.max(height, child.getMaxIntrinsicHeight(double.infinity)),
  );

  BoxConstraints _constraintsFor(
    RenderBox child,
    List<RenderBox> all,
    List<double?> plan,
    double height,
  ) {
    for (var i = 0; i < _stepCount; i++) {
      if (identical(child, _label(all, i))) {
        final width = plan[i];
        return width == null
            ? BoxConstraints.tight(Size.zero)
            : BoxConstraints(maxWidth: width, maxHeight: height);
      }
    }
    return BoxConstraints(maxHeight: height);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    if (!_valid) return constraints.smallest;
    final all = getChildrenAsList();
    final plan = _plan(all, constraints.maxWidth);
    var width = 0.0;
    var height = 0.0;
    for (final child in _ordered(all)) {
      final size = child.getDryLayout(
        _constraintsFor(child, all, plan, constraints.maxHeight),
      );
      width += size.width;
      height = math.max(height, size.height);
    }
    return constraints.constrain(Size(width, height));
  }

  @override
  void performLayout() {
    if (!_valid) {
      size = constraints.smallest;
      return;
    }
    final all = getChildrenAsList();
    final plan = _plan(all, constraints.maxWidth);
    var width = 0.0;
    var height = 0.0;
    for (final child in _ordered(all)) {
      child.layout(
        _constraintsFor(child, all, plan, constraints.maxHeight),
        parentUsesSize: true,
      );
      width += child.size.width;
      height = math.max(height, child.size.height);
    }
    size = constraints.constrain(Size(width, height));
    _overflows = width > size.width;
    final rtl = _textDirection == TextDirection.rtl;
    var x = 0.0;
    for (var i = 0; i < _stepCount; i++) {
      (_label(all, i).parentData! as _StepsParentData).shown = plan[i] != null;
    }
    for (final child in _ordered(all)) {
      final data = child.parentData! as _StepsParentData;
      final dx = rtl ? size.width - x - child.size.width : x;
      data.offset = Offset(dx, (size.height - child.size.height) / 2);
      x += child.size.width;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_overflows) {
      _clip.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        _paintChildren,
        oldLayer: _clip.layer,
      );
    } else {
      _clip.layer = null;
      _paintChildren(context, offset);
    }
  }

  final _clip = LayerHandle<ClipRectLayer>();

  void _paintChildren(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as _StepsParentData;
      if (data.shown) context.paintChild(child, data.offset + offset);
      child = data.nextSibling;
    }
  }

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      false;

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as _StepsParentData;
      if (data.shown) visitor(child);
      child = data.nextSibling;
    }
  }
}
