import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

void main() {
  group('settings group fitLabels', () {
    Widget form({required bool fit, double width = 460}) => SizedBox(
      width: width,
      child: MeridianSettingsGroup(
        fitLabels: fit,
        children: [
          const MeridianSettingsRow(
            label: 'Remote',
            children: [
              SizedBox(key: ValueKey('remote'), height: 28, width: 80),
            ],
          ),
          const MeridianSettingsRow(
            label: 'Pull strategy',
            children: [
              SizedBox(key: ValueKey('strategy'), height: 28, width: 80),
            ],
          ),
          MeridianSettingsRow(
            label: '',
            children: [
              MeridianCheckbox(
                key: const ValueKey('check'),
                value: false,
                label: 'Fetch all remotes',
                onChanged: (_) {},
              ),
            ],
          ),
        ],
      ),
    );

    testWidgets('the label column hugs the widest label', (tester) async {
      await tester.pumpWidget(host(form(fit: true)));
      final left = tester.getTopLeft(find.byType(MeridianSettingsGroup)).dx;
      final remote = tester.getTopLeft(find.byKey(const ValueKey('remote')));
      final strategy = tester.getTopLeft(
        find.byKey(const ValueKey('strategy')),
      );
      final check = tester.getTopLeft(find.byKey(const ValueKey('check')));
      final labelWidth = tester.getSize(find.text('Pull strategy')).width;
      expect(remote.dx, strategy.dx);
      expect(check.dx, strategy.dx);
      expect(
        strategy.dx - left,
        moreOrLessEquals(labelWidth + MeridianSpace.space5, epsilon: 1),
      );
      expect(
        strategy.dx - left,
        lessThan(MeridianLayout.settingsLabelColumn + MeridianSpace.space7),
      );
      // Labels stay right-aligned against the controls.
      expect(
        tester.getTopRight(find.text('Remote')).dx,
        moreOrLessEquals(tester.getTopRight(find.text('Pull strategy')).dx),
      );
    });

    testWidgets('without fitLabels the settings column is kept', (
      tester,
    ) async {
      await tester.pumpWidget(host(form(fit: false, width: 600)));
      final left = tester.getTopLeft(find.byType(MeridianSettingsGroup)).dx;
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('remote'))).dx - left,
        MeridianLayout.settingsLabelColumn + MeridianSpace.space7,
      );
    });

    testWidgets('a fitted form stays side by side in a narrow dialog and '
        'stacks only when the controls no longer fit', (tester) async {
      await tester.pumpWidget(host(form(fit: true, width: 360)));
      final remote = tester.getTopLeft(find.byKey(const ValueKey('remote')));
      expect(
        tester.getTopLeft(find.text('Remote')).dy,
        lessThan(remote.dy + 8),
      );

      await tester.pumpWidget(host(form(fit: true, width: 200)));
      final stacked = tester.getTopLeft(find.byKey(const ValueKey('remote')));
      expect(
        tester.getBottomLeft(find.text('Remote')).dy,
        lessThan(stacked.dy),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('large text widens the column instead of clipping labels', (
      tester,
    ) async {
      await tester.pumpWidget(host(form(fit: true), textScale: 1.5));
      final left = tester.getTopLeft(find.byType(MeridianSettingsGroup)).dx;
      final labelWidth = tester.getSize(find.text('Pull strategy')).width;
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('strategy'))).dx - left,
        moreOrLessEquals(labelWidth + MeridianSpace.space5, epsilon: 1),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
