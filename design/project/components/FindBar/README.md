# FindBar

Finds text in the content it sits above: a diff, a file, a log, a history. Flutter: `MeridianFindBar`.

- A search TextField (`search` variant, `small`) showing where the current match is ("3 of 12", localized; "No matches"; "Searching…"), then Previous and Next, optional toggles for case (`case-sensitive`), whole words (`whole-word`) and regular expressions (`regex`), the owner's `trailing` controls (search scopes, apply as a filter) and Close.
- The consumer owns the search: it provides `onChanged`, `onNext`, `onPrevious`, `matchCount`, `currentMatch` (from 0) and `searching`, the toggles' values with their `on…Changed` callbacks (a toggle shows only with its callback), `onClose` (no Close button without), `error` (an invalid expression) and `labels` (each falls back to Meridian's own strings). Never show a raw "3/12".
- Keyboard: Enter goes to the next match and Shift+Enter to the previous one, also before the first search (so Enter can run it); Escape clears the query and, on an empty field, closes the bar. Bind the app's own Find and Find Next shortcuts to focus the field and to `onNext`.
- The field is 200px (`findFieldWidth`) and gives way first; when even 120px (scaled with the text) does not fit beside the buttons, the field takes the whole width and the buttons move below it. Previous and Next are disabled until there are matches. `visible` reveals and collapses the bar, at once under reduced motion.
- Motion: `visible` reveals and collapses it (MM-24 reveal), at once with reduce motion; the counter swaps with a roll (MM-70).
