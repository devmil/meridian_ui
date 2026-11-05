import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';
import 'support.dart';

void main() {
  for (final density in [MeridianDensity.regular, MeridianDensity.touch]) {
    for (final size in MeridianControlSize.values) {
      for (final scale in [1.0, 1.25, 2.0]) {
        testWidgets('scaled Segmented labels fit at $density $size x$scale', (
          tester,
        ) async {
          var value = 'all';
          await tester.pumpWidget(
            host(
              StatefulBuilder(
                builder: (context, setState) => MeridianSegmented<String>(
                  label: 'Show',
                  value: value,
                  size: size,
                  segments: const [
                    MeridianSegment(value: 'all', label: 'All'),
                    MeridianSegment(value: 'background', label: 'Background'),
                  ],
                  onChanged: (next) => setState(() => value = next),
                ),
              ),
              density: density,
              textScale: scale,
            ),
          );
          for (final label in ['All', 'Background']) {
            final paragraph = tester.renderObject<RenderParagraph>(
              find.text(label),
            );
            final boxes = paragraph.getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: label.length),
            );
            expect(boxes, isNotEmpty);
            for (final box in boxes) {
              expect(box.top, greaterThanOrEqualTo(0));
              expect(box.bottom, lessThanOrEqualTo(paragraph.size.height));
            }
          }
          await tester.tap(find.text('Background'));
          await tester.pumpAndSettle();
          expect(value, 'background');
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('unscaled Segmented keeps the density extent', (tester) async {
    await tester.pumpWidget(
      host(
        Align(
          alignment: Alignment.topLeft,
          child: MeridianSegmented<String>(
            label: 'Show',
            value: 'all',
            size: MeridianControlSize.small,
            segments: const [MeridianSegment(value: 'all', label: 'All')],
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(MeridianSegmented<String>)).height,
      MeridianSize.controlSm,
    );
  });
}
