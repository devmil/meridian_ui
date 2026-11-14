import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Loads `package:intl`'s date symbols for the app's locale, so
/// `DateFormat` works in that locale.
///
/// Material's localizations did this as a side effect; an app without them
/// needs it explicitly. `MeridianApp` registers [delegate]; add it to a
/// `WidgetsApp` of your own.
abstract final class MeridianDateFormatting {
  /// Initializes date formatting for each locale the app switches to.
  static const LocalizationsDelegate<MeridianDateFormatting> delegate =
      _Delegate();
}

final class _Ready implements MeridianDateFormatting {
  const _Ready();
}

class _Delegate extends LocalizationsDelegate<MeridianDateFormatting> {
  const _Delegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MeridianDateFormatting> load(Locale locale) {
    // intl's bundled data loads synchronously (the returned future only
    // signals completion), so the first frame is not held back.
    if (!_loaded) {
      unawaited(initializeDateFormatting());
      _loaded = true;
    }
    return SynchronousFuture(const _Ready());
  }

  static var _loaded = false;

  @override
  bool shouldReload(_Delegate old) => false;
}
