import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'meridian_theme_scope.dart';

import 'meridian_brand.dart';
import 'meridian_density.dart';
import 'meridian_tokens.g.dart';

export 'meridian_motion.dart' hide meridianAfterFrame;
export 'meridian_glide.dart';
export 'meridian_motion_helpers.dart';

/// Resolves icon names to SVG assets.
///
/// Meridian ships a Lucide set under `packages/meridian_ui/assets/icons/`.
/// An app adds its own icons (or overrides one) through [extra]: a map from
/// icon name to an asset path in the app's bundle.
@immutable
final class MeridianIconSet {
  const MeridianIconSet({
    this.extra = const <String, String>{},
    this.package = 'meridian_ui',
  });

  /// App icons by name, as asset paths in the app's own bundle.
  final Map<String, String> extra;

  /// The package that bundles the built-in set. `null` when meridian_ui is
  /// itself the root package (its own tests).
  final String? package;

  /// The asset path for [name].
  String assetFor(String name) =>
      extra[name] ??
      (package == null
          ? 'assets/icons/$name.svg'
          : 'packages/$package/assets/icons/$name.svg');

  MeridianIconSet merge(Map<String, String> more) =>
      MeridianIconSet(extra: {...extra, ...more}, package: package);

  @override
  bool operator ==(Object other) =>
      other is MeridianIconSet &&
      other.package == package &&
      mapEquals(other.extra, extra);

  @override
  int get hashCode => Object.hash(
    package,
    Object.hashAllUnordered(
      extra.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}

/// The ten Meridian text styles for the active density, brand fonts and
/// theme, coloured `ink`. Recolour with `copyWith(color: …)`.
///
/// A style in [scale] that names its own `fontFamily` keeps it (a user theme
/// that sets a heading in the reading face); the others take the brand's
/// families.
@immutable
final class MeridianTextStyles {
  const MeridianTextStyles({
    required this.scale,
    required this.fonts,
    required this.colors,
  });

  final MeridianTypeScale scale;
  final MeridianFonts fonts;
  final MeridianColors colors;

  String? get _monoFamily {
    final mono = fonts.mono;
    if (mono == null) return null;
    final package = fonts.monoPackage;
    return package == null ? mono : 'packages/$package/$mono';
  }

  /// The platform's UI family (the SF system face, Segoe UI, Roboto), for
  /// brands without a sans of their own. Naming it keeps text from
  /// inheriting the engine's fallback face.
  static String? get platformSans => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'CupertinoSystemText',
    TargetPlatform.macOS => '.AppleSystemUIFont',
    TargetPlatform.windows => 'Segoe UI',
    TargetPlatform.android ||
    TargetPlatform.fuchsia ||
    TargetPlatform.linux => 'Roboto',
  };

  TextStyle _sans(TextStyle style) => style.fontFamily != null
      ? style.copyWith(color: colors.ink)
      : style.copyWith(
          fontFamily: fonts.sans ?? platformSans,
          fontFamilyFallback: fonts.sansFallback.isEmpty
              ? null
              : fonts.sansFallback,
          color: colors.ink,
        );

  TextStyle _display(TextStyle style) =>
      fonts.display == null || style.fontFamily != null
      ? _sans(style)
      : style.copyWith(
          fontFamily: fonts.display,
          fontFamilyFallback: fonts.readingFallback.isEmpty
              ? null
              : fonts.readingFallback,
          fontWeight: fonts.displayWeight ?? style.fontWeight,
          color: colors.ink,
        );

  TextStyle _mono(TextStyle style) => style.fontFamily != null
      ? style.copyWith(color: colors.ink)
      : style.copyWith(
          fontFamily: _monoFamily,
          fontFamilyFallback: fonts.monoFallback,
          color: colors.ink,
        );

  TextStyle get display => _display(scale.display);
  TextStyle get title =>
      fonts.displayForTitle ? _display(scale.title) : _sans(scale.title);
  TextStyle get heading => _sans(scale.heading);
  TextStyle get body => _sans(scale.body);
  TextStyle get bodyStrong => _sans(scale.bodyStrong);
  TextStyle get label => _sans(scale.label);
  TextStyle get caption => _sans(scale.caption);
  TextStyle get overline => _sans(scale.overline);
  TextStyle get code => _mono(scale.code);
  TextStyle get codeSm => _mono(scale.codeSm);
  TextStyle get reading =>
      fonts.reading == null || scale.reading.fontFamily != null
      ? _sans(scale.reading)
      : scale.reading.copyWith(
          fontFamily: fonts.reading,
          fontFamilyFallback: fonts.readingFallback.isEmpty
              ? null
              : fonts.readingFallback,
          color: colors.ink,
        );

  /// [style] with tabular figures, for numbers that change or line up in
  /// columns (counts, metrics, timestamps).
  static TextStyle numeric(TextStyle style) =>
      style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// [style] for the part of a text that matches a filter or search query:
  /// [color] (`accent`, or `on-accent` on a solid selection), the
  /// `body-strong` weight and an underline in the same colour.
  TextStyle match(TextStyle style, Color color) => style.copyWith(
    color: color,
    fontWeight: bodyStrong.fontWeight,
    decoration: TextDecoration.underline,
    decorationColor: color,
  );
}

/// How a selected row is filled.
enum MeridianSelectionStyle {
  /// Solid `accent` with `on-accent` text while the island has keyboard
  /// focus, `accent-soft` otherwise.
  strong,

