import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

MeridianTheme _theme(Brightness brightness, {MeridianDensity? density}) =>
    MeridianTheme.resolve(
      brand: MeridianBrands.gitlama,
      brightness: brightness,
      density: density,
      icons: testIcons,
    );

void main() {
  group('MeridianApp', () {
    for (final (mode, platform, dark) in [
      (MeridianThemeMode.light, Brightness.dark, false),
      (MeridianThemeMode.dark, Brightness.light, true),
      (MeridianThemeMode.system, Brightness.dark, true),
      (MeridianThemeMode.system, Brightness.light, false),
    ]) {
      testWidgets('${mode.name} on a ${platform.name} platform', (
        tester,
      ) async {
        tester.platformDispatcher.platformBrightnessTestValue = platform;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpWidget(
          MeridianApp(
            theme: _theme(Brightness.light),
            darkTheme: _theme(Brightness.dark),
            themeMode: mode,
            home: const Text('Home'),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.text('Home'));
        expect(MeridianTheme.of(context).isDark, dark);
        expect(
          DefaultTextStyle.of(context).style.color,
          MeridianTheme.of(context).colors.ink,
        );
      });
    }

    testWidgets('a theme change animates through the blend', (tester) async {
      Widget app(MeridianThemeMode mode) => MeridianApp(
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: mode,
        home: const Text('Home'),
      );
      await tester.pumpWidget(app(MeridianThemeMode.light));
      final light = MeridianTheme.of(tester.element(find.text('Home')));
      await tester.pumpWidget(app(MeridianThemeMode.dark));
      await tester.pump(MeridianDurations.overlay ~/ 2);
      final halfway = MeridianTheme.of(tester.element(find.text('Home')));
      expect(halfway.colors.ground, isNot(light.colors.ground));
      expect(
        halfway.colors.ground,
        isNot(_theme(Brightness.dark).colors.ground),
      );
      await tester.pumpAndSettle();
      expect(
        MeridianTheme.of(tester.element(find.text('Home'))).isDark,
        isTrue,
      );
    });

    testWidgets('routes are Meridian page routes with Meridian strings', (
      tester,
    ) async {
      await tester.pumpWidget(
        MeridianApp(
          theme: _theme(Brightness.light),
          locale: const Locale('de'),
          supportedLocales: const [Locale('en'), Locale('de')],
          routes: {'/': (_) => const Text('Start')},
        ),
      );
      final context = tester.element(find.text('Start'));
      expect(ModalRoute.of(context), isA<MeridianPageRoute<dynamic>>());
      expect(MeridianLocalizations.of(context).close, 'Schließen');
      // intl's DateFormat works in the app's locale.
      expect(DateFormat.MMMM('de').format(DateTime(2026, 3)), 'März');
      Navigator.of(context)
          .push(MeridianPageRoute<void>(builder: (_) => const Text('Next')));
      await tester.pumpAndSettle();
      expect(find.text('Next'), findsOneWidget);
      Navigator.of(tester.element(find.text('Next'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Next'), findsNothing);
    });

    for (final transition in [
      MeridianPageTransition.instant,
      MeridianPageTransition.fade,
      MeridianPageTransition.fadeUpwards,
      MeridianPageTransition.predictiveBack,
    ]) {
      testWidgets('page transition $transition pushes and pops', (
        tester,
      ) async {
        await tester.pumpWidget(
          MeridianApp(
            theme: _theme(Brightness.light),
            pageTransition: transition,
            home: const Text('Start'),
          ),
        );
        Navigator.of(tester.element(find.text('Start')))
            .push(MeridianPageRoute<void>(builder: (_) => const Text('Next')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(find.text('Next'), findsOneWidget);
        Navigator.of(tester.element(find.text('Next'))).pop();
        await tester.pumpAndSettle();
        expect(find.text('Next'), findsNothing);
      });
    }

    for (final (platform, stretch) in [
      (TargetPlatform.android, true),
      (TargetPlatform.iOS, false),
      (TargetPlatform.linux, false),
    ]) {
      testWidgets('${platform.name} overscroll', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        await tester.pumpWidget(
          MeridianApp(
            theme: _theme(Brightness.light),
            home: ListView(children: const [SizedBox(height: 4000)]),
          ),
        );
        expect(
          find.byType(StretchingOverscrollIndicator),
          stretch ? findsOneWidget : findsNothing,
        );
        expect(find.byType(GlowingOverscrollIndicator), findsNothing);
        debugDefaultTargetPlatformOverride = null;
      });
    }

    testWidgets('desktop views clamp and draw the Meridian thumb', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(
        MeridianApp(
          theme: _theme(Brightness.light),
          home: ListView(
            children: [for (var i = 0; i < 80; i++) Text('Row $i')],
          ),
        ),
      );
      expect(find.byType(MeridianScrollbarThumb), findsOneWidget);
      expect(
        tester
            .widget<MeridianScrollbarThumb>(find.byType(MeridianScrollbarThumb))
            .thumbVisibility,
        isNull,
      );
      await tester.pumpWidget(
        MeridianApp(
          theme: _theme(Brightness.light),
          scrollBehavior: const MeridianScrollBehavior(alwaysShowThumb: true),
          home: ListView(
            children: [for (var i = 0; i < 80; i++) Text('Row $i')],
          ),
        ),
      );
      expect(
        tester
            .widget<MeridianScrollbarThumb>(find.byType(MeridianScrollbarThumb))
            .thumbVisibility,
        isTrue,
      );
      final context = tester.element(find.text('Row 0'));
      expect(
        ScrollConfiguration.of(context).getScrollPhysics(context),
        isA<ClampingScrollPhysics>(),
      );
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('MeridianScaffold', () {
    Widget scaffold({Widget? drawer, Widget? bottomBar}) => host(
      SizedBox(
        width: 400,
        height: 600,
        child: MeridianScaffold(
          appBar: const MeridianAppBar(title: 'Library'),
          drawer: drawer,
          bottomBar: bottomBar,
          body: const Text('Body'),
        ),
      ),
    );

    testWidgets('stacks app bar, body and bottom bar', (tester) async {
      await tester.pumpWidget(
        scaffold(bottomBar: const SizedBox(height: 30, child: Text('Bar'))),
      );
      expect(
        tester.getTopLeft(find.text('Body')).dy,
        greaterThanOrEqualTo(
          tester.getBottomLeft(find.byType(MeridianAppBar)).dy,
        ),
      );
      expect(
        tester.getBottomLeft(find.text('Body')).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.text('Bar')).dy),
      );
    });

    testWidgets('the drawer opens from the app bar and closes on pop, '
        'Escape and the scrim', (tester) async {
      await tester.pumpWidget(
        scaffold(
          drawer: Builder(
            builder: (context) => MeridianDrawer(
              child: MeridianNavRow(
                label: 'Inbox',
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      );
      final menu = find.bySemanticsLabel('Open navigation menu');
      expect(menu, findsOneWidget);

      await tester.tap(menu);
      await tester.pumpAndSettle();
      expect(find.text('Inbox'), findsOneWidget);
      await tester.tap(find.text('Inbox'));
      await tester.pumpAndSettle();
      expect(find.text('Inbox'), findsNothing);

      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Inbox'), findsNothing);

      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tapAt(
        tester.getBottomRight(find.byType(MeridianScaffold)) -
            const Offset(10, 10),
      );
      await tester.pumpAndSettle();
      expect(find.text('Inbox'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a body that sizes itself keeps its size', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 400,
            height: 300,
            child: MeridianScaffold(
              body: SizedBox(width: 210, height: 40, child: Text('Row')),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(SizedBox).last), const Size(210, 40));
    });

    testWidgets('the body moves out of the keyboard', (tester) async {
      await tester.pumpWidget(
        MeridianApp(
          theme: _theme(Brightness.light),
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(400, 800),
              viewInsets: EdgeInsets.only(bottom: 300),
            ),
            child: MeridianScaffold(
              body: SizedBox.expand(child: Text('Body')),
              bottomBar: Text('Bar'),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(SizedBox).last).height,
        lessThanOrEqualTo(500),
      );
      expect(find.text('Bar'), findsNothing);
    });
  });

  group('MeridianTooltip', () {
    testWidgets('shows on hover in Meridian colours', (tester) async {
      await tester.pumpWidget(
        host(
          const MeridianTooltip(
            message: 'Fetch',
            child: SizedBox.square(dimension: 40),
          ),
        ),
      );
      final mouse = await hoverAt(
        tester,
        tester.getCenter(find.byType(SizedBox).last),
      );
      await tester.pump(MeridianDurations.tooltipWait);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Fetch'), findsOneWidget);
      final box = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('Fetch'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((box.decoration as BoxDecoration).color, colorsOf(tester).ink);
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(find.text('Fetch'), findsNothing);
    });

    testWidgets('announces its message unless excluded', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MeridianTooltip(
                message: 'Said',
                child: SizedBox.square(dimension: 20),
              ),
              MeridianTooltip(
                message: 'Quiet',
                excludeFromSemantics: true,
                child: SizedBox.square(dimension: 20),
              ),
            ],
          ),
        ),
      );
      expect(find.byTooltip('Said'), findsOneWidget);
      expect(find.byTooltip('Quiet'), findsNothing);
      expect(findTooltip('Quiet'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an empty message adds nothing', (tester) async {
      await tester.pumpWidget(
        host(const MeridianTooltip(message: '', child: Text('Plain'))),
      );
      expect(find.byType(RawTooltip), findsNothing);
    });
  });

  group('selection', () {
    testWidgets('selectable text selects, copies and shows the Meridian menu', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(host(const MeridianSelectableText('3f2a9c1')));
      Future<void> secondaryClick() async {
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('3f2a9c1')),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await gesture.up();
        await tester.pumpAndSettle();
      }

      await secondaryClick();
      expect(find.byType(MeridianMenuSurface), findsOneWidget);
      await tester.tap(find.text('Select all'));
      await tester.pumpAndSettle();
      await secondaryClick();
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(copied, '3f2a9c1');
      expect(find.byType(MeridianMenuSurface), findsNothing);
    });

    testWidgets('text menu labels come from the widgets layer', (tester) async {
      await tester.pumpWidget(host(const Text('x')));
      final context = tester.element(find.text('x'));
      for (final (type, label) in [
        (ContextMenuButtonType.copy, 'Copy'),
        (ContextMenuButtonType.cut, 'Cut'),
        (ContextMenuButtonType.paste, 'Paste'),
        (ContextMenuButtonType.selectAll, 'Select all'),
        (ContextMenuButtonType.delete, 'Delete'),
      ]) {
        expect(
          meridianTextMenuLabel(
            context,
            ContextMenuButtonItem(type: type, onPressed: () {}),
          ),
          label,
        );
      }
    });

    test('touch handles anchor like the platform', () {
      final controls = MeridianTextSelectionControls();
      expect(controls.getHandleSize(16), const Size(22, 22));
      expect(
        controls.getHandleAnchor(TextSelectionHandleType.left, 16),
        const Offset(22, 0),
      );
      expect(
        controls.getHandleAnchor(TextSelectionHandleType.collapsed, 16),
        const Offset(11, -4),
      );
    });
  });

  group('MeridianEditableText', () {
    testWidgets('a disabled field takes no focus or input', (tester) async {
      final controller = TextEditingController(text: 'fixed');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: MeridianTextField(controller: controller, enabled: false),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).readOnly,
        isTrue,
      );
    });

    testWidgets('maxLength cuts input; the placeholder hides once typed', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 300,
            child: MeridianTextField(placeholder: 'Branch', maxLength: 4),
          ),
        ),
      );
      expect(find.text('Branch'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'feature');
      await tester.pump();
      expect(find.text('feat'), findsOneWidget);
      expect(find.text('Branch'), findsNothing);
    });

    testWidgets('a tap places the caret and focuses', (tester) async {
      final controller = TextEditingController(text: 'hello world');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: MeridianTextField(controller: controller),
          ),
        ),
      );
      await tester.tapAt(
        tester.getTopLeft(find.byType(EditableText)) + const Offset(2, 8),
      );
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(controller.selection.isCollapsed, isTrue);
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('dates and strings', () {
    test('Meridian dates', () {
      expect(MeridianDates.daysInMonth(2024, 2), 29);
      expect(MeridianDates.daysInMonth(2026, 2), 28);
      expect(
        MeridianDates.addMonths(DateTime(2026, 11, 14), 3),
        DateTime(2027, 2),
      );
      expect(
        MeridianDates.isSameDay(
          DateTime(2026, 11, 14, 9),
          DateTime(2026, 11, 14, 22),
        ),
        isTrue,
      );
      expect(
        MeridianDates.dateOnly(DateTime(2026, 11, 14, 9, 30)),
        DateTime(2026, 11, 14),
      );
      expect(
        MeridianDates.monthDelta(DateTime(2026, 11), DateTime(2027, 2)),
        3,
      );
    });

    test('English and German date formats', () {
      final day = DateTime(2026, 11, 14, 15, 7);
      const en = MeridianLocalizationsEn();
      const de = MeridianLocalizationsDe();
      expect(en.formatMediumDate(day), 'Nov 14, 2026');
      expect(de.formatMediumDate(day), '14. Nov. 2026');
      expect(en.formatFullDate(day), 'Saturday, November 14, 2026');
      expect(de.formatFullDate(day), 'Samstag, 14. November 2026');
      expect(en.formatTime(day), '3:07 PM');
      expect(en.formatTime(day, alwaysUse24HourFormat: true), '15:07');
      expect(de.formatTime(day), '15:07');
      expect(en.formatMonthYear(day), 'November 2026');
      expect(en.firstDayOfWeek, DateTime.sunday);
      expect(de.firstDayOfWeek, DateTime.monday);
    });
  });

  testWidgets('a sheet slides up, follows a drag down and closes', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => MeridianButton(
            label: 'Open',
            onPressed: () => showMeridianSheet<void>(
              context: context,
              builder: (_) => const MeridianSheet(
                title: 'Pen',
                child: SizedBox(height: 200, child: Text('Sheet body')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Sheet body'), findsOneWidget);
    await tester.drag(find.text('Sheet body'), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(find.text('Sheet body'), findsNothing);
  });
}
