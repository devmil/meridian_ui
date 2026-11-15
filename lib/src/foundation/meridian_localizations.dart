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

  // Common ------------------------------------------------------------------

  /// A button or ✕ that closes a dialog, panel, banner or sheet.
  String get close;

  /// Tapping outside a menu, popover or dialog to dismiss it.
  String get dismiss;

  /// The button that abandons a choice.
  String get cancel;

  /// The button that confirms a choice.
  String get ok;

  /// The back button of an app bar.
  String get back;

  /// The button that opens the menu of a split button or overflow.
  String get showMenu;

  /// A drawer of navigation destinations.
  String get navigationMenu;

  /// The app bar button that opens the navigation drawer.
  String get openNavigationMenu;

  /// The action of a collapsed row's chevron.
  String get expand;

  /// The action of an expanded row's chevron.
  String get collapse;

  /// The text menu action that deletes the selection.
  String get textDelete;

  /// The text menu action that reads text with the camera.
  String get textScan;

  // Dates -------------------------------------------------------------------

  /// The month names, January first.
  List<String> get monthNames;

  /// The short month names, January first.
  List<String> get shortMonthNames;

  /// The weekday names, Monday first.
  List<String> get weekdayNames;

  /// The short weekday names, Monday first.
  List<String> get shortWeekdayNames;

  /// The one-letter weekday names, Monday first.
  List<String> get narrowWeekdayNames;

  /// The day weeks start on: `DateTime.monday` … `DateTime.sunday`.
  int get firstDayOfWeek;

  /// "November 2026".
  String formatMonthYear(DateTime date);

  /// "Nov 14, 2026" / "14. Nov. 2026".
  String formatMediumDate(DateTime date);

  /// "Saturday, November 14, 2026" / "Samstag, 14. November 2026".
  String formatFullDate(DateTime date);

  /// The time of day: "3:07 PM" / "15:07", or 24-hour when
  /// [alwaysUse24HourFormat] (from `MediaQuery.alwaysUse24HourFormatOf`).
  String formatTime(DateTime time, {bool alwaysUse24HourFormat = false});

  /// A date picker's heading.
  String get datePickerTitle;

  String get previousMonth;
  String get nextMonth;

  // License dialog ----------------------------------------------------------

  /// The title of a `MeridianLicenseDialog` when the app gives none.
  String get licensesTitle;

  /// The field that narrows the package list of a `MeridianLicenseDialog`.
  String get licensesFilter;

  /// How many licenses a package has: "3 licenses".
  String licensesCount(int count);

  /// A package filter that matched nothing.
  String get licensesNoMatches;

  /// The button that goes back from one package's licenses to the list.
  String get licensesBack;

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
  String get close => 'Close';
  @override
  String get dismiss => 'Dismiss';
  @override
  String get cancel => 'Cancel';
  @override
  String get ok => 'OK';
  @override
  String get back => 'Back';
  @override
  String get showMenu => 'Show menu';
  @override
  String get navigationMenu => 'Navigation menu';
  @override
  String get openNavigationMenu => 'Open navigation menu';
  @override
  String get expand => 'Expand';
  @override
  String get collapse => 'Collapse';
  @override
  String get textDelete => 'Delete';
  @override
  String get textScan => 'Scan text';
  @override
  List<String> get monthNames => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  @override
  List<String> get shortMonthNames => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  @override
  List<String> get weekdayNames => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  @override
  List<String> get shortWeekdayNames => const [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  @override
  List<String> get narrowWeekdayNames => const [
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];
  @override
  int get firstDayOfWeek => DateTime.sunday;
  @override
  String formatMonthYear(DateTime date) =>
      '${monthNames[date.month - 1]} ${date.year}';
  @override
  String formatMediumDate(DateTime date) =>
      '${shortMonthNames[date.month - 1]} ${date.day}, ${date.year}';
  @override
  String formatFullDate(DateTime date) =>
      '${weekdayNames[date.weekday - 1]}, ${monthNames[date.month - 1]} '
      '${date.day}, ${date.year}';
  @override
  String formatTime(DateTime time, {bool alwaysUse24HourFormat = false}) {
    final minute = time.minute.toString().padLeft(2, '0');
    if (alwaysUse24HourFormat) {
      return '${time.hour.toString().padLeft(2, '0')}:$minute';
    }
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    return '$hour:$minute ${time.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  String get datePickerTitle => 'Select date';
  @override
  String get previousMonth => 'Previous month';
  @override
  String get nextMonth => 'Next month';
  @override
  String get licensesTitle => 'Licenses';
  @override
  String get licensesFilter => 'Filter packages';
  @override
  String licensesCount(int count) =>
      count == 1 ? '1 license' : '$count licenses';
  @override
  String get licensesNoMatches => 'No packages match';
  @override
  String get licensesBack => 'All packages';
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
  String get close => 'Schließen';
  @override
  String get dismiss => 'Schließen';
  @override
  String get cancel => 'Abbrechen';
  @override
  String get ok => 'OK';
  @override
  String get back => 'Zurück';
  @override
  String get showMenu => 'Menü anzeigen';
  @override
  String get navigationMenu => 'Navigationsmenü';
  @override
  String get openNavigationMenu => 'Navigationsmenü öffnen';
  @override
  String get expand => 'Aufklappen';
  @override
  String get collapse => 'Zuklappen';
  @override
  String get textDelete => 'Löschen';
  @override
  String get textScan => 'Text scannen';
  @override
  List<String> get monthNames => const [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];
  @override
  List<String> get shortMonthNames => const [
    'Jan.',
    'Feb.',
    'März',
    'Apr.',
    'Mai',
    'Juni',
    'Juli',
    'Aug.',
    'Sept.',
    'Okt.',
    'Nov.',
    'Dez.',
  ];
  @override
  List<String> get weekdayNames => const [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];
  @override
  List<String> get shortWeekdayNames => const [
    'Mo.',
    'Di.',
    'Mi.',
    'Do.',
    'Fr.',
    'Sa.',
    'So.',
  ];
  @override
  List<String> get narrowWeekdayNames => const [
    'M',
    'D',
    'M',
    'D',
    'F',
    'S',
    'S',
  ];
  @override
  int get firstDayOfWeek => DateTime.monday;
  @override
  String formatMonthYear(DateTime date) =>
      '${monthNames[date.month - 1]} ${date.year}';
  @override
  String formatMediumDate(DateTime date) =>
      '${date.day}. ${shortMonthNames[date.month - 1]} ${date.year}';
  @override
  String formatFullDate(DateTime date) =>
      '${weekdayNames[date.weekday - 1]}, ${date.day}. '
      '${monthNames[date.month - 1]} ${date.year}';
  @override
  String formatTime(DateTime time, {bool alwaysUse24HourFormat = false}) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
  @override
  String get datePickerTitle => 'Datum auswählen';
  @override
  String get previousMonth => 'Vorheriger Monat';
  @override
  String get nextMonth => 'Nächster Monat';
  @override
  String get licensesTitle => 'Lizenzen';
  @override
  String get licensesFilter => 'Pakete filtern';
  @override
  String licensesCount(int count) =>
      count == 1 ? '1 Lizenz' : '$count Lizenzen';
  @override
  String get licensesNoMatches => 'Keine passenden Pakete';
  @override
  String get licensesBack => 'Alle Pakete';
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
