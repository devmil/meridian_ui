import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'support.dart';

List<MeridianSettingsPage> _pages() => [
  MeridianSettingsPage(
    label: 'Appearance',
    icon: MeridianIcons.palette,
    description: 'Theme and density.',
    builder: (context) => MeridianSettingsGroup(
      children: [
        MeridianSettingsRow(
          label: 'Theme',
          children: [
            MeridianSegmented<int>(
              label: 'Theme',
              value: 0,
              onChanged: (_) {},
              segments: const [
                MeridianSegment(value: 0, label: 'System'),
                MeridianSegment(value: 1, label: 'Light'),
              ],
            ),
          ],
        ),
      ],
    ),
  ),
  MeridianSettingsPage(
    label: 'Columns',
    icon: MeridianIcons.columns2,
    builder: (context) =>
        Column(children: [for (var i = 0; i < 40; i++) Text('Column $i')]),
  ),
  MeridianSettingsPage(
    label: 'Remote hosts',
    icon: MeridianIcons.server,
    description: 'Computers reached over SSH.',
    builder: (context) => const Text('No hosts yet.'),
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(1280, 900),
  MeridianDensity? density,
  double textScale = 1,
  ValueChanged<int>? onPageChanged,
  int initialPage = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    host(
      MeridianSettingsDialog(
        title: 'Settings',
        pages: _pages(),
        initialPage: initialPage,
        onPageChanged: onPageChanged,
      ),
      density: density,
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists the pages and shows the selected one', (tester) async {
    final changes = <int>[];
    await _pump(tester, onPageChanged: changes.add);

    expect(find.byType(MeridianNavRow), findsNWidgets(3));
    expect(find.text('Theme'), findsWidgets);
    expect(find.text('Theme and density.'), findsOneWidget);
    expect(find.text('No hosts yet.'), findsNothing);

    await tester.tap(find.text('Remote hosts'));
    await tester.pumpAndSettle();

    expect(find.text('No hosts yet.'), findsOneWidget);
    expect(find.text('Computers reached over SSH.'), findsOneWidget);
    expect(find.text('Theme and density.'), findsNothing);
    expect(changes, [2]);
    final rows = tester.widgetList<MeridianNavRow>(find.byType(MeridianNavRow));
    expect(rows.map((row) => row.selected), [false, false, true]);
  });

  testWidgets('keeps one height while pages change', (tester) async {
    await _pump(tester);
    final surface = find
        .descendant(
          of: find.byType(MeridianDialogSurface),
          matching: find.byType(ClipRRect),
        )
        .first;
    final short = tester.getSize(surface);
    await tester.tap(find.text('Columns'));
    await tester.pumpAndSettle();
    expect(tester.getSize(surface), short);
    expect(short.height, MeridianLayout.settingsDialogHeight);
    expect(short.width, MeridianLayout.settingsDialogWidth);
  });

  testWidgets('Up and Down in the page list move between pages', (
    tester,
  ) async {
    await _pump(tester);
    // Tab past the close button into the page list.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('Column 0'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('No hosts yet.'), findsOneWidget);
    // The last page stays put.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('No hosts yet.'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(find.text('Column 0'), findsOneWidget);
    // Enter on the focused row keeps it.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Column 0'), findsOneWidget);
  });

  testWidgets('closes with the close button', (tester) async {
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => MeridianButton(
            label: 'Open',
            onPressed: () => showMeridianDialog<void>(
              context: context,
              builder: (_) =>
                  MeridianSettingsDialog(title: 'Settings', pages: _pages()),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(MeridianSettingsDialog), findsOneWidget);
    await tester.tap(find.byType(MeridianIconButton).first);
    await tester.pumpAndSettle();
    expect(find.byType(MeridianSettingsDialog), findsNothing);
  });

  testWidgets('closes with Escape before anything in it has focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => MeridianButton(
            label: 'Open',
            onPressed: () => showMeridianDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) =>
                  MeridianSettingsDialog(title: 'Settings', pages: _pages()),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(MeridianSettingsDialog), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(MeridianSettingsDialog), findsNothing);
  });

  testWidgets('narrow windows and touch swap the list for a select', (
    tester,
  ) async {
    for (final (size, density) in [
      (const Size(390, 800), null),
      (const Size(1280, 900), MeridianDensity.touch),
    ]) {
      await _pump(tester, size: size, density: density);
      expect(find.byType(MeridianNavRow), findsNothing, reason: '$size');
      expect(find.byType(MeridianSelect<int>), findsOneWidget);
      expect(find.text('Appearance'), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('fits enlarged text without overflow', (tester) async {
    for (final size in const [Size(1280, 900), Size(390, 700)]) {
      await _pump(tester, size: size, textScale: 2, initialPage: 2);
      expect(tester.takeException(), isNull, reason: '$size');
      expect(find.text('No hosts yet.'), findsOneWidget);
    }
  });

  testWidgets('follows a page the app sets and keys its list entries', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var page = 0;
    final pages = [
      for (final (i, entry) in _pages().indexed)
        MeridianSettingsPage(
          key: ValueKey('page-$i'),
          label: entry.label,
          icon: entry.icon,
          description: entry.description,
          builder: entry.builder,
        ),
    ];
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => MeridianSettingsDialog(
            title: 'Settings',
            page: page,
            onPageChanged: (next) => setState(() => page = next),
            footer: page == 2 ? const Text('That shortcut is taken.') : null,
            pages: [
              for (final (i, entry) in pages.indexed)
                i == 0
                    ? MeridianSettingsPage(
                        key: entry.key,
                        label: entry.label,
                        builder: (context) => MeridianButton(
                          label: 'Go to hosts',
                          onPressed: () => setState(() => page = 2),
                        ),
                      )
                    : entry,
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('page-1')), findsOneWidget);
    expect(find.text('That shortcut is taken.'), findsNothing);

    await tester.tap(find.text('Go to hosts'));
    await tester.pumpAndSettle();
    expect(find.text('No hosts yet.'), findsOneWidget);
    expect(find.text('That shortcut is taken.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('page-1')));
    await tester.pumpAndSettle();
    expect(page, 1);
    expect(find.text('Column 0'), findsOneWidget);
    expect(find.text('That shortcut is taken.'), findsNothing);
  });

  testWidgets('clamps an out-of-range initial page', (tester) async {
    await _pump(tester, initialPage: 9);
    expect(find.text('No hosts yet.'), findsOneWidget);
  });
}
