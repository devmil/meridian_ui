import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_gallery/widgetbook.dart';
import 'package:meridian_ui/meridian_ui.dart';
import 'package:widgetbook/widgetbook.dart';

/// Every use case path, in navigation order.
List<String> useCasePaths() => WidgetbookRoot(
  children: meridianDirectories(),
).leaves.whereType<WidgetbookUseCase>().map((node) => node.path).toList();

/// Opens [path] in preview mode with [addons] set, such as
/// `{'brand': 'Nibluma', 'theme': 'dark'}`.
Future<void> open(
  WidgetTester tester,
  String path, {
  Map<String, String> addons = const {},
  Map<String, String> query = const {},
}) async {
  final route = Uri(
    path: '/',
    queryParameters: {
      'path': path,
      'preview': 'true',
      for (final MapEntry(:key, :value) in addons.entries) key: '{name:$value}',
      ...query,
    },
  );
  await tester.pumpWidget(
    MeridianWidgetbook(key: UniqueKey(), initialRoute: '$route'),
  );
  // Spinners and an indeterminate bar run forever: pump, not settle.
  await tester.pump(const Duration(milliseconds: 600));
}

/// The toolbar button is a desktop title-bar control with a fixed height.
/// Its icon and caption do not fit at touch density once text is enlarged.
const fixedHeightAtTouch = {
  'actions/toolbar-button/playground',
  'actions/toolbar-button/toolbar',
};

WidgetbookState stateOf(WidgetTester tester) =>
    WidgetbookState.of(tester.element(find.byType(MaterialApp).first));

void main() {
  for (final path in [
    'inputs/shortcut-field/playground',
    'inputs/shortcut-field/states',
    'actions/button/playground',
    'data-and-window/status-bar/playground',
  ]) {
    testWidgets('$path fits desktop 200% text', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await open(
        tester,
        path,
        addons: const {'brand': 'ShotLama', 'density': 'regular'},
        query: const {'text-scale': '{factor:2}'},
      );
      expect(tester.takeException(), isNull);
      expect(stateOf(tester).useCase?.path, path);
    });
  }

  test('use case paths are unique', () {
    final paths = useCasePaths();
    expect(paths, isNotEmpty);
    expect(paths.toSet(), hasLength(paths.length));
  });

  for (final size in const [Size(390, 844), Size(1280, 900)]) {
    for (final density in const ['regular', 'touch']) {
      testWidgets('every use case lays out at ${size.width.round()}px in '
          '$density density', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final path in useCasePaths()) {
          await open(tester, path, addons: {'density': density});
          expect(tester.takeException(), isNull, reason: path);
          expect(stateOf(tester).useCase?.path, path);
        }
      });
    }
  }

  testWidgets('every use case lays out in a dark brand with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final path in useCasePaths()) {
      if (fixedHeightAtTouch.contains(path)) continue;
      await open(
        tester,
        path,
        addons: const {'brand': 'Nibluma', 'theme': 'dark'},
        query: const {'text-scale': '{factor:1.6}'},
      );
      expect(tester.takeException(), isNull, reason: path);
    }
  });

  testWidgets('the addons apply brand, theme, density and reduced motion', (
    tester,
  ) async {
    await open(
      tester,
      'actions/button/playground',
      addons: const {
        'brand': 'CrossProton',
        'theme': 'dark',
        'density': 'touch',
      },
      query: const {
        'reduce-motion': '{enabled:true}',
        'speed': '{factor:0.5×}',
      },
    );
    final meridian = MeridianTheme.of(
      tester.element(find.byType(MeridianButton)),
    );
    expect(meridian.brand.name, 'CrossProton');
    expect(meridian.brightness, Brightness.dark);
    expect(meridian.density.isTouch, isTrue);
    final button = tester.element(find.byType(MeridianButton));
    expect(MediaQuery.disableAnimationsOf(button), isTrue);
    expect(timeDilation, 2);
    // The binding checks this before tearDown runs.
    timeDilation = 1;
  });

  testWidgets('a brand keeps its own density by default', (tester) async {
    await open(
      tester,
      'actions/button/playground',
      addons: const {'brand': 'Nibluma'},
    );
    final meridian = MeridianTheme.of(
      tester.element(find.byType(MeridianButton)),
    );
    expect(meridian.brand.name, 'Nibluma');
    expect(meridian.density, MeridianBrands.nibluma.density);
  });

  testWidgets('a knob changes the component', (tester) async {
    await open(
      tester,
      'actions/button/playground',
      query: {
        'knobs': '{Label:${Uri.encodeComponent('Hello Meridian')},Expand:true}',
      },
    );
    expect(find.text('Hello Meridian'), findsOneWidget);
  });

  testWidgets('the home page and navigation lay out', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MeridianWidgetbook(key: UniqueKey()));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(find.text('Turn the knobs'), findsOneWidget);
    expect(find.text('Foundation'), findsOneWidget);
  });
}
