# SectionHeader

The 36px strip that names an island, a pane or a section inside one and holds its actions. Flutter: `MeridianSectionHeader` (the Island header is one).

- The consumer provides `title` (or a richer `titleChild`, such as a path with a muted directory; `title` stays the accessible name), `icon` or `leading`, `count` (quiet, with an optional `countLabel`), `caption` (metadata in `caption` `ink-muted` with tabular figures), `middle` (content that takes all the width the heading leaves, the heading keeping its natural width up to half the strip: a filter field, a row of view controls; let a row of controls scroll so it never pushes the actions out), `actions` (small IconButtons and Buttons, `space-1` apart), `divider` (the `line` hairline under it, on by default), `color` (transparent by default; `pane-alt` for a section inside an island) and `size` (`regular` in `body-strong` for an island or pane, `small` in `label` for a section inside one).
- Height `size-island-header` (36px; 48px at touch density so its buttons keep their target), `space-5` before and `space-3` after. The title ellipsizes first, then the caption; the actions never leave the strip.
- One strip per section. Never hand-build a header row with its own height or padding; never put two divider lines on top of each other (turn `divider` off when the content starts with an edge).
