import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import '../foundation/meridian_icons.g.dart';
import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import 'actions.dart';
import 'containers.dart';
import '../foundation/meridian_localizations.dart';
import '../foundation/meridian_dates.dart';

/// A month of days to pick one from: the month and year with previous and
/// next buttons, the weekdays in the locale's order, and the days. Today
/// has an `accent` ring, the chosen day is solid `accent`, days outside
/// [firstDate]…[lastDate] are `ink-faint` and cannot be chosen.
///
/// The grid is one tab stop. Arrow keys move a day or a week, Page Up and
/// Page Down a month, Home and End to the start and end of the week, and
/// Enter or Space chooses the day. Names come from [MeridianLocalizations].
class MeridianCalendar extends StatefulWidget {
  const MeridianCalendar({
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    super.key,
    this.value,
    this.autofocus = false,
  });

  /// The chosen day, or `null`.
  final DateTime? value;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;
  final bool autofocus;

  @override
  State<MeridianCalendar> createState() => _MeridianCalendarState();
}

class _MeridianCalendarState extends State<MeridianCalendar> {
  late DateTime _focused = _clamp(
    MeridianDates.dateOnly(widget.value ?? DateTime.now()),
  );
  late DateTime _month = DateTime(_focused.year, _focused.month);
  final _focus = FocusNode(debugLabel: 'meridian-calendar');
  var _hasFocus = false;
  DateTime? _hovered;

  @override
  void initState() {
    super.initState();
    MeridianInputModality.retain();
  }

  @override
  void didUpdateWidget(covariant MeridianCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = widget.value;
    if (value != null && !MeridianDates.isSameDay(value, oldWidget.value)) {
      _focused = _clamp(MeridianDates.dateOnly(value));
      _month = DateTime(_focused.year, _focused.month);
    }
  }

  @override
  void dispose() {
    MeridianInputModality.release();
    _focus.dispose();
    super.dispose();
  }

  DateTime get _first => MeridianDates.dateOnly(widget.firstDate);
  DateTime get _last => MeridianDates.dateOnly(widget.lastDate);

  DateTime _clamp(DateTime day) {
    if (day.isBefore(_first)) return _first;
    if (day.isAfter(_last)) return _last;
    return day;
  }

  bool _selectable(DateTime day) =>
      !day.isBefore(_first) && !day.isAfter(_last);

  void _moveFocus(DateTime day) {
    final next = _clamp(day);
    setState(() {
      _focused = next;
      _month = DateTime(next.year, next.month);
    });
  }

  void _showMonth(int delta) {
    final month = MeridianDates.addMonths(_month, delta);
    final days = MeridianDates.daysInMonth(month.year, month.month);
    final day = _focused.day > days ? days : _focused.day;
    setState(() {
      _month = month;
      _focused = _clamp(DateTime(month.year, month.month, day));
    });
  }

