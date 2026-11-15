import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

/// Pumps a host and returns a context inside it for show* calls.
Future<BuildContext> pumpHost(
  WidgetTester tester, {
  MeridianBrand brand = MeridianBrands.gitlama,
  Widget Function(Widget child)? wrap,
}) async {
  late BuildContext captured;
  final probe = Builder(
    builder: (context) {
      captured = context;
      return const SizedBox();
    },
  );
  await tester.pumpWidget(host(wrap?.call(probe) ?? probe, brand: brand));
  return captured;
}

void main() {
  testWidgets('a split menu used with the mouse leaves no focus ring on '
      'its caret; used with the keyboard it does', (tester) async {
    useDesktopHighlights();
    var picked = 0;
    await tester.pumpWidget(
      host(
        MeridianToolbarButton(
          label: 'Snapshot',
          icon: MeridianIcons.camera,
          onPressed: () {},
          menuLabel: 'More snapshot options',
          menu: [
            MeridianMenuItem(
              label: 'Open snapshot',
              onSelected: () => picked++,
            ),
          ],
        ),
      ),
    );
    final button = find.byType(MeridianToolbarButton);
    final caret = find.bySemanticsLabel('More snapshot options');

    await tester.tap(caret);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open snapshot'));
    await tester.pumpAndSettle();
    expect(picked, 1);
    expect(ringVisible(tester, button), isFalse);

    // A click never focuses a toolbar button, so the keyboard opens it.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Open snapshot'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(ringVisible(tester, button), isTrue);
  });

  group('toast', () {
    testWidgets('dismisses itself after motion-toast and fades out', (
      tester,
    ) async {
      final context = await pumpHost(tester);
      showMeridianToast(context, message: 'Archived 3 messages');
      await tester.pump();
      expect(find.text('Archived 3 messages'), findsOneWidget);
      await tester.pump(MeridianDurations.toast - const Duration(seconds: 1));
      expect(find.text('Archived 3 messages'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      // Fading out, still on screen for the exit.
      expect(find.text('Archived 3 messages'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Archived 3 messages'), findsNothing);
    });

    testWidgets('an action keeps it for motion-toast-action', (tester) async {
      final context = await pumpHost(tester);
      var undone = 0;
      showMeridianToast(
        context,
        message: 'Deleted draft',
        actionLabel: 'Undo',
        onAction: () => undone++,
      );
      await tester.pump(MeridianDurations.toast + const Duration(seconds: 1));
      expect(find.text('Deleted draft'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(undone, 1);
      expect(find.text('Deleted draft'), findsNothing);
    });

    testWidgets('only one toast shows at a time', (tester) async {
      final context = await pumpHost(tester);
      showMeridianToast(context, message: 'First');
      await tester.pump();
      showMeridianToast(context, message: 'Second');
      await tester.pump();
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
      expect(find.byType(MeridianToast), findsOneWidget);
      await tester.pumpAndSettle(MeridianDurations.toast);
      expect(find.byType(MeridianToast), findsNothing);
    });

    testWidgets('hover pauses the countdown', (tester) async {
      useDesktopHighlights();
      final context = await pumpHost(tester);
      showMeridianToast(context, message: 'Synced');
      await tester.pumpAndSettle();
      final mouse = await hoverAt(
        tester,
        tester.getCenter(find.text('Synced')),
      );
      await tester.pump(MeridianDurations.toast * 2);
      expect(find.text('Synced'), findsOneWidget);
      await mouse.moveTo(Offset.zero);
      await tester.pump(MeridianDurations.toast);
      await tester.pumpAndSettle();
      expect(find.text('Synced'), findsNothing);
    });

    testWidgets('is announced to assistive technology', (tester) async {
      final announced = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
            message,
          ) async {
            final map = message as Map<Object?, Object?>;
            if (map['type'] == 'announce') {
              final data = map['data']! as Map<Object?, Object?>;
              announced.add(data['message']! as String);
            }
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<dynamic>(
              SystemChannels.accessibility,
              null,
            ),
      );
      final context = await pumpHost(tester);
      final dismiss = showMeridianToast(context, message: 'Sent');
      await tester.pump();
      expect(announced, ['Sent']);
      dismiss();
      await tester.pumpAndSettle();
      expect(find.text('Sent'), findsNothing);
    });

    testWidgets('carries local theme overrides', (tester) async {
      final dark = testTheme(brightness: Brightness.dark);
      final context = await pumpHost(
        tester,
        wrap: (child) => MeridianThemeScope(theme: dark, child: child),
      );
      showMeridianToast(context, message: 'Dark toast');
      await tester.pumpAndSettle();
      expect(
        MeridianTheme.of(tester.element(find.text('Dark toast'))).isDark,
        isTrue,
      );
      await tester.pumpAndSettle(MeridianDurations.toast);
    });
  });

  group('dialog', () {
    testWidgets('confirm returns true on the verb', (tester) async {
      final context = await pumpHost(tester);
      final result = showMeridianConfirm(
        context,
        title: 'Delete Linear algebra',
        confirmLabel: 'Delete notebook',
        destructive: true,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete notebook'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
    });

    testWidgets('Escape closes it even when the scrim cannot', (tester) async {
      final context = await pumpHost(tester);
      final result = showMeridianDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const MeridianDialog(title: 'Choose a folder'),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.text('Choose a folder'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Choose a folder'), findsNothing);
      expect(await result, isNull);
    });

    testWidgets('dismissOnEscape: false keeps it open', (tester) async {
      final context = await pumpHost(tester);
      showMeridianDialog<void>(
        context: context,
        dismissOnEscape: false,
        builder: (_) => const MeridianDialog(title: 'Pick one'),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Pick one'), findsOneWidget);
    });

    testWidgets('Enter runs onSubmit, but not from a text field', (
      tester,
    ) async {
      final context = await pumpHost(tester);
      var submitted = 0;
      showMeridianDialog<void>(
        context: context,
        builder: (context) => MeridianDialog(
          title: 'Rename notebook',
          onSubmit: () => submitted++,
          content: const MeridianTextField(label: 'Name'),
          actions: [
            MeridianButton(label: 'Cancel', onPressed: () {}),
            MeridianButton(
              label: 'Rename',
              variant: MeridianButtonVariant.primary,
              onPressed: () => submitted++,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(submitted, 1);
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(submitted, 1);
    });

    testWidgets('actions stack full width at touch on a phone, verb on top', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final context = await pumpHost(tester, brand: MeridianBrands.nibluma);
      showMeridianDialog<void>(
        context: context,
        builder: (context) => MeridianDialog(
          title: 'Discard changes?',
          actions: [
            MeridianButton(label: 'Keep editing', onPressed: () {}),
            MeridianButton(
              label: 'Discard',
              variant: MeridianButtonVariant.danger,
              onPressed: () {},
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      Rect face(String label) => tester.getRect(
        find
            .descendant(
              of: find.widgetWithText(MeridianButton, label),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final verb = face('Discard');
      final cancel = face('Keep editing');
      expect(verb.top, lessThan(cancel.top));
      expect(verb.width, cancel.width);
      expect(verb.width, greaterThan(250));
    });

    testWidgets('long content scrolls instead of overflowing', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final context = await pumpHost(tester);
      showMeridianDialog<void>(
        context: context,
        builder: (context) => MeridianDialog(
          title: 'Release notes',
          content: Column(
            children: [for (var i = 0; i < 40; i++) Text('Line $i')],
          ),
          actions: [MeridianButton(label: 'Close', onPressed: () {})],
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Close').hitTestable(), findsOneWidget);
    });

    testWidgets('carries local theme overrides', (tester) async {
      final context = await pumpHost(
        tester,
        wrap: (child) => MeridianThemeScope(
          theme: testTheme(brightness: Brightness.dark),
          child: child,
        ),
      );
      showMeridianDialog<void>(
        context: context,
        builder: (context) => const MeridianDialog(title: 'Dark dialog'),
      );
      await tester.pumpAndSettle();
      expect(
        MeridianTheme.of(tester.element(find.text('Dark dialog'))).isDark,
        isTrue,
      );
    });
  });

  testWidgets('a sheet rises above the keyboard', (tester) async {
    await tester.pumpWidget(
      MeridianApp(
        theme: testTheme(brand: MeridianBrands.nibluma),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: MeridianGround(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: MeridianSheet(
                title: 'Label',
                child: Container(key: const Key('body'), height: 40),
              ),
            ),
          ),
        ),
      ),
    );
    final body = tester.getRect(find.byKey(const Key('body')));
    expect(body.bottom, lessThanOrEqualTo(600 - 300 + 1));
  });

  group('panel', () {
    testWidgets('visible closes while mounted and reports hidden', (
      tester,
    ) async {
      var visible = true;
      var hidden = 0;
      late StateSetter update;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return MeridianPanel(
                title: 'Inspector',
                visible: visible,
                onHidden: () => hidden++,
                child: const Text('Body'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      update(() => visible = false);
      await tester.pump();
      expect(find.text('Body'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(hidden, 1);
    });

    testWidgets('Escape closes it; no top padding under the header', (
      tester,
    ) async {
      var closed = 0;
      await tester.pumpWidget(
        host(
          MeridianPanel(
            title: 'Inspector',
            onClose: () => closed++,
            child: MeridianButton(
              label: 'Reveal',
              autofocus: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final header = tester.getRect(find.text('Inspector'));
      final button = tester.getRect(find.byType(MeridianButton));
      final headerBox = tester.getRect(
        find
            .ancestor(
              of: find.text('Inspector'),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(button.top, moreOrLessEquals(headerBox.bottom));
      expect(header.top, greaterThanOrEqualTo(headerBox.top));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(closed, 1);
      expect(
        tester.getSize(find.byType(MeridianPanel)).width,
        MeridianLayout.panelWidth,
      );
    });

    testWidgets('header buttons keep 48px at touch density', (tester) async {
      await tester.pumpWidget(
        host(
          MeridianPanel(
            title: 'Inspector',
            onClose: () {},
            child: const SizedBox(height: 40),
          ),
          brand: MeridianBrands.nibluma,
        ),
      );
      await tester.pumpAndSettle();
      final close = tester.getSize(
        find.descendant(
          of: find.byType(MeridianIconButton),
          matching: find.byType(MeridianInteraction),
        ),
      );
      expect(close.height, greaterThanOrEqualTo(48));
    });
  });

  testWidgets('island header buttons keep 48px at touch density', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 400,
          child: MeridianIsland(
            title: 'Inbox',
            actions: [
              MeridianIconButton(
                label: 'Filter',
                icon: MeridianIcons.search,
                size: MeridianControlSize.small,
                onPressed: () {},
              ),
            ],
            child: const SizedBox(height: 40),
          ),
        ),
        brand: MeridianBrands.nibluma,
      ),
    );
    final button = tester.getSize(
      find.descendant(
        of: find.byType(MeridianIconButton),
        matching: find.byType(MeridianInteraction),
      ),
    );
    expect(button.height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('island reports focus to its rows', (tester) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 400,
          child: MeridianIsland(
            title: 'Inbox',
            child: MeridianListRow(
              title: 'Quarterly report',
              selected: true,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Quarterly report'));
    await tester.pump();
    final scope = tester.widget<MeridianSurfaceScope>(
      find.byType(MeridianSurfaceScope).last,
    );
    expect(scope.focused, isTrue);
  });

  group('disclosure', () {
    testWidgets('toggles, with pressed and disabled states', (tester) async {
      final semantics = tester.ensureSemantics();
      var enabled = true;
      late StateSetter rebuild;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return host(
              SizedBox(
                width: 300,
                child: MeridianDisclosure(
                  title: 'Advanced',
                  enabled: enabled,
                  trailing: const MeridianCount(
                    label: '2',
                    semanticLabel: '2 changed',
                  ),
                  child: const Text('Body'),
                ),
              ),
            );
          },
        ),
      );
      expect(find.text('Body'), findsNothing);
      expect(find.bySemanticsLabel('2 changed'), findsOneWidget);
      final colors = colorsOf(tester);
      final press = await tester.startGesture(
        tester.getCenter(find.text('Advanced')),
      );
      await tester.pumpAndSettle();
      expect(
        fillAround(tester, find.text('Advanced')),
        // On ground: the ground hover plus 4% ink.
        meridianPressed(colors.groundHover, colors.ink),
      );
      await press.up();
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsOneWidget);
      rebuild(() => enabled = false);
      await tester.pump();
      await tester.tap(find.text('Advanced'));
      await tester.pump();
      expect(find.text('Body'), findsOneWidget);
      expect(textColor(tester, 'Advanced'), colors.inkFaint);
      semantics.dispose();
    });
  });

  group('settings row', () {
    Widget row(double width) => host(
      SizedBox(
        width: width,
        child: MeridianSettingsRow(
          label: 'Theme',
          help: 'Follows the system by default.',
          children: [
            MeridianSwitch(label: 'Dark', value: false, onChanged: (_) {}),
          ],
        ),
      ),
    );

    testWidgets('label beside the controls when wide', (tester) async {
      await tester.pumpWidget(row(700));
      final label = tester.getRect(find.text('Theme'));
      final control = tester.getRect(find.text('Dark'));
      expect(label.right, lessThan(control.left));
      expect((label.center.dy - control.center.dy).abs(), lessThan(8));
    });

    testWidgets('label above the controls below the breakpoint', (
      tester,
    ) async {
      await tester.pumpWidget(row(MeridianLayout.settingsStackBreakpoint - 20));
      final label = tester.getRect(find.text('Theme'));
      final control = tester.getRect(find.text('Dark'));
      expect(label.bottom, lessThanOrEqualTo(control.top));
    });
  });

  testWidgets('app bar content is exactly 56px, hairline included', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 400,
          child: MeridianAppBar(
            title: 'Notebooks',
            elevated: true,
            leading: MeridianIconButton(
              label: 'Back',
              icon: MeridianIcons.arrowLeft,
              onPressed: () {},
            ),
          ),
        ),
        brand: MeridianBrands.nibluma,
      ),
    );
    expect(
      tester.getSize(find.byType(NavigationToolbar)).height,
      MeridianSize.appbarTouch,
    );
    expect(
      tester.getSize(find.byType(MeridianAppBar)).height,
      MeridianSize.appbarTouch,
    );
  });

  group('feedback', () {
    testWidgets('a narrow desktop banner puts its actions under the text', (
      tester,
    ) async {
      Widget banner(double width) => host(
        SizedBox(
          width: width,
          child: MeridianBanner(
            title: 'Could not send.',
            message: 'The attachment is larger than 25 MB.',
            actions: [
              MeridianButton(label: 'Open draft', onPressed: () {}),
              MeridianButton(label: 'Share a link', onPressed: () {}),
            ],
            onDismiss: () {},
          ),
        ),
      );
      await tester.pumpWidget(banner(320));
      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(find.text('Open draft')).dy,
        greaterThan(tester.getBottomLeft(find.text('Could not send.')).dy),
      );
      await tester.pumpWidget(banner(760));
      final action = tester.getCenter(find.text('Open draft'));
      final banner760 = tester.getRect(find.byType(MeridianBanner));
      expect(action.dy, moreOrLessEquals(banner760.center.dy, epsilon: 1));
    });

    testWidgets('an empty state scrolls in a short space', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 160,
            height: 120,
            child: MeridianEmptyState(
              icon: 'text-search',
              title: 'No messages match this search',
              message: 'Try fewer words or search all folders.',
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('skeleton waits for its delay', (tester) async {
      await tester.pumpWidget(
        host(
          const MeridianSkeleton(
            width: 120,
            delay: MeridianDurations.skeletonDelay,
          ),
        ),
      );
      BoxDecoration? decoration() =>
          tester
                  .widget<Container>(
                    find.descendant(
                      of: find.byType(MeridianSkeleton),
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration
              as BoxDecoration?;
      expect(decoration(), isNull);
      expect(tester.getSize(find.byType(MeridianSkeleton)).width, 120);
      await tester.pump(MeridianDurations.skeletonDelay);
      expect(decoration()?.color, colorsOf(tester).paneHover);
    });

    testWidgets('meter fills its fraction and asserts a bounded width', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const SizedBox(width: 200, child: MeridianMeter(value: 0.25))),
      );
      await tester.pumpAndSettle();
      final fill = tester.getSize(
        find.descendant(
          of: find.byType(AnimatedFractionallySizedBox),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(fill.width, 50);
      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      await tester.pumpWidget(
        host(const Row(children: [MeridianMeter(value: 0.5)])),
      );
      FlutterError.onError = previous;
      expect(errors.first.exceptionAsString(), contains('bounded width'));
    });

    testWidgets('progress sweeps while indeterminate, then settles', (
      tester,
    ) async {
      double? value;
      late StateSetter rebuild;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return host(
              SizedBox(width: 200, child: MeridianProgressBar(value: value)),
            );
          },
        ),
      );
      // Indeterminate: pump frames, never pumpAndSettle.
      double barStart() => tester
          .getTopLeft(
            find
                .descendant(
                  of: find.byType(MeridianProgressBar),
                  matching: find.byType(ColoredBox),
                )
                .last,
          )
          .dx;
      await tester.pump(const Duration(milliseconds: 200));
      final a = barStart();
      await tester.pump(const Duration(milliseconds: 300));
      expect(barStart(), isNot(a));
      rebuild(() => value = 0.5);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
