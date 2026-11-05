# SelectionBar

The strip that replaces a list's header while items are selected: how many, the commands for them, and Clear. Flutter: `MeridianSelectionBar` with `MeridianSelectionAction`s.

- The consumer provides `label` (the count: "3 selected", announced as it changes), `actions`, `clearLabel` with `onClear`, `overflowLabel` for the "more" menu, and an optional `leading` control (a select-all menu).
- An action is its control in the bar (usually a small IconButton or a menu anchor) and, optionally, the same command as a menu entry (`overflow`). When the bar is too narrow, actions with an overflow entry move, last first, into a trailing "more" menu; actions without one stay.
- `accent-soft`, the count in `accent-ink` with tabular figures and never more than a third of the width; controls in it hover relative to that fill. Keep its commands the same as the items' context menu.
- Motion: `visible` lets it rise in from 12px on `spring-gentle` and leave downwards; a leading count rolls (MM-30).
