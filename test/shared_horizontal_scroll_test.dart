import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  group('MeridianSharedHorizontalScroll', () {
    Future<ScrollController> pump(
      WidgetTester tester, {
      required double contentWidth,
    }) async {
      final vertical = ScrollController();
      final horizontal = ScrollController();
      addTearDown(vertical.dispose);
      addTearDown(horizontal.dispose);
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            height: 240,
            child: MeridianSharedHorizontalScroll(
              controller: horizontal,
              contentWidth: contentWidth,
              child: ListView.builder(
                key: const ValueKey('rows'),
                controller: vertical,
                itemExtent: 24,
                itemCount: 40,
                itemBuilder: (context, index) => MeridianHorizontalShift(
                  controller: horizontal,
                  child: Text('Row $index'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return vertical;
    }

    testWidgets('keeps the last row above the horizontal scrollbar', (
      tester,
    ) async {
      final vertical = await pump(tester, contentWidth: 900);
      final rows = find.byKey(const ValueKey('rows'));
      expect(tester.getSize(rows).height, 240 - MeridianLayout.scrollbarGutter);

      vertical.jumpTo(vertical.position.maxScrollExtent);
      await tester.pumpAndSettle();
      final last = find.text('Row 39');
      expect(
        tester.getBottomLeft(last).dy,
        lessThanOrEqualTo(tester.getBottomLeft(rows).dy),
      );
    });

    testWidgets('gives the rows the full height when the text fits', (
      tester,
    ) async {
      await pump(tester, contentWidth: 100);
      expect(tester.getSize(find.byKey(const ValueKey('rows'))).height, 240);
    });
  });
}