  /// Always the lighter `accent-soft` with the normal inks; the island's
  /// focus halo shows where the keyboard is.
  soft,
}

/// App-specific tokens that travel with a [MeridianTheme]: a git app's diff
/// and lane colours, a mail app's reading theme. Extend it like
/// `class GitColors extends MeridianThemeExtension<GitColors>`, pass it in
/// [MeridianTheme.extensions] and read it with
/// `context.meridian.extension<GitColors>()`.
///
/// [lerp] lets an animated theme change (light to dark) move the app's
/// tokens along with Meridian's.
@immutable
abstract class MeridianThemeExtension<T extends MeridianThemeExtension<T>> {
  const MeridianThemeExtension();

  /// The key the theme stores this extension under.
  Object get type => T;

  /// A copy with some values changed.
  T copyWith();

  /// The tokens [t] of the way from this to [other].
  T lerp(covariant T? other, double t);
}

/// Meridian's theme: the brand, brightness, colours, type, density and
/// icons every Meridian widget draws with, plus an app's own tokens in
/// [extensions].
///
/// Put it above the app with `MeridianApp(theme: …)` or a
/// [MeridianThemeScope], and read it with `MeridianTheme.of(context)` or
/// `context.meridian`.
@immutable
final class MeridianTheme {
  const MeridianTheme({
    required this.brand,
    required this.brightness,
    required this.colors,
    required this.shadows,
    required this.density,
    this.icons = const MeridianIconSet(),
    this.typeScale,
    this.selection = MeridianSelectionStyle.strong,
    this.extensions = const {},
  });

  /// Builds the theme for [brand] in [brightness].
  ///
  /// [colors] replaces the colours resolved from the brand, for apps whose
  /// people pick or edit themes; start from `MeridianColors.resolve` and
  /// `copyWith` the colours a theme changes. [typeScale] replaces the
  /// density's type scale the same way, and [shadows] the elevation
  /// shadows (see [MeridianShadowsTint.tinted]).
  factory MeridianTheme.resolve({
    required MeridianBrand brand,
    required Brightness brightness,
    MeridianDensity? density,
    MeridianIconSet icons = const MeridianIconSet(),
    MeridianColors? colors,
    MeridianTypeScale? typeScale,
    MeridianShadows? shadows,
    MeridianSelectionStyle selection = MeridianSelectionStyle.strong,
    Iterable<MeridianThemeExtension<dynamic>> extensions = const [],
  }) {
    final dark = brightness == Brightness.dark;
    return MeridianTheme(
      extensions: {for (final e in extensions) e.type: e},
      brand: brand,
      brightness: brightness,
      colors:
          colors ??
          MeridianColors.resolve(
            brightness,
            dark ? brand.dark : brand.light,
            brand.neutralsFor(brightness),
          ),
      shadows: shadows ?? (dark ? MeridianShadows.dark : MeridianShadows.light),
      density: density ?? brand.density,
      icons: icons,
      typeScale: typeScale,
      selection: selection,
    );
  }

  final MeridianBrand brand;
  final Brightness brightness;
  final MeridianColors colors;
  final MeridianShadows shadows;
  final MeridianDensity density;
  final MeridianIconSet icons;

  /// Replaces the density's type scale (a user theme's sizes); `null` uses
  /// `density.typeScale`.
  final MeridianTypeScale? typeScale;

  /// How selected rows are filled.
  final MeridianSelectionStyle selection;

  /// The app's own tokens, keyed by their [MeridianThemeExtension.type].
  final Map<Object, MeridianThemeExtension<dynamic>> extensions;

  /// The app tokens of type [T], or `null` when the theme has none.
  T? extension<T>() => extensions[T] as T?;

  /// The brand's corner radius scale.
  MeridianRadiusScale get radius => brand.radius;

  /// The code token colours of [brightness], shared by every brand.
  MeridianSyntaxColors get syntax => MeridianSyntaxColors.resolve(brightness);

  /// Text styles for the active density and brand fonts.
  MeridianTextStyles get text => MeridianTextStyles(
    scale: typeScale ?? density.typeScale,
    fonts: brand.fonts,
    colors: colors,
  );

  bool get isDark => brightness == Brightness.dark;