  void _choose(DateTime day) {
    if (!_selectable(day)) return;
    setState(() => _focused = day);
    widget.onChanged(day);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final firstWeekday = MeridianLocalizations.of(context).firstDayOfWeek % 7;
    // DateTime.weekday is 1 (Monday) … 7 (Sunday); the index 0 is Sunday.
    final column = (_focused.weekday % 7 - firstWeekday) % 7;
    DateTime shift(int n) =>
        DateTime(_focused.year, _focused.month, _focused.day + n);
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _moveFocus(shift(rtl ? 1 : -1));
      case LogicalKeyboardKey.arrowRight:
        _moveFocus(shift(rtl ? -1 : 1));
      case LogicalKeyboardKey.arrowUp:
        _moveFocus(shift(-7));
      case LogicalKeyboardKey.arrowDown:
        _moveFocus(shift(7));
      case LogicalKeyboardKey.pageUp:
        _showMonth(-1);
      case LogicalKeyboardKey.pageDown:
        _showMonth(1);
      case LogicalKeyboardKey.home:
        _moveFocus(shift(-column));
      case LogicalKeyboardKey.end:
        _moveFocus(shift(6 - column));
      case LogicalKeyboardKey.enter ||
          LogicalKeyboardKey.numpadEnter ||
          LogicalKeyboardKey.space:
        // A second Enter on the chosen day goes to the enclosing dialog.
        if (MeridianDates.isSameDay(_focused, widget.value) &&
            event.logicalKey != LogicalKeyboardKey.space) {
          return KeyEventResult.ignored;
        }
        _choose(_focused);
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final localizations = MeridianLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final firstWeekday = localizations.firstDayOfWeek % 7;
    final canGoBack = _month.isAfter(DateTime(_first.year, _first.month));
    final canGoForward = _month.isBefore(DateTime(_last.year, _last.month));
    final daysInMonth = MeridianDates.daysInMonth(_month.year, _month.month);
    final offset =
        (DateTime(_month.year, _month.month).weekday % 7 - firstWeekday) % 7;
    final today = MeridianDates.dateOnly(DateTime.now());
    final focusVisible = _hasFocus && MeridianInputModality.keyboard;
    return SizedBox(
      width: MeridianLayout.calendarWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: MeridianSpace.space2),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    localizations.formatMonthYear(_month),
                    style: meridian.text.bodyStrong,
                  ),
                ),
              ),
              MeridianIconButton(
                label: localizations.previousMonth,
                icon: rtl
                    ? MeridianIcons.chevronRight
                    : MeridianIcons.chevronLeft,
                size: MeridianControlSize.small,
                onPressed: canGoBack ? () => _showMonth(-1) : null,
              ),
              MeridianIconButton(
                label: localizations.nextMonth,
                icon: rtl
                    ? MeridianIcons.chevronLeft
                    : MeridianIcons.chevronRight,
                size: MeridianControlSize.small,
                onPressed: canGoForward ? () => _showMonth(1) : null,
              ),
            ],
          ),
          const SizedBox(height: MeridianSpace.space3),
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  SizedBox(
                    width: MeridianLayout.calendarCell,
                    child: Text(
                      localizations.narrowWeekdayNames[(firstWeekday + i + 6) %
                          7],
                      textAlign: TextAlign.center,
                      style: meridian.text.caption.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: MeridianSpace.space2),
          Focus(
            focusNode: _focus,
            autofocus: widget.autofocus,
            onKeyEvent: _onKey,
            onFocusChange: (value) => setState(() => _hasFocus = value),
            child: Wrap(
              children: [
                for (var i = 0; i < offset; i++)
                  const SizedBox.square(dimension: MeridianLayout.calendarCell),
                for (var d = 1; d <= daysInMonth; d++)
                  _day(
                    context,
                    DateTime(_month.year, _month.month, d),
                    today: today,
                    focusVisible: focusVisible,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _day(
    BuildContext context,
    DateTime day, {
    required DateTime today,
    required bool focusVisible,
  }) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final selectable = _selectable(day);
    final selected = MeridianDates.isSameDay(day, widget.value);
    final isToday = MeridianDates.isSameDay(day, today);
    final hovered = selectable && MeridianDates.isSameDay(day, _hovered);
    final focused = focusVisible && MeridianDates.isSameDay(day, _focused);
    final radius = BorderRadius.circular(MeridianRadiusScale.pill);
    final fill = selected
        ? colors.accent
        : hovered
        ? colors.paneHover
        : meridianClear(colors.paneHover);
    final ink = !selectable
        ? colors.inkFaint
        : selected
        ? colors.onAccent
        : isToday
        ? colors.accentInk
        : colors.ink;
    final label = MeridianLocalizations.of(context).formatFullDate(day);
    return Semantics(
      button: true,
      selected: selected,
      enabled: selectable,
      label: label,
      excludeSemantics: true,
      onTap: selectable ? () => _choose(day) : null,
      child: MouseRegion(
        cursor: selectable
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = day),
        onExit: (_) {
          if (MeridianDates.isSameDay(_hovered, day)) {
            setState(() => _hovered = null);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: selectable
              ? () {
                  _focus.requestFocus();
                  _choose(day);
                }
              : null,
          child: SizedBox.square(
            dimension: MeridianLayout.calendarCell,
            child: Padding(
              padding: const EdgeInsets.all(MeridianSpace.space1),
              child: CustomPaint(
                foregroundPainter: MeridianFocusRingPainter(
                  visible: focused,
                  color: colors.focus,
                  radius: radius,
                ),
                child: AnimatedContainer(
                  duration: meridianHoverDuration(
                    context,
                    MeridianDates.isSameDay(_hovered, day),
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: radius,
                    border: Border.all(
                      color: isToday && !selected
                          ? colors.accent
                          : meridianClear(colors.accent),
                    ),
                  ),
                  child: Text(
                    '${day.day}',
                    style: MeridianTextStyles.numeric(
                      (selected || isToday
                              ? meridian.text.bodyStrong
                              : meridian.text.body)
                          .copyWith(color: ink),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks for a day in a dialog with a [MeridianCalendar]. Returns the day,
/// or `null` when the person cancels. Enter on the chosen day confirms.
///
/// [title], [confirmLabel] and [cancelLabel] default to the localized
/// "Select date", OK and Cancel. [locale] overrides the locale of the
/// month names, weekdays and first day of the week (a regional date format).
Future<DateTime?> showMeridianDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? title,
  String? confirmLabel,
  String? cancelLabel,
  Locale? locale,
}) {
  var chosen = MeridianDates.dateOnly(initialDate);
  Widget localized(BuildContext context, Widget child) => locale == null
      ? child
      : Localizations.override(context: context, locale: locale, child: child);
  return showMeridianDialog<DateTime>(
    context: context,
    builder: (outerContext) => localized(
      outerContext,
      Builder(
        builder: (dialogContext) {
          final localizations = MeridianLocalizations.of(dialogContext);
          void confirm() => Navigator.of(dialogContext).pop(chosen);
          return StatefulBuilder(
            builder: (context, setState) => MeridianDialog(
              title: title ?? localizations.datePickerTitle,
              width: MeridianLayout.datePickerWidth,
              onSubmit: confirm,
              content: Center(
                child: MeridianCalendar(
                  value: chosen,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  autofocus: true,
                  onChanged: (day) => setState(() => chosen = day),
                ),
              ),
              actions: [
                MeridianButton(
                  label: cancelLabel ?? localizations.cancel,
                  variant: MeridianButtonVariant.quiet,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                MeridianButton(
                  label: confirmLabel ?? localizations.ok,
                  variant: MeridianButtonVariant.primary,
                  onPressed: confirm,
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
