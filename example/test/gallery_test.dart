import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_gallery/main.dart';

const lastSection = 'Documents: canvas, paper and tool dock';

/// Scrolls the page end to end so every section is built and laid out.
Future<void> scrollThrough(WidgetTester tester) async {
  // The page's own scrollable; its position can be replaced while scrolling.
  ScrollPosition position() => tester
      .state<ScrollableState>(
        find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      )
      .position;
  // Step to the end, however long the page grows at narrow widths. Jumps,
  // not drags: a drag can land on a nested scroller and stall the page.
  for (var i = 0; i < 200; i++) {
    final page = position();
    if (page.pixels >= page.maxScrollExtent) break;
    page.jumpTo(math.min(page.pixels + 400, page.maxScrollExtent));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
  }
  // The last section must have been reached, or overflow there goes unseen.
  expect(position().pixels, position().maxScrollExtent);
  expect(find.text(lastSection), findsOneWidget);
  position().jumpTo(0);
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  for (final size in const [Size(390, 844), Size(1280, 900)]) {
    testWidgets('the gallery lays out at ${size.width.round()}px in regular '
        'and touch density', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MeridianGalleryApp());
      // Spinners and an indeterminate bar run forever: pump, not settle.
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      await scrollThrough(tester);

      await tester.ensureVisible(find.text('regular'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('regular'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('touch'));
      // Menu results precede reverse-animation completion. Selection dispatch
      // now waits for overlay removal, followed by the rebuilt density label.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.text('touch'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await scrollThrough(tester);
    });
  }
}
