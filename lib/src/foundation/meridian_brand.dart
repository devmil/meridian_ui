import 'dart:ui' show Brightness, FontWeight;

import 'package:flutter/foundation.dart';

import 'meridian_density.dart';
import 'meridian_tokens.g.dart';

/// Font families a brand uses. `null` means the platform face.
///
/// Families other than the bundled JetBrains Mono are registered by the app
/// in its own `pubspec.yaml`; the brand only names them.
@immutable
final class MeridianFonts {
  const MeridianFonts({
    this.sans,
    this.sansFallback = const <String>[],
    this.mono = 'JetBrains Mono',
    this.monoPackage = 'meridian_ui',
    this.monoFallback = const <String>['Menlo', 'Consolas', 'monospace'],
    this.display,
    this.reading,
    this.readingFallback = const <String>[],
    this.displayForTitle = true,
    this.displayWeight,
  });

  /// The UI face. `null` uses the platform face (SF Pro, Segoe UI Variable,
  /// Roboto, Cantarell or Noto Sans).
  final String? sans;

  /// Fallback families for [sans].
  final List<String> sansFallback;

  /// The code and identifier face.
  final String? mono;

  /// The package that bundles [mono], or `null` when the app bundles it.
  final String? monoPackage;

  /// Fallback families for [mono].
  final List<String> monoFallback;

  /// Optional face for `display` and `title` (for example an editorial serif).
  /// `null` uses [sans].
  final String? display;

  /// Optional face for the `reading` style. `null` uses [sans].
  final String? reading;

  /// Fallback families for [reading].
  final List<String> readingFallback;

  /// Whether the `title` style (dialog, sheet and page titles) also uses
  /// [display]. `false` keeps titles in [sans] and saves the display face
  /// for the `display` style (a library headline, a book title).
  final bool displayForTitle;

  /// The weight of the styles set in [display], for faces that read best
  /// lighter than the scale's 600 (an editorial serif at 500). `null` keeps
  /// the scale's weight.
  final FontWeight? displayWeight;

  /// A copy with the given fields replaced. Pass `clearMonoPackage: true`
  /// when switching [mono] to a family the app bundles itself.
  MeridianFonts copyWith({
    String? sans,
    List<String>? sansFallback,
    String? mono,
    String? monoPackage,
    bool clearMonoPackage = false,
    List<String>? monoFallback,
    String? display,
    String? reading,
    List<String>? readingFallback,
    bool? displayForTitle,
    FontWeight? displayWeight,
  }) => MeridianFonts(
    sans: sans ?? this.sans,
    sansFallback: sansFallback ?? this.sansFallback,
    mono: mono ?? this.mono,
    monoPackage: clearMonoPackage ? null : (monoPackage ?? this.monoPackage),
    monoFallback: monoFallback ?? this.monoFallback,
    display: display ?? this.display,
    reading: reading ?? this.reading,
    readingFallback: readingFallback ?? this.readingFallback,
    displayForTitle: displayForTitle ?? this.displayForTitle,
    displayWeight: displayWeight ?? this.displayWeight,
  );

  @override
  bool operator ==(Object other) =>
      other is MeridianFonts &&
      other.sans == sans &&
      listEquals(other.sansFallback, sansFallback) &&
      other.mono == mono &&
      other.monoPackage == monoPackage &&
      listEquals(other.monoFallback, monoFallback) &&
      other.display == display &&
      other.reading == reading &&
      listEquals(other.readingFallback, readingFallback) &&
      other.displayForTitle == displayForTitle &&
      other.displayWeight == displayWeight;

  @override
  int get hashCode => Object.hash(
    sans,
    Object.hashAll(sansFallback),
    mono,
    monoPackage,
    Object.hashAll(monoFallback),
    display,
    reading,
    Object.hashAll(readingFallback),
    displayForTitle,
    displayWeight,
  );
}

/// One app's identity on top of the shared Meridian core: its accent family
/// for light and dark, its fonts, its corner radius scale and its default
/// density. Everything else (surfaces, ink, status colours, spacing, motion)
/// is shared by every Meridian app.
@immutable
final class MeridianBrand {
  const MeridianBrand({
    required this.id,
    required this.name,
    required this.light,
    required this.dark,
    this.fonts = const MeridianFonts(),
    this.radius = MeridianRadiusScale.standard,
    this.density = MeridianDensity.regular,
    this.lightNeutrals,
    this.darkNeutrals,
  });

  /// Stable identifier, for example `gitlama`.
  final String id;

  /// Display name, for example `GitLama`.
  final String name;

  /// Accent family in the light theme.
  final MeridianAccentColors light;

  /// Accent family in the dark theme.
  final MeridianAccentColors dark;

  /// Font families.
  final MeridianFonts fonts;

  /// Corner radius scale.
  final MeridianRadiusScale radius;

  /// The density the app starts with. People may still change it.
  final MeridianDensity density;

  /// The brand's own neutrals (surfaces, canvas, ink, lines) in the light
  /// theme, or `null` for the shared core. Status and series colours stay
  /// shared.
  final MeridianNeutralColors? lightNeutrals;

  /// The brand's own neutrals in the dark theme, or `null` for the core.
  final MeridianNeutralColors? darkNeutrals;

  /// The neutrals for [brightness].
  MeridianNeutralColors? neutralsFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkNeutrals : lightNeutrals;

  MeridianBrand copyWith({
    String? id,
    String? name,
    MeridianAccentColors? light,
    MeridianAccentColors? dark,
    MeridianFonts? fonts,
    MeridianRadiusScale? radius,
    MeridianDensity? density,
    MeridianNeutralColors? lightNeutrals,
    MeridianNeutralColors? darkNeutrals,
  }) => MeridianBrand(
    id: id ?? this.id,
    name: name ?? this.name,
    light: light ?? this.light,
    dark: dark ?? this.dark,
    fonts: fonts ?? this.fonts,
    radius: radius ?? this.radius,
    density: density ?? this.density,
    lightNeutrals: lightNeutrals ?? this.lightNeutrals,
    darkNeutrals: darkNeutrals ?? this.darkNeutrals,
  );

  @override
  bool operator ==(Object other) =>
      other is MeridianBrand &&
      other.id == id &&
      other.name == name &&
      other.light == light &&
      other.dark == dark &&
      other.fonts == fonts &&
      other.radius == radius &&
      other.density == density &&
      other.lightNeutrals == lightNeutrals &&
      other.darkNeutrals == darkNeutrals;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    light,
    dark,
    fonts,
    radius,
    density,
    lightNeutrals,
    darkNeutrals,
  );
}
