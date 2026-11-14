import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

/// [child] in a Meridian host with reduce motion on or off.
Widget motionHost(Widget child, {bool reduced = false}) => host(
  Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
      child: child,
    ),
  ),
);

/// Pumps [total] in 16 ms frames, so tickers started along the way run.
Future<void> pumpFrames(WidgetTester tester, Duration total) async {
  var left = total;
  const frame = Duration(milliseconds: 16);
  while (left > Duration.zero) {
    final step = left < frame ? left : frame;
    await tester.pump(step);
    left -= step;
  }
}

void main() {
  for (final duration in [null, Duration.zero]) {
    testWidgets(
      'resize snaps at zero motion without losing focused child, override=$duration',
      (tester) async {
        var reduced = duration == null, width = 120.0;
        final focus = FocusNode();
        final controller = TextEditingController(text: 'Owned text');
        late StateSetter rebuild;
        try {
          await tester.pumpWidget(
            host(
              StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  return MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(disableAnimations: reduced),
                    child: Center(
                      child: MeridianResize(
                        duration: duration,
                        child: SizedBox(
                          key: const ValueKey('resize.child'),
                          width: width,
                          child: MeridianTextField(
                            controller: controller,
                            focusNode: focus,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
          focus.requestFocus();
          await tester.pumpAndSettle();
          final input = tester.state(find.byType(EditableText));
          rebuild(() => width = 280);
          await tester.pump();
          expect(tester.getSize(find.byType(MeridianResize)).width, 280);
          expect(tester.takeException(), isNull);
          expect(tester.state(find.byType(EditableText)), same(input));
          expect(focus.hasFocus, true);
          await tester.pumpAndSettle();
          expect(tester.binding.hasScheduledFrame, false);
          rebuild(() => reduced = false);
          await tester.pumpAndSettle();
          expect(tester.state(find.byType(EditableText)), same(input));
          expect(focus.hasFocus, true);
          rebuild(() {
            reduced = true;
            width = 200;
          });
          await tester.pump();
          expect(tester.getSize(find.byType(MeridianResize)).width, 200);
          expect(tester.state(find.byType(EditableText)), same(input));
          expect(focus.hasFocus, true);
          expect(controller.text, 'Owned text');
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          focus.dispose();
          controller.dispose();
        }
      },
    );
  }

  testWidgets('select value rises without replacing its control', (
    tester,
  ) async {
    var value = 'Pick';
    late StateSetter rebuild;
    await tester.pumpWidget(
      motionHost(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return MeridianSelect<String>(
              value: value,
              values: const ['Pick', 'Squash'],
              valueLabel: (choice) => choice,
              animateValue: true,
              onChanged: (_) {},
            );
          },
        ),
      ),
    );
    final select = tester.state(find.byType(MeridianSelect<String>));
    rebuild(() => value = 'Squash');
    await tester.pump();
    expect(tester.state(find.byType(MeridianSelect<String>)), same(select));
    expect(
      tester.widget<MeridianSwap>(find.byType(MeridianSwap)).swapKey,
      'Squash',
    );
    await pumpFrames(tester, MeridianDurations.select);
    expect(find.text('Squash'), findsOneWidget);
  });

  testWidgets('button action label swaps while its semantics update', (
    tester,
  ) async {
    var label = 'Commit';
    late StateSetter rebuild;
    await tester.pumpWidget(
      motionHost(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return Center(
              child: MeridianButton(
                label: label,
                animateLabel: true,
                onPressed: () {},
              ),
            );
          },
        ),
      ),
    );
    final before = tester.getSize(find.byType(MeridianButton));
    rebuild(() => label = 'Amend commit');
    await tester.pump();
    expect(find.byType(MeridianSwap), findsOneWidget);
    expect(
      tester.widget<MeridianSwap>(find.byType(MeridianSwap)).swapKey,
      'Amend commit',
    );
    await pumpFrames(tester, MeridianDurations.layout);
    expect(
      tester.getSize(find.byType(MeridianButton)).width,
      greaterThan(before.width),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Amend commit',
      ),
      findsOneWidget,
    );
  });

  testWidgets('programmatic clear fades old text without moving focus', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Previous subject');
    final focus = FocusNode();
    var sequence = 0;
    late StateSetter rebuild;
    await tester.pumpWidget(
      motionHost(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return MeridianTextField(
              controller: controller,
              focusNode: focus,
              programmaticClearSequence: sequence,
            );
          },
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    controller.clear();
    rebuild(() => sequence++);
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(find.text('Previous subject'), findsOneWidget);
    expect(focus.hasFocus, isTrue);
    await tester.pump(MeridianDurations.quick);
    final fade = find.ancestor(
      of: find.text('Previous subject'),
      matching: find.byType(FadeTransition),
    );
    expect(
      tester
          .widgetList<FadeTransition>(fade)
          .any((item) => item.opacity.value == 0),
      isTrue,
    );
    expect(focus.hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    focus.dispose();
  });

  group('foundation', () {
    testWidgets('fade and curve follow reduce motion', (tester) async {
      late BuildContext normal;
      late BuildContext reduced;
      await tester.pumpWidget(
        motionHost(
          Column(
            children: [
              Builder(
                builder: (context) {
                  normal = context;
                  return const SizedBox();
                },
              ),
              MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: Builder(
                  builder: (context) {
                    reduced = context;
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      );
      expect(
        MeridianMotion.fade(normal, MeridianDurations.dialog),
        MeridianDurations.dialog,
      );
      expect(
        MeridianMotion.fade(reduced, MeridianDurations.dialog),
        MeridianDurations.reducedFade,
      );
      expect(
        MeridianMotion.fade(reduced, MeridianDurations.press),
        MeridianDurations.press,
      );
      expect(
        MeridianMotion.of(reduced, MeridianDurations.dialog),
        Duration.zero,
      );
      expect(
        MeridianMotion.curve(normal, MeridianCurves.standard),
        MeridianCurves.standard,
      );
      expect(
        MeridianMotion.curve(reduced, MeridianCurves.standard),
        Curves.linear,
      );
      expect(meridianHoverDuration(normal, true), MeridianDurations.hover);
      expect(meridianHoverDuration(normal, false), MeridianDurations.hoverOut);
      expect(meridianHoverDuration(reduced, false), Duration.zero);
    });

    testWidgets('press scale follows the density', (tester) async {
      late BuildContext desktop;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              desktop = context;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(MeridianMotion.pressScale(desktop), MeridianMotionScales.press);
      late BuildContext touch;
      await tester.pumpWidget(
        host(
          density: MeridianDensity.touch,
          Builder(
            builder: (context) {
              touch = context;
              return const SizedBox();
            },
          ),
        ),
      );
      // The theme change animates; density switches at its midpoint.
      await tester.pump(const Duration(seconds: 1));
      expect(MeridianMotion.pressScale(touch), MeridianMotionScales.pressTouch);
    });

    test('memory marks a key once and evicts the oldest', () {
      final memory = MeridianMotionMemory(capacity: 2);
      expect(memory.markSeen('a'), isTrue);
      expect(memory.markSeen('a'), isFalse);
      expect(memory.markSeen('b'), isTrue);
      expect(memory.markSeen('c'), isTrue);
      expect(memory.hasSeen('a'), isFalse);
      expect(memory.hasSeen('b'), isTrue);
      memory.forget('b');
      expect(memory.markSeen('b'), isTrue);
    });

    testWidgets('memory has a default and a scope', (tester) async {
      late MeridianMotionMemory outside;
      late MeridianMotionMemory inside;
      await tester.pumpWidget(
        host(
          Column(
            children: [
              Builder(
                builder: (context) {
                  outside = MeridianMotionMemory.of(context);
                  return const SizedBox();
                },
              ),
              MeridianMotionScope(
                child: Builder(
                  builder: (context) {
                    inside = MeridianMotionMemory.of(context);
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      );
      expect(outside, isNotNull);
      expect(identical(outside, inside), isFalse);
    });

    testWidgets('a retargeted spring keeps a continuous value', (tester) async {
      late MeridianSpringController spring;
      await tester.pumpWidget(
        host(
          _Vsync(
            onReady: (vsync) => spring = MeridianSpringController(vsync: vsync),
          ),
        ),
      );
      spring.animateTo(1, spring: MeridianSprings.snappy);
      var last = spring.value;
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect((spring.value - last).abs(), lessThan(0.2));
        last = spring.value;
      }
      final before = spring.value;
      spring.animateTo(0, spring: MeridianSprings.snappy);
      await tester.pump(const Duration(milliseconds: 1));
      expect((spring.value - before).abs(), lessThan(0.05));
      await tester.pump(const Duration(milliseconds: 600));
      expect(spring.value, closeTo(0, 0.01));
      spring.animateTo(1, spring: MeridianSprings.snappy, reduced: true);
      expect(spring.value, 1);
      spring.dispose();
    });

    testWidgets('an animated value starts at rest and retargets from where '
        'it is', (tester) async {
      Widget build(double value) => host(
        MeridianAnimatedValue(
          value: value,
          duration: MeridianDurations.select,
          builder: (context, v, _) => Text('${(v * 100).round()}'),
        ),
      );
      await tester.pumpWidget(build(0));
      expect(find.text('0'), findsOneWidget);
      await tester.pumpWidget(build(1));
      await tester.pump(const Duration(milliseconds: 60));
      final mid = int.parse(tester.widget<Text>(find.byType(Text)).data!);
      expect(mid, inExclusiveRange(0, 100));
      await tester.pumpWidget(build(0));
      await tester.pump(const Duration(milliseconds: 1));
      final after = int.parse(tester.widget<Text>(find.byType(Text)).data!);
      expect((after - mid).abs(), lessThanOrEqualTo(3));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('an animated value jumps under reduce motion', (tester) async {
      Widget build(double value) => motionHost(
        reduced: true,
        MeridianAnimatedValue(
          value: value,
          spring: MeridianSprings.snappy,
          builder: (context, v, _) => Text('${(v * 100).round()}'),
        ),
      );
      await tester.pumpWidget(build(0));
      await tester.pumpWidget(build(1));
      await tester.pump();
      expect(find.text('100'), findsOneWidget);
    });
  });

  group('helpers', () {
    double scaleOf(WidgetTester tester, Finder finder) {
      final transform = tester.widget<Transform>(
        find.descendant(of: finder, matching: find.byType(Transform)).first,
      );
      return transform.transform.storage[0];
    }

    testWidgets('MM-02 press scale presses in and springs back', (
      tester,
    ) async {
      Widget build(bool pressed) =>
          host(MeridianPressScale(pressed: pressed, child: const Text('Push')));
      await tester.pumpWidget(build(false));
      await tester.pumpWidget(build(true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      final mid = scaleOf(tester, find.byType(MeridianPressScale));
      expect(mid, inExclusiveRange(0.97, 1));
      await tester.pump(const Duration(milliseconds: 40));
      expect(
        scaleOf(tester, find.byType(MeridianPressScale)),
        closeTo(0.97, 0.001),
      );
      await tester.pumpWidget(build(false));
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        scaleOf(tester, find.byType(MeridianPressScale)),
        closeTo(1, 0.01),
      );
    });

    testWidgets('MM-02 press scale stays at 1 under reduce motion', (
      tester,
    ) async {
      Widget build(bool pressed) => motionHost(
        reduced: true,
        MeridianPressScale(pressed: pressed, child: const Text('Push')),
      );
      await tester.pumpWidget(build(false));
      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(milliseconds: 60));
      expect(scaleOf(tester, find.byType(MeridianPressScale)), 1);
    });

    testWidgets('swap rises the new child and fades the old one', (
      tester,
    ) async {
      Widget build(String text) => host(
        MeridianSwap(
          swapKey: text,
          style: MeridianSwapStyle.rise,
          child: Text(text),
        ),
      );
      await tester.pumpWidget(build('a'));
      await tester.pumpWidget(build('b'));
      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 50));
      final rising = tester.widget<Transform>(
        find
            .ancestor(of: find.text('b'), matching: find.byType(Transform))
            .first,
      );
      final dy = rising.transform.getTranslation().y;
      expect(dy, inExclusiveRange(0, MeridianMotionScales.riseContent));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('a'), findsNothing);
      expect(find.text('b'), findsOneWidget);
    });

    testWidgets('swap reuses its curve across repeated row rebuilds', (
      tester,
    ) async {
      Widget build(int frame) => host(
        MeridianSwap(
          swapKey: 'stable',
          style: MeridianSwapStyle.rise,
          child: Text('frame $frame'),
        ),
      );
      await tester.pumpWidget(build(0));
      Animation<double> curve() => tester
          .widgetList<AnimatedBuilder>(
            find.descendant(
              of: find.byType(MeridianSwap),
              matching: find.byType(AnimatedBuilder),
            ),
          )
          .map((builder) => builder.animation)
          .whereType<CurvedAnimation>()
          .single;
      final original = curve();
      for (var frame = 1; frame <= 50; frame++) {
        await tester.pumpWidget(build(frame));
        expect(identical(curve(), original), isTrue);
      }
    });

    testWidgets('swap skips when keys change faster than the threshold', (
      tester,
    ) async {
      Widget build(String text) => host(
        MeridianSwap(
          swapKey: text,
          skipIfFasterThan: const Duration(milliseconds: 150),
          child: Text(text),
        ),
      );
      await tester.pumpWidget(build('a'));
      await tester.pumpWidget(build('b'));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpWidget(build('c'));
      expect(find.text('b'), findsNothing);
      expect(find.text('a'), findsNothing);
      expect(find.text('c'), findsOneWidget);
    });

    testWidgets('swap crossfades within 100 ms under reduce motion', (
      tester,
    ) async {
      Widget build(String text) => motionHost(
        reduced: true,
        MeridianSwap(
          swapKey: text,
          style: MeridianSwapStyle.rise,
          child: Text(text),
        ),
      );
      await tester.pumpWidget(build('a'));
      await tester.pumpWidget(build('b'));
      expect(
        find.ancestor(of: find.text('b'), matching: find.byType(Transform)),
        findsNothing,
      );
      await tester.pump(const Duration(milliseconds: 101));
      expect(find.text('a'), findsNothing);
    });

    testWidgets('MM-70 rolling number from 9 to 10 rolls both characters and '
        'keeps semantics at the final value', (tester) async {
      final handle = tester.ensureSemantics();
      Widget build(int v) => host(MeridianRollingNumber(value: v));
      await tester.pumpWidget(build(9));
      await tester.pumpWidget(build(10));
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.bySemanticsLabel('10'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('10'), findsOneWidget);
      expect(find.text('9'), findsNothing);
      handle.dispose();
    });

    testWidgets('MM-70 rolling number pops on increase', (tester) async {
      Widget build(int v) =>
          host(MeridianRollingNumber(value: v, popOnIncrease: true));
      await tester.pumpWidget(build(3));
      await tester.pumpWidget(build(4));
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        scaleOf(tester, find.byType(MeridianRollingNumber)),
        greaterThan(1.05),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        scaleOf(tester, find.byType(MeridianRollingNumber)),
        closeTo(1, 0.01),
      );
    });

    testWidgets('MM-70 rolling number is instant under reduce motion', (
      tester,
    ) async {
      Widget build(int v) =>
          motionHost(reduced: true, MeridianRollingNumber(value: v));
      await tester.pumpWidget(build(3));
      await tester.pumpWidget(build(4));
      await tester.pump();
      expect(find.text('4'), findsOneWidget);
      expect(find.text('3'), findsNothing);
    });

    double heightOf(WidgetTester tester) =>
        tester.getSize(find.byType(MeridianReveal)).height;

    testWidgets('reveal grows, then fades out and collapses', (tester) async {
      Widget build(bool visible) => host(
        MeridianReveal(
          visible: visible,
          child: const SizedBox(width: 100, height: 40),
        ),
      );
      await tester.pumpWidget(build(false));
      expect(heightOf(tester), 0);
      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(milliseconds: 100));
      expect(heightOf(tester), inExclusiveRange(0, 40));
      await tester.pump(const Duration(milliseconds: 150));
      expect(heightOf(tester), 40);
      await tester.pumpWidget(build(false));
      await tester.pump(const Duration(milliseconds: 50));
      // Fading, not collapsing yet.
      expect(heightOf(tester), 40);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 100));
      expect(heightOf(tester), inExclusiveRange(0, 40));
      await tester.pump(const Duration(milliseconds: 200));
      expect(heightOf(tester), 0);
    });

    testWidgets('reveal is instant under reduce motion', (tester) async {
      Widget build(bool visible) => motionHost(
        reduced: true,
        MeridianReveal(
          visible: visible,
          child: const SizedBox(width: 100, height: 40),
        ),
      );
      await tester.pumpWidget(build(false));
      await tester.pumpWidget(build(true));
      await tester.pump();
      expect(heightOf(tester), 40);
      await tester.pumpWidget(build(false));
      await tester.pump();
      await tester.pump();
      expect(heightOf(tester), 0);
    });

    testWidgets('a removing row collapses and reports it', (tester) async {
      var removed = false;
      await tester.pumpWidget(
        host(
          MeridianRemovingRow(
            onRemoved: () => removed = true,
            child: const SizedBox(width: 100, height: 40),
          ),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(removed, isTrue);
    });

    testWidgets('removing rows can wait for their place in a batch', (
      tester,
    ) async {
      var removed = false;
      await tester.pumpWidget(
        host(
          MeridianRemovingRow(
            delay: const Duration(milliseconds: 80),
            onRemoved: () => removed = true,
            child: const SizedBox(width: 100, height: 40),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 70));
      expect(find.byType(MeridianReveal), findsOneWidget);
      expect(
        tester.widget<MeridianReveal>(find.byType(MeridianReveal)).visible,
        isTrue,
      );
      await tester.pump(const Duration(milliseconds: 10));
      expect(
        tester.widget<MeridianReveal>(find.byType(MeridianReveal)).visible,
        isFalse,
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(removed, isTrue);
    });

    testWidgets('overlay entrance is available for an inline prompt', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const MeridianOverlayEntrance(child: Text('Drop here'))),
      );
      expect(find.text('Drop here'), findsOneWidget);
      await tester.pump();
      await tester.pump(MeridianDurations.overlay);
      expect(tester.takeException(), isNull);
    });

    double opacityOf(WidgetTester tester, Finder of) => tester
        .widget<Opacity>(
          find.descendant(of: of, matching: find.byType(Opacity)).first,
        )
        .opacity;

    testWidgets('entrance plays once per key and staggers', (tester) async {
      Widget build(bool shown) => host(
        MeridianMotionScope(
          child: shown
              ? const MeridianEntrance(
                  entranceKey: 'row-1',
                  index: 2,
                  child: Text('row'),
                )
              : const SizedBox(),
        ),
      );
      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(milliseconds: 30));
      // Two stagger steps (36 ms) have not passed.
      expect(opacityOf(tester, find.byType(MeridianEntrance)), 0);
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        opacityOf(tester, find.byType(MeridianEntrance)),
        inExclusiveRange(0, 1),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacityOf(tester, find.byType(MeridianEntrance)), 1);
      // A recycled row: disposed and built again with the same key.
      await tester.pumpWidget(build(false));
      await tester.pumpWidget(build(true));
      expect(opacityOf(tester, find.byType(MeridianEntrance)), 1);
    });

    testWidgets('entrance is off under reduce motion', (tester) async {
      await tester.pumpWidget(
        motionHost(
          reduced: true,
          const MeridianMotionScope(
            child: MeridianEntrance(entranceKey: 'k', child: Text('row')),
          ),
        ),
      );
      expect(opacityOf(tester, find.byType(MeridianEntrance)), 1);
    });

    testWidgets('stroke icon draws about half the path at half progress', (
      tester,
    ) async {
      final full = meridianStrokeIconPath('check', const Size(48, 48));
      final length = full.computeMetrics().fold<double>(
        0,
        (sum, m) => sum + m.length,
      );
      Widget build(bool drawn) =>
          host(MeridianStrokeIcon('check', drawn: drawn, size: 48));
      await tester.pumpWidget(build(false));
      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(milliseconds: 50));
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(MeridianStrokeIcon),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as MeridianStrokePainter;
      expect(painter.progress, inExclusiveRange(0.2, 0.95));
      expect(length, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 60));
      final done =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(MeridianStrokeIcon),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as MeridianStrokePainter;
      expect(done.progress, 1);
    });

    testWidgets('stroke icon draws at once under reduce motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        motionHost(
          reduced: true,
          const MeridianStrokeIcon('x', appear: true, size: 24),
        ),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(MeridianStrokeIcon),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as MeridianStrokePainter;
      expect(painter.progress, 1);
      expect(meridianStrokeIconNames, containsAll(['check', 'x', 'minus']));
    });

    double dxOf(WidgetTester tester) => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(MeridianShake),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .getTranslation()
        .x;

    testWidgets('MM-09 shake moves −3 px early and rests at 0', (tester) async {
      Widget build(int trigger) =>
          host(MeridianShake(trigger: trigger, child: const Text('field')));
      await tester.pumpWidget(build(0));
      await tester.pumpWidget(build(1));
      await tester.pump(const Duration(milliseconds: 40));
      expect(dxOf(tester), closeTo(-3, 0.3));
      await tester.pump(const Duration(milliseconds: 200));
      expect(dxOf(tester), 0);
    });

    testWidgets('shake does nothing under reduce motion', (tester) async {
      Widget build(int trigger) => motionHost(
        reduced: true,
        MeridianShake(trigger: trigger, child: const Text('field')),
      );
      await tester.pumpWidget(build(0));
      await tester.pumpWidget(build(1));
      await tester.pump(const Duration(milliseconds: 40));
      expect(dxOf(tester), 0);
    });

    testWidgets('MM-69 pulse loops while active and holds under reduce '
        'motion', (tester) async {
      Widget build(bool active, {bool reduced = false}) => motionHost(
        reduced: reduced,
        MeridianPulse(
          active: active,
          color: const Color(0xFF16733A),
          size: 8,
          child: const SizedBox.square(dimension: 8),
        ),
      );
      await tester.pumpWidget(build(false));
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 1600));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pumpWidget(build(false));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(build(true, reduced: true));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.transientCallbackCount, 0);
    });

    Color? tintOf(WidgetTester tester) {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(MeridianAttention),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      return (box.decoration as BoxDecoration).color ?? const Color(0x00000000);
    }

    testWidgets('MM-23 attention tints and fades back once per trigger', (
      tester,
    ) async {
      Widget build(int trigger, {bool shown = true}) => host(
        MeridianMotionScope(
          child: shown
              ? MeridianAttention(
                  trigger: trigger,
                  memoryKey: 'row',
                  child: const SizedBox(width: 100, height: 20),
                )
              : const SizedBox(),
        ),
      );
      await tester.pumpWidget(build(0));
      final soft = colorsOf(tester).accentSoft;
      expect(tintOf(tester)!.a, 0);
      await tester.pumpWidget(build(1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(tintOf(tester)!.a, closeTo(soft.a, 0.02));
      await tester.pump(const Duration(milliseconds: 450));
      expect(tintOf(tester)!.a, inExclusiveRange(0, soft.a));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tintOf(tester)!.a, 0);
      // Scrolled out and back: the same trigger does not replay.
      await tester.pumpWidget(build(1, shown: false));
      await tester.pumpWidget(build(1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(tintOf(tester)!.a, 0);
    });

    testWidgets('MM-23 attention holds 300 ms under reduce motion', (
      tester,
    ) async {
      Widget build(int trigger) => motionHost(
        reduced: true,
        MeridianAttention(
          trigger: trigger,
          child: const SizedBox(width: 100, height: 20),
        ),
      );
      await tester.pumpWidget(build(0));
      await tester.pumpWidget(build(1));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tintOf(tester)!.a, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 150));
      expect(tintOf(tester)!.a, 0);
    });
  });

  group('glide', () {
    testWidgets(
      'selected sliver target resizes its indicator without switching',
      (tester) async {
        Widget build(double width) => host(
          SizedBox(
            width: 300,
            height: 40,
            child: MeridianGlide.custom(
              selection: 0,
              indicator: const ColoredBox(
                key: ValueKey('resize-indicator'),
                color: Color(0xFF0A62CC),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  MeridianGlideTarget(
                    selected: true,
                    child: SizedBox(width: width, height: 30),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpWidget(build(60));
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(const ValueKey('resize-indicator'))).width,
          60,
        );
        await tester.pumpWidget(build(120));
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(const ValueKey('resize-indicator'))).width,
          120,
        );
        expect(tester.takeException(), isNull);
      },
    );

    Widget glide(int selected, {bool reduced = false}) => motionHost(
      reduced: reduced,
      MeridianGlide(
        selectedIndex: selected,
        itemCount: 3,
        itemBuilder: (context, i) => const SizedBox(width: 50, height: 20),
        indicator: const ColoredBox(
          key: ValueKey('indicator'),
          color: Color(0xFF0A62CC),
        ),
      ),
    );

    testWidgets('MM-14 glide indicator springs to the new item', (
      tester,
    ) async {
      await tester.pumpWidget(glide(0));
      final start = tester.getRect(find.byKey(const ValueKey('indicator')));
      expect(start.width, 50);
      await tester.pumpWidget(glide(2));
      final lefts = <double>[];
      for (final ms in [0, 60, 60, 180]) {
        await tester.pump(Duration(milliseconds: ms));
        lefts.add(tester.getRect(find.byKey(const ValueKey('indicator'))).left);
      }
      for (var i = 1; i < lefts.length; i++) {
        expect(lefts[i], greaterThanOrEqualTo(lefts[i - 1] - 0.5));
      }
      expect(lefts[1], inExclusiveRange(start.left, start.left + 100));
      expect(lefts.last, closeTo(start.left + 100, 1));
    });

    testWidgets('glide targets inside a scrolling list are measured', (
      tester,
    ) async {
      Widget build(int selected) => host(
        SizedBox(
          width: 300,
          height: 40,
          child: MeridianGlide.custom(
            selection: selected,
            indicator: const ColoredBox(
              key: ValueKey('pill'),
              color: Color(0xFF0A62CC),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, i) => MeridianGlideTarget(
                selected: i == selected,
                child: SizedBox(width: 60, child: Text('tab $i')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(build(2));
      await tester.pump();
      expect(
        tester.getRect(find.byKey(const ValueKey('pill'))).left,
        closeTo(tester.getRect(find.text('tab 2')).left, 0.5),
      );
    });

    testWidgets(
      'glide survives selected target recycling during sliver layout',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          host(
            SizedBox(
              width: 300,
              height: 160,
              child: MeridianGlide.custom(
                selection: 0,
                indicator: const ColoredBox(
                  key: ValueKey('recycled-pill'),
                  color: Color(0xFF0A62CC),
                ),
                child: CustomScrollView(
                  controller: controller,
                  slivers: [
                    SliverFixedExtentList.builder(
                      itemExtent: 32,
                      itemCount: 4000,
                      itemBuilder: (context, i) => MeridianGlideTarget(
                        selected: i == 0,
                        child: Text('row $i'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        controller.jumpTo(30000);
        await tester.pumpAndSettle();
        expect(find.text('row 0'), findsNothing);
        controller.jumpTo(0);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.byKey(const ValueKey('recycled-pill'))),
          tester.getRect(find.text('row 0')),
        );
        // A queued geometry update must be harmless when its owner goes away.
        controller.jumpTo(30000);
        await tester.pump();
        controller.jumpTo(0);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('glide jumps under reduce motion', (tester) async {
      await tester.pumpWidget(glide(0, reduced: true));
      final start = tester.getRect(find.byKey(const ValueKey('indicator')));
      await tester.pumpWidget(glide(2, reduced: true));
      expect(
        tester.getRect(find.byKey(const ValueKey('indicator'))).left,
        start.left + 100,
      );
    });

    Widget list(ScrollController controller, int selected) => host(
      SizedBox(
        width: 200,
        height: 200,
        child: MeridianSelectionGlide(
          controller: controller,
          itemExtent: 20,
          selectedIndex: selected,
          indicator: const ColoredBox(
            key: ValueKey('bar'),
            color: Color(0xFF0A62CC),
          ),
          child: ListView.builder(
            controller: controller,
            itemExtent: 20,
            itemCount: 100,
            itemBuilder: (context, i) => Text('row $i'),
          ),
        ),
      ),
    );

    testWidgets('MM-20 a long jump does not glide', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(list(controller, 0));
      final top = tester.getRect(find.byKey(const ValueKey('bar'))).top;
      await tester.pumpWidget(list(controller, 9));
      await tester.pump();
      expect(
        tester.getRect(find.byKey(const ValueKey('bar'))).top,
        closeTo(top + 180, 0.01),
      );
    });

    testWidgets('MM-20 a short move glides', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(list(controller, 0));
      final top = tester.getRect(find.byKey(const ValueKey('bar'))).top;
      await tester.pumpWidget(list(controller, 3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(
        tester.getRect(find.byKey(const ValueKey('bar'))).top,
        inExclusiveRange(top, top + 60),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.getRect(find.byKey(const ValueKey('bar'))).top,
        closeTo(top + 60, 0.5),
      );
    });

    testWidgets('MM-20 the bar stays on its row while the list scrolls', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(list(controller, 4));
      await tester.drag(find.byType(ListView), const Offset(0, -30));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          tester.getRect(find.byKey(const ValueKey('bar'))).top,
          closeTo(tester.getRect(find.text('row 4')).top, 0.5),
        );
      }
    });

    testWidgets('MM-28 lift scales to lift-scale', (tester) async {
      Widget build(bool lifted, {bool reduced = false}) => motionHost(
        reduced: reduced,
        MeridianLift(lifted: lifted, child: const Text('tab')),
      );
      double scale() => tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byType(MeridianLift),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .storage[0];
      await tester.pumpWidget(build(false));
      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(milliseconds: 400));
      expect(scale(), closeTo(MeridianMotionScales.lift, 0.002));
      await tester.pumpWidget(build(false));
      await tester.pump(const Duration(milliseconds: 500));
      expect(scale(), closeTo(1, 0.002));
      await tester.pumpWidget(build(true, reduced: true));
      await tester.pump();
      expect(scale(), 1);
    });

    Widget lists(bool moved, {bool reduced = false}) => motionHost(
      reduced: reduced,
      Row(
        children: [
          SizedBox(
            width: 150,
            child: Column(
              children: [
                if (!moved)
                  const MeridianTravel(
                    travelKey: 'file',
                    child: SizedBox(width: 100, height: 20, child: Text('a')),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 150,
            child: Column(
              children: [
                const SizedBox(height: 60),
                if (moved)
                  const MeridianTravel(
                    travelKey: 'file',
                    child: SizedBox(width: 100, height: 20, child: Text('a')),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    testWidgets('travel flies in an overlay and lands', (tester) async {
      await tester.pumpWidget(lists(false));
      MeridianTravel.capture(tester.element(find.text('a')), 'file');
      await tester.pumpWidget(lists(true));
      await tester.pump();
      expect(MeridianTravel.flying, isTrue);
      expect(find.byType(RawImage), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(MeridianTravel.flying, isFalse);
      expect(find.byType(RawImage), findsNothing);
    });

    testWidgets('travel does not fly under reduce motion', (tester) async {
      await tester.pumpWidget(lists(false, reduced: true));
      MeridianTravel.capture(tester.element(find.text('a')), 'file');
      await tester.pumpWidget(lists(true, reduced: true));
      await tester.pump();
      expect(MeridianTravel.flying, isFalse);
    });
  });

  group('controls', () {
    /// The scale of the first [Transform] under [of].
    double scaleUnder(WidgetTester tester, Finder of) => tester
        .widget<Transform>(
          find.descendant(of: of, matching: find.byType(Transform)).first,
        )
        .transform
        .storage[0];

    Offset translationUnder(WidgetTester tester, Finder of) {
      final t = tester
          .widget<Transform>(
            find.descendant(of: of, matching: find.byType(Transform)).first,
          )
          .transform
          .getTranslation();
      return Offset(t.x, t.y);
    }

    testWidgets('MM-01 hover fills in fast and out slowly', (tester) async {
      useDesktopHighlights();
      await tester.pumpWidget(
        host(MeridianButton(label: 'Fetch', onPressed: () {})),
      );
      Duration duration() => tester
          .widget<AnimatedContainer>(
            find
                .descendant(
                  of: find.byType(MeridianButton),
                  matching: find.byType(AnimatedContainer),
                )
                .first,
          )
          .duration;
      final mouse = await hoverAt(
        tester,
        tester.getCenter(find.byType(MeridianButton)),
      );
      expect(duration(), MeridianDurations.hover);
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      expect(duration(), MeridianDurations.hoverOut);
    });

    testWidgets('MM-02 a button presses to 0.97 and springs back', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(MeridianButton(label: 'Push', onPressed: () {})),
      );
      final press = find.byType(MeridianPressScale);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(MeridianButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(scaleUnder(tester, press), closeTo(0.97, 0.002));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(scaleUnder(tester, press), closeTo(1, 0.01));
    });

    testWidgets('MM-02 touch density presses to 0.96; reduce motion does '
        'not scale', (tester) async {
      await tester.pumpWidget(
        host(
          density: MeridianDensity.touch,
          MeridianButton(label: 'Push', onPressed: () {}),
        ),
      );
      final press = find.byType(MeridianPressScale);
      var gesture = await tester.startGesture(
        tester.getCenter(find.byType(MeridianButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(scaleUnder(tester, press), closeTo(0.96, 0.002));
      await gesture.up();
      await tester.pumpWidget(
        motionHost(
          reduced: true,
          MeridianButton(label: 'Push', onPressed: () {}),
        ),
      );
      gesture = await tester.startGesture(
        tester.getCenter(find.byType(MeridianButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(scaleUnder(tester, press), 1);
      await gesture.up();
    });

    testWidgets('MM-03 the spinner waits 150 ms and the width follows', (
      tester,
    ) async {
      Widget build(bool loading) => host(
        MeridianButton(label: 'Sync', loading: loading, onPressed: () {}),
      );
      await tester.pumpWidget(build(false));
      final rest = tester.getSize(find.byType(MeridianButton)).width;
      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MeridianSpinner), findsNothing);
      expect(tester.getSize(find.byType(MeridianButton)).width, rest);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MeridianSpinner), findsOneWidget);
      final growing = tester.getSize(find.byType(MeridianButton)).width;
      expect(growing, greaterThan(rest));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.getSize(find.byType(MeridianButton)).width,
        greaterThanOrEqualTo(growing),
      );
      // Loading that ends before the delay changes nothing.
      await tester.pumpWidget(build(false));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(build(false));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(MeridianSpinner), findsNothing);
    });

    testWidgets('MM-04 success draws a check for 900 ms', (tester) async {
      Widget build(bool success) => host(
        MeridianButton(
          label: 'Push',
          icon: MeridianIcons.arrowUp,
          success: success,
          onPressed: () {},
        ),
      );
      await tester.pumpWidget(build(false));
      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MeridianStrokeIcon), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 850));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(MeridianStrokeIcon), findsNothing);
    });

    testWidgets('MM-05 an icon button turns its chevron', (tester) async {
      Widget build(double turns) => host(
        MeridianIconButton(
          label: 'Expand',
          icon: MeridianIcons.chevronRight,
          turns: turns,
          onPressed: () {},
        ),
      );
      double angle() {
        final m = tester
            .widget<Transform>(
              find
                  .descendant(
                    of: find.byType(MeridianTurns),
                    matching: find.byType(Transform),
                  )
                  .first,
            )
            .transform;
        return math.atan2(m.storage[1], m.storage[0]);
      }

      await tester.pumpWidget(build(0));
      expect(angle(), 0);
      await tester.pumpWidget(build(0.25));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(angle(), inExclusiveRange(0, math.pi / 2));
      await tester.pump(const Duration(milliseconds: 100));
      expect(angle(), closeTo(math.pi / 2, 0.001));
    });

    testWidgets('an icon button spins while spinning and finishes its turn', (
      tester,
    ) async {
      Widget build(bool spinning) => host(
        MeridianIconButton(
          label: 'Refresh',
          icon: MeridianIcons.refreshCw,
          spinning: spinning,
          onPressed: () {},
        ),
      );
      double angle() {
        final m = tester
            .widget<Transform>(
              find
                  .descendant(
                    of: find.byType(MeridianIconButton),
                    matching: find.byType(Transform),
                  )
                  .at(1),
            )
            .transform;
        return math.atan2(m.storage[1], m.storage[0]);
      }

      await tester.pumpWidget(build(false));
      await tester.pumpWidget(build(true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 175));
      expect(angle(), closeTo(math.pi / 2, 0.05));
      await tester.pumpWidget(build(false));
      await pumpFrames(tester, const Duration(milliseconds: 700));
      expect(angle().abs(), closeTo(0, 0.001));
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('an icon button badge pops in with its tone', (tester) async {
      Widget build(int? badge) => host(
        MeridianIconButton(
          label: 'Logbook',
          icon: MeridianIcons.list,
          badge: badge,
          badgeTone: MeridianCountTone.attention,
          onPressed: () {},
        ),
      );
      await tester.pumpWidget(build(null));
      expect(find.byType(MeridianCount), findsNothing);
      await tester.pumpWidget(build(1));
      await pumpFrames(tester, const Duration(milliseconds: 400));
      expect(
        tester.widget<MeridianCount>(find.byType(MeridianCount)).tone,
        MeridianCountTone.attention,
      );
      await tester.pumpWidget(build(null));
      await pumpFrames(tester, const Duration(milliseconds: 200));
      expect(find.byType(MeridianCount), findsNothing);
    });

    testWidgets('MM-06 a toolbar badge pops in, rolls and leaves', (
      tester,
    ) async {
      Widget build(int? badge) => host(
        MeridianToolbarButton(
          label: 'Logbook',
          icon: MeridianIcons.list,
          badge: badge,
          onPressed: () {},
        ),
      );
      await tester.pumpWidget(build(null));
      expect(find.byType(MeridianCount), findsNothing);
      await tester.pumpWidget(build(2));
      await tester.pump();
      final badge = find.ancestor(
        of: find.byType(MeridianCount),
        matching: find.byType(FadeTransition),
      );
      expect(scaleUnder(tester, badge), lessThan(0.2));
      await tester.pump(const Duration(milliseconds: 400));
      expect(scaleUnder(tester, badge), closeTo(1, 0.02));
      await tester.pumpWidget(build(3));
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byType(MeridianRollingNumber), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(build(null));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('3'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.byType(MeridianCount), findsNothing);
    });

    testWidgets('MM-07 the icon nudges 2 px in its direction', (tester) async {
      await tester.pumpWidget(
        host(
          MeridianToolbarButton(
            label: 'Pull',
            icon: MeridianIcons.arrowDown,
            nudge: MeridianNudge.down,
            onPressed: () {},
          ),
        ),
      );
      final icon = find.byType(MeridianNudgeIcon);
      await tester.tap(find.byType(MeridianToolbarButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      expect(translationUnder(tester, icon).dy, closeTo(2, 0.05));
      await pumpFrames(tester, const Duration(milliseconds: 400));
      expect(translationUnder(tester, icon).dy, closeTo(0, 0.05));
    });

    testWidgets('MM-07 no nudge under reduce motion', (tester) async {
      await tester.pumpWidget(
        motionHost(
          reduced: true,
          MeridianToolbarButton(
            label: 'Push',
            icon: MeridianIcons.arrowUp,
            nudge: MeridianNudge.up,
            onPressed: () {},
          ),
        ),
      );
      await tester.tap(find.byType(MeridianToolbarButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      expect(translationUnder(tester, find.byType(MeridianNudgeIcon)).dy, 0);
    });

    testWidgets('MM-08 focus grows the halo over motion-quick', (tester) async {
      await tester.pumpWidget(host(const MeridianTextField(label: 'Branch')));
      AnimatedContainer chrome() => tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(MeridianTextField),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      double spread() =>
          (chrome().decoration! as BoxDecoration).boxShadow!.first.spreadRadius;
      expect(spread(), 0);
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      expect(chrome().duration, MeridianDurations.quick);
      expect(spread(), MeridianLayout.hairline);
    });

    testWidgets('MM-09 a rejected submit shakes; an error alone does not', (
      tester,
    ) async {
      Widget build(int rejects, String? error) => host(
        MeridianTextField(label: 'Branch', rejectCount: rejects, error: error),
      );
      double dx() => translationUnder(tester, find.byType(MeridianShake)).dx;
      await tester.pumpWidget(build(0, null));
      await tester.pumpWidget(build(0, 'Spaces are not allowed.'));
      await tester.pump(const Duration(milliseconds: 40));
      expect(dx(), 0);
      await tester.pumpWidget(build(1, 'Enter a branch name.'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(dx(), closeTo(-3, 0.3));
      await tester.pump(const Duration(milliseconds: 220));
      expect(dx(), 0);
      expect(find.text('Enter a branch name.'), findsOneWidget);
    });

    testWidgets('MM-10 a numeric trailing text rolls', (tester) async {
      Widget build(String count) =>
          host(MeridianTextField(label: 'Find', trailingText: count));
      await tester.pumpWidget(build('3'));
      await tester.pumpWidget(build('4'));
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('3'), findsNothing);
      await tester.pumpWidget(build('4 of 9'));
      await tester.pumpWidget(build('5 of 9'));
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('4 of 9'), findsOneWidget);
      expect(find.text('5 of 9'), findsOneWidget);
      await pumpFrames(tester, const Duration(milliseconds: 200));
      expect(find.text('4 of 9'), findsNothing);
    });

    testWidgets('MM-11 the checkbox fill pops and the check draws', (
      tester,
    ) async {
      Widget build(bool value) => host(
        MeridianCheckbox(value: value, label: 'Prune', onChanged: (_) {}),
      );
      Finder stroke() => find.descendant(
        of: find.byType(MeridianCheckbox),
        matching: find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is MeridianStrokePainter,
        ),
      );
      Finder icon() => find.descendant(
        of: find.byType(MeridianCheckbox),
        matching: find.byWidgetPredicate(
          (w) => w is MeridianIcon && w.name == 'check',
        ),
      );
      await tester.pumpWidget(build(false));
      expect(icon(), findsNothing);
      await tester.pumpWidget(build(true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      // The check starts 40 ms in.
      expect(stroke(), findsNothing);
      await tester.pump(const Duration(milliseconds: 60));
      final drawing =
          tester.widget<CustomPaint>(stroke()).painter!
              as MeridianStrokePainter;
      expect(drawing.progress, inExclusiveRange(0, 1));
      await pumpFrames(tester, const Duration(milliseconds: 200));
      // At rest the Lucide icon itself shows.
      expect(icon(), findsOneWidget);
      expect(stroke(), findsNothing);
      await tester.pumpWidget(build(false));
      await pumpFrames(tester, const Duration(milliseconds: 150));
      expect(icon(), findsNothing);
      expect(stroke(), findsNothing);
    });

    testWidgets('MM-11 the checkbox is instant under reduce motion', (
      tester,
    ) async {
      Widget build(bool value) => motionHost(
        reduced: true,
        MeridianCheckbox(value: value, label: 'Prune', onChanged: (_) {}),
      );
      await tester.pumpWidget(build(false));
      await tester.pumpWidget(build(true));
      await tester.pump();
      expect(
        find.byWidgetPredicate((w) => w is MeridianIcon && w.name == 'check'),
        findsOneWidget,
      );
    });

    testWidgets('MM-12 the switch thumb springs to its end', (tester) async {
      Widget build(bool value, {bool reduced = false}) => motionHost(
        reduced: reduced,
        MeridianSwitch(value: value, label: 'Autostash', onChanged: (_) {}),
      );
      Finder thumb() => find
          .descendant(
            of: find.byType(MeridianSwitch),
            matching: find.byType(PositionedDirectional),
          )
          .first;
      await tester.pumpWidget(build(false));
      final start = tester.getRect(thumb()).left;
      await tester.pumpWidget(build(true));
      final xs = <double>[];
      for (final ms in [16, 50, 100, 250]) {
        await tester.pump(Duration(milliseconds: ms));
        xs.add(tester.getRect(thumb()).left);
      }
      for (var i = 1; i < xs.length; i++) {
        expect(xs[i], greaterThanOrEqualTo(xs[i - 1] - 0.5));
      }
      final end = xs.last;
      const travel =
          MeridianLayout.switchWidth -
          MeridianLayout.switchThumbInset * 2 -
          MeridianLayout.switchThumb;
      expect(end - start, closeTo(travel, 0.5));
      await tester.pumpWidget(build(false, reduced: true));
      await tester.pump();
      expect(tester.getRect(thumb()).left, closeTo(start, 0.01));
    });

    testWidgets('MM-13 the radio dot pops in', (tester) async {
      Widget build(String group) => host(
        MeridianRadio<String>(
          value: 'merge',
          groupValue: group,
          label: 'Merge',
          onChanged: (_) {},
        ),
      );
      await tester.pumpWidget(build('rebase'));
      await tester.pumpWidget(build('merge'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final mid = scaleUnder(tester, find.byType(MeridianRadio<String>));
      expect(mid, inExclusiveRange(0, 1.2));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        scaleUnder(tester, find.byType(MeridianRadio<String>)),
        closeTo(1, 0.01),
      );
    });

    testWidgets('MM-14 the segmented tile glides to the new segment', (
      tester,
    ) async {
      Widget build(String value) => host(
        MeridianSegmented<String>(
          label: 'View',
          value: value,
          segments: const [
            MeridianSegment(value: 'a', label: 'Unified'),
            MeridianSegment(value: 'b', label: 'Split'),
          ],
          onChanged: (_) {},
        ),
      );
      Rect tile() => tester.getRect(
        find
            .descendant(
              of: find.byType(MeridianGlide),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      await tester.pumpWidget(build('a'));
      final first = tile();
      final second = tester.getRect(
        find.ancestor(
          of: find.text('Split'),
          matching: find.byType(MeridianGlideTarget),
        ),
      );
      await tester.pumpWidget(build('b'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(tile().left, inExclusiveRange(first.left, second.left));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tile().left, closeTo(second.left, 1));
      expect(tile().width, closeTo(second.width, 1));
    });

    testWidgets('MM-15 the slider thumb grows on hover', (tester) async {
      useDesktopHighlights();
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 200,
            child: MeridianSlider(label: 'Zoom', value: 0.5, onChanged: (_) {}),
          ),
        ),
      );
      final value = find.descendant(
        of: find.byType(MeridianSlider),
        matching: find.byType(MeridianAnimatedValue),
      );
      await hoverAt(tester, tester.getCenter(find.byType(MeridianSlider)));
      await tester.pump(const Duration(milliseconds: 150));
      expect(scaleUnder(tester, value), closeTo(1.15, 0.001));
    });

    testWidgets('MM-16 the select chevron turns while its menu is open', (
      tester,
    ) async {
      final completer = Completer<void>();
      await tester.pumpWidget(
        host(
          MeridianMenuPresenter(
            present: (context, {required anchor, required entries}) =>
                completer.future,
            child: MeridianSelect<String>(
              label: 'Sort',
              value: 'Newest',
              values: const ['Newest', 'Oldest'],
              valueLabel: (v) => v,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      double angle() {
        final m = tester
            .widget<Transform>(
              find
                  .descendant(
                    of: find.byType(MeridianTurns),
                    matching: find.byType(Transform),
                  )
                  .first,
            )
            .transform;
        return math.atan2(m.storage[1], m.storage[0]).abs();
      }

      expect(angle(), 0);
      await tester.tap(find.byType(MeridianSelect<String>));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(angle(), closeTo(math.pi, 0.001));
      completer.complete();
      await pumpFrames(tester, const Duration(milliseconds: 200));
      expect(angle(), closeTo(0, 0.001));
    });

    testWidgets('MM-17 a pressed keycap sinks 1 px', (tester) async {
      Widget build(bool pressed, {bool reduced = false}) => motionHost(
        reduced: reduced,
        MeridianKbd(keys: const ['⌘', 'K'], pressed: pressed),
      );
      await tester.pumpWidget(build(false));
      await tester.pumpWidget(build(true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(translationUnder(tester, find.byType(MeridianKbd)).dy, 1);
      await tester.pumpWidget(build(true, reduced: true));
      await tester.pump();
      expect(translationUnder(tester, find.byType(MeridianKbd)).dy, 0);
    });
  });

  group('lists', () {
    Widget list({
      required int selected,
      ScrollController? controller,
      MeridianSelectionStyle selection = MeridianSelectionStyle.strong,
    }) => MeridianApp(
      theme: MeridianTheme.resolve(
        brand: MeridianBrands.gitlama,
        brightness: Brightness.light,
        icons: testIcons,
        selection: selection,
      ),
      home: MeridianGround(
        child: Center(
          child: SizedBox(
            width: 240,
            height: 200,
            child: MeridianList.builder(
              controller: controller,
              itemCount: 40,
              itemExtent: 26,
              selectedIndex: selected,
              itemBuilder: (context, i) => MeridianListRow(
                title: 'Row $i',
                selected: i == selected,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    Rect bar(WidgetTester tester) =>
        tester.getRect(find.byType(MeridianSelectionFill));

    testWidgets('MM-20 the list selection bar glides and the row is clear', (
      tester,
    ) async {
      await tester.pumpWidget(list(selected: 1));
      final start = bar(tester);
      expect(start.top, closeTo(tester.getRect(find.text('Row 1')).top, 13));
      // The row paints no fill of its own under the glide.
      final row = find.ancestor(
        of: find.text('Row 1'),
        matching: find.byType(AnimatedContainer),
      );
      final fill =
          (tester.widget<AnimatedContainer>(row.first).decoration!
                  as BoxDecoration)
              .color!;
      expect(fill.a, 0);
      await tester.pumpWidget(list(selected: 3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(bar(tester).top, inExclusiveRange(start.top, start.top + 52));
      await pumpFrames(tester, const Duration(milliseconds: 300));
      expect(bar(tester).top, closeTo(start.top + 52, 0.5));
    });

    testWidgets('MM-20 the bar scrolls with its row', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(list(selected: 5, controller: controller));
      controller.jumpTo(40);
      await tester.pump();
      final row5 = tester.getRect(
        find.ancestor(
          of: find.text('Row 5'),
          matching: find.byType(MeridianListRow),
        ),
      );
      expect(bar(tester).top, closeTo(row5.top, 0.5));
    });

    testWidgets('a soft selection stays accent-soft in a focused island', (
      tester,
    ) async {
      late MeridianRowColors strong;
      late MeridianRowColors soft;
      Widget probe(
        MeridianSelectionStyle style,
        void Function(MeridianRowColors) out,
      ) => MeridianApp(
        theme: MeridianTheme.resolve(
          brand: MeridianBrands.gitlama,
          brightness: Brightness.light,
          icons: testIcons,
          selection: style,
        ),
        home: MeridianSurfaceScope(
          focused: true,
          child: Builder(
            builder: (context) {
              out(
                MeridianRowColors.resolve(
                  context,
                  selected: true,
                  hovered: false,
                ),
              );
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        probe(MeridianSelectionStyle.strong, (c) => strong = c),
      );
      final colors = colorsOf(tester, find.byType(SizedBox));
      expect(strong.fill, colors.accent);
      expect(strong.strong, isTrue);
      await tester.pumpWidget(
        probe(MeridianSelectionStyle.soft, (c) => soft = c),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(soft.fill, colors.accentSoft);
      expect(soft.primary, colors.ink);
      expect(soft.strong, isFalse);
    });

    testWidgets('MM-78 a focused selection turns soft while the window is '
        'inactive', (tester) async {
      late MeridianRowColors paint;
      await tester.pumpWidget(
        host(
          MeridianSurfaceScope(
            focused: true,
            child: Builder(
              builder: (context) {
                paint = MeridianRowColors.resolve(
                  context,
                  selected: true,
                  hovered: false,
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(paint.strong, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(paint.strong, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(paint.strong, isTrue);
    });

    testWidgets('MM-21 hover actions slide in from the trailing edge', (
      tester,
    ) async {
      useDesktopHighlights();
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: MeridianListRow(
              title: 'Report',
              meta: '12 May',
              onTap: () {},
              hoverActions: [
                MeridianIconButton(
                  label: 'Archive',
                  icon: MeridianIcons.archive,
                  size: MeridianControlSize.small,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      final mouse = await hoverAt(
        tester,
        tester.getCenter(find.text('Report')),
      );
      await tester.pump(const Duration(milliseconds: 40));
      final slot = find.ancestor(
        of: findTooltip('Archive'),
        matching: find.byType(Opacity),
      );
      final opacity = tester.widget<Opacity>(slot.first).opacity;
      expect(opacity, inExclusiveRange(0, 1));
      await pumpFrames(tester, const Duration(milliseconds: 150));
      expect(tester.widget<Opacity>(slot.first).opacity, 1);
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      expect(find.text('12 May'), findsOneWidget);
      await pumpFrames(tester, const Duration(milliseconds: 150));
      expect(findTooltip('Archive'), findsNothing);
    });

    testWidgets('MM-22 a new row reveals once; a recycled one does not', (
      tester,
    ) async {
      Widget build(bool shown) => host(
        MeridianMotionScope(
          child: SizedBox(
            width: 240,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (shown)
                  const MeridianListRow(title: 'feature/x', revealKey: 'ref-x'),
              ],
            ),
          ),
        ),
      );
      double height() => tester.getSize(find.byType(MeridianReveal)).height;
      await tester.pumpWidget(build(false));
      await tester.pumpWidget(build(true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final mid = height();
      await pumpFrames(tester, const Duration(milliseconds: 300));
      final full = height();
      expect(mid, lessThan(full));
      await tester.pumpWidget(build(false));
      await tester.pumpWidget(build(true));
      expect(height(), full);
    });

    testWidgets('MM-23 a row changed underneath plays one tint', (
      tester,
    ) async {
      Widget build(int attention) => host(
        MeridianMotionScope(
          child: SizedBox(
            width: 240,
            child: MeridianListRow(
              title: 'main',
              revealKey: 'main',
              attention: attention,
            ),
          ),
        ),
      );
      await tester.pumpWidget(build(0));
      await tester.pumpWidget(build(1));
      await tester.pump();
      final state = tester.state<MeridianAttentionState>(
        find.byType(MeridianAttention),
      );
      expect(state.progress, greaterThan(0.9));
      await pumpFrames(tester, const Duration(milliseconds: 950));
      expect(state.progress, 0);
    });

    testWidgets('MM-24 a section reveals and staggers its rows', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 240,
            child: MeridianNavSection(
              title: 'Branches',
              collapsible: true,
              initiallyExpanded: false,
              children: [
                for (var i = 0; i < 8; i++)
                  MeridianNavRow(label: 'branch $i', onTap: () {}),
              ],
            ),
          ),
        ),
      );
      expect(find.text('branch 0'), findsNothing);
      await tester.tap(find.text('BRANCHES'));
      await tester.pump();
      expect(find.byType(MeridianEntrance), findsNWidgets(6));
      await tester.pump(const Duration(milliseconds: 60));
      final height = tester.getSize(find.byType(MeridianReveal)).height;
      await pumpFrames(tester, const Duration(milliseconds: 300));
      expect(
        tester.getSize(find.byType(MeridianReveal)).height,
        greaterThan(height),
      );
      expect(find.text('branch 7'), findsOneWidget);
    });

    testWidgets('MM-25 the current check travels between rows', (tester) async {
      Widget build(int current) => host(
        SizedBox(
          width: 240,
          child: MeridianNavSection(
            title: 'Branches',
            children: [
              for (var i = 0; i < 4; i++)
                MeridianNavRow(
                  label: 'branch $i',
                  current: i == current,
                  onTap: () {},
                ),
            ],
          ),
        ),
      );
      Rect indicator() => tester.getRect(
        find
            .descendant(
              of: find.byType(MeridianGlide),
              matching: find.byType(Align),
            )
            .first,
      );
      await tester.pumpWidget(build(0));
      final first = tester.getRect(find.byType(MeridianGlideTarget));
      await tester.pumpWidget(build(3));
      final last = tester.getRect(find.byType(MeridianGlideTarget));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(indicator().top, inExclusiveRange(first.top, last.top));
      await pumpFrames(tester, const Duration(milliseconds: 300));
      expect(indicator().top, closeTo(last.top, 0.5));
    });

    testWidgets('MM-26 the tab rule glides', (tester) async {
      Widget build(int index) => host(
        MeridianTabs(
          scrollable: false,
          index: index,
          onChanged: (_) {},
          tabs: const [
            MeridianTab(label: 'Changes'),
            MeridianTab(label: 'History'),
          ],
        ),
      );
      Rect rule() => tester.getRect(
        find
            .descendant(
              of: find.byType(MeridianGlide),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      await tester.pumpWidget(build(0));
      final start = rule();
      await tester.pumpWidget(build(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final mid = rule();
      await pumpFrames(tester, const Duration(milliseconds: 300));
      expect(mid.left, inExclusiveRange(start.left, rule().left));
    });

    testWidgets('MM-27 a tab grows in and a closed tab collapses', (
      tester,
    ) async {
      Widget build(List<String> labels) => host(
        MeridianTabs(
          style: MeridianTabsStyle.pill,
          scrollable: false,
          index: 0,
          onChanged: (_) {},
          tabs: [for (final l in labels) MeridianTab(label: l)],
        ),
      );
      await tester.pumpWidget(build(['a.txt']));
      await tester.pumpWidget(build(['a.txt', 'b.txt']));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final growing = tester
          .getSize(
            find.ancestor(
              of: find.text('b.txt'),
              matching: find.byType(MeridianReveal),
            ),
          )
          .width;
      await pumpFrames(tester, const Duration(milliseconds: 300));
      final full = tester
          .getSize(
            find.ancestor(
              of: find.text('b.txt'),
              matching: find.byType(MeridianReveal),
            ),
          )
          .width;
      expect(growing, lessThan(full));
      await tester.pumpWidget(build(['a.txt']));
      await tester.pump();
      expect(find.text('b.txt'), findsOneWidget);
      await pumpFrames(tester, const Duration(milliseconds: 400));
      expect(find.text('b.txt'), findsNothing);
    });

    testWidgets('MM-29 the current page pill glides', (tester) async {
      Widget build(int page) => host(
        MeridianPagination(
          page: page,
          pageCount: 5,
          previousLabel: 'Previous',
          nextLabel: 'Next',
          onPageSelected: (_) {},
        ),
      );
      Rect pill() => tester.getRect(
        find
            .descendant(
              of: find.byType(MeridianGlide),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      await tester.pumpWidget(build(1));
      final start = pill();
      await tester.pumpWidget(build(3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final mid = pill();
      await pumpFrames(tester, const Duration(milliseconds: 300));
      expect(mid.left, inExclusiveRange(start.left, pill().left));
    });

    testWidgets('MM-30 the selection bar rises in and leaves downwards', (
      tester,
    ) async {
      Widget build(bool visible, String label) => host(
        SizedBox(
          width: 400,
          child: MeridianSelectionBar(
            label: label,
            visible: visible,
            actions: const [],
            clearLabel: 'Clear',
            onClear: () {},
            overflowLabel: 'More',
          ),
        ),
      );
      double dy() => tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byType(MeridianSelectionBar),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .getTranslation()
          .y;
      await tester.pumpWidget(build(true, '3 selected'));
      await tester.pump();
      expect(dy(), closeTo(12, 0.5));
      await pumpFrames(tester, const Duration(milliseconds: 400));
      expect(dy(), closeTo(0, 0.05));
      await tester.pumpWidget(build(true, '4 selected'));
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byType(MeridianRollingNumber), findsOneWidget);
      await pumpFrames(tester, const Duration(milliseconds: 200));
      await tester.pumpWidget(build(false, '4 selected'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(dy(), greaterThan(0));
      await pumpFrames(tester, const Duration(milliseconds: 150));
      expect(find.text('Clear'), findsNothing);
    });
  });

  group('overlays', () {
    Future<BuildContext> pumpApp(
      WidgetTester tester, {
      bool reduced = false,
    }) async {
      late BuildContext context;
      await tester.pumpWidget(
        motionHost(
          reduced: reduced,
          Builder(
            builder: (c) {
              context = c;
              return const SizedBox(width: 10, height: 10);
            },
          ),
        ),
      );
      return context;
    }

    Matrix4 transformAbove(WidgetTester tester, Finder of) => tester
        .widget<Transform>(
          find.ancestor(of: of, matching: find.byType(Transform)).first,
        )
        .transform;

    testWidgets('MM-40 and MM-41 a menu grows from its anchor and leaves '
        'faster', (tester) async {
      final context = await pumpApp(tester);
      unawaited(
        showMeridianMenu(
          context,
          anchor: const Rect.fromLTWH(100, 100, 80, 24),
          entries: [MeridianMenuItem(label: 'Rename', onSelected: () {})],
        ),
      );
      await tester.pump();
      final surface = find.byType(MeridianMenuSurface);
      expect(transformAbove(tester, surface).storage[0], closeTo(0.98, 0.001));
      await tester.pump(const Duration(milliseconds: 60));
      final mid = transformAbove(tester, surface).storage[0];
      expect(mid, inExclusiveRange(0.98, 1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(transformAbove(tester, surface).storage[0], closeTo(1, 0.001));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byType(MeridianMenuSurface), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byType(MeridianMenuSurface), findsNothing);
    });

    testWidgets('MM-40 a menu only fades under reduce motion', (tester) async {
      // Reduce motion is a platform setting: the menu route reads it above
      // the page.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final context = await pumpApp(tester);
      unawaited(
        showMeridianMenu(
          context,
          anchor: const Rect.fromLTWH(100, 100, 80, 24),
          entries: [MeridianMenuItem(label: 'Rename', onSelected: () {})],
        ),
      );
      await tester.pump();
      expect(
        find.ancestor(
          of: find.byType(MeridianMenuSurface),
          matching: find.byType(FadeTransition),
        ),
        findsWidgets,
      );
      await tester.pump(const Duration(milliseconds: 110));
      expect(find.byType(MeridianMenuSurface), findsOneWidget);
    });

    testWidgets('MM-42 the menu highlight follows the pointer without '
        'trailing it', (tester) async {
      await tester.pumpWidget(
        host(
          MeridianMenuSurface(
            onSelected: (_) {},
            entries: [
              for (final label in ['One', 'Two', 'Three', 'Four'])
                MeridianMenuItem(label: label, onSelected: () {}),
            ],
          ),
        ),
      );
      final colors = MeridianTheme.of(
        tester.element(find.byType(MeridianMenuSurface)),
      ).colors;
      Color? ink(String label) =>
          tester.widget<Text>(find.text(label)).style?.color;
      Color? fill(String label) =>
          (tester
                      .widget<DecoratedBox>(
                        find
                            .ancestor(
                              of: find.text(label),
                              matching: find.byType(DecoratedBox),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration)
              .color;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      for (final (from, to) in [('One', 'Four'), ('Four', 'Two')]) {
        await mouse.moveTo(tester.getCenter(find.text(from)));
        await tester.pump();
        await mouse.moveTo(tester.getCenter(find.text(to)));
        // One frame later the highlight and its ink are on the new row.
        await tester.pump();
        expect(fill(to), colors.accent);
        expect(ink(to), colors.onAccent);
        expect(fill(from)!.a, 0);
        expect(ink(from), colors.ink);
        for (final other in ['One', 'Two', 'Three', 'Four']) {
          if (other != to) expect(fill(other)!.a, 0, reason: other);
        }
      }
      expect(find.byType(MeridianGlide), findsNothing);
    });

    testWidgets('MM-42 the keyboard highlight moves without gliding', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          MeridianMenuSurface(
            onSelected: (_) {},
            entries: [
              for (final label in ['One', 'Two', 'Three', 'Four'])
                MeridianMenuItem(label: label, onSelected: () {}),
            ],
          ),
        ),
      );
      final colors = MeridianTheme.of(
        tester.element(find.byType(MeridianMenuSurface)),
      ).colors;
      Color? ink(String label) =>
          tester.widget<Text>(find.text(label)).style?.color;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(ink('One'), colors.onAccent);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(ink('One'), colors.ink);
      expect(ink('Two'), colors.ink);
      expect(ink('Three'), colors.onAccent);
    });

    testWidgets('MM-42 a row whose submenu is open reads dark once the '
        'highlight moves on', (tester) async {
      await tester.pumpWidget(
        host(
          MeridianMenuSurface(
            onSelected: (_) {},
            entries: [
              MeridianMenuItem(
                label: 'Move to',
                children: [MeridianMenuItem(label: 'Inbox', onSelected: () {})],
              ),
              MeridianMenuItem(label: 'Archive', onSelected: () {}),
            ],
          ),
        ),
      );
      final colors = MeridianTheme.of(
        tester.element(find.byType(MeridianMenuSurface)),
      ).colors;
      Color? ink(String label) =>
          tester.widget<Text>(find.text(label)).style?.color;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('Move to')));
      await pumpFrames(tester, const Duration(milliseconds: 600));
      expect(find.text('Inbox'), findsOneWidget);
      expect(ink('Move to'), colors.onAccent);
      await mouse.moveTo(tester.getCenter(find.text('Archive')));
      await tester.pump();
      expect(ink('Archive'), colors.onAccent);
      expect(ink('Move to'), colors.ink);
    });

    testWidgets('MM-44 tooltips leave over motion-exit', (tester) async {
      await tester.pumpWidget(
        host(const MeridianTooltip(message: 'Tip', child: SizedBox())),
      );
      final raw = tester.widget<RawTooltip>(find.byType(RawTooltip));
      expect(raw.dismissDelay, MeridianDurations.exit);
      expect(raw.hoverDelay, MeridianDurations.tooltipWait);
    });

    testWidgets('MM-45 and MM-46 a dialog grows and rises, and leaves in '
        '100 ms', (tester) async {
      final context = await pumpApp(tester);
      unawaited(
        showMeridianDialog<void>(
          context: context,
          builder: (_) => const MeridianDialog(title: 'Delete branch'),
        ),
      );
      await tester.pump();
      final surface = find.byType(MeridianDialogSurface);
      Matrix4 scale() => tester
          .widget<Transform>(
            find.ancestor(of: surface, matching: find.byType(Transform)).first,
          )
          .transform;
      final dy = tester
          .widget<Transform>(
            find.ancestor(of: surface, matching: find.byType(Transform)).at(1),
          )
          .transform
          .getTranslation()
          .y;
      expect(scale().storage[0], closeTo(0.96, 0.001));
      expect(dy, closeTo(8, 0.01));
      await tester.pump(const Duration(milliseconds: 210));
      expect(scale().storage[0], closeTo(1, 0.001));
      Navigator.of(tester.element(surface)).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(surface, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 60));
      expect(surface, findsNothing);
    });

    testWidgets('MM-47 Enter on a disabled primary shakes the dialog', (
      tester,
    ) async {
      final context = await pumpApp(tester);
      unawaited(
        showMeridianDialog<void>(
          context: context,
          builder: (_) => const MeridianDialog(
            title: 'Rename',
            submitDisabled: true,
            actions: [
              MeridianButton(
                label: 'Rename',
                onPressed: null,
                disabledReason: 'Enter a name',
              ),
            ],
          ),
        ),
      );
      await pumpFrames(tester, const Duration(milliseconds: 300));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 45));
      final dx = tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byType(MeridianShake),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .getTranslation()
          .x;
      expect(dx.abs(), greaterThan(1));
      await pumpFrames(tester, const Duration(milliseconds: 1000));
      expect(find.text('Enter a name'), findsOneWidget);
    });

    testWidgets('MM-49 a toast arrives from below-right on a spring', (
      tester,
    ) async {
      final context = await pumpApp(tester);
      showMeridianToast(context, message: 'Pushed');
      await tester.pump();
      await tester.pump();
      final toast = find.byType(MeridianToast);
      Offset offset() {
        final t = transformAbove(tester, toast).getTranslation();
        return Offset(t.x, t.y);
      }

      expect(offset().dy, greaterThan(10));
      expect(offset().dx, greaterThan(10));
      await pumpFrames(tester, const Duration(milliseconds: 500));
      expect(offset().distance, lessThan(0.05));
      hideMeridianToast();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(offset().dx, greaterThan(0));
      await pumpFrames(tester, const Duration(milliseconds: 100));
      expect(toast, findsNothing);
    });

    testWidgets('MM-49 an action toast rule shrinks and pauses on hover', (
      tester,
    ) async {
      useDesktopHighlights();
      final context = await pumpApp(tester);
      showMeridianToast(
        context,
        message: 'Deleted draft',
        actionLabel: 'Undo',
        onAction: () {},
      );
      await pumpFrames(tester, const Duration(milliseconds: 500));
      double rule() => tester
          .widget<FractionallySizedBox>(
            find.descendant(
              of: find.byType(Stack),
              matching: find.byType(FractionallySizedBox),
            ),
          )
          .widthFactor!;
      await tester.pump(const Duration(seconds: 2));
      final before = rule();
      expect(before, lessThan(1));
      await hoverAt(tester, tester.getCenter(find.text('Deleted draft')));
      await tester.pump(MeridianDurations.toastAction);
      await tester.pump();
      expect(find.text('Deleted draft'), findsOneWidget);
      expect(rule(), closeTo(before, 0.05));
    });
  });

  group('feedback', () {
    double fadeOf(WidgetTester tester, Finder of) => tester
        .widget<FadeTransition>(
          find.descendant(of: of, matching: find.byType(FadeTransition)).first,
        )
        .opacity
        .value;

    testWidgets('MM-60 a spinner waits 150 ms, then fades in', (tester) async {
      await tester.pumpWidget(host(const MeridianSpinner()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(fadeOf(tester, find.byType(MeridianSpinner)), 0);
      await tester.pump(const Duration(milliseconds: 150));
      expect(fadeOf(tester, find.byType(MeridianSpinner)), 1);
    });

    Widget bar(double? value, {bool persistent = false}) => host(
      SizedBox(
        width: 200,
        child: MeridianProgressBar(value: value, persistent: persistent),
      ),
    );
    Rect fill(WidgetTester tester) => tester.getRect(
      find
          .descendant(
            of: find.byType(MeridianProgressBar),
            matching: find.byType(ColoredBox),
          )
          .last,
    );
    double barOpacity(WidgetTester tester) => tester
        .widget<Opacity>(
          find
              .descendant(
                of: find.byType(MeridianProgressBar),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;

    testWidgets('MM-62 the sweep morphs into the value bar', (tester) async {
      await tester.pumpWidget(bar(null));
      await tester.pump(const Duration(milliseconds: 500));
      final sweep = fill(tester);
      await tester.pumpWidget(bar(0.5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = fill(tester);
      expect(mid.left, lessThan(sweep.left));
      await pumpFrames(tester, const Duration(milliseconds: 200));
      final left = tester.getTopLeft(find.byType(MeridianProgressBar)).dx;
      expect(fill(tester).left, closeTo(left, 0.5));
      expect(fill(tester).width, closeTo(100, 0.5));
    });

    testWidgets('MM-63 a full bar holds 300 ms, then fades out', (
      tester,
    ) async {
      await tester.pumpWidget(bar(0.6));
      await tester.pumpWidget(bar(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(barOpacity(tester), 1);
      await tester.pump(const Duration(milliseconds: 160));
      expect(barOpacity(tester), 0);
      await tester.pumpWidget(bar(0.6, persistent: true));
      await tester.pumpWidget(bar(1, persistent: true));
      await pumpFrames(tester, const Duration(milliseconds: 500));
      expect(barOpacity(tester), 1);
    });

    double skeletonOpacity(WidgetTester tester) => tester
        .widget<Opacity>(
          find
              .descendant(
                of: find.byType(MeridianSkeleton),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;

    testWidgets('MM-64 a skeleton breathes, and holds still under reduce '
        'motion', (tester) async {
      await tester.pumpWidget(host(const MeridianSkeleton(width: 80)));
      await tester.pump();
      final start = skeletonOpacity(tester);
      await tester.pump(const Duration(milliseconds: 1200));
      final low = skeletonOpacity(tester);
      expect(start, closeTo(1, 0.01));
      expect(low, closeTo(MeridianOpacity.skeletonLow, 0.02));
      await tester.pumpWidget(
        motionHost(reduced: true, const MeridianSkeleton(width: 80)),
      );
      await tester.pump();
      expect(skeletonOpacity(tester), MeridianOpacity.skeletonStatic);
    });

    testWidgets('MM-64 skeleton swap crossfades the content in', (
      tester,
    ) async {
      Widget build(bool loaded) => host(
        MeridianSkeleton.swap(
          loaded: loaded,
          skeleton: const MeridianSkeleton(width: 80),
          child: const Text('Loaded'),
        ),
      );
      await tester.pumpWidget(build(false));
      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(MeridianSkeleton), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(MeridianSkeleton), findsNothing);
      expect(find.text('Loaded'), findsOneWidget);
    });

    testWidgets('MM-65 a banner reveals and MM-66 its tone swaps the icon', (
      tester,
    ) async {
      Widget build(bool visible, MeridianBannerTone tone) => host(
        SizedBox(
          width: 400,
          child: MeridianBanner(
            message: 'Resolve the conflicts to continue.',
            tone: tone,
            visible: visible,
          ),
        ),
      );
      double height() => tester.getSize(find.byType(MeridianReveal)).height;
      await tester.pumpWidget(build(false, MeridianBannerTone.attention));
      expect(height(), 0);
      await tester.pumpWidget(build(true, MeridianBannerTone.attention));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = height();
      await pumpFrames(tester, const Duration(milliseconds: 200));
      expect(mid, inExclusiveRange(0, height()));
      await tester.pumpWidget(build(true, MeridianBannerTone.success));
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.byType(MeridianIcon), findsNWidgets(2));
      await pumpFrames(tester, const Duration(milliseconds: 250));
      expect(find.byType(MeridianIcon), findsOneWidget);
    });

    testWidgets('MM-67 an empty state enters staggered, once', (tester) async {
      Widget build(bool shown) => host(
        MeridianMotionScope(
          child: shown
              ? const MeridianEmptyState(
                  title: 'No changes',
                  icon: 'check',
                  message: 'Your working tree is clean.',
                )
              : const SizedBox(),
        ),
      );
      await tester.pumpWidget(build(true));
      expect(find.byType(MeridianEntrance), findsNWidgets(3));
      await tester.pump(const Duration(milliseconds: 10));
      double opacity(int i) => tester
          .widget<Opacity>(
            find
                .descendant(
                  of: find.byType(MeridianEntrance).at(i),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;
      expect(opacity(0), greaterThanOrEqualTo(opacity(2)));
      await pumpFrames(tester, const Duration(milliseconds: 300));
      expect(opacity(2), 1);
    });

    testWidgets('MM-68 a busy overlay blocks input at once and shows after '
        '150 ms', (tester) async {
      await tester.pumpWidget(
        host(const MeridianBusyOverlay(message: 'Verifying…')),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(fadeOf(tester, find.byType(MeridianBusyOverlay)), 0);
      await tester.pump(const Duration(milliseconds: 150));
      expect(fadeOf(tester, find.byType(MeridianBusyOverlay)), 1);
    });

    testWidgets('MM-69 a live status dot pulses; a static one runs no '
        'ticker', (tester) async {
      await tester.pumpWidget(host(const MeridianStatusDot(label: 'Synced')));
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(
        host(const MeridianStatusDot(label: 'Fetching', live: true)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(MeridianPulse), findsOneWidget);
      expect(tester.binding.transientCallbackCount, greaterThan(0));
    });

    testWidgets('MM-72 a removed chip collapses', (tester) async {
      Widget build(bool visible) =>
          host(MeridianChip(label: 'bug', visible: visible));
      double width() => tester.getSize(find.byType(MeridianChip)).width;
      await tester.pumpWidget(build(true));
      final full = width();
      await tester.pumpWidget(build(false));
      await pumpFrames(tester, const Duration(milliseconds: 180));
      expect(width(), inExclusiveRange(0, full));
      await pumpFrames(tester, const Duration(milliseconds: 200));
      expect(width(), 0);
    });

    testWidgets('MM-73 the island halo fades in on focus', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 200,
            child: MeridianIsland(
              child: Focus(focusNode: focus, child: const Text('body')),
            ),
          ),
        ),
      );
      AnimatedContainer island() => tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(MeridianIsland),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      Color halo() =>
          (island().decoration! as BoxDecoration).boxShadow!.first.color;
      expect(halo().a, 0);
      focus.requestFocus();
      await tester.pump();
      expect(island().duration, MeridianDurations.select);
      expect(halo().a, greaterThan(0));
      focus.unfocus();
      await tester.pump();
      expect(island().duration, MeridianDurations.hoverOut);
    });

    testWidgets('MM-74 island content rises in; fast switches are instant', (
      tester,
    ) async {
      Widget build(String id) => host(
        SizedBox(
          width: 200,
          child: MeridianIsland(contentKey: id, child: Text('commit $id')),
        ),
      );
      await tester.pumpWidget(build('a'));
      await pumpFrames(tester, const Duration(milliseconds: 300));
      await tester.pumpWidget(build('b'));
      await tester.pump(const Duration(milliseconds: 30));
      expect(find.text('commit a'), findsOneWidget);
      expect(find.text('commit b'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpWidget(build('c'));
      expect(find.text('commit b'), findsNothing);
      expect(find.text('commit c'), findsOneWidget);
    });

    testWidgets('MM-75 the resize line grows after 150 ms of hover', (
      tester,
    ) async {
      useDesktopHighlights();
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 200,
            child: MeridianResizeHandle(
              direction: Axis.horizontal,
              semanticLabel: 'Resize',
              onDrag: (_) {},
            ),
          ),
        ),
      );
      double scale() => tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byType(MeridianResizeHandle),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .storage[5];
      await hoverAt(
        tester,
        tester.getCenter(find.byType(MeridianResizeHandle)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(scale(), 0);
      await tester.pump(const Duration(milliseconds: 60));
      await pumpFrames(tester, const Duration(milliseconds: 120));
      expect(scale(), 1);
    });

    testWidgets('MM-76 status bar text swaps with a rise', (tester) async {
      Widget build(String text) => host(
        SizedBox(width: 300, child: MeridianStatusBar(leading: [Text(text)])),
      );
      await tester.pumpWidget(build('Fetching'));
      await tester.pumpWidget(build('Up to date'));
      await tester.pump(const Duration(milliseconds: 30));
      expect(find.text('Fetching'), findsOneWidget);
      expect(find.text('Up to date'), findsOneWidget);
      await pumpFrames(tester, const Duration(milliseconds: 200));
      expect(find.text('Fetching'), findsNothing);
    });

    testWidgets('MM-77 an active drop zone marches its dashes', (tester) async {
      Widget build({bool reduced = false}) => motionHost(
        reduced: reduced,
        const SizedBox(
          width: 200,
          child: MeridianDropZone(
            label: 'Drop a folder',
            state: MeridianDropZoneState.active,
          ),
        ),
      );
      await tester.pumpWidget(build());
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pumpWidget(build(reduced: true));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.binding.transientCallbackCount, 0);
    });
  });
}

/// Hands its ticker provider to a test.
class _Vsync extends StatefulWidget {
  const _Vsync({required this.onReady});

  final ValueChanged<TickerProvider> onReady;

  @override
  State<_Vsync> createState() => _VsyncState();
}

class _VsyncState extends State<_Vsync> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    widget.onReady(this);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
