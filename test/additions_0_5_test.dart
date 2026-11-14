import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  group('MeridianFloatingButton', () {
    testWidgets('runs its command and names it for assistive technology', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var pressed = 0;
      await tester.pumpWidget(
        host(
          MeridianFloatingButton(
            label: 'New notebook',
            icon: MeridianIcons.plus,
            onPressed: () => pressed++,
          ),
          density: MeridianDensity.touch,
        ),
      );
      expect(
        tester.getSize(find.byType(MeridianFloatingButton)),
        const Size.square(MeridianLayout.floatingButtonSize),
      );
      expect(find.text('New notebook'), findsNothing);
      await tester.tap(find.byType(MeridianFloatingButton));
      expect(pressed, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel('New notebook')),
        isSemantics(isButton: true, isEnabled: true, hasTapAction: true),
      );
      semantics.dispose();
    });

    testWidgets('extended shows the label; disabled ignores taps', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const MeridianFloatingButton(
            label: 'New notebook',
            icon: MeridianIcons.plus,
            onPressed: null,
            extended: true,
          ),
        ),
      );
      expect(find.text('New notebook'), findsOneWidget);
      await tester.tap(find.byType(MeridianFloatingButton));
      expect(tester.takeException(), isNull);
    });

    testWidgets('keyboard activation', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        host(
          MeridianFloatingButton(
            label: 'New notebook',
            icon: MeridianIcons.plus,
            onPressed: () => pressed++,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(pressed, 1);
    });
  });

  group('MeridianColorSwatch', () {
    testWidgets('selects, checks and keeps a 48px target on touch', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var chosen = 0;
      await tester.pumpWidget(
        host(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MeridianColorSwatch(
                color: const Color(0xFF18304F),
                label: 'Ink',
                selected: true,
                onPressed: () => chosen++,
              ),
              const MeridianColorSwatch(
                color: Color(0xFFFFFFFF),
                label: 'Paper',
                selected: false,
                onPressed: null,
              ),
            ],
          ),
          density: MeridianDensity.touch,
        ),
      );
      expect(
        tester.getSize(find.byType(MeridianColorSwatch).first).height,
        greaterThanOrEqualTo(MeridianSize.targetTouch),
      );
      final checks = find.byWidgetPredicate(
        (widget) =>
            widget is MeridianIcon && widget.name == MeridianIcons.check,
      );
      expect(checks, findsOneWidget);
      await tester.tap(find.byType(MeridianColorSwatch).first);
      await tester.tap(find.byType(MeridianColorSwatch).last);
      expect(chosen, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Ink')),
        isSemantics(
          isButton: true,
          isSelected: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('the check contrasts with the content colour', (tester) async {
      await tester.pumpWidget(
        host(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MeridianColorSwatch(
                color: const Color(0xFFF4D864),
                label: 'Yellow',
                selected: true,
                onPressed: () {},
              ),
              MeridianColorSwatch(
                color: const Color(0xFF18304F),
                label: 'Ink',
                selected: true,
                onPressed: () {},
              ),
            ],
          ),
          brightness: Brightness.dark,
        ),
      );
      final checks = tester
          .widgetList<MeridianIcon>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is MeridianIcon && widget.name == MeridianIcons.check,
            ),
          )
          .map((icon) => icon.color!.computeLuminance())
          .toList();
      expect(checks.first, lessThan(0.2));
      expect(checks.last, greaterThan(0.8));
    });
  });

  group('MeridianDrawer', () {
    testWidgets('opens from the app bar and names its route', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MeridianApp(
          theme: testTheme(density: MeridianDensity.touch),
          home: MeridianScaffold(
            appBar: const MeridianAppBar(title: 'Library'),
            drawer: MeridianDrawer(
              child: ListView(
                children: [MeridianNavRow(label: 'Archive', onTap: () {})],
              ),
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );
      await tester.tap(findTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(find.text('Archive'), findsOneWidget);
      expect(
        tester.getSize(find.byType(MeridianDrawer)).width,
        MeridianLayout.drawerWidth,
      );
      expect(
        tester.getSemantics(find.byType(MeridianDrawer)),
        isSemantics(
          scopesRoute: true,
          namesRoute: true,
          label: 'Navigation menu',
        ),
      );
      semantics.dispose();
    });
  });

  group('MeridianAppBar', () {
    testWidgets('implies a back button on pushed routes', (tester) async {
      await tester.pumpWidget(
        MeridianApp(
          theme: testTheme(),
          home: Builder(
            builder: (context) => MeridianScaffold(
              appBar: const MeridianAppBar(title: 'Library'),
              body: MeridianButton(
                label: 'Open',
                onPressed: () => Navigator.of(context).push(
                  MeridianPageRoute<void>(
                    builder: (_) => const MeridianScaffold(
                      appBar: MeridianAppBar(
                        title: 'Settings',
                        subtitle: 'Saved on this device',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(findTooltip('Back'), findsNothing);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Saved on this device'), findsOneWidget);
      await tester.tap(findTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('title and subtitle fit at 200% text', (tester) async {
      await tester.pumpWidget(
        MeridianApp(
          theme: testTheme(density: MeridianDensity.touch),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const MeridianScaffold(
            appBar: MeridianAppBar(
              title: 'Experimentelle Naturwissenschaft',
              subtitle: 'Auf diesem Gerät gespeichert',
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('MeridianSwitch description', () {
    testWidgets('shows the description and reads it as a hint', (tester) async {
      final semantics = tester.ensureSemantics();
      var value = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => MeridianSwitch(
              label: 'Finger drawing',
              description: 'Draw with one finger; two fingers scroll.',
              labelFirst: true,
              value: value,
              onChanged: (next) => setState(() => value = next),
            ),
          ),
          density: MeridianDensity.touch,
        ),
      );
      expect(
        find.text('Draw with one finger; two fingers scroll.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Draw with one finger; two fingers scroll.'));
      await tester.pump();
      expect(value, isTrue);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Finger drawing')),
        isSemantics(
          label: 'Finger drawing',
          hint: 'Draw with one finger; two fingers scroll.',
          hasToggledState: true,
          isToggled: true,
        ),
      );
      semantics.dispose();
    });
  });

  group('MeridianSelect label and expand', () {
    testWidgets('shows its label and fills the width', (tester) async {
      var value = 'A4';
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 320,
            child: StatefulBuilder(
              builder: (context, setState) => MeridianSelect<String>(
                label: 'Page size',
                showLabel: true,
                expand: true,
                value: value,
                values: const ['A4', 'Letter'],
                valueLabel: (value) => value,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Page size'), findsOneWidget);
      expect(
        tester.getSize(find.byType(MeridianInteraction)).width,
        greaterThanOrEqualTo(320),
      );
      await tester.tap(find.text('A4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Letter').last);
      await tester.pumpAndSettle();
      expect(value, 'Letter');
    });
  });

  group('MeridianButton leading', () {
    testWidgets('shows a picture instead of an icon', (tester) async {
      await tester.pumpWidget(
        host(
          MeridianButton(
            label: 'Preset 1',
            leading: const SizedBox(key: Key('pen'), width: 16, height: 16),
            onPressed: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('pen')), findsOneWidget);
      expect(find.text('Preset 1'), findsOneWidget);
    });
  });

  group('rows grow with large text', () {
    testWidgets('two-line list rows and nav rows do not overflow at 200%', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MeridianListRow(
                  title: 'Speicherstatus',
                  subtitle: 'Synchronisierung ist ausgeschaltet',
                  twoLine: true,
                  onTap: () {},
                ),
                MeridianNavRow(
                  label: 'Einstellungen',
                  icon: MeridianIcons.settings,
                  onTap: () {},
                ),
              ],
            ),
          ),
          density: MeridianDensity.touch,
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MeridianListRow)).height,
        greaterThan(
          MeridianSize.rowTouch + MeridianLayout.rowTwoLineExtraTouch,
        ),
      );
    });

    testWidgets('rows keep their density height at normal text', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 320,
            child: MeridianNavRow(label: 'Inbox', onTap: () {}),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(MeridianNavRow)).height,
        MeridianSize.row,
      );
    });
  });

  group('MeridianBanner semantics', () {
    testWidgets('the message is one live node and actions stay buttons', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 480,
            child: MeridianBanner(
              title: 'Not saved',
              message: 'Free up space, then try again.',
              tone: MeridianBannerTone.error,
              actions: [
                MeridianButton(
                  label: 'Try again',
                  size: MeridianControlSize.small,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('Not saved')),
        isSemantics(
          label: 'Not saved\nFree up space, then try again.',
          isLiveRegion: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Try again')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      semantics.dispose();
    });
  });

  group('toasts after the screen has gone', () {
    testWidgets('showMeridianToastIn and hideMeridianToast', (tester) async {
      await tester.pumpWidget(host(const SizedBox()));
      final overlay = tester.state<OverlayState>(find.byType(Overlay).first);
      showMeridianToastIn(overlay, message: 'Book deleted');
      await tester.pumpAndSettle();
      expect(find.text('Book deleted'), findsOneWidget);
      hideMeridianToast();
      await tester.pumpAndSettle();
      expect(find.text('Book deleted'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      expect(showMeridianToastIn(overlay, message: 'Gone'), isA<Function>());
    });
  });

  group('MeridianDialogSurface', () {
    testWidgets('uses an explicit radius for paint and clipping', (
      tester,
    ) async {
      const corners = BorderRadius.all(Radius.elliptical(40, 20));
      await tester.pumpWidget(
        host(
          const MeridianDialogSurface(
            borderRadius: corners,
            child: SizedBox(width: 200, height: 100, child: Text('Palette')),
          ),
        ),
      );
      final surface = find
          .ancestor(
            of: find.text('Palette'),
            matching: find.byType(DecoratedBox),
          )
          .last;
      final decoration =
          tester.widget<DecoratedBox>(surface).decoration as BoxDecoration;
      expect(decoration.borderRadius, corners);
      expect(
        tester.widget<ClipRRect>(find.byType(ClipRRect).last).borderRadius,
        corners,
      );
    });

    testWidgets('aligns and rises above the keyboard', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          const MeridianDialogSurface(
            alignment: Alignment.bottomRight,
            maxWidth: 200,
            child: SizedBox(height: 100, width: 200),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byType(DecoratedBox).last);
      expect(rect.bottom, lessThanOrEqualTo(800 - 300));
      expect(rect.right, greaterThan(150));
    });
  });
}
