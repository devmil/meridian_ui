import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

const _ink = Color(0xFF18304F);
const _berry = Color(0xFF943A55);

Finder get _wheel => find.bySemanticsLabel('Hue and saturation');
Finder get _hex => find.byType(EditableText);

Widget _picker({
  required double width,
  MeridianColorPickerLayout layout = MeridianColorPickerLayout.auto,
}) => SizedBox(
  width: width,
  child: SingleChildScrollView(
    child: MeridianColorPicker(color: _ink, layout: layout, onChanged: (_) {}),
  ),
);

/// Whether the wheel stands beside the hex field rather than above it.
bool _wheelBeside(WidgetTester tester) {
  final wheel = tester.getRect(_wheel);
  final hex = tester.getRect(_hex);
  return hex.left >= wheel.right && hex.top < wheel.bottom;
}

/// A well that keeps the custom colour the way an app does.
class _Well extends StatefulWidget {
  const _Well({this.initial, this.enabled = true, this.changes, this.ends});

  final Color? initial;
  final bool enabled;
  final List<Color>? changes;
  final List<Color>? ends;

  @override
  State<_Well> createState() => _WellState();
}

class _WellState extends State<_Well> {
  late Color? _color = widget.initial;

  @override
  Widget build(BuildContext context) => MeridianColorWell(
    color: _color,
    label: 'Custom colour',
    initial: _berry,
    selected: _color != null,
    groups: const [
      MeridianColorGroup(
        title: 'Palette',
        colors: [_ink, _berry],
        labels: ['Ink', 'Berry'],
      ),
    ],
    onChanged: widget.enabled
        ? (color) {
            widget.changes?.add(color);
            setState(() => _color = color);
          }
        : null,
    onChangeEnd: widget.ends?.add,
  );
}

void main() {
  group('colour picker layout', () {
    testWidgets('a desktop picker puts its wheel beside the controls '
        'where there is room', (tester) async {
      await tester.pumpWidget(host(_picker(width: 480)));
      expect(_wheelBeside(tester), isTrue);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(host(_picker(width: 360)));
      await tester.pumpAndSettle();
      expect(_wheelBeside(tester), isFalse);
      expect(tester.getRect(_wheel).bottom, lessThan(tester.getRect(_hex).top));
    });

    testWidgets('touch density keeps the wheel above the controls', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(_picker(width: 600), density: MeridianDensity.touch),
      );
      expect(_wheelBeside(tester), isFalse);
    });

    testWidgets('an explicit layout wins over the width', (tester) async {
      await tester.pumpWidget(
        host(_picker(width: 600, layout: MeridianColorPickerLayout.stacked)),
      );
      expect(_wheelBeside(tester), isFalse);

      await tester.pumpWidget(
        host(_picker(width: 360, layout: MeridianColorPickerLayout.wide)),
      );
      await tester.pumpAndSettle();
      expect(_wheelBeside(tester), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the wide layout follows a right-to-left reading', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(_picker(width: 480), textDirection: TextDirection.rtl),
      );
      expect(
        tester.getRect(_hex).right,
        lessThanOrEqualTo(tester.getRect(_wheel).left),
      );
    });

    testWidgets('the wide layout fits enlarged text', (tester) async {
      await tester.pumpWidget(host(_picker(width: 480), textScale: 2));
      expect(tester.takeException(), isNull);
    });
  });

  group('colour well', () {
    testWidgets('without a colour it offers a new one and opens a picker '
        'starting from the initial colour', (tester) async {
      final changes = <Color>[];
      final ends = <Color>[];
      await tester.pumpWidget(host(_Well(changes: changes, ends: ends)));
      expect(
        find.descendant(
          of: find.byType(MeridianColorWell),
          matching: find.byType(MeridianIcon),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byType(MeridianColorWell));
      await tester.pumpAndSettle();
      expect(find.byType(MeridianColorPicker), findsOneWidget);
      expect(tester.widget<EditableText>(_hex).controller.text, '#943A55');

      await tester.tap(findTooltip('Ink'));
      await tester.pumpAndSettle();
      expect(changes, [_ink]);
      expect(ends, [_ink]);
      // The well shows the colour at once, while the popover stays open.
      expect(find.byType(MeridianColorPicker), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MeridianColorWell),
          matching: find.byType(MeridianIcon),
        ),
        findsNothing,
      );
    });

    testWidgets('Escape closes the popover and focus returns to the well', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(
          MeridianColorWell(
            color: _ink,
            label: 'Custom colour',
            focusNode: focus,
            onChanged: (_) {},
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(MeridianColorPicker), findsOneWidget);
      expect(tester.widget<EditableText>(_hex).controller.text, '#18304F');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(MeridianColorPicker), findsNothing);
      expect(focus.hasFocus, isTrue);
    });

    testWidgets('it announces its name, colour and choice', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(const _Well(initial: _ink)));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Custom colour')),
        matchesSemantics(
          label: 'Custom colour',
          value: '#18304F',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('a disabled well opens nothing', (tester) async {
      await tester.pumpWidget(host(const _Well(enabled: false)));
      await tester.tap(find.byType(MeridianColorWell), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(MeridianColorPicker), findsNothing);
    });

    testWidgets('the popover fits a touch density', (tester) async {
      await tester.pumpWidget(
        host(const _Well(initial: _ink), density: MeridianDensity.touch),
      );
      await tester.tap(find.byType(MeridianColorWell));
      await tester.pumpAndSettle();
      expect(find.byType(MeridianColorPicker), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MeridianColorWell)).width,
        greaterThanOrEqualTo(MeridianLayout.swatchSizeTouch),
      );
    });
  });
}
