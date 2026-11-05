# FloatingButton

The one prominent command of a touch screen that floats over its content: create a notebook, compose a message. Flutter: `MeridianFloatingButton`.

- The consumer provides `icon`, `label` (always the tooltip and the accessible name), `onPressed` (`null` disables it) and `extended` to show the label next to the icon.
- `accent` fill with an `on-accent` icon, `radius-lg`, `shadow-float`, 56px square (a pill when extended); hover brightens like a primary Button, pressed adds 4% `ink`. Disabled: `ink-muted` on `accent-soft`, no shadow.
- At most one per screen, at the bottom trailing corner (`space-8` in), clear of the content's last row. Desktop layouts put the command in the toolbar instead.
- Motion: Presses to 0.97 and springs back (MM-02).
