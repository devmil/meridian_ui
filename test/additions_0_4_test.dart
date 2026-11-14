import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  group('MeridianToolbarButton focus', () {
    testWidgets('a click leaves focus where the person was working', (
      tester,
    ) async {
      final field = FocusNode();
      addTearDown(field.dispose);
      var fetched = 0;
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MeridianToolbarButton(
                label: 'Fetch',
                icon: MeridianIcons.download,
                onPressed: () => fetched++,
                menu: [MeridianMenuItem(label: 'Fetch all', onSelected: () {})],
              ),
              Focus(focusNode: field, child: const SizedBox(height: 20)),
            ],
          ),
        ),
      );
      field.requestFocus();
      await tester.pump();
      await tester.tap(find.text('Fetch'));
      await tester.pumpAndSettle();
      expect(fetched, 1);
      expect(field.hasPrimaryFocus, isTrue);
    });

    testWidgets('the keyboard still reaches it', (tester) async {
      var fetched = 0;
      await tester.pumpWidget(
        host(
          MeridianToolbarButton(
            label: 'Fetch',
            icon: MeridianIcons.download,
            onPressed: () => fetched++,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(fetched, 1);
    });
  });

  group('MeridianKbd reveal', () {
    Finder keycap(String key) => find.text(key);

    testWidgets('shows while one of its command modifiers is held', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const MeridianKbd(
            keys: ['⌘', 'P'],
            reveal: MeridianKbdReveal.whileModifierHeld,
          ),
        ),
      );
      expect(keycap('⌘'), findsNothing);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();
      expect(keycap('⌘'), findsOneWidget);
      expect(keycap('P'), findsOneWidget);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();
      expect(keycap('⌘'), findsNothing);
    });

    testWidgets('keycaps keep their height in a taller slot', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            height: 40,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MeridianKbd(keys: ['⌘', 'P']),
              ],
            ),
          ),
        ),
      );
      final cap = find
          .ancestor(of: keycap('P'), matching: find.byType(Container))
          .first;
      expect(tester.getSize(cap).height, MeridianLayout.kbdHeight);
    });

    testWidgets('ignores other modifiers and Shift', (tester) async {
      await tester.pumpWidget(
        host(
          const MeridianKbd(
            keys: ['Ctrl', 'Shift', 'P'],
            reveal: MeridianKbdReveal.whileModifierHeld,
          ),
        ),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
      expect(keycap('Ctrl'), findsNothing);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(keycap('Ctrl'), findsOneWidget);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
    });

    testWidgets('keys without a command modifier always show', (tester) async {
      await tester.pumpWidget(
        host(
          const MeridianKbd(
            keys: ['F8'],
            reveal: MeridianKbdReveal.whileModifierHeld,
          ),
        ),
      );
      expect(keycap('F8'), findsOneWidget);
    });

    testWidgets('a button collapses its hidden hint', (tester) async {
      await tester.pumpWidget(
        host(
          MeridianButton(
            label: 'Commit',
            onPressed: () {},
            shortcut: const ['⌘', '↵'],
            shortcutReveal: MeridianKbdReveal.whileModifierHeld,
          ),
        ),
      );
      final hidden = tester.getSize(find.byType(MeridianButton)).width;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();
      final shown = tester.getSize(find.byType(MeridianButton)).width;
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();
      expect(shown, greaterThan(hidden + MeridianSpace.space4));
      expect(tester.getSize(find.byType(MeridianButton)).width, hidden);
    });
  });

  group('MeridianSelect width', () {
    Widget select(String value, {double minWidth = 160}) => host(
      MeridianSelect<String>(
        label: 'Remote',
        value: value,
        values: const ['origin', 'a-much-longer-remote-name'],
        valueLabel: (v) => v,
        minWidth: minWidth,
        onChanged: (_) {},
      ),
    );

    testWidgets('fits its longest choice and keeps that size', (tester) async {
      await tester.pumpWidget(select('origin', minWidth: 0));
      final short = tester.getSize(find.byType(MeridianSelect<String>));
      await tester.pumpWidget(select('a-much-longer-remote-name', minWidth: 0));
      final long = tester.getSize(find.byType(MeridianSelect<String>));
      expect(short.width, long.width);
    });

    testWidgets('minWidth 0 hugs a single short choice', (tester) async {
      await tester.pumpWidget(
        host(
          MeridianSelect<String>(
            label: 'Remote',
            value: 'origin',
            values: const ['origin'],
            valueLabel: (v) => v,
            minWidth: 0,
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(MeridianSelect<String>)).width,
        lessThan(MeridianLayout.selectMinWidth),
      );
    });

    testWidgets('keeps the chevron at the trailing edge', (tester) async {
      await tester.pumpWidget(
        host(
          MeridianSelect<String>(
            label: 'Remote',
            value: 'a',
            values: const ['a'],
            valueLabel: (v) => v,
            onChanged: (_) {},
          ),
        ),
      );
      final trigger = tester.getRect(find.byType(MeridianSelect<String>));
      final chevron = tester.getRect(find.byType(MeridianIcon));
      expect(trigger.right - chevron.right, lessThan(MeridianSpace.space5));
    });
  });
}