  @override
  bool operator ==(Object other) =>
      other is MeridianTheme &&
      other.brand == brand &&
      other.brightness == brightness &&
      other.colors == colors &&
      other.shadows == shadows &&
      other.density == density &&
      other.icons == icons &&
      other.typeScale == typeScale &&
      other.selection == selection &&
      mapEquals(other.extensions, extensions);

  @override
  int get hashCode => Object.hash(
    brand,
    brightness,
    colors,
    shadows,
    density,
    icons,
    typeScale,
    selection,
    Object.hashAllUnordered(extensions.values),
  );

  /// The nearest Meridian theme. Falls back to a neutral Meridian theme in
  /// the platform's brightness when there is none (useful in tests).
  static MeridianTheme of(BuildContext context) =>
      MeridianThemeScope.maybeOf(context) ??
      MeridianTheme.resolve(
        brand: _fallbackBrand,
        brightness:
            MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light,
      );

  static const _fallbackBrand = MeridianBrand(
    id: 'meridian',
    name: 'Meridian',
    light: MeridianAccentColors(
      accent: Color(0xFF0A62CC),
      onAccent: Color(0xFFFFFFFF),
      onAccentMuted: Color(0xFFE3EEFC),
      accentSoft: Color(0xFFDCEBFD),
      accentInk: Color(0xFF0A58B8),
      focus: Color(0xFF0A62CC),
      brand: Color(0xFF14242B),
    ),
    dark: MeridianAccentColors(
      accent: Color(0xFF6AAEFF),
      onAccent: Color(0xFF04121C),
      onAccentMuted: Color(0xFF123452),
      accentSoft: Color(0xFF16334D),
      accentInk: Color(0xFF8CC2FF),
      focus: Color(0xFF8CC2FF),
      brand: Color(0xFF1F3A48),
    ),
  );

  MeridianTheme copyWith({
    MeridianBrand? brand,
    MeridianDensity? density,
    MeridianIconSet? icons,
    MeridianColors? colors,
    MeridianTypeScale? typeScale,
    MeridianSelectionStyle? selection,
    Iterable<MeridianThemeExtension<dynamic>>? extensions,
  }) {
    final nextBrand = brand ?? this.brand;
    return MeridianTheme(
      brand: nextBrand,
      brightness: brightness,
      colors:
          colors ??
          (brand == null
              ? this.colors
              : MeridianColors.resolve(
                  brightness,
                  isDark ? nextBrand.dark : nextBrand.light,
                  nextBrand.neutralsFor(brightness),
                )),
      shadows: shadows,
      density: density ?? this.density,
      icons: icons ?? this.icons,
      typeScale: typeScale ?? this.typeScale,
      selection: selection ?? this.selection,
      extensions: extensions == null
          ? this.extensions
          : {for (final e in extensions) e.type: e},
    );
  }

  /// The theme [t] of the way from this to [other], for theme animations.
  /// Colours, shadows, corners and the app's extensions blend; fonts,
  /// density and icons switch at the midpoint.
  MeridianTheme lerp(MeridianTheme? other, double t) {
    if (other == null) return this;
    final end = t >= 0.5;
    return MeridianTheme(
      // Fonts and density switch at the midpoint; the corners animate.
      brand: (end ? other.brand : brand).copyWith(
        radius: MeridianRadiusScale.lerp(brand.radius, other.brand.radius, t),
      ),
      brightness: end ? other.brightness : brightness,
      colors: MeridianColors.lerp(colors, other.colors, t),
      shadows: MeridianShadows.lerp(shadows, other.shadows, t),
      density: end ? other.density : density,
      icons: end ? other.icons : icons,
      typeScale: end ? other.typeScale : typeScale,
      selection: end ? other.selection : selection,
      extensions: {
        for (final MapEntry(:key, :value) in extensions.entries)
          key: other.extensions.containsKey(key)
              ? value.lerp(other.extensions[key], t)
                    as MeridianThemeExtension<dynamic>
              : value,
        for (final MapEntry(:key, :value) in other.extensions.entries)
          if (!extensions.containsKey(key)) key: value,
      },
    );
  }
}

/// Shorthand for `MeridianTheme.of(context)`.
extension MeridianContext on BuildContext {
  MeridianTheme get meridian => MeridianTheme.of(this);
}

/// Shadows in another colour, for a theme that tints its elevation (a warm
/// or coloured canvas). Each layer keeps its offset, blur, spread and
/// opacity; only the colour changes. `null` keeps that shadow as it is.
extension MeridianShadowsTint on MeridianShadows {
  MeridianShadows tinted({Color? pane, Color? float, Color? control}) {
    List<BoxShadow> tint(List<BoxShadow> layers, Color? color) => color == null
        ? layers
        : [
            for (final layer in layers)
              layer.copyWith(color: color.withValues(alpha: layer.color.a)),
          ];
    return MeridianShadows(
      shadowPane: tint(shadowPane, pane),
      shadowFloat: tint(shadowFloat, float),
      shadowControl: tint(shadowControl, control),
    );
  }
}
