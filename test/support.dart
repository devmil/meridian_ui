import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

/// meridian_ui is the root package in its own tests, so the icons live at
/// `assets/icons/`, not under `packages/meridian_ui/`.
const testIcons = MeridianIconSet(package: null);

ThemeData testTheme({
  MeridianBrand brand = MeridianBrands.gitlama,
  Brightness brightness = Brightness.light,
  MeridianDensity? density,
}) => buildMeridianTheme(
  brand: brand,
  brightness: brightness,
  density: density,
  icons: testIcons,
);

/// [child] centred on a Meridian ground in a MaterialApp.
///
/// No Scaffold: MeridianGround must provide everything a primitive needs
/// (a Material ancestor, the body text style).
Widget host(
  Widget child, {
  MeridianBrand brand = MeridianBrands.gitlama,
  Brightness brightness = Brightness.light,
  MeridianDensity? density,
  TextDirection textDirection = TextDirection.ltr,
  double textScale = 1,
}) => MaterialApp(
  theme: testTheme(brand: brand, brightness: brightness, density: density),
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: Directionality(textDirection: textDirection, child: app!),
  ),
  home: MeridianGround(child: Center(child: child)),
);

/// The Meridian colours [tester] is rendering (light GitLama unless the
/// host says otherwise).
MeridianColors colorsOf(WidgetTester tester, [Finder? at]) =>
    MeridianTheme.of(tester.element(at ?? find.byType(MeridianGround))).colors;

/// Whether a Meridian focus ring is painted inside [scope].
bool ringVisible(WidgetTester tester, Finder scope) => tester
    .widgetList<CustomPaint>(
      find.descendant(of: scope, matching: find.byType(CustomPaint)),
    )
    .map((paint) => paint.foregroundPainter)
    .whereType<MeridianFocusRingPainter>()
    .any((painter) => painter.visible);

/// The text colour of the [Text] showing [value].
Color? textColor(WidgetTester tester, String value) =>
    tester.widget<Text>(find.text(value)).style?.color;

/// The fill of the nearest decorated ancestor of [of] that has a colour.
Color? fillAround(WidgetTester tester, Finder of) {
  for (final element
      in find
          .ancestor(of: of, matching: find.byType(AnimatedContainer))
          .evaluate()) {
    final decoration =
        (element.widget as AnimatedContainer).decoration as BoxDecoration?;
    if (decoration?.color case final color?) return color;
  }
  return null;
}

/// Hover highlights follow [FocusManager.highlightMode], which starts in
/// touch mode on the default test platform. Desktop starts traditional;
/// call this in hover tests to match.
void useDesktopHighlights() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

/// A mouse hovering at [location]; removed when the test ends.
Future<TestGesture> hoverAt(WidgetTester tester, Offset location) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(mouse.removePointer);
  await mouse.addPointer(location: Offset.zero);
  await mouse.moveTo(location);
  await tester.pump();
  return mouse;
}
