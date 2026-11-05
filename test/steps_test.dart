import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

const _steps = [
  MeridianStep(label: 'Pick', key: ValueKey('pick')),
  MeridianStep(label: 'Review', key: ValueKey('review')),
  MeridianStep(label: 'Resolve', key: ValueKey('resolve')),
  MeridianStep(label: 'Continue', key: ValueKey('continue')),
];

Future<void> _pump(
  WidgetTester tester, {
  int current = 1,
  double? width,
  MeridianDensity? density,
  double textScale = 1,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  Widget steps = MeridianSteps(
    steps: _steps,
    current: current,
    semanticLabel: 'Resolve conflicts',
  );
  if (width != null) steps = SizedBox(width: width, child: steps);
  await tester.pumpWidget(
    host(
      steps,
      density: density,
      textScale: textScale,
      textDirection: textDirection,
    ),
  );
}

/// Whether [text] is painted (a hidden label is laid out at zero size and
/// skipped).
bool _labelShown(WidgetTester tester, String text) {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) return false;
  return tester.getSize(finder).width > 0;
}

void main() {
  testWidgets('shows every step with its marker and label', (tester) async {
    await _pump(tester);
    for (final step in _steps) {
      expect(_labelShown(tester, step.label), isTrue);
    }
    // The done step shows a check, the others their numbers.
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('styles done, current and upcoming steps', (tester) async {
    await _pump(tester);
    final colors = colorsOf(tester);
    expect(textColor(tester, 'Pick'), colors.inkMuted);
    expect(textColor(tester, 'Review'), colors.ink);
    expect(
      tester.widget<Text>(find.text('Review')).style?.fontWeight,
      FontWeight.w600,
    );
    expect(textColor(tester, 'Resolve'), colors.inkMuted);
    expect(textColor(tester, '2'), colors.onAccent);
    expect(textColor(tester, '3'), colors.inkMuted);
  });

  testWidgets('current = steps.length marks every step done', (tester) async {
    await _pump(tester, current: _steps.length);
    for (final number in ['1', '2', '3', '4']) {
      expect(find.text(number), findsNothing);
    }
    final colors = colorsOf(tester);
    for (final step in _steps) {
      expect(textColor(tester, step.label), colors.inkMuted);
    }
  });

  testWidgets('announces label, state and position of each step', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    expect(find.bySemanticsLabel('Resolve conflicts'), findsOneWidget);
    expect(find.bySemanticsLabel('Pick, done, 1 of 4'), findsOneWidget);
    expect(find.bySemanticsLabel('Review, current, 2 of 4'), findsOneWidget);
    expect(find.bySemanticsLabel('Resolve, upcoming, 3 of 4'), findsOneWidget);
    expect(find.bySemanticsLabel('Continue, upcoming, 4 of 4'), findsOneWidget);
    // Labels are not read twice.
    expect(find.bySemanticsLabel('Pick'), findsNothing);
    handle.dispose();
  });

  testWidgets('announces in German', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const MeridianLocalizationsScope(
          localizations: MeridianLocalizationsDe(),
          child: MeridianSteps(steps: _steps, current: 2),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Pick, erledigt, 1 von 4'), findsOneWidget);
    expect(find.bySemanticsLabel('Resolve, aktuell, 3 von 4'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Continue, ausstehend, 4 von 4'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('steps are not interactive', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    final node = tester.getSemantics(
      find.bySemanticsLabel('Review, current, 2 of 4'),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    expect(
      find.descendant(
        of: find.byType(MeridianSteps),
        matching: find.byType(GestureDetector),
      ),
      findsNothing,
    );
    handle.dispose();
  });

  testWidgets('step keys identify the markers', (tester) async {
    await _pump(tester);
    expect(find.byKey(const ValueKey('resolve')), findsOneWidget);
    final pick = tester.getCenter(find.byKey(const ValueKey('pick')));
    final resolve = tester.getCenter(find.byKey(const ValueKey('resolve')));
    expect(pick.dx, lessThan(resolve.dx));
  });

  testWidgets('narrow: hides the other labels and ellipsizes the current', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, width: 200);
    expect(tester.takeException(), isNull);
    expect(_labelShown(tester, 'Review'), isTrue);
    for (final label in ['Pick', 'Resolve', 'Continue']) {
      expect(_labelShown(tester, label), isFalse, reason: label);
    }
    // Hidden labels still announce through their markers.
    expect(find.bySemanticsLabel('Pick, done, 1 of 4'), findsOneWidget);
    expect(find.bySemanticsLabel('Continue, upcoming, 4 of 4'), findsOneWidget);
    expect(tester.getSize(find.byType(MeridianSteps)).width, lessThan(200.5));

    await _pump(tester, width: 140);
    expect(tester.takeException(), isNull);
    final review = tester.getSize(find.text('Review')).width;
    expect(review, lessThan(40));
    handle.dispose();
  });

  testWidgets('narrower than the markers clips without overflow', (
    tester,
  ) async {
    await _pump(tester, width: 60);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(MeridianSteps)).width, 60);
  });

  testWidgets('follows the reading direction', (tester) async {
    await _pump(tester, textDirection: TextDirection.rtl);
    final pick = tester.getCenter(find.byKey(const ValueKey('pick')));
    final resolve = tester.getCenter(find.byKey(const ValueKey('resolve')));
    expect(pick.dx, greaterThan(resolve.dx));
    final label = tester.getCenter(find.text('Pick'));
    expect(label.dx, lessThan(pick.dx));
  });

  testWidgets('touch density and large text lay out without overflow', (
    tester,
  ) async {
    await _pump(tester, density: MeridianDensity.touch);
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const ValueKey('resolve'))).height,
      MeridianLayout.stepMarkerTouch,
    );

    await _pump(tester, textScale: 2, width: 260);
    expect(tester.takeException(), isNull);
    expect(_labelShown(tester, 'Review'), isTrue);
  });

  testWidgets('a single step', (tester) async {
    await tester.pumpWidget(
      host(
        const MeridianSteps(steps: [MeridianStep(label: 'Only')], current: 0),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('1'), findsOneWidget);
    expect(_labelShown(tester, 'Only'), isTrue);
  });
}
