import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';
import 'package:meridian_ui/src/components/inputs.dart'
    show MeridianCheckboxMark;

import 'support.dart';

/// A checklist row whose caller owns the checked state, as apps do.
class _Checklist extends StatefulWidget {
  const _Checklist({this.enabled = true, this.width = 400});

  final bool enabled;
  final double width;

  @override
  State<_Checklist> createState() => _ChecklistState();
}

class _ChecklistState extends State<_Checklist> {
  var checked = false;
  var taps = 0;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.width,
    child: MeridianListRow(
      title: 'lib/src/components/navigation.dart',
      subtitle: 'Modified',
      meta: '+12 -3',
      leading: const MeridianIcon(MeridianIcons.fileText),
      checked: checked,
      enabled: widget.enabled,
      onTap: () => setState(() {
        taps++;
        checked = !checked;
      }),
    ),
  );
}

_ChecklistState _state(WidgetTester tester) =>
    tester.state<_ChecklistState>(find.byType(_Checklist));

MeridianCheckboxMark _mark(WidgetTester tester) =>
    tester.widget<MeridianCheckboxMark>(find.byType(MeridianCheckboxMark));

void main() {
  group('MeridianListRow checklist', () {
    testWidgets('null checked draws no mark and stays a button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 400,
            child: MeridianListRow(title: 'Inbox', onTap: () {}),
          ),
        ),
      );
      expect(find.byType(MeridianCheckboxMark), findsNothing);
      expect(
        tester.getSemantics(find.byType(MeridianListRow)),
        matchesSemantics(
          label: 'Inbox',
          isButton: true,
          hasCheckedState: false,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('the mark sits before leading and the title', (tester) async {
      await tester.pumpWidget(host(const _Checklist()));
      final mark = tester.getRect(find.byType(MeridianCheckboxMark));
      final glyph = tester.getRect(find.byType(MeridianIcon).last);
      expect(mark.width, MeridianLayout.checkboxSize);
      expect(glyph.left - mark.right, MeridianSpace.space4);
      expect(
        tester.getTopLeft(find.text('lib/src/components/navigation.dart')).dx,
        greaterThan(glyph.right),
      );
      expect(_mark(tester).checked, isFalse);
    });

    testWidgets('a pointer tap calls onTap and the caller toggles', (
      tester,
    ) async {
      await tester.pumpWidget(host(const _Checklist()));
      await tester.tap(find.text('lib/src/components/navigation.dart'));
      await tester.pumpAndSettle();
      expect(_state(tester).taps, 1);
      expect(_mark(tester).checked, isTrue);
      await tester.tap(find.byType(MeridianCheckboxMark));
      await tester.pumpAndSettle();
      expect(_state(tester).taps, 2);
      expect(_mark(tester).checked, isFalse);
    });

    testWidgets('Space and Enter toggle; the mark is no extra focus stop', (
      tester,
    ) async {
      var next = 0;
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Checklist(),
              SizedBox(
                width: 400,
                child: MeridianListRow(title: 'Next', onTap: () => next++),
              ),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(_state(tester).taps, 1);
      expect(_mark(tester).checked, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_state(tester).taps, 2);
      expect(_mark(tester).checked, isFalse);
      // One Tab leaves the row for the next one: the mark takes no focus.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(next, 1);
      expect(_state(tester).taps, 2);
    });

    testWidgets('a disabled row ignores input and fades the mark', (
      tester,
    ) async {
      await tester.pumpWidget(host(const _Checklist(enabled: false)));
      await tester.tap(find.text('lib/src/components/navigation.dart'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(_state(tester).taps, 0);
      expect(_mark(tester).checked, isFalse);
      expect(_mark(tester).enabled, isFalse);
    });

    testWidgets('semantics expose checked, not button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const _Checklist()));
      Finder row() => find.byType(MeridianListRow);
      expect(
        tester.getSemantics(row()),
        matchesSemantics(
          label: 'lib/src/components/navigation.dart, Modified, +12 -3',
          hasCheckedState: true,
          isChecked: false,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.text('lib/src/components/navigation.dart'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(row()),
        matchesSemantics(
          label: 'lib/src/components/navigation.dart, Modified, +12 -3',
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a narrow row keeps the mark and ellipsizes the text', (
      tester,
    ) async {
      await tester.pumpWidget(host(const _Checklist(width: 180)));
      expect(tester.takeException(), isNull);
      final title = tester.renderObject<RenderParagraph>(
        find.text('lib/src/components/navigation.dart'),
      );
      expect(title.didExceedMaxLines, isTrue);
      expect(
        tester.getSize(find.byType(MeridianCheckboxMark)).width,
        MeridianLayout.checkboxSize,
      );
      await tester.tap(find.byType(MeridianCheckboxMark));
      await tester.pumpAndSettle();
      expect(_state(tester).taps, 1);
    });

    testWidgets('touch density keeps the row extent and toggles', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const _Checklist(width: 360), density: MeridianDensity.touch),
      );
      final row = tester.getSize(find.byType(MeridianListRow));
      expect(row.height, greaterThanOrEqualTo(MeridianDensity.touch.rowExtent));
      expect(row.height, greaterThanOrEqualTo(kMinInteractiveDimension));
      await tester.tap(find.text('lib/src/components/navigation.dart'));
      await tester.pumpAndSettle();
      expect(_mark(tester).checked, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('on a strong selection the mark inverts to on-accent', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          MeridianSurfaceScope(
            focused: true,
            child: SizedBox(
              width: 360,
              child: MeridianListRow(
                title: 'Staged file',
                selected: true,
                checked: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final colors = colorsOf(tester);
      expect(_mark(tester).onAccent, isTrue);
      final check = tester.widget<MeridianIcon>(
        find.descendant(
          of: find.byType(MeridianCheckboxMark),
          matching: find.byType(MeridianIcon),
        ),
      );
      expect(check.color, colors.accent);
    });
  });
}
