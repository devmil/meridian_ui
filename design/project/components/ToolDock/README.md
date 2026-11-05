# ToolDock

The floating tool palette of a document screen: pen, eraser, selection, a few colours, undo. Flutter: `MeridianToolDock` with `MeridianToolDockDivider`.

- `raised`, `radius-xl`, `shadow-float`, 4px padding; buttons 2px apart; `line-strong` dividers between tool groups. It hugs its content, horizontally (`axis: Axis.horizontal`) or as a vertical rail.
- The consumer provides `children`: IconButtons (the current tool with `active`), ColorSwatches and dividers, plus a `semanticLabel` ("Tools"). The screen places the dock (bottom centre on phones, top centre or the writing hand's side on tablets), keeps it clear of the writing palm and decides what moves into an overflow menu (keep the moved item's label and selected state).
- One dock per screen. It floats over the Canvas without a scrim and never over the page being written on mid-stroke.
