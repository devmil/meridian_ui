import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  group('MeridianSectionHeader', () {
    testWidgets('lays out icon, title, count, caption and actions', (
      tester,
    ) async {
      var pressed = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 480,
            child: MeridianSectionHeader(
              icon: MeridianIcons.folder,
              title: 'Unstaged',
              count: 12,
              caption: const Text('3 selected'),
              actions: [
                MeridianIconButton(
                  label: 'Stage all',
                  icon: MeridianIcons.plus,
                  size: MeridianControlSize.small,
                  onPressed: () => pressed++,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Unstaged'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('3 selected'), findsOneWidget);
      expect(find.byType(MeridianHairline), findsOneWidget);
      expect(
        tester.getSize(find.byType(MeridianSectionHeader)).height,
        MeridianSize.islandHeader + MeridianLayout.hairline,
      );
      await tester.tap(find.bySemanticsLabel('Stage all'));
      expect(pressed, 1);
      // Keyboard: Tab reaches the action, Enter runs it.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(pressed, 2);
    });

    testWidgets('the title ellipsizes in a narrow pane; touch is 48px', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 140,
            child: MeridianSectionHeader(
              title: 'A very long section title that cannot fit',
              count: 1200,
              divider: false,
              actions: [
                MeridianIconButton(
                  label: 'More',
                  icon: MeridianIcons.ellipsis,
                  size: MeridianControlSize.small,
                  onPressed: null,
                ),
              ],
            ),
          ),
          density: MeridianDensity.touch,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(MeridianHairline), findsNothing);
      expect(
        tester.getSize(find.byType(MeridianSectionHeader)).height,
        MeridianSize.targetTouch,
      );
    });

    testWidgets('a middle widget takes the free width', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 400,
            child: MeridianSectionHeader(
              title: 'History',
              middle: SizedBox(key: ValueKey('middle'), height: 10),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('middle'))).width,
        greaterThan(150),
      );
    });

    testWidgets('actions follow a middle widget at the strip end', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 600,
              child: MeridianSectionHeader(
                title: 'a.txt',
                middle: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SizedBox(
                    key: ValueKey('middle'),
                    width: 80,
                    height: 10,
                  ),
                ),
                actions: [
                  SizedBox(key: ValueKey('action'), width: 20, height: 20),
                ],
              ),
            ),
          ),
        ),
      );
      final header = tester.getRect(find.byType(MeridianSectionHeader));
      final action = tester.getRect(find.byKey(const ValueKey('action')));
      expect(header.right - action.right, MeridianSpace.space3);
      // The short title keeps its natural width; the middle starts after it.
      expect(
        tester.getRect(find.byKey(const ValueKey('middle'))).left,
        lessThan(header.left + 120),
      );
    });

    testWidgets('a long heading leaves the middle half the strip', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              child: MeridianSectionHeader(
                title: 'a/very/long/path/' * 12,
                middle: const SizedBox(key: ValueKey('middle'), height: 10),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const ValueKey('middle'))).width,
        greaterThan(150),
      );
    });

    testWidgets('the island header gains icon, count and divider control', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 360,
            child: MeridianIsland(
              title: 'Staged',
              icon: MeridianIcons.check,
              count: 4,
              headerDivider: false,
              child: SizedBox(height: 40),
            ),
          ),
        ),
      );
      expect(find.byType(MeridianSectionHeader), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.byType(MeridianHairline), findsNothing);
    });
  });

  group('MeridianEmptyState progress', () {
    testWidgets('a spinner replaces the icon and the title is live', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const MeridianEmptyState(
            title: 'Loading history…',
            icon: MeridianIcons.history,
            progress: true,
            compact: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(MeridianSpinner), findsOneWidget);
      expect(find.byType(MeridianIcon), findsNothing);
      final semantics = tester.getSemantics(find.text('Loading history…'));
      expect(semantics.flagsCollection.isLiveRegion, isTrue);
      expect(
        tester.widget<Text>(find.text('Loading history…')).style?.fontSize,
        MeridianTheme.of(
          tester.element(find.byType(MeridianEmptyState)),
        ).text.body.fontSize,
      );
    });

    testWidgets('a determinate value adds a bar; narrow and touch fit', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 180,
            height: 160,
            child: MeridianEmptyState(
              title: 'Indexing 1,240 files',
              message: 'Search is available when indexing ends.',
              progress: true,
              progressValue: 0.4,
            ),
          ),
          density: MeridianDensity.touch,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.byType(MeridianProgressBar), findsOneWidget);
    });

    testWidgets('the action stays reachable by keyboard', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        host(
          MeridianEmptyState(
            title: 'Could not load',
            compact: true,
            action: MeridianButton(
              label: 'Try again',
              onPressed: () => retried++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(retried, 1);
    });
  });

  group('MeridianSplitPane', () {
    Widget split({
      double? ratio,
      ValueChanged<double>? onChanged,
      ValueChanged<double>? onEnd,
      Axis axis = Axis.horizontal,
      TextDirection direction = TextDirection.ltr,
    }) => Directionality(
      textDirection: direction,
      child: SizedBox(
        width: 600 + MeridianSpace.space3,
        height: 400 + MeridianSpace.space3,
        child: MeridianSplitPane(
          axis: axis,
          ratio: ratio,
          onRatioChanged: onChanged,
          onRatioChangeEnd: onEnd,
          semanticLabel: 'Resize lists',
          handleKey: const ValueKey('handle'),
          first: const ColoredBox(
            key: ValueKey('first'),
            color: Color(0xFF000000),
          ),
          second: const ColoredBox(
            key: ValueKey('second'),
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
    );

    testWidgets('splits by ratio and follows a drag', (tester) async {
      double? changed, ended;
      var ratio = 0.5;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => split(
              ratio: ratio,
              onChanged: (v) => setState(() => ratio = changed = v),
              onEnd: (v) => ended = v,
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const ValueKey('first'))).width, 300);
      await tester.timedDrag(
        find.byKey(const ValueKey('handle')),
        const Offset(60, 0),
        const Duration(milliseconds: 200),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(changed, closeTo(0.6, 0.01));
      expect(ended, closeTo(0.6, 0.01));
    });

    testWidgets('keeps minimums and an uncontrolled ratio', (tester) async {
      await tester.pumpWidget(host(split()));
      await tester.timedDrag(
        find.byKey(const ValueKey('handle')),
        const Offset(-400, 0),
        const Duration(milliseconds: 200),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester.getSize(find.byKey(const ValueKey('first'))).width,
        MeridianLayout.splitPaneMinExtent,
      );
    });

    testWidgets('arrow keys step and Enter resets', (tester) async {
      double? ended;
      await tester.pumpWidget(host(split(onEnd: (v) => ended = v)));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        tester.getSize(find.byKey(const ValueKey('first'))).width,
        closeTo(300 + MeridianLayout.resizeKeyboardStep, 0.001),
      );
      expect(ended, isNotNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(tester.getSize(find.byKey(const ValueKey('first'))).width, 300);
    });

    testWidgets('right to left mirrors the drag', (tester) async {
      await tester.pumpWidget(host(split(direction: TextDirection.rtl)));
      await tester.timedDrag(
        find.byKey(const ValueKey('handle')),
        const Offset(-60, 0),
        const Duration(milliseconds: 200),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.getSize(find.byKey(const ValueKey('first'))).width, 360);
    });

    testWidgets('stacks vertically and announces its share', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(split(axis: Axis.vertical)));
      expect(tester.getSize(find.byKey(const ValueKey('first'))).height, 200);
      expect(find.bySemanticsLabel('Resize lists'), findsOneWidget);
      final node = tester.getSemantics(find.bySemanticsLabel('Resize lists'));
      expect(node.value, '50%');
      handle.dispose();
    });

    testWidgets('extent sizing pins the second pane; touch and narrow fit', (
      tester,
    ) async {
      var extent = 150.0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 200,
              height: 400,
              child: MeridianSplitPane(
                axis: Axis.vertical,
                extent: extent,
                pinned: MeridianSplitPinned.second,
                firstMinExtent: 50,
                secondMinExtent: 50,
                onExtentChanged: (v) => setState(() => extent = v),
                handleKey: const ValueKey('handle'),
                first: const SizedBox.expand(key: ValueKey('first')),
                second: const SizedBox.expand(key: ValueKey('second')),
              ),
            ),
          ),
          density: MeridianDensity.touch,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(const ValueKey('second'))).height, 150);
      await tester.timedDrag(
        find.byKey(const ValueKey('handle')),
        const Offset(0, -30),
        const Duration(milliseconds: 200),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(extent, closeTo(180, 0.5));
    });
  });

  group('code', () {
    testWidgets('the gutter numbers lines and marks them', (tester) async {
      await tester.pumpWidget(
        host(
          const MeridianCodeGutter(
            numbers: [12, null],
            marker: MeridianCodeMarker('+', semanticLabel: 'Added'),
            highlighted: true,
            divider: true,
            height: MeridianLayout.codeLineHeight,
          ),
        ),
      );
      expect(find.text('12'), findsOneWidget);
      expect(find.text('+'), findsOneWidget);
      expect(
        tester.getSize(find.byType(MeridianCodeGutter)).width,
        MeridianCodeGutter.widthFor(numbers: 2, marker: true, divider: true),
      );
    });

    testWidgets('lines share one horizontal offset', (tester) async {
      final horizontal = ScrollController();
      addTearDown(horizontal.dispose);
      final long = 'x' * 400;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            height: 200,
            child: MeridianCodeLines(
              lines: ['short', long, 'third'],
              horizontalController: horizontal,
              highlightedLines: const {2},
              currentLine: 1,
              marks: const {
                0: [TextRange(start: 0, end: 3)],
              },
              markers: const {1: MeridianCodeMarker('~')},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(horizontal.position.maxScrollExtent, greaterThan(1000));
      final before = tester.getTopLeft(find.text('short')).dx;
      horizontal.jumpTo(100);
      await tester.pump();
      expect(tester.getTopLeft(find.text('short')).dx, before - 100);
      expect(tester.getTopLeft(find.text('third')).dx, before - 100);
      // The gutter stays.
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('wrapping lines grow instead of scrolling; touch fits', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 200,
            height: 300,
            child: MeridianCodeLines(
              lines: ['word ' * 40],
              wrap: true,
              selectable: false,
            ),
          ),
          density: MeridianDensity.touch,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(MeridianSharedHorizontalScroll), findsNothing);
      expect(
        tester.getSize(find.byType(Text).last).height,
        greaterThan(MeridianLayout.codeLineHeight * 2),
      );
    });

    testWidgets('line marks paint behind a pointer-selectable line', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const MeridianLineMarks(
            marks: [TextRange(start: 2, end: 5), TextRange(start: 90, end: 99)],
            selection: TextRange(start: 0, end: 1),
            child: Text('let value = 1;'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.byType(MeridianLineMarks),
        paints
          ..rrect()
          ..rect(),
      );
    });
  });

  group('MeridianColorChoiceRow', () {
    testWidgets('offers named series colours, none and a custom well', (
      tester,
    ) async {
      MeridianColorChoice? chosen = const MeridianSeriesColor(0);
      var calls = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => MeridianColorChoiceRow(
              value: chosen,
              allowNone: true,
              onChanged: (value) => setState(() {
                calls++;
                chosen = value;
              }),
            ),
          ),
        ),
      );
      for (final name in const ['Blue', 'Teal', 'Olive', 'No colour']) {
        expect(find.bySemanticsLabel(name), findsOneWidget, reason: name);
      }
      expect(find.bySemanticsLabel('Custom colour'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('meridian-color-series-2')));
      await tester.pump();
      expect(chosen, const MeridianSeriesColor(2));
      await tester.tap(find.byKey(const ValueKey('meridian-color-none')));
      await tester.pump();
      expect(chosen, isNull);
      expect(calls, 2);
    });

    testWidgets('the keyboard chooses a swatch', (tester) async {
      MeridianColorChoice? chosen;
      await tester.pumpWidget(
        host(
          MeridianColorChoiceRow(
            value: null,
            allowNone: true,
            onChanged: (value) => chosen = value,
          ),
        ),
      );
      // Tab past "No colour" to Blue; Enter chooses it.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(chosen, const MeridianSeriesColor(0));
    });

    testWidgets('German names; disabled; narrow touch wraps', (tester) async {
      await tester.pumpWidget(
        host(
          const MeridianLocalizationsScope(
            localizations: MeridianLocalizationsDe(),
            child: SizedBox(
              width: 120,
              child: MeridianColorChoiceRow(
                value: MeridianCustomColor(Color(0xFF123456)),
                allowNone: true,
                onChanged: null,
              ),
            ),
          ),
          density: MeridianDensity.touch,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Petrol'), findsOneWidget);
      expect(find.bySemanticsLabel('Keine Farbe'), findsOneWidget);
      expect(find.bySemanticsLabel('Eigene Farbe #123456'), findsOneWidget);
      expect(
        tester
            .widget<MeridianColorSwatch>(
              find.byKey(const ValueKey('meridian-color-series-0')),
            )
            .onPressed,
        isNull,
      );
    });

    test('choices compare by value', () {
      expect(
        const MeridianCustomColor(Color(0x80123456)),
        const MeridianCustomColor(Color(0xFF123456)),
      );
      expect(const MeridianCustomColor(Color(0xFF123456)).hex, '#123456');
      expect(const MeridianSeriesColor(3), isNot(const MeridianSeriesColor(4)));
    });

    testWidgets('the colour picker falls back to German labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          MeridianLocalizationsScope(
            localizations: const MeridianLocalizationsDe(),
            child: SizedBox(
              width: 480,
              child: MeridianColorPicker(
                color: const Color(0xFF336699),
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('Farbton'), findsWidgets);
      // An explicit label still wins.
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 480,
            child: MeridianColorPicker(
              color: const Color(0xFF336699),
              labels: const MeridianColorPickerLabels(hue: 'Tint'),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Tint'), findsWidgets);
      expect(find.text('Saturation'), findsWidgets);
    });
  });

  group('pressable avatar and status bar item', () {
    testWidgets('an avatar with onPressed is a button', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        host(
          MeridianAvatar(
            name: 'Ada Lovelace',
            tooltip: 'Load pictures',
            onPressed: () => pressed++,
          ),
          density: MeridianDensity.touch,
        ),
      );
      await tester.tap(find.byType(MeridianAvatar));
      expect(pressed, 1);
      expect(find.bySemanticsLabel('Load pictures'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(pressed, 2);
      // Without onPressed it stays a picture.
      await tester.pumpWidget(host(const MeridianAvatar(name: 'Ada')));
      expect(find.byType(MeridianInteraction), findsNothing);
    });

    testWidgets('a status bar item shows an icon, ellipsizes and presses', (
      tester,
    ) async {
      var pressed = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: MeridianStatusBar(
              leading: [
                MeridianStatusBarItem(
                  icon: MeridianIcons.gitBranch,
                  label: 'feature/a-very-long-branch-name-that-cannot-fit',
                  maxWidth: 120,
                  onPressed: () => pressed++,
                  tooltip: 'Switch branch',
                ),
                const MeridianStatusBarItem(label: 'Ready'),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MeridianStatusBarItem).first).width,
        lessThanOrEqualTo(120 + 2 * MeridianSpace.space2),
      );
      await tester.tap(find.byType(MeridianStatusBarItem).first);
      expect(pressed, 1);
      // Disabled (no onPressed) items are plain text.
      expect(
        find.descendant(
          of: find.byType(MeridianStatusBarItem).last,
          matching: find.byType(MeridianInteraction),
        ),
        findsNothing,
      );
    });
  });
}
