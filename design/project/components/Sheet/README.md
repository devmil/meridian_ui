# Sheet

A bottom sheet for touch layouts: tool options, pickers, secondary flows. Flutter: `MeridianSheet` with `showMeridianSheet`.

- The consumer provides `child`, an optional `title` (`title` type) and header `actions` (Done), and `showHandle`.
- `raised`, top corners `radius-xl`, `shadow-float`, a 36×4 grab handle, at most 560px wide, on `scrim`. It slides up over 240ms (`motion-sheet`) and is dismissed by dragging down or tapping the scrim. It rises above the on-screen keyboard. Desktop apps use a Dialog or a Panel instead.
- Motion: Slides in over `motion-sheet` on the enter curve and closes over `motion-exit` (MM-48).
