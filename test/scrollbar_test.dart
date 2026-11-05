import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  group('MeridianScrollbar', () {
    Future<ScrollController> pumpList(
      WidgetTester tester, {
      MeridianScrollbarVisibility visibility =
          MeridianScrollbarVisibility.hover,
      int rows = 60,
      MeridianDensity? density,
    }) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          density: density,
          SizedBox(
            width: 200,
            height: 240,
            child: MeridianScrollbar(
              controller: controller,
              visibility: visibility,
              child: ListView.builder(
                controller: controller,
                itemExtent: 24,
                itemCount: rows,
                itemBuilder: (context, index) => Text('Row $index'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return controller;
    }

    // The thumb is the only rounded rectangle below the scrollbar.
    final thumb = paints..rrect();

    Future<TestGesture> pointer(WidgetTester tester) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      return gesture;
    }

    testWidgets('shows the thumb while the pointer is over the view', (
      tester,
    ) async {
      await pumpList(tester);
      expect(find.byType(Scrollbar), isNot(thumb));
      // Only this scrollbar: the platform adds none below it.
      expect(find.byType(Scrollbar), findsOneWidget);

      final gesture = await pointer(tester);
      await gesture.moveTo(tester.getCenter(find.byType(ListView)));
      await tester.pumpAndSettle();
      expect(find.byType(Scrollbar), thumb);

      await gesture.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(find.byType(Scrollbar), isNot(thumb));
    }, variant: TargetPlatformVariant.desktop());

    testWidgets(
      'shows the thumb while the view scrolls and hides it afterwards',
      (tester) async {
        final controller = await pumpList(tester);
        controller.jumpTo(120);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(Scrollbar), thumb);

        await tester.pumpAndSettle(const Duration(seconds: 1));
        expect(find.byType(Scrollbar), isNot(thumb));
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets('scrolling visibility ignores the pointer', (tester) async {
      await pumpList(tester, visibility: MeridianScrollbarVisibility.scrolling);
      final gesture = await pointer(tester);
      await gesture.moveTo(tester.getCenter(find.byType(ListView)));
      await tester.pumpAndSettle();
      expect(find.byType(Scrollbar), isNot(thumb));
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('always visibility keeps the thumb', (tester) async {
      await pumpList(tester, visibility: MeridianScrollbarVisibility.always);
      expect(find.byType(Scrollbar), thumb);
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('a view that fits shows no thumb', (tester) async {
      await pumpList(tester, rows: 3);
      final gesture = await pointer(tester);
      await gesture.moveTo(tester.getCenter(find.byType(ListView)));
      await tester.pumpAndSettle();
      expect(find.byType(Scrollbar), isNot(thumb));
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('touch density shows the thumb while a finger scrolls', (
      tester,
    ) async {
      await pumpList(tester, density: MeridianDensity.touch);
      expect(find.byType(Scrollbar), isNot(thumb));
      final drag = await tester.startGesture(
        tester.getCenter(find.byType(ListView)),
      );
      await drag.moveBy(const Offset(0, -80));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(Scrollbar), thumb);
      await drag.up();
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  });
}
