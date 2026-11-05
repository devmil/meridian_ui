# Suggestions

Wrap the search field and results in `MeridianResultNavigation` to keep typing focus while Up/Down wrap the selected index and Enter activates it. The owner resets selection when filtering, scrolls the selected row into view, and rejects disabled actions. Empty lists consume these keys without activation.

Completions under a field while the person types: branch names, recipients, tags, paths. Flutter: `MeridianSuggestionSurface` with `MeridianSuggestionRow` and `MeridianSuggestionHeader`.

- The field keeps keyboard focus and the caret. Up and Down move the highlight, Enter or Tab accepts it, Escape closes the list; the rows never take focus. A pointer click accepts a row directly.
- A row provides `label`, `onTap`, optional `icon` or `leading` (a picture such as a recipient's avatar), `hint` (where it comes from: a remote, a path) and `highlighted` for the one Enter accepts. Group rows under `MeridianSuggestionHeader`s (`overline`, in capitals) when they come from different sources.
- `raised`, `radius-xl`, `shadow-float`, `space-2` padding, at most 240px tall (`maxHeight`) and scrolling beyond that; rows at the density's row height. The highlighted row is solid `accent` with `on-accent` text and `on-accent-muted` hint, like a keyboard-highlighted menu row; hover paints `pane-hover`.
- It is a form control, not a menu: it filters as the person types and never holds commands. For a fixed list of choices use Select; for commands use Menu.
- Motion: Grows from its field like a popover (MM-40, MM-41).
