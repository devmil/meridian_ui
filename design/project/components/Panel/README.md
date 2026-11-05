# Panel

A floating panel with a header and a close button, anchored by the app: an inspector, an operations log, a filter builder. Flutter: `MeridianPanel`.

- The consumer provides `title`, `child`, `onClose`, header `actions`, `width` (420px, `panelWidth`) and `padding` (no top padding: the header spaces the body).
- `raised`, `radius-xl`, `shadow-float`, a 44px header (48px at touch density, so its buttons keep their target); it grows in from its `origin`. It floats above the islands without a scrim and closes with Escape (while focus is inside) or its close button.
- Motion: Grows from its `origin` like an overlay (MM-40).
