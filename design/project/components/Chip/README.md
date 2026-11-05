# Chip

A compact label: a filter, a tag, a recipient, an attachment. Flutter: `MeridianChip`.

- The consumer provides `label` and optionally `icon`, `dotColor` (a `series` colour for a category; the text always goes with it), `tone` (neutral outline, `accent`, or a status tint), `selected` (a filter toggle: `accent-soft` with a check), `onPressed`, `onRemove` with its `removeLabel` ("Remove Anna"), and `enabled` (off shows `ink-faint` on a `line` edge and ignores input).
- At least 22px tall (32px at touch density), `radius-sm`, `label` type. The pill grows for enlarged text instead of clipping its line; the width remains bounded by the consumer’s `maxWidth` and truncates with an ellipsis.
- Every tone hovers except a selected filter: outlined chips take `pane-hover`, tinted chips darken by 4% `ink`; pressing adds another 4%.
- The remove button is its own button for assistive technology and the keyboard, and a 48px target at touch density (it may reach past the pill).
- Motion: Presses to 0.97; `visible: false` fades it and collapses its width (MM-02, MM-72).
