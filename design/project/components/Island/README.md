# Island

The rounded work surface. Flutter: `MeridianIsland` on a `MeridianGround`.

- Islands sit on `ground` 6px (`space-3`) apart and 6px from the window edge: `pane`, `radius-lg`, `shadow-pane` (the shadow is the edge; no border). The gutter between islands is the divider and the splitter. Islands never nest.
- The consumer provides `child`, optional `title` (`body-strong`), `icon` or `leading` (before the title), `count` (a quiet count after it), `subtitle` (metadata in `caption`, tabular figures), `actions` (small IconButtons and Buttons) for the 36px header (48px at touch density), `headerDivider` (the hairline under the header; off when the content starts with its own edge), `expandChild` for lists and editors, `padding`, and `color` to override `pane` (a document's paper). The header is a SectionHeader; never hand-build a 36px strip.
- The island tracks keyboard focus: while focus is inside, it draws a 1px `accent-soft` halo and its rows paint the selection solid `accent`. Only one island has focus at a time.
- Chrome (sidebar, toolbar, tab strip, touch app bar) sits straight on `ground`, not in an island, so the islands read as the content.
- Motion: The focus halo fades in and out; `contentKey` swaps content with a rise, instantly while scrubbing (MM-73, MM-74).
