import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  group('motion tokens', () {
    final motion =
        (jsonDecode(File('tokens/meridian.tokens.json').readAsStringSync())
                as Map<String, dynamic>)['motion']
            as Map<String, dynamic>;

    test('curves match the guide', () {
      expect(
        MeridianCurves.standard.transform(0.5),
        const Cubic(0.2, 0, 0, 1).transform(0.5),
      );
      expect(
        MeridianCurves.enter.transform(0.3),
        const Cubic(0.05, 0.7, 0.1, 1).transform(0.3),
      );
      expect(MeridianDurations.selectCurve, MeridianCurves.standard);
      expect(MeridianDurations.overlayCurve, MeridianCurves.enter);
      expect(MeridianDurations.sheetCurve, MeridianCurves.enter);
      expect(MeridianDurations.emphasizedCurve, MeridianCurves.standard);
    });

    test('every duration matches the token file', () {
      final generated = <String, Duration>{
        'motion-hover': MeridianDurations.hover,
        'motion-hover-out': MeridianDurations.hoverOut,
        'motion-press': MeridianDurations.press,
        'motion-quick': MeridianDurations.quick,
        'motion-select': MeridianDurations.select,
        'motion-exit': MeridianDurations.exit,
        'motion-overlay': MeridianDurations.overlay,
        'motion-dialog': MeridianDurations.dialog,
        'motion-layout': MeridianDurations.layout,
        'motion-sheet': MeridianDurations.sheet,
        'motion-emphasized': MeridianDurations.emphasized,
        'motion-highlight': MeridianDurations.highlight,
        'motion-celebrate': MeridianDurations.celebrate,
        'motion-attention': MeridianDurations.attention,
        'motion-reduced-fade': MeridianDurations.reducedFade,
        'motion-stagger': MeridianDurations.stagger,
        'motion-spinner-delay': MeridianDurations.spinnerDelay,
        'motion-shake-field': MeridianDurations.shakeField,
        'motion-shake-surface': MeridianDurations.shakeSurface,
        'motion-nudge': MeridianDurations.nudge,
        'motion-hold': MeridianDurations.hold,
        'motion-progress-hold': MeridianDurations.progressHold,
        'motion-tooltip-wait': MeridianDurations.tooltipWait,
        'motion-tooltip-warm': MeridianDurations.tooltipWarm,
        'motion-pulse': MeridianDurations.pulse,
        'motion-skeleton-pulse': MeridianDurations.skeletonPulse,
        'motion-march': MeridianDurations.march,
        'motion-spinner': MeridianDurations.spinner,
        'motion-spinner-reduced': MeridianDurations.spinnerReduced,
        'motion-progress': MeridianDurations.progress,
        'motion-skeleton-delay': MeridianDurations.skeletonDelay,
        'motion-toast': MeridianDurations.toast,
        'motion-toast-action': MeridianDurations.toastAction,
      };
      final tokens = (motion['tokens'] as List).cast<Map<String, dynamic>>();
      expect(tokens.map((t) => t['name']).toSet(), generated.keys.toSet());
      for (final token in tokens) {
        expect(
          generated[token['name']],
          Duration(milliseconds: token['value'] as int),
          reason: token['name'] as String,
        );
      }
    });

    /// Samples [spring] from 0 to 1 every millisecond.
    List<double> sample(SpringDescription spring, int ms) {
      final simulation = SpringSimulation(spring, 0, 1, 0);
      return [for (var t = 0; t <= ms; t++) simulation.x(t / 1000)];
    }

    test('spring-snappy settles within 1% by 190 ms', () {
      final values = sample(MeridianSprings.snappy, 400);
      final settled = values.lastIndexWhere((v) => (v - 1).abs() > 0.01) + 1;
      expect(settled, inInclusiveRange(180, 200));
    });

    test('spring-pop overshoots 12.6%', () {
      final peak = sample(MeridianSprings.pop, 600).reduce(math.max);
      expect(peak - 1, closeTo(0.126, 0.005));
    });

    test('scales carry the guide values', () {
      expect(MeridianMotionScales.press, 0.97);
      expect(MeridianMotionScales.staggerMax, 6);
      expect(MeridianMotionScales.glideMaxRows, 8);
      expect(MeridianLayout.overlayRise, MeridianMotionScales.riseOverlay);
    });
  });

  group('hover fades without a dark flash', () {
    /// The fill the render tree paints right now inside [of] (the
    /// AnimatedContainer's in-between value, not its target).
    Color? paintedFill(WidgetTester tester, Finder of) {
      for (final box in tester.renderObjectList<RenderDecoratedBox>(
        find.descendant(of: of, matching: find.byType(DecoratedBox)),
      )) {
        final decoration = box.decoration;
        if (decoration is BoxDecoration && decoration.color != null) {
          return decoration.color;
        }
      }
      return null;
    }

    /// Mid-transition, the fill must keep the hover colour's hue and only
    /// fade its alpha. Fading from `Colors.transparent` (transparent black)
    /// would pass through translucent grey.
    void expectHueOf(Color? painted, Color hover) {
      expect(painted, isNotNull);
      expect(painted!.r, closeTo(hover.r, 0.01));
      expect(painted.g, closeTo(hover.g, 0.01));
      expect(painted.b, closeTo(hover.b, 0.01));
    }

    Future<void> hoverMidway(
      WidgetTester tester,
      Finder target,
      Color hover,
    ) async {
      final mouse = await hoverAt(tester, tester.getCenter(target));
      await tester.pump(const Duration(milliseconds: 30));
      expectHueOf(paintedFill(tester, target), hover);
      await tester.pumpAndSettle();
      await mouse.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 30));
      expectHueOf(paintedFill(tester, target), hover);
      await tester.pumpAndSettle();
    }

    testWidgets('icon button', (tester) async {
      useDesktopHighlights();
      await tester.pumpWidget(
        host(
          MeridianIsland(
            child: MeridianIconButton(
              label: 'Search',
              icon: MeridianIcons.search,
              onPressed: () {},
            ),
          ),
        ),
      );
      await hoverMidway(
        tester,
        find.byType(MeridianIconButton),
        colorsOf(tester).paneHover,
      );
    });

    testWidgets('list row', (tester) async {
      useDesktopHighlights();
      await tester.pumpWidget(
        host(
          MeridianIsland(
            child: SizedBox(
              width: 300,
              child: MeridianListRow(title: 'Inbox', onTap: () {}),
            ),
          ),
        ),
      );
      await hoverMidway(
        tester,
        find.byType(MeridianListRow),
        colorsOf(tester).paneHover,
      );
    });

    testWidgets('quiet button', (tester) async {
      useDesktopHighlights();
      await tester.pumpWidget(
        host(
          MeridianIsland(
            child: MeridianButton(
              label: 'Copy ID',
              variant: MeridianButtonVariant.quiet,
              onPressed: () {},
            ),
          ),
        ),
      );
      await hoverMidway(
        tester,
        find.byType(MeridianButton),
        colorsOf(tester).paneHover,
      );
    });

    test('meridianClear keeps the hue', () {
      const color = Color(0xFFEEF2F4);
      final clear = meridianClear(color);
      expect(clear.a, 0);
      expect(clear.r, color.r);
    });
  });

  group('theme', () {
    for (final brand in MeridianBrands.all) {
      for (final brightness in Brightness.values) {
        test('${brand.id} ${brightness.name} resolves', () {
          final theme = buildMeridianTheme(
            brand: brand,
            brightness: brightness,
          );
          final meridian = theme.extension<MeridianTheme>()!;
          final accent = brightness == Brightness.dark
              ? brand.dark
              : brand.light;
          expect(meridian.colors.accent, accent.accent);
          expect(meridian.colors.focus, accent.focus);
          expect(theme.colorScheme.primary, accent.accent);
          expect(meridian.density, brand.density);
          expect(meridian.radius, brand.radius);
          expect(theme.splashFactory, NoSplash.splashFactory);
          expect(theme.iconTheme.color, meridian.colors.ink);
        });
      }
    }

    test('touch density uses the touch type scale and 48px targets', () {
      final meridian = buildMeridianTheme(
        brand: MeridianBrands.nibluma,
        brightness: Brightness.light,
      ).extension<MeridianTheme>()!;
      expect(meridian.density, MeridianDensity.touch);
      expect(meridian.text.body.fontSize, 15);
      expect(meridian.density.minTarget, 48);
      expect(meridian.density.rowExtent, MeridianSize.rowTouch);
    });

    test('mono resolves to the bundled package font', () {
      final meridian = buildMeridianTheme(
        brand: MeridianBrands.gitlama,
        brightness: Brightness.light,
      ).extension<MeridianTheme>()!;
      expect(
        meridian.text.code.fontFamily,
        'packages/meridian_ui/JetBrains Mono',
      );
    });

    test('app fonts are used as named', () {
      final meridian = buildMeridianTheme(
        brand: MeridianBrands.mimameidr,
        brightness: Brightness.dark,
      ).extension<MeridianTheme>()!;
      expect(meridian.text.body.fontFamily, 'Geist');
      expect(meridian.text.code.fontFamily, 'Geist Mono');
    });

    test('lerp crosses colours smoothly', () {
      final light = MeridianTheme.resolve(
        brand: MeridianBrands.crossproton,
        brightness: Brightness.light,
      );
      final dark = MeridianTheme.resolve(
        brand: MeridianBrands.crossproton,
        brightness: Brightness.dark,
      );
      final mid = light.lerp(dark, 0.5);
      expect(mid.colors.ink, isNot(light.colors.ink));
      expect(mid.colors.ink, isNot(dark.colors.ink));
    });

    test('equal inputs give equal themes', () {
      MeridianTheme make() => MeridianTheme.resolve(
        brand: MeridianBrands.nibluma,
        brightness: Brightness.dark,
        icons: const MeridianIconSet(extra: {'stash': 'a.svg'}),
      );
      expect(make(), make());
      expect(make().hashCode, make().hashCode);
    });
  });

  group('icons', () {
    test('asset paths follow the package', () {
      const set = MeridianIconSet(extra: {'stash': 'assets/icons/stash.svg'});
      expect(
        set.assetFor('check'),
        'packages/meridian_ui/assets/icons/check.svg',
      );
      expect(set.assetFor('stash'), 'assets/icons/stash.svg');
      expect(testIcons.assetFor('check'), 'assets/icons/check.svg');
      expect(MeridianIcons.all, contains('check'));
    });

    test('every MeridianIcons name has an SVG on disk', () {
      final missing = [
        for (final name in MeridianIcons.all)
          if (!File('assets/icons/$name.svg').existsSync()) name,
      ];
      expect(missing, isEmpty);
      expect(MeridianIcons.all.toSet(), hasLength(MeridianIcons.all.length));
    });
  });

  group('MeridianInteraction', () {
    for (final density in [MeridianDensity.regular, MeridianDensity.touch]) {
      testWidgets(
        'double tap keeps selection immediate and keyboard single at ${density.name}',
        (tester) async {
          var taps = 0;
          var doubles = 0;
          final focus = FocusNode();
          addTearDown(focus.dispose);
          await tester.pumpWidget(
            host(
              SizedBox(
                width: 100,
                height: 48,
                child: MeridianInteraction(
                  focusNode: focus,
                  onTap: () => taps++,
                  onDoubleTap: () => doubles++,
                  child: const Text('Surface'),
                ),
              ),
              density: density,
            ),
          );
          await tester.tap(find.text('Surface'));
          expect(taps, 1);
          await tester.pump(const Duration(milliseconds: 60));
          await tester.tap(find.text('Surface'));
          expect(doubles, 1);
          expect(taps, 1);
          focus.requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          expect(taps, 3);
          expect(doubles, 1);
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(find.text('Surface'));
          expect(taps, 4);
          await tester.pumpWidget(host(const Text('retired')));
          await tester.pump(const Duration(milliseconds: 400));
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('a tap in the grown 48px margin fires', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          MeridianIconButton(
            label: 'Search',
            icon: MeridianIcons.search,
            size: MeridianControlSize.small,
            onPressed: () => taps++,
          ),
          brand: MeridianBrands.nibluma,
        ),
      );
      final target = tester.getRect(find.byType(MeridianInteraction));
      final visual = tester.getRect(
        find.descendant(
          of: find.byType(MeridianInteraction),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(target.width, greaterThanOrEqualTo(48));
      expect(target.height, greaterThanOrEqualTo(48));
      expect(visual.height, lessThan(target.height));
      // Just inside the target, well outside the visible button.
      await tester.tapAt(target.topLeft + const Offset(2, 2));
      expect(taps, 1);
    });

    testWidgets('a stretched control stays full width at touch density', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [MeridianButton(label: 'Save', onPressed: () {})],
            ),
          ),
          brand: MeridianBrands.nibluma,
        ),
      );
      final face = find.descendant(
        of: find.byType(MeridianButton),
        matching: find.byType(AnimatedContainer),
      );
      expect(tester.getSize(face).width, 300);
    });

    testWidgets('the ring shows for keyboard focus only', (tester) async {
      await tester.pumpWidget(
        host(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MeridianButton(label: 'One', onPressed: () {}),
              MeridianButton(label: 'Two', onPressed: () {}),
            ],
          ),
        ),
      );
      final one = find.widgetWithText(MeridianButton, 'One');
      final two = find.widgetWithText(MeridianButton, 'Two');
      await tester.tap(find.text('One'));
      await tester.pump();
      expect(ringVisible(tester, one), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ringVisible(tester, one), isFalse);
      expect(ringVisible(tester, two), isTrue);
    });

    testWidgets('only the node with primary focus draws a ring', (
      tester,
    ) async {
      final outer = FocusNode();
      final inner = FocusNode();
      addTearDown(outer.dispose);
      addTearDown(inner.dispose);
      await tester.pumpWidget(
        host(
          MeridianInteraction(
            focusNode: outer,
            onTap: () {},
            child: SizedBox(
              width: 120,
              height: 40,
              child: Center(
                child: MeridianInteraction(
                  focusNode: inner,
                  onTap: () {},
                  child: const SizedBox.square(dimension: 16),
                ),
              ),
            ),
          ),
        ),
      );
      List<bool> rings() => tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((c) => c.foregroundPainter)
          .whereType<MeridianFocusRingPainter>()
          .map((p) => p.visible)
          .toList();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(outer.hasPrimaryFocus, isTrue);
      expect(rings(), [true, false]);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(inner.hasPrimaryFocus, isTrue);
      expect(rings(), [false, true]);
    });

    testWidgets('pressed is hover plus 4% ink', (tester) async {
      useDesktopHighlights();
      await tester.pumpWidget(
        host(
          MeridianButton(
            label: 'Archive',
            variant: MeridianButtonVariant.quiet,
            onPressed: () {},
          ),
        ),
      );
      final colors = colorsOf(tester);
      final center = tester.getCenter(find.text('Archive'));
      final mouse = await hoverAt(tester, center);
      await tester.pumpAndSettle();
      // On ground (chrome) a quiet control hovers with ground-hover.
      expect(fillAround(tester, find.text('Archive')), colors.groundHover);
      await mouse.down(center);
      await tester.pumpAndSettle();
      expect(
        fillAround(tester, find.text('Archive')),
        meridianPressed(colors.groundHover, colors.ink),
      );
      await mouse.up();
    });
  });

  testWidgets('MeridianGround gives plain text the body style in ink', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme(),
        home: const MeridianGround(child: Text('Plain')),
      ),
    );
    final style = tester
        .widget<RichText>(
          find.descendant(
            of: find.text('Plain'),
            matching: find.byType(RichText),
          ),
        )
        .text
        .style!;
    final meridian = MeridianTheme.of(tester.element(find.text('Plain')));
    expect(style.color, meridian.colors.ink);
    expect(style.fontSize, meridian.text.body.fontSize);
    expect(style.decoration, isNot(TextDecoration.underline));
  });

  testWidgets('MeridianHairline is 1px tall inside a loose Column', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 200,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [MeridianHairline()],
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byType(MeridianHairline));
    expect(size.height, 1);
    expect(size.width, 200);
  });

  testWidgets('input modality notifies on a switch between keyboard and '
      'pointer', (tester) async {
    MeridianInputModality.retain();
    addTearDown(MeridianInputModality.release);
    final seen = <bool>[];
    void record() => seen.add(MeridianInputModality.changes.value);
    MeridianInputModality.changes.addListener(record);
    addTearDown(() => MeridianInputModality.changes.removeListener(record));
    await tester.pumpWidget(const SizedBox.expand());

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(seen, [true]);
    expect(MeridianInputModality.keyboard, isTrue);

    await tester.tapAt(const Offset(10, 10));
    expect(seen, [true, false]);
    expect(MeridianInputModality.keyboard, isFalse);
  });
}
