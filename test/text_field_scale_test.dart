import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  for (final density in [MeridianDensity.regular, MeridianDensity.touch]) {
    for (final size in MeridianControlSize.values) {
      for (final scale in [1.0, 1.25, 2.0]) {
        testWidgets('$density $size scale=$scale fits editable line', (
          tester,
        ) async {
          final controller = TextEditingController(text: 'Größe 20,5');
          addTearDown(controller.dispose);
          await tester.pumpWidget(
            host(
              MeridianTextField(
                controller: controller,
                label: 'Größe',
                showLabel: false,
                width: 120,
                size: size,
              ),
              density: density,
              textScale: scale,
            ),
          );
          final editable = tester.state<EditableTextState>(
            find.byType(EditableText),
          );
          final line = editable.renderEditable;
          expect(
            line.size.height,
            greaterThanOrEqualTo(line.preferredLineHeight),
          );
          expect(tester.takeException(), isNull);
          if (scale == 1) {
            final minimum = size == MeridianControlSize.small
                ? density.controlSmallExtent
                : density.controlExtent;
            expect(
              tester.getSize(find.byType(MeridianTextField)).height,
              minimum,
            );
          }
          await tester.tap(find.byType(EditableText));
          await tester.enterText(find.byType(EditableText), '23,5');
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
          expect(controller.text, '23,5');
          expect(controller.selection.baseOffset, 3);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
  testWidgets(
    'explicit short height cannot clip a custom style; disabled stays inert',
    (tester) async {
      var changes = 0;
      await tester.pumpWidget(
        host(
          MeridianTextField(
            label: 'Value',
            showLabel: false,
            width: 120,
            height: 22,
            textStyle: const TextStyle(fontSize: 20, height: 1.5),
            enabled: false,
            onChanged: (_) => changes++,
          ),
          textScale: 2,
        ),
      );
      final line = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      expect(line.size.height, greaterThanOrEqualTo(line.preferredLineHeight));
      await tester.tap(find.byType(EditableText));
      expect(
        FocusManager.instance.primaryFocus?.context?.widget,
        isNot(isA<EditableText>()),
      );
      expect(changes, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
