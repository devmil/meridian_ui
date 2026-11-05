import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The strings Meridian's own widgets show or announce, in English and
/// German.
///
/// Widgets read them with [MeridianLocalizations.of]. An app does not have
/// to register anything: without [delegate] the strings follow the
/// language of the nearest [Localizations] (German for `de`, English
/// otherwise). Add [delegate] to `localizationsDelegates` to resolve them
/// with the app's other catalogs, or put a [MeridianLocalizationsScope]
/// above a subtree to supply an app's own translation.
///
/// A widget property that names a string (a `label`, a `placeholder`)
/// always wins over these defaults.
abstract class MeridianLocalizations {
  const MeridianLocalizations();

  /// Resolves [MeridianLocalizations] for `en` and `de` (and English for
  /// every other language).
  static const LocalizationsDelegate<MeridianLocalizations> delegate =
      _MeridianLocalizationsDelegate();

  /// The languages with their own catalog.
  static const supportedLocales = [Locale('en'), Locale('de')];

  /// The strings for [context]: a [MeridianLocalizationsScope], then the
  /// [delegate]'s, then the catalog for the nearest locale.
  static MeridianLocalizations of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<MeridianLocalizationsScope>()
          ?.localizations ??
      Localizations.of<MeridianLocalizations>(context, MeridianLocalizations) ??
      forLocale(Localizations.maybeLocaleOf(context));

  /// The built-in catalog for [locale]: German for `de`, else English.
  static MeridianLocalizations forLocale(Locale? locale) =>
      locale?.languageCode == 'de'
      ? const MeridianLocalizationsDe()
      : const MeridianLocalizationsEn();

  // Find bar ----------------------------------------------------------------

  /// The find field's placeholder and accessible name.
  String get findPlaceholder;

  /// The button and Shift+Enter that go to the previous match.
  String get findPrevious;

  /// The button and Enter that go to the next match.
  String get findNext;

  /// The toggle for a search that tells capitals from small letters.
  String get findCaseSensitive;

  /// The button that clears the field.
  String get findClear;

  /// The button that closes the find bar.
  String get findClose;

  /// The position of the current match: "3 of 12".
  String findMatchPosition(int current, int total);

  /// The number of matches while none is current: "12 matches".
  String findMatchCount(int total);

  /// A search that found nothing.
  String get findNoMatches;

  /// The toggle that matches whole words only.
  String get findWholeWord;

  /// The toggle that reads the query as a regular expression.
  String get findRegex;

  /// A search that is still running.
  String get findSearching;

  // Feedback ---------------------------------------------------------------

  /// A generic "loading" announcement for a progress state without its own
  /// text.
  String get loading;

  // Steps -------------------------------------------------------------------

  /// A step of a `MeridianSteps` line that is finished.
  String get stepDone;

  /// The step of a `MeridianSteps` line the person is on.
  String get stepCurrent;

  /// A step of a `MeridianSteps` line that is still to come.
  String get stepUpcoming;

  /// A step's place in its line: "2 of 4".
  String stepPosition(int position, int total);

  // Split pane --------------------------------------------------------------

  /// The divider between two panes, when the app gives no name.
  String get splitPaneResize;

  /// A share of the space, such as a pane's size: "40%" or "40 %".
  String percent(int value);

  // Colours -----------------------------------------------------------------

  /// The names of the categorical colours `series-1` … `series-8`, in order:
  /// blue, teal, amber, orange, rose, violet, cyan, olive.
  List<String> get seriesColorNames;

  /// The swatch that chooses no colour.
  String get colorNone;

  /// The well that opens the picker for any other colour.
  String get colorCustom;

  /// A custom colour, named by its hex value.
  String colorCustomValue(String hex);

  // Colour picker -----------------------------------------------------------

  String get colorPickerWheel;
  String get colorPickerHue;
  String get colorPickerSaturation;
  String get colorPickerBrightness;
  String get colorPickerRed;
  String get colorPickerGreen;
  String get colorPickerBlue;
  String get colorPickerHsb;
  String get colorPickerRgb;
  String get colorPickerModel;
  String get colorPickerHex;
  String get colorPickerInvalidHex;
  String get colorPickerOriginal;
  String get colorPickerNew;
  String colorPickerSwatch(String hex);
  String degrees(int value);
}

/// English, Meridian's default.
class MeridianLocalizationsEn extends MeridianLocalizations {
  const MeridianLocalizationsEn();

