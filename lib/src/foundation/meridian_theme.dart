import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'meridian_brand.dart';
import 'meridian_density.dart';
import 'meridian_layout.dart';
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

  /// The platform's UI family as Material's typography names it (Roboto,
  /// the SF system face, Segoe UI), for brands without a sans of their own.
  /// Naming it keeps text below no `Material` (a dialog or sheet over
  /// `MaterialApp`'s fallback style) from inheriting `monospace`.
  static String? get platformSans => Typography.material2021(
    platform: defaultTargetPlatform,
  ).black.bodyMedium?.fontFamily;

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

/// Meridian's theme extension. Read it with `MeridianTheme.of(context)` or
/// `context.meridian`.
@immutable
final class MeridianTheme extends ThemeExtension<MeridianTheme> {
  const MeridianTheme({
    required this.brand,
    required this.brightness,
    required this.colors,
    required this.shadows,
    required this.density,
    this.icons = const MeridianIconSet(),
    this.typeScale,
    this.selection = MeridianSelectionStyle.strong,
  });

  /// Builds the extension for [brand] in [brightness].
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
  }) {
    final dark = brightness == Brightness.dark;
    return MeridianTheme(
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
      other.selection == selection;

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
  );

  /// The nearest Meridian theme. Falls back to the GitLama-default light
  /// or dark theme when no extension is installed (useful in tests).
  static MeridianTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<MeridianTheme>() ??
        MeridianTheme.resolve(
          brand: _fallbackBrand,
          brightness: theme.brightness,
        );
  }

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

  @override
  MeridianTheme copyWith({
    MeridianBrand? brand,
    MeridianDensity? density,
    MeridianIconSet? icons,
    MeridianColors? colors,
    MeridianTypeScale? typeScale,
    MeridianSelectionStyle? selection,
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
    );
  }

  @override
  MeridianTheme lerp(covariant MeridianTheme? other, double t) {
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
    );
  }
}

/// Shorthand for `MeridianTheme.of(context)`.
extension MeridianContext on BuildContext {
  MeridianTheme get meridian => MeridianTheme.of(this);
}

/// Builds a Material [ThemeData] that carries Meridian.
///
/// Material widgets that stay in use (Scrollbar, Tooltip, TextField's
/// selection) are tuned to Meridian; everything visible is drawn by the
/// Meridian components. Ripples and splashes are off.
///
/// [colors], [typeScale] and [shadows] replace the brand's colours, the
/// density's type scale and the elevation shadows, for apps with user
/// themes (see [MeridianTheme.resolve]).
ThemeData buildMeridianTheme({
  required MeridianBrand brand,
  required Brightness brightness,
  MeridianDensity? density,
  MeridianIconSet icons = const MeridianIconSet(),
  MeridianColors? colors,
  MeridianTypeScale? typeScale,
  MeridianShadows? shadows,
  List<ThemeExtension<dynamic>> extensions = const [],
  MeridianSelectionStyle selection = MeridianSelectionStyle.strong,
}) {
  final meridian = MeridianTheme.resolve(
    brand: brand,
    brightness: brightness,
    density: density,
    icons: icons,
    colors: colors,
    typeScale: typeScale,
    shadows: shadows,
    selection: selection,
  );
  final palette = meridian.colors;
  final text = meridian.text;
  final radius = meridian.radius;
  final touch = meridian.density.isTouch;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: palette.accent,
    onPrimary: palette.onAccent,
    primaryContainer: palette.accentSoft,
    onPrimaryContainer: palette.ink,
    secondary: palette.accent,
    onSecondary: palette.onAccent,
    error: palette.danger,
    onError: palette.onDanger,
    errorContainer: palette.dangerBg,
    onErrorContainer: palette.ink,
    surface: palette.pane,
    onSurface: palette.ink,
    onSurfaceVariant: palette.inkMuted,
    surfaceContainerLowest: palette.pane,
    surfaceContainerLow: palette.paneAlt,
    surfaceContainer: palette.paneAlt,
    surfaceContainerHigh: palette.raised,
    surfaceContainerHighest: palette.paneHover,
    outline: palette.controlEdge,
    outlineVariant: palette.line,
    scrim: palette.scrim,
    surfaceTint: Colors.transparent,
  );
  final textTheme = TextTheme(
    displayLarge: text.display,
    displayMedium: text.display,
    displaySmall: text.display,
    headlineLarge: text.title,
    headlineMedium: text.title,
    headlineSmall: text.title,
    titleLarge: text.title,
    titleMedium: text.heading,
    titleSmall: text.bodyStrong,
    bodyLarge: text.body,
    bodyMedium: text.body,
    bodySmall: text.caption.copyWith(color: palette.inkMuted),
    labelLarge: text.label,
    labelMedium: text.overline.copyWith(color: palette.inkMuted),
    labelSmall: text.caption,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: brand.fonts.sans,
    textTheme: textTheme,
    scaffoldBackgroundColor: palette.ground,
    canvasColor: palette.pane,
    cardColor: palette.pane,
    dividerColor: palette.line,
    focusColor: palette.focus,
    hoverColor: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    materialTapTargetSize: touch
        ? MaterialTapTargetSize.padded
        : MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.standard,
    iconTheme: IconThemeData(
      color: palette.ink,
      size: meridian.density.iconSize,
    ),
    drawerTheme: DrawerThemeData(scrimColor: palette.scrim),
    dividerTheme: DividerThemeData(
      color: palette.line,
      thickness: MeridianLayout.hairline,
      space: MeridianLayout.hairline,
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: MeridianDurations.tooltipWait,
      exitDuration: MeridianDurations.exit,
      decoration: BoxDecoration(
        color: palette.ink,
        borderRadius: BorderRadius.circular(radius.sm),
      ),
      textStyle: text.caption.copyWith(color: palette.pane),
      padding: const EdgeInsets.symmetric(
        horizontal: MeridianSpace.space3,
        vertical: MeridianSpace.space2,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.hovered)
            ? MeridianLayout.scrollbarThicknessHover
            : MeridianLayout.scrollbarThickness,
      ),
      radius: const Radius.circular(MeridianRadiusScale.pill),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.dragged)
            ? palette.controlEdge
            : palette.lineStrong,
      ),
      trackVisibility: const WidgetStatePropertyAll(false),
    ),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: palette.accentSoft,
      cursorColor: palette.accent,
      selectionHandleColor: palette.accent,
    ),
    extensions: [meridian, ...extensions],
  );
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
