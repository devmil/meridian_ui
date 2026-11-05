# SplitPane

Two panes that share a space, with a ResizeHandle between them: a list beside its detail, staged above unstaged changes, a sidebar beside the work. Flutter: `MeridianSplitPane`.

- `axis: horizontal` puts `first` at the start and `second` at the end; `vertical` stacks them. The panes are usually Islands; the `space-3` gap between them is the handle. Set `divider` only for panes inside one island, which have no gap of `ground` between them.
- Sizes are either a **ratio** (`ratio`, the first pane's share; or uncontrolled from `initialRatio`) with `onRatioChanged` during the drag and `onRatioChangeEnd` once it ends (persist here), or an **extent** (`extent` in logical pixels of the `pinned` pane, the other takes the rest) with `onExtentChanged` / `onExtentChangeEnd`.
- Neither pane gets smaller than `firstMinExtent` / `secondMinExtent` (200px by default); when both do not fit they shrink evenly, so the split never overflows.
- Drag the gap, or Tab to it and use the arrow keys (16px a press); double click or Enter calls `onReset` (an uncontrolled ratio returns to `initialRatio`). `focusable: false` keeps it out of the Tab order where the panes have their own resize command. It is announced as an adjustable control named `semanticLabel` ("Resize lists") whose value is the first pane's share ("40%"). Right-to-left layouts mirror the drag.
- Motion: 150ms into a hover the handle's `accent` line grows from its centre (MM-75); the panes follow the pointer exactly.
