# Select

A trigger that shows the current value and opens a Menu of the choices, the current one checked. Flutter: `MeridianSelect`.

- The consumer provides `value`, `values`, `valueLabel`, `onChanged`, an accessible `label` ("Sort by"), optional `width`, `minWidth` and `size: small`. In forms and dialogs set `showLabel` to show the label above the trigger (as a TextField does) and `expand` to fill the width.
- Without a `width` the trigger fits its longest choice, at least `minWidth` (160px), so it keeps its size when the value changes; the chevron sits at the trailing edge. Pass `minWidth: 0` for a picker that usually holds one short name (a remote).
- Density sets the minimum trigger height. Larger text increases it to fit the scaled value and vertical padding; a narrow trigger ellipsises horizontally and never clips the glyphs vertically.
- The trigger looks like a secondary Button: `pane`, `line-strong` edge, `shadow-control`, `chevron-down` in `ink-muted`. The menu opens below it (above when there is no room) and is at least as wide as the trigger.
- Use it for five or more options, or for fewer when they do not switch a view (sort order, account, language).
- Motion: The chevron turns half a turn while the menu is open (MM-16).