  @override
  String get findPlaceholder => 'Find';
  @override
  String get findPrevious => 'Previous match';
  @override
  String get findNext => 'Next match';
  @override
  String get findCaseSensitive => 'Match case';
  @override
  String get findClear => 'Clear search';
  @override
  String get findClose => 'Close find';
  @override
  String findMatchPosition(int current, int total) => '$current of $total';
  @override
  String findMatchCount(int total) => total == 1 ? '1 match' : '$total matches';
  @override
  String get findNoMatches => 'No matches';
  @override
  String get findWholeWord => 'Match whole word';
  @override
  String get findRegex => 'Use regular expression';
  @override
  String get findSearching => 'Searching…';
  @override
  String get loading => 'Loading…';
  @override
  String get stepDone => 'done';
  @override
  String get stepCurrent => 'current';
  @override
  String get stepUpcoming => 'upcoming';
  @override
  String stepPosition(int position, int total) => '$position of $total';
  @override
  String get splitPaneResize => 'Resize panes';
  @override
  String percent(int value) => '$value%';
  @override
  List<String> get seriesColorNames => const [
    'Blue',
    'Teal',
    'Amber',
    'Orange',
    'Rose',
    'Violet',
    'Cyan',
    'Olive',
  ];
  @override
  String get colorNone => 'No colour';
  @override
  String get colorCustom => 'Custom colour';
  @override
  String colorCustomValue(String hex) => 'Custom colour $hex';
  @override
  String get colorPickerWheel => 'Hue and saturation';
  @override
  String get colorPickerHue => 'Hue';
  @override
  String get colorPickerSaturation => 'Saturation';
  @override
  String get colorPickerBrightness => 'Brightness';
  @override
  String get colorPickerRed => 'Red';
  @override
  String get colorPickerGreen => 'Green';
  @override
  String get colorPickerBlue => 'Blue';
  @override
  String get colorPickerHsb => 'HSB';
  @override
  String get colorPickerRgb => 'RGB';
  @override
  String get colorPickerModel => 'Colour model';
  @override
  String get colorPickerHex => 'Hex';
  @override
  String get colorPickerInvalidHex => 'Enter six hex digits, such as #18304F';
  @override
  String get colorPickerOriginal => 'Original colour';
  @override
  String get colorPickerNew => 'New colour';
  @override
  String colorPickerSwatch(String hex) => 'Colour $hex';
  @override
  String degrees(int value) => '$value°';
}

/// German.
class MeridianLocalizationsDe extends MeridianLocalizations {
  const MeridianLocalizationsDe();

  @override
  String get findPlaceholder => 'Suchen';
  @override
  String get findPrevious => 'Vorheriger Treffer';
  @override
  String get findNext => 'Nächster Treffer';
  @override
  String get findCaseSensitive => 'Groß-/Kleinschreibung beachten';
  @override
  String get findClear => 'Suche leeren';
  @override
  String get findClose => 'Suche schließen';
  @override
  String findMatchPosition(int current, int total) => '$current von $total';
  @override
  String findMatchCount(int total) => '$total Treffer';
  @override
  String get findNoMatches => 'Keine Treffer';
  @override
  String get findWholeWord => 'Nur ganzes Wort';
  @override
  String get findRegex => 'Regulären Ausdruck verwenden';
  @override
  String get findSearching => 'Wird gesucht …';
  @override
  String get loading => 'Wird geladen …';
  @override
  String get stepDone => 'erledigt';
  @override
  String get stepCurrent => 'aktuell';
  @override
  String get stepUpcoming => 'ausstehend';
  @override
  String stepPosition(int position, int total) => '$position von $total';
  @override
  String get splitPaneResize => 'Bereiche skalieren';
  @override
  String percent(int value) => '$value %';
  @override
  List<String> get seriesColorNames => const [
    'Blau',
    'Petrol',
    'Bernstein',
    'Orange',
    'Rosa',
    'Violett',
    'Cyan',
    'Oliv',
  ];
  @override
  String get colorNone => 'Keine Farbe';
  @override
  String get colorCustom => 'Eigene Farbe';
  @override
  String colorCustomValue(String hex) => 'Eigene Farbe $hex';
  @override
  String get colorPickerWheel => 'Farbton und Sättigung';
  @override
  String get colorPickerHue => 'Farbton';
  @override
  String get colorPickerSaturation => 'Sättigung';
  @override
  String get colorPickerBrightness => 'Helligkeit';
  @override
  String get colorPickerRed => 'Rot';
  @override
  String get colorPickerGreen => 'Grün';
  @override
  String get colorPickerBlue => 'Blau';
  @override
  String get colorPickerHsb => 'HSB';
  @override
  String get colorPickerRgb => 'RGB';
  @override
  String get colorPickerModel => 'Farbmodell';
  @override
  String get colorPickerHex => 'Hex-Wert';
  @override
  String get colorPickerInvalidHex =>
      'Sechs Hex-Ziffern eingeben, etwa #18304F';
  @override
  String get colorPickerOriginal => 'Ursprüngliche Farbe';
  @override
  String get colorPickerNew => 'Neue Farbe';
  @override
  String colorPickerSwatch(String hex) => 'Farbe $hex';
  @override
  String degrees(int value) => '$value°';
}

/// Supplies [localizations] to the Meridian widgets below it, for an app
/// that translates Meridian into a language it does not ship.
class MeridianLocalizationsScope extends InheritedWidget {
  const MeridianLocalizationsScope({
    required this.localizations,
    required super.child,
    super.key,
  });

  final MeridianLocalizations localizations;

  @override
  bool updateShouldNotify(MeridianLocalizationsScope oldWidget) =>
      localizations != oldWidget.localizations;
}

class _MeridianLocalizationsDelegate
    extends LocalizationsDelegate<MeridianLocalizations> {
  const _MeridianLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MeridianLocalizations> load(Locale locale) =>
      SynchronousFuture(MeridianLocalizations.forLocale(locale));

  @override
  bool shouldReload(_MeridianLocalizationsDelegate old) => false;
}
