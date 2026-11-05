# Calendar

A month of days to pick one from, inline or in a dialog. Flutter: `MeridianCalendar` and `showMeridianDatePicker`.

- The consumer provides `value`, `firstDate`, `lastDate` and `onChanged`. `showMeridianDatePicker` shows it in a 300px dialog with Cancel and OK and returns the day (or `null`); `title`, `confirmLabel` and `cancelLabel` default to the localized "Select date", OK and Cancel.
- The month and year in `body-strong` with previous and next buttons, the weekdays in the locale's order and narrow names (`caption`, `ink-muted`), and 32px day cells: today has an `accent` ring and `accent-ink`, the chosen day is solid `accent` with `on-accent`, days outside the range are `ink-faint` and cannot be chosen. Names come from `MaterialLocalizations`.
- The grid is one tab stop: arrow keys move a day or a week (following the reading direction), Page Up and Page Down a month, Home and End to the ends of the week, Enter or Space chooses. In the dialog a second Enter on the chosen day confirms.
- For a date a person types more easily than they pick (a birthday), use a TextField.
