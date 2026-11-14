import 'dart:ui' show SemanticsAction;

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('independent keyboard handles and bounds in $direction', (
      tester,
    ) async {
      var values = const MeridianRangeValues(2, 8);
      final commits = <MeridianRangeValues>[];
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, set) => host(
            SizedBox(
              width: 212,
              child: MeridianRangeSlider(
                startLabel: 'Start',
                endLabel: 'End',
                values: values,
                max: 10,
                step: 1,
                onChanged: (value) => set(() => values = value),
                onChangeEnd: commits.add,
              ),
            ),
            textDirection: direction,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(
        direction == TextDirection.ltr
            ? LogicalKeyboardKey.arrowRight
            : LogicalKeyboardKey.arrowLeft,
      );
      await tester.pump();
      expect(values, const MeridianRangeValues(3, 8));
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(values, const MeridianRangeValues(8, 8));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(values, const MeridianRangeValues(8, 10));
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(values, const MeridianRangeValues(8, 8));
      expect(commits.last, values);
      expect(commits, hasLength(4));
    });
  }

  testWidgets(
    'pointer chooses nearest endpoint and commits actual final value',
    (tester) async {
      final changes = <MeridianRangeValues>[];
      final commits = <MeridianRangeValues>[];
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 212,
            child: MeridianRangeSlider(
              startLabel: 'Start',
              endLabel: 'End',
              values: const MeridianRangeValues(0.2, 0.8),
              onChanged: changes.add,
              onChangeEnd: commits.add,
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(MeridianRangeSlider));
      await tester.dragFrom(
        rect.centerLeft + const Offset(46, 0),
        const Offset(200, 0),
      );
      await tester.pump();
      expect(changes, isNotEmpty);
      expect(changes.every((values) => values.start <= values.end), isTrue);
      expect(commits.single, const MeridianRangeValues(0.8, 0.8));
      await tester.tapAt(rect.centerLeft + const Offset(190, 0));
      await tester.pump();
      expect(commits.last.start, 0.2);
      expect(commits.last.end, closeTo(0.92, 0.01));
    },
  );

  testWidgets('each endpoint exposes independent semantic steps', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var values = const MeridianRangeValues(2, 8);
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, set) => host(
            SizedBox(
              width: 212,
              child: MeridianRangeSlider(
                startLabel: 'Start',
                endLabel: 'End',
                values: values,
                max: 10,
                step: 1,
                valueLabel: (value) => '${value.round()} seconds',
                onChanged: (value) => set(() => values = value),
              ),
            ),
          ),
        ),
      );
      final start = tester.getSemantics(find.bySemanticsLabel('Start'));
      final end = tester.getSemantics(find.bySemanticsLabel('End'));
      expect(start.value, '2 seconds');
      expect(end.value, '8 seconds');
      tester
          .element(find.byType(MeridianRangeSlider))
          .renderObject!
          .owner!
          .semanticsOwner!
          .performAction(start.id, SemanticsAction.increase);
      await tester.pump();
      expect(values, const MeridianRangeValues(3, 8));
      tester
          .element(find.byType(MeridianRangeSlider))
          .renderObject!
          .owner!
          .semanticsOwner!
          .performAction(end.id, SemanticsAction.decrease);
      await tester.pump();
      expect(values, const MeridianRangeValues(3, 7));
    } finally {
      semantics.dispose();
    }
  });

  for (final zero in [false, true]) {
    testWidgets('disabled input zero span=$zero', (tester) async {
      final changes = <MeridianRangeValues>[];
      await tester.pumpWidget(
        host(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MeridianRangeSlider(
                startLabel: 'Start',
                endLabel: 'End',
                values: MeridianRangeValues(zero ? 1 : 0.2, zero ? 1 : 0.8),
                min: zero ? 1 : 0,
                max: 1,
                onChanged: zero ? changes.add : null,
              ),
            ],
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(MeridianRangeSlider)).width,
        MeridianLayout.sliderDefaultWidth,
      );
      await tester.tap(find.byType(MeridianRangeSlider));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(changes, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'coincident endpoints retain focused endpoint and pointer snapping',
    (tester) async {
      var values = const MeridianRangeValues(0.5, 0.5);
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, set) => host(
            SizedBox(
              width: 212,
              child: MeridianRangeSlider(
                startLabel: 'Start',
                endLabel: 'End',
                values: values,
                step: 0.1,
                onChanged: (value) => set(() => values = value),
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final rect = tester.getRect(find.byType(MeridianRangeSlider));
      await tester.dragFrom(rect.center, const Offset(67, 0));
      await tester.pump();
      expect(values.start, 0.5);
      expect(values.end, closeTo(0.8, 0.00001));
    },
  );

  testWidgets('touch endpoints expose minimum semantic target extent', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 212,
            child: MeridianRangeSlider(
              startLabel: 'Start',
              endLabel: 'End',
              values: const MeridianRangeValues(0, 1),
              onChanged: (_) {},
            ),
          ),
          brand: MeridianBrands.nibluma,
        ),
      );
      for (final label in ['Start', 'End']) {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(node.rect.width, greaterThanOrEqualTo(48));
        expect(node.rect.height, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
