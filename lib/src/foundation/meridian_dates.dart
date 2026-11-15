/// Calendar arithmetic for date pickers and date lists, on local dates
/// without a time of day.
abstract final class MeridianDates {
  /// [date] at midnight.
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Whether [a] and [b] fall on the same day (either may be `null`).
  static bool isSameDay(DateTime? a, DateTime? b) =>
      a != null &&
      b != null &&
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;

  /// Whether [a] and [b] fall in the same month.
  static bool isSameMonth(DateTime? a, DateTime? b) =>
      a != null && b != null && a.year == b.year && a.month == b.month;

  /// The number of days in [month] of [year].
  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// The first day of the month [months] after [monthDate]'s month.
  static DateTime addMonths(DateTime monthDate, int months) =>
      DateTime(monthDate.year, monthDate.month + months);

  /// The number of whole months from [start]'s month to [end]'s.
  static int monthDelta(DateTime start, DateTime end) =>
      (end.year - start.year) * 12 + end.month - start.month;
}
