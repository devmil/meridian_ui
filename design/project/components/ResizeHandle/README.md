# ResizeHandle

Resizes the islands on either side of the gutter it sits in: a sidebar, an inspector, a split between two lists. Flutter: `MeridianResizeHandle`.

- It is the `space-3` gap itself, invisible at rest: hover shows a 2px `line-strong` rule, dragging turns it `accent`, keyboard focus `focus`. The cursor is the resize cursor for its `direction`.
- The consumer provides `semanticLabel` ("Resize inspector"), `onDrag` (the movement along `direction` in logical pixels; the consumer decides which island grows and clamps it), `onReset` (a double click or Enter restores the default size) and `keyboardStep` (arrow keys move it, 16px by default).
- Never draw a divider line between islands; the gap is the divider. Persist the size the person chose.
- For two panes that share a space, use SplitPane: it owns the handle, the sizes, the minimums and the announcement.
- Motion: 150ms into a hover an `accent` line grows from its centre (MM-75).
