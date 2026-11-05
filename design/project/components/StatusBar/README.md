# StatusBar

The window's bottom strip on `ground`: live state and totals ("Polling every second", "412 processes"), never commands. Flutter: `MeridianStatusBar`.

Its token height is a minimum. It grows to fit enlarged caption text and
consumer content; do not wrap it in a fixed-height box.

- The consumer provides `leading` items (state, usually a StatusDot) and `trailing` items (totals). They are `space-5` apart; leading items shrink and ellipsize first.
- 24px tall, `caption` type in `ink-muted` with tabular figures, `space-5` from the window edges, no hairline: the islands above end with the island gap.
- Put commands in the toolbar and transient results in toasts; the status bar only reports.
- `MeridianStatusBarItem` is one item: an optional small `icon` (or `leading`), a one-line `label` that swaps with a rise when it changes and ellipsizes at `maxWidth`. With `onPressed` it becomes a quiet button that opens more about what it shows (the About window, the branch list, the connected host), with `tooltip` on hover; it never runs a command.
- Motion: Text items swap with a 3px rise (MM-76).
