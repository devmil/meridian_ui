import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

Stream<LicenseEntry> _licenses() async* {
  yield const LicenseEntryWithLineBreaks(['zeta'], 'Zeta license text.');
  yield const LicenseEntryWithLineBreaks([
    'alpha',
    'beta',
  ], 'Shared license.\n\n  Indented clause.');
  yield const LicenseEntryWithLineBreaks(['alpha'], 'Second alpha license.');
  for (var i = 0; i < 40; i++) {
    yield LicenseEntryWithLineBreaks(['pkg_$i'], 'License of pkg_$i.');
  }
}

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(1280, 900),
  MeridianDensity? density,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  const dialog = MeridianLicenseDialog(
    applicationName: 'GitLama',
    applicationVersion: '1.2.3',
    applicationLegalese: '© Devmil',
    applicationIcon: SizedBox.square(dimension: 40),
    licenses: _licenses,
  );
  await tester.pumpWidget(host(dialog, density: density, textScale: textScale));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists packages sorted with counts and shows the first', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Licenses'), findsOneWidget);
    expect(find.text('GitLama'), findsOneWidget);
    expect(find.text('1.2.3'), findsOneWidget);
    expect(find.text('© Devmil'), findsOneWidget);
    final rows = tester
        .widgetList<MeridianNavRow>(find.byType(MeridianNavRow))
        .toList();
    expect(rows.take(3).map((r) => r.label), ['alpha', 'beta', 'pkg_0']);
    expect(rows.first.count, 2);
    expect(rows.first.selected, isTrue);
    expect(find.text('2 licenses'), findsOneWidget);
    expect(find.text('Shared license.'), findsOneWidget);
    expect(find.text('Second alpha license.'), findsOneWidget);
    expect(find.text('Indented clause.'), findsOneWidget);
  });

  testWidgets('selecting a package shows its licenses', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('meridian-license-beta')));
    await tester.pumpAndSettle();

    expect(find.text('1 license'), findsOneWidget);
    expect(find.text('Shared license.'), findsOneWidget);
    expect(find.text('Second alpha license.'), findsNothing);
  });

  testWidgets('the filter narrows the list and reports no match', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('meridian-licenses-filter')),
        matching: find.byType(EditableText),
      ),
      'ZET',
    );
    await tester.pumpAndSettle();
    expect(find.byType(MeridianNavRow), findsOneWidget);
    expect(find.byKey(const ValueKey('meridian-license-zeta')), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('meridian-licenses-filter')),
        matching: find.byType(EditableText),
      ),
      'nothing here',
    );
    await tester.pumpAndSettle();
    expect(find.byType(MeridianNavRow), findsNothing);
    expect(find.text('No packages match'), findsOneWidget);
  });

  testWidgets('Down and Up move between packages', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('meridian-license-alpha')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('1 license'), findsOneWidget);
    expect(
      tester
          .widget<MeridianNavRow>(
            find.byKey(const ValueKey('meridian-license-beta')),
          )
          .selected,
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(find.text('2 licenses'), findsOneWidget);
  });

  testWidgets('the close button pops the route', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => MeridianButton(
            label: 'Open',
            onPressed: () =>
                showMeridianLicenses(context: context, licenses: _licenses),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(MeridianLicenseDialog), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(MeridianLicenseDialog), findsNothing);
  });

  for (final (name, size, density) in [
    ('narrow', const Size(390, 800), null),
    ('touch', const Size(1280, 900), MeridianDensity.touch),
  ]) {
    testWidgets('$name: list and package take turns', (tester) async {
      await _pump(tester, size: size, density: density);

      expect(find.byKey(const Key('meridian-licenses-back')), findsNothing);
      expect(find.text('Shared license.'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('meridian-license-beta')));
      await tester.pumpAndSettle();
      expect(find.byType(MeridianNavRow), findsNothing);
      expect(find.text('Shared license.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('meridian-licenses-back')));
      await tester.pumpAndSettle();
      expect(find.byType(MeridianNavRow), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('lays out at 200% text without overflow', (tester) async {
    await _pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    await _pump(tester, size: const Size(390, 800), textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('speaks German', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        const MeridianLocalizationsScope(
          localizations: MeridianLocalizationsDe(),
          child: MeridianLicenseDialog(licenses: _licenses),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lizenzen'), findsOneWidget);
    expect(find.text('2 Lizenzen'), findsOneWidget);
  });

  testWidgets('a failing source shows the error', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        MeridianLicenseDialog(
          licenses: () => Stream<LicenseEntry>.error('notices missing'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('notices missing'), findsOneWidget);
  });
}
