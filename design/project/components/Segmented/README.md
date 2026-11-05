# Segmented

Picks one of two to four peer options that change a view: list or tree, day or week, light or dark. Flutter: `MeridianSegmented` with `MeridianSegment`s.

- The consumer provides `label` (the group's accessible name), `segments` (`value`, `label` and/or `icon`; icon-only segments need a `tooltip`), `value`, `onChanged`, `size: small`, `expand` to fill the width on touch. Without `expand` the control hugs its labels; in a space narrower than that, the segments share it and ellipsize their labels rather than overflow.
- Density sets the minimum track height. Larger text grows the tiles and the track to fit the scaled labels; a narrow control ellipsizes horizontally and never clips the glyphs vertically.
- Track `pane-alt` with a `line` edge; the selected segment is a `pane` tile with a `line-strong` edge and `shadow-control`. Arrow keys move the selection. With `manualActivation` they move only the focus ring, and Space or Enter selects: use it when a change is expensive (a filter that reloads a list). The focus ring shows for the keyboard only, never after a click; at touch density each segment is a 48px target.
- A segment with `enabled: false` is an option that exists but is unavailable right now: its label and icon read `ink-faint`, it takes no click, tap, Space or Enter, and the arrow keys (and Home and End) step over it. Its `tooltip` says why and still shows on hover; screen readers hear its label as a disabled button. It may be the selected value: the tile stays on it, with muted ink. Hide an option instead when it never applies here.
- Never for commands. More than four options is a Select.
- Motion: The raised tile glides to the chosen segment on `spring-snappy` (MM-14).
