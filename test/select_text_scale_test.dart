import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  for (final density in [MeridianDensity.regular, MeridianDensity.touch]) {
    for (final size in MeridianControlSize.values) {
      for (final expanded in [false, true]) {
        testWidgets(
          'scaled Select glyphs fit at $density $size expanded=$expanded',
          (tester) async {
            var presented = 0;
            const value = 'WebP (verlustbehaftet)';
            await tester.pumpWidget(
              host(
                SizedBox(
                  width: 220,
                  child: MeridianMenuPresenter(
                    present: (_, {required anchor, required entries}) async {
                      presented++;
                    },
                    child: MeridianSelect<String>(
                      value: value,
                      values: const [value, 'PNG'],
                      valueLabel: (value) => value,
                      label: 'Format',
                      showLabel: true,
                      size: size,
                      expand: expanded,
                      onChanged: (_) {},
                    ),
                  ),
                ),
                density: density,
                textScale: 2,
              ),
            );
            final paragraph = tester.renderObject<RenderParagraph>(
              find.text(value),
            );
            final boxes = paragraph.getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: value.length),
            );
            expect(boxes, isNotEmpty);
            for (final box in boxes) {
              expect(box.top, greaterThanOrEqualTo(0));
              expect(box.bottom, lessThanOrEqualTo(paragraph.size.height));
            }
            final trigger = find.byType(MeridianInteraction);
            await tester.tap(trigger);
            await tester.pumpAndSettle();
            expect(presented, 1);
            await tester.sendKeyEvent(LogicalKeyboardKey.space);
            await tester.pumpAndSettle();
            expect(presented, 2);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
  testWidgets('disabled scaled Select remains readable and inert', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        MeridianSelect<String>(
          value: 'JPEG',
          values: const ['JPEG', 'PNG'],
          valueLabel: (value) => value,
          onChanged: null,
        ),
        textScale: 2,
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(find.text('JPEG'));
    final boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 4),
    );
    expect(boxes.single.bottom, lessThanOrEqualTo(paragraph.size.height));
    await tester.tap(find.byType(MeridianInteraction));
    await tester.pumpAndSettle();
    expect(find.byType(MeridianMenuSurface), findsNothing);
  });
}
