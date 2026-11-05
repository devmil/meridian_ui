import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  group('MeridianButton', () {
    testWidgets('runs on tap and on Enter', (tester) async {
      var count = 0;
      await tester.pumpWidget(
        host(
          MeridianButton(
            label: 'Archive',
            autofocus: true,
            onPressed: () => count++,
          ),
        ),
      );
      await tester.tap(find.text('Archive'));
      expect(count, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(count, 2);
    });

    testWidgets('disabled buttons do nothing and explain why', (tester) async {
      await tester.pumpWidget(
        host(
          const MeridianButton(
            label: 'Send',
            onPressed: null,
            disabledReason: 'Add a recipient first',
          ),
        ),
      );
      await tester.tap(find.text('Send'));
      expect(find.byTooltip('Add a recipient first'), findsOneWidget);
    });

    testWidgets('canRequestFocus: false leaves focus with the list', (
      tester,
    ) async {
      final list = FocusNode(debugLabel: 'list');
      addTearDown(list.dispose);
      var count = 0;
      await tester.pumpWidget(
        host(
          Focus(
            focusNode: list,
            autofocus: true,
            child: MeridianIconButton(
              label: 'Expand',
              icon: MeridianIcons.chevronRight,
              canRequestFocus: false,
              onPressed: () => count++,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(list.hasPrimaryFocus, isTrue);
      await tester.tap(find.byType(MeridianIconButton));
      await tester.pump();
      expect(count, 1);
      expect(list.hasPrimaryFocus, isTrue);
    });

    testWidgets('touch density gives at least a 48px target', (tester) async {
      await tester.pumpWidget(
        host(
          MeridianIconButton(
            label: 'Search',
            icon: MeridianIcons.search,
            onPressed: () {},
          ),
          brand: MeridianBrands.nibluma,
        ),
      );
      final size = tester.getSize(find.byType(MeridianInteraction));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('a loading button keeps focus and ignores activation', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var count = 0;
      Widget build({required bool loading}) => host(
        MeridianButton(
          label: 'Save',
          focusNode: focus,
          loading: loading,
          onPressed: () => count++,
        ),
      );
      await tester.pumpWidget(build(loading: false));
      focus.requestFocus();
      await tester.pump();
      await tester.pumpWidget(build(loading: true));
      // A spinner is on screen: pump, never pumpAndSettle. It appears after
      // motion-spinner-delay (150 ms, MM-03).
      await tester.pump(const Duration(milliseconds: 200));
      expect(focus.hasFocus, isTrue);
      expect(find.byType(MeridianSpinner), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.tap(find.text('Save'));
      expect(count, 0);
      await tester.pumpWidget(build(loading: false));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(count, 1);
    });
  });

  group('MeridianToolbarButton', () {
    testWidgets('announces its badge as the value', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          MeridianToolbarButton(
            label: 'Inbox',
            icon: MeridianIcons.inbox,
            badge: 12,
            onPressed: () {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Inbox')),
        isSemantics(label: 'Inbox', value: '12', isButton: true),
      );
      semantics.dispose();
    });

    testWidgets('the split menu is at least as wide as the button', (
      tester,
    ) async {
      var sent = false;
      await tester.pumpWidget(
        host(
          MeridianToolbarButton(
            label: 'Send and archive every selected conversation',
            icon: MeridianIcons.send,
            onPressed: () {},
            menuLabel: 'More send options',
            menu: [
              MeridianMenuItem(label: 'Send later', onSelected: () {}),
              MeridianMenuItem(label: 'Send', onSelected: () => sent = true),
            ],
          ),
        ),
      );
      final button = tester.getRect(find.byType(MeridianToolbarButton));
      expect(button.width, greaterThan(MeridianLayout.menuMinWidth));
      await tester.tap(find.byTooltip('More send options'));
      await tester.pumpAndSettle();
      final menu = tester.getRect(find.byType(MeridianMenuSurface));
      expect(menu.width, greaterThanOrEqualTo(button.width));
      expect(menu.left, moreOrLessEquals(button.left));
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(sent, isTrue);
    });
  });

  group('MeridianTextField', () {
    testWidgets('minLines alone grows under MeridianGround with no Scaffold', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme(),
          home: const MeridianGround(
            child: Center(
              child: SizedBox(
                width: 300,
                child: MeridianTextField(label: 'Notes', minLines: 3),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.minLines, 3);
      expect(field.maxLines, isNull);
      await tester.enterText(find.byType(TextField), 'one\ntwo\nthree\nfour');
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('one\ntwo\nthree\nfour'), findsOneWidget);
    });

    testWidgets('an error replaces the message', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 300,
            child: MeridianTextField(
              label: 'Name',
              message: 'As shown to others',
              error: 'Enter a name',
            ),
          ),
        ),
      );
      expect(find.text('Enter a name'), findsOneWidget);
      expect(find.text('As shown to others'), findsNothing);
      expect(textColor(tester, 'Enter a name'), colorsOf(tester).danger);
    });
  });

  group('toggles', () {
    testWidgets('checkbox toggles from its label', (tester) async {
      bool? value = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => host(
            MeridianCheckbox(
              label: 'Include attachments',
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Include attachments'));
      await tester.pump();
      expect(value, isTrue);
    });

    testWidgets('a mixed checkbox is announced as mixed, not checked', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          MeridianCheckbox(
            label: 'Select all',
            tristate: true,
            value: null,
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(MeridianCheckbox)),
        isSemantics(
          label: 'Select all',
          isCheckStateMixed: true,
          isChecked: false,
        ),
      );
      semantics.dispose();
    });

    testWidgets('switch toggles from track and label, 48px at touch', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var value = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => host(
            MeridianSwitch(
              label: 'Check mail automatically',
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
            brand: MeridianBrands.nibluma,
          ),
        ),
      );
      final track = find.byType(MeridianInteraction);
      expect(tester.getSize(track).height, greaterThanOrEqualTo(48));
      await tester.tap(track);
      await tester.pump();
      expect(value, isTrue);
      await tester.tap(find.text('Check mail automatically'));
      await tester.pump();
      expect(value, isFalse);
      expect(
        tester.getSemantics(find.byType(MeridianSwitch)),
        isSemantics(label: 'Check mail automatically', isToggled: false),
      );
      semantics.dispose();
    });

    testWidgets('radio chooses its value and reads as a group member', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var group = 'day';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => host(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final v in ['day', 'week'])
                  MeridianRadio<String>(
                    label: v,
                    value: v,
                    groupValue: group,
                    onChanged: (next) => setState(() => group = next),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('week'));
      await tester.pump();
      expect(group, 'week');
      expect(
        tester.getSemantics(find.widgetWithText(MeridianRadio<String>, 'week')),
        isSemantics(isChecked: true, isInMutuallyExclusiveGroup: true),
      );
      semantics.dispose();
    });
  });

  group('MeridianSegmented', () {
    Widget segmented(
      ValueChanged<String> onChanged,
      String value, {
      MeridianBrand brand = MeridianBrands.gitlama,
    }) => host(
      MeridianSegmented<String>(
        label: 'Layout',
        value: value,
        segments: const [
          MeridianSegment(value: 'list', label: 'List'),
          MeridianSegment(value: 'grid', label: 'Grid'),
        ],
        onChanged: onChanged,
      ),
      brand: brand,
    );

    testWidgets('moves with arrow keys', (tester) async {
      var value = 'list';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) =>
              segmented((v) => setState(() => value = v), value),
        ),
      );
      await tester.tap(find.text('List'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(value, 'grid');
    });

    testWidgets('no ring after a click, a ring after a key press', (
      tester,
    ) async {
      var value = 'list';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) =>
              segmented((v) => setState(() => value = v), value),
        ),
      );
      final group = find.byType(MeridianSegmented<String>);
      await tester.tap(find.text('Grid'));
      await tester.pump();
      expect(value, 'grid');
      expect(ringVisible(tester, group), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(value, 'list');
      expect(ringVisible(tester, group), isTrue);
    });

    testWidgets('is 48px tall at touch density', (tester) async {
      await tester.pumpWidget(
        segmented((_) {}, 'list', brand: MeridianBrands.nibluma),
      );
      expect(
        tester.getSize(find.byType(MeridianSegmented<String>)).height,
        greaterThanOrEqualTo(48),
      );
      final segment = find.ancestor(
        of: find.text('List'),
        matching: find.byType(GestureDetector),
      );
      expect(tester.getSize(segment.first).height, greaterThanOrEqualTo(48));
    });

    group('disabled segments', () {
      Widget withDisabled(
        ValueChanged<String> onChanged,
        String value, {
        bool manual = false,
      }) => host(
        MeridianSegmented<String>(
          label: 'View',
          value: value,
          manualActivation: manual,
          segments: const [
            MeridianSegment(value: 'list', label: 'List'),
            MeridianSegment(
              value: 'tree',
              label: 'Tree',
              tooltip: 'Needs a folder',
              enabled: false,
            ),
            MeridianSegment(value: 'grid', label: 'Grid'),
          ],
          onChanged: onChanged,
        ),
      );

      testWidgets('ignore taps', (tester) async {
        final changes = <String>[];
        await tester.pumpWidget(withDisabled(changes.add, 'list'));
        await tester.tap(find.text('Tree'));
        await tester.pump();
        expect(changes, isEmpty);
        await tester.tap(find.text('Grid'));
        expect(changes, ['grid']);
      });

      testWidgets('are skipped by the arrow keys, Home and End', (
        tester,
      ) async {
        var value = 'list';
        final changes = <String>[];
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) => withDisabled((v) {
              changes.add(v);
              setState(() => value = v);
            }, value),
          ),
        );
        await tester.tap(find.text('List'));
        await tester.pump();
        changes.clear();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(value, 'grid');
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        expect(value, 'list');
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.pump();
        expect(changes, ['grid', 'list', 'grid', 'list']);
        expect(changes, isNot(contains('tree')));
      });

      testWidgets('manual activation skips them and never selects them', (
        tester,
      ) async {
        var value = 'list';
        final changes = <String>[];
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) => withDisabled(
              (v) {
                changes.add(v);
                setState(() => value = v);
              },
              value,
              manual: true,
            ),
          ),
        );
        await tester.tap(find.text('List'));
        await tester.pump();
        changes.clear();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(changes, isEmpty);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(changes, ['grid']);
      });

      testWidgets('a selected disabled segment stays selected and muted; '
          'Enter does nothing', (tester) async {
        final changes = <String>[];
        await tester.pumpWidget(
          withDisabled(changes.add, 'tree', manual: true),
        );
        final colors = colorsOf(tester);
        expect(textColor(tester, 'Tree'), colors.inkFaint);
        expect(textColor(tester, 'List'), colors.inkMuted);
        final selected = tester.widget<MeridianGlideTarget>(
          find.ancestor(
            of: find.text('Tree'),
            matching: find.byType(MeridianGlideTarget),
          ),
        );
        expect(selected.selected, isTrue);
        await tester.tap(find.text('Tree'));
        await tester.pump();
        expect(changes, isEmpty);
        // A tap on it does not focus the group; Tab does.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(changes, isEmpty);
        // The arrow keys move off it to an enabled neighbour.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(changes, ['grid']);
      });

      testWidgets('announce enabled: false with their own label', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(withDisabled((_) {}, 'list'));
        expect(
          tester.getSemantics(find.bySemanticsLabel('Tree')),
          isSemantics(
            label: 'Tree',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
            isInMutuallyExclusiveGroup: true,
            hasSelectedState: true,
            isSelected: false,
            hasTapAction: false,
            tooltip: 'Needs a folder',
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Grid')),
          isSemantics(
            label: 'Grid',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            isInMutuallyExclusiveGroup: true,
            hasSelectedState: true,
            isSelected: false,
            hasTapAction: true,
          ),
        );
        semantics.dispose();
      });

      testWidgets('show their reason on hover', (tester) async {
        useDesktopHighlights();
        await tester.pumpWidget(withDisabled((_) {}, 'list'));
        await hoverAt(tester, tester.getCenter(find.text('Tree')));
        await tester.pump(const Duration(seconds: 2));
        expect(find.text('Needs a folder'), findsOneWidget);
      });
    });
  });

  group('MeridianSlider', () {
    testWidgets('min == max renders and never divides by zero', (tester) async {
      final values = <double>[];
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 200,
            child: MeridianSlider(
              label: 'Zoom',
              value: 1,
              min: 1,
              max: 1,
              onChanged: values.add,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(MeridianSlider));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(values, everyElement(1.0));
      expect(values.every((v) => v.isFinite), isTrue);
    });

    testWidgets('lays out in an unbounded Row', (tester) async {
      await tester.pumpWidget(
        host(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MeridianSlider(label: 'Opacity', value: 0.5, onChanged: (_) {}),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MeridianSlider)).width,
        MeridianLayout.sliderDefaultWidth,
      );
    });

    testWidgets('onChangeEnd gets the final value, not the stale widget '
        'value', (tester) async {
      double? ended;
      // The parent does not rebuild with the new value during the drag.
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 212,
            child: MeridianSlider(
              label: 'Stroke',
              value: 0,
              onChanged: (_) {},
              onChangeEnd: (v) => ended = v,
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(MeridianSlider));
      await tester.dragFrom(
        rect.centerLeft + const Offset(6, 0),
        Offset(rect.width, 0),
      );
      await tester.pump();
      expect(ended, 1.0);
    });

    testWidgets('arrow keys follow the reading direction', (tester) async {
      var value = 0.5;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => host(
            SizedBox(
              width: 200,
              child: MeridianSlider(
                label: 'Balance',
                value: value,
                step: 0.1,
                onChanged: (v) => setState(() => value = v),
              ),
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      );
      await tester.tap(find.byType(MeridianSlider));
      await tester.pump();
      value = 0.5;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(value, closeTo(0.6, 1e-9));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(value, closeTo(0.4, 1e-9));
    });
  });

  group('menus', () {
    testWidgets('select opens a menu and picks a value', (tester) async {
      var value = 'Newest first';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => host(
            MeridianSelect<String>(
              label: 'Sort by',
              value: value,
              values: const ['Newest first', 'Sender'],
              valueLabel: (v) => v,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Newest first'));
      await tester.pumpAndSettle();
      expect(find.text('Sender'), findsOneWidget);
      await tester.tap(find.text('Sender'));
      await tester.pumpAndSettle();
      expect(value, 'Sender');
      expect(find.byType(MeridianMenuSurface), findsNothing);
    });

    testWidgets('Enter opens a select with its checked item highlighted', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          MeridianSelect<String>(
            label: 'Sort by',
            value: 'Sender',
            values: const ['Newest first', 'Sender', 'Subject'],
            valueLabel: (v) => v,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final menu = find.byType(MeridianMenuSurface);
      expect(menu, findsOneWidget);
      final colors = colorsOf(tester);
      Color? inMenu(String label) => tester
          .widget<Text>(find.descendant(of: menu, matching: find.text(label)))
          .style
          ?.color;
      expect(inMenu('Sender'), colors.onAccent);
      expect(inMenu('Subject'), isNot(colors.onAccent));
    });

    testWidgets('a pointer-opened menu has no highlight', (tester) async {
      await tester.pumpWidget(
        host(
          MeridianSelect<String>(
            label: 'Sort by',
            value: 'Sender',
            values: const ['Newest first', 'Sender'],
            valueLabel: (v) => v,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.tap(find.text('Sender'));
      await tester.pumpAndSettle();
      final menu = find.byType(MeridianMenuSurface);
      expect(
        tester
            .widget<Text>(
              find.descendant(of: menu, matching: find.text('Sender')),
            )
            .style
            ?.color,
        isNot(colorsOf(tester).onAccent),
      );
    });

    testWidgets('Escape on a docked menu calls onDismiss', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        host(
          MeridianMenuSurface(
            entries: [MeridianMenuItem(label: 'Rename', onSelected: () {})],
            onSelected: (_) {},
            onDismiss: () => dismissed++,
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(dismissed, 1);
    });

    testWidgets('arrow keys and Enter run a menu item', (tester) async {
      MeridianMenuItem? chosen;
      await tester.pumpWidget(
        host(
          MeridianMenuSurface(
            entries: [
              const MeridianMenuHeader('Move'),
              MeridianMenuItem(label: 'Archive', onSelected: () {}),
              const MeridianMenuItem(label: 'Disabled'),
              const MeridianMenuDivider(),
              MeridianMenuItem(
                label: 'Delete',
                danger: true,
                onSelected: () {},
              ),
            ],
            onSelected: (item) => chosen = item,
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(chosen?.label, 'Delete');
    });
  });
}
