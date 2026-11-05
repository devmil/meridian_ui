# Paper

A document page resting on the Canvas. Flutter: `MeridianPaper`.

- The consumer provides `color` (the page's paper: document content, never a theme colour, so it does not invert in dark), the `child` that draws the page, the page's `aspectRatio`, `selected` and a `semanticLabel` ("Page 3 of 12").
- `shadow-pane` is its edge; corners are 2px (`paperRadius`): paper, not a card. A selected page gets a 2px `accent` ring outside the edge; the paper itself never changes colour.
- Content drawn on paper (ink, scans, templates) uses the document's own colours, never theme tokens.
