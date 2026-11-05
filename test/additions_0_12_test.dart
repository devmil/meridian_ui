import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

/// Holds the picked colour the way an app does.
class _Picker extends StatefulWidget {
  const _Picker({
    required this.initial,
    this.enabled = true,
    this.original,
    this.groups = const [],
    this.changes,
    this.ends,
  });

  final Color initial;
  final bool enabled;
  final Color? original;
  final List<MeridianColorGroup> groups;
  final List<Color>? changes;
  final List<Color>? ends;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  late Color _color = widget.initial;

  @override
  Widget build(BuildContext context) => MeridianColorPicker(
    color: _color,
    original: widget.original,
    groups: widget.groups,
    onChanged: widget.enabled
        ? (color) {
            widget.changes?.add(color);
            setState(() => _color = color);
          }
        : null,
    onChangeEnd: widget.ends?.add,
  );
}

Widget _sized(Widget child, {double width = 360}) => SizedBox(
  width: width,
  child: SingleChildScrollView(child: child),
);

Finder get _wheel => find.bySemanticsLabel('Hue and saturation');

HSVColor _hsv(Color color) => HSVColor.fromColor(color);

void main() {
  const ink = Color(0xFF18304F);
  const berry = Color(0xFF943A55);

  testWidgets('a swatch picks its colour and ends the change', (tester) async {
    final changes = <Color>[];
    final ends = <Color>[];
    await tester.pumpWidget(
      host(
        _sized(
          _Picker(
            initial: ink,
            changes: changes,
            ends: ends,
            groups: const [
              MeridianColorGroup(
                title: 'Palette',
                colors: [ink, berry],
                labels: ['Ink', 'Berry'],
              ),
              MeridianColorGroup(title: 'Empty', colors: []),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Palette'), findsOneWidget);
    expect(find.text('Empty'), findsNothing);
    await tester.tap(find.byTooltip('Berry'));
    await tester.pumpAndSettle();
    expect(changes.single.toARGB32(), berry.toARGB32());
    expect(ends.single.toARGB32(), berry.toARGB32());
    expect(find.text('#943A55'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the picker keeps the alpha of its colour', (tester) async {
    final ends = <Color>[];
    await tester.pumpWidget(
      host(
        _sized(
          _Picker(
            initial: const Color(0x8018304F),
            ends: ends,
            groups: const [
              MeridianColorGroup(title: 'Palette', colors: [berry]),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Colour #943A55'));
    await tester.pumpAndSettle();
    expect(ends.single.toARGB32(), 0x80943A55);
  });

  testWidgets('a drag on the wheel sets hue and saturation, not the scroll', (
    tester,
  ) async {
    final changes = <Color>[];
    final ends = <Color>[];
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 360,
          height: 300,
          child: SingleChildScrollView(
            child: _Picker(initial: ink, changes: changes, ends: ends),
          ),
        ),
      ),
    );
    final scroll = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    final wheel = tester.getRect(_wheel);
    expect(wheel.width, MeridianLayout.colorWheel);
    // From the centre (white) straight down: hue 90, full saturation.
    final gesture = await tester.startGesture(wheel.center);
    await gesture.moveBy(const Offset(0, 40));
    await gesture.moveTo(wheel.bottomCenter + const Offset(0, 20));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(scroll.pixels, 0);
    final picked = _hsv(changes.last);
    expect(picked.hue, closeTo(90, .5));
    expect(picked.saturation, 1);
    expect(picked.value, closeTo(_hsv(ink).value, .01));
    expect(ends, isNotEmpty);
  });

  testWidgets('arrow keys turn the wheel by one degree and one percent', (
    tester,
  ) async {
    final ends = <Color>[];
    await tester.pumpWidget(host(_sized(_Picker(initial: berry, ends: ends))));
    final before = _hsv(berry);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    // The wheel follows the swatch-less top of the picker.
    final focused = FocusManager.instance.primaryFocus!;
    expect(focused.debugLabel, 'meridian-color-wheel');
    await tester.pumpAndSettle();
    expect(ringVisible(tester, find.byType(MeridianColorPicker)), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    debugPrint('ENDS $ends');
    debugPrint(
      'TEXTS ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList()}',
    );
    expect(ends, hasLength(2));
    // The picker keeps the exact hue; the 8-bit colour only approximates
    // a one-degree step.
    expect(find.text('${(before.hue + 1).round()}°'), findsOneWidget);
    expect(
      find.text('${((before.saturation - .01) * 100).round()}%'),
      findsOneWidget,
    );
  });

  testWidgets('hex entry sets the colour; an invalid one shows an error', (
    tester,
  ) async {
    final changes = <Color>[];
    final ends = <Color>[];
    await tester.pumpWidget(
      host(_sized(_Picker(initial: ink, changes: changes, ends: ends))),
    );
    final field = find.byType(EditableText);
    await tester.enterText(field, '#0b6477');
    await tester.pump();
    expect(changes.last.toARGB32(), 0xFF0B6477);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(ends.last.toARGB32(), 0xFF0B6477);
    await tester.enterText(field, '#0b64');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Enter six hex digits, such as #18304F'), findsOneWidget);
    expect(ends, hasLength(1));
    // Three digits stand for six.
    await tester.enterText(field, 'f80');
    await tester.pump();
    expect(changes.last.toARGB32(), 0xFFFF8800);
  });

  testWidgets('a grey keeps the hue the wheel was turned to', (tester) async {
    final changes = <Color>[];
    await tester.pumpWidget(
      host(_sized(_Picker(initial: berry, changes: changes))),
    );
    final hue = _hsv(berry).hue;
    await tester.enterText(find.byType(EditableText), '#808080');
    await tester.pump();
    final state = tester.state(find.byType(MeridianColorPicker));
    expect(changes.last.toARGB32(), 0xFF808080);
    // The hue slider still reads the berry's hue.
    expect(
      find.text('${hue.round()}°'),
      findsOneWidget,
      reason: state.toString(),
    );
  });

  testWidgets('RGB sliders step one unit from the keyboard', (tester) async {
    final ends = <Color>[];
    await tester.pumpWidget(host(_sized(_Picker(initial: ink, ends: ends))));
    await tester.tap(find.text('RGB'));
    await tester.pumpAndSettle();
    expect(find.text('Red'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    final red = find.byWidgetPredicate(
      (widget) => widget is MeridianSlider && widget.label == 'Red',
    );
    tester
        .widget<FocusableActionDetector>(
          find.descendant(
            of: red,
            matching: find.byType(FocusableActionDetector),
          ),
        )
        .focusNode!
        .requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(ends.last.toARGB32(), 0xFF19304F);
    expect(find.text('25'), findsOneWidget);
  });

  testWidgets('the original colour restores on a tap', (tester) async {
    final ends = <Color>[];
    await tester.pumpWidget(
      host(_sized(_Picker(initial: berry, original: ink, ends: ends))),
    );
    await tester.tap(find.byTooltip('Original colour'));
    await tester.pump();
    expect(ends.single.toARGB32(), ink.toARGB32());
  });

  testWidgets('a disabled picker takes no input', (tester) async {
    final ends = <Color>[];
    await tester.pumpWidget(
      host(
        _sized(
          _Picker(
            initial: ink,
            enabled: false,
            ends: ends,
            groups: const [
              MeridianColorGroup(title: 'Palette', colors: [berry]),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Colour #943A55'), warnIfMissed: false);
    await tester.tap(_wheel, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(ends, isEmpty);
    expect(
      tester.widget<MeridianTextField>(find.byType(MeridianTextField)).enabled,
      isFalse,
    );
  });

  for (final width in [220.0, 420.0]) {
    testWidgets('touch density fits $width px at 200% text', (tester) async {
      await tester.pumpWidget(
        host(
          _sized(
            const _Picker(
              initial: berry,
              original: ink,
              groups: [
                MeridianColorGroup(
                  title: 'Zuletzt verwendet',
                  colors: [ink, berry, ink, berry, ink, berry, ink, berry],
                ),
              ],
            ),
            width: width,
          ),
          density: MeridianDensity.touch,
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(_wheel).width,
        width < MeridianLayout.colorWheelTouch
            ? width
            : MeridianLayout.colorWheelTouch,
      );
      for (final slider in tester.widgetList(find.byType(MeridianSlider))) {
        expect(
          tester.getSize(find.byWidget(slider)).height,
          greaterThanOrEqualTo(48),
        );
      }
    });
  }

  testWidgets('a gradient track follows a right-to-left slider', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 200,
          child: MeridianSlider(
            label: 'Red',
            value: 10,
            max: 255,
            track: const LinearGradient(
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: [Color(0xFF000000), Color(0xFFFF0000)],
            ),
            onChanged: (_) {},
          ),
        ),
        textDirection: TextDirection.rtl,
      ),
    );
    final track = tester.widget<Container>(
      find.descendant(
        of: find.byType(MeridianSlider),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              (widget.decoration as BoxDecoration?)?.gradient != null,
        ),
      ),
    );
    expect(
      tester.getSize(find.byWidget(track)).height,
      MeridianLayout.sliderColorTrack,
    );
    expect(tester.takeException(), isNull);
  });
}
