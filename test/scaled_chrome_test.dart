import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  for (final density in MeridianDensity.values) {
    for (final size in MeridianControlSize.values) {
      for (final enabled in [true, false]) {
        testWidgets('button line fits 200% text $density $size $enabled', (
          tester,
        ) async {
          var calls = 0;
          await tester.pumpWidget(
            host(
              SizedBox(
                width: 320,
                child: MeridianButton(
                  label: 'Änderungen speichern',
                  size: size,
                  icon: MeridianIcons.save,
                  onPressed: enabled ? () => calls++ : null,
                ),
              ),
              density: density,
              textScale: 2,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final label = find.text('Änderungen speichern');
          final paragraph = tester.renderObject<RenderParagraph>(label);
          final intrinsicHeight = paragraph.getMaxIntrinsicHeight(
            paragraph.size.width,
          );
          expect(paragraph.size.height, greaterThanOrEqualTo(intrinsicHeight));
          final control = tester.getRect(find.byType(MeridianButton));
          final text = tester.getRect(label);
          expect(text.top, greaterThanOrEqualTo(control.top));
          expect(text.bottom, lessThanOrEqualTo(control.bottom));
          await tester.tap(find.byType(MeridianButton));
          await tester.pumpAndSettle();
          expect(calls, enabled ? 1 : 0);
        });
      }
    }
  }

  testWidgets('status bar grows to fit enlarged text and small controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 720,
          child: MeridianStatusBar(
            leading: [
              MeridianButton(
                label: '100 %',
                size: MeridianControlSize.small,
                onPressed: () {},
              ),
            ],
            trailing: const [Text('Änderungen gespeichert')],
          ),
        ),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final bar = tester.getRect(find.byType(MeridianStatusBar));
    for (final label in ['100 %', 'Änderungen gespeichert']) {
      final finder = find.text(label);
      final paragraph = tester.renderObject<RenderParagraph>(finder);
      expect(
        paragraph.size.height,
        greaterThanOrEqualTo(
          paragraph.getMaxIntrinsicHeight(paragraph.size.width),
        ),
      );
      expect(tester.getRect(finder).top, greaterThanOrEqualTo(bar.top));
      expect(tester.getRect(finder).bottom, lessThanOrEqualTo(bar.bottom));
    }
    expect(bar.height, greaterThan(MeridianLayout.statusBarHeight));
  });
}
