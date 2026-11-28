# EmptyState

What an empty list or screen says. Flutter: `MeridianEmptyState`.

- The consumer provides `title` (what is true: "No messages match “invoice 2025”"), an optional `icon` or `illustration`, `message` (one sentence on what to do), one `action`, and `headline` for first-run and welcome screens (the `display` style).
- `heading` title, `ink-muted` message, 24px `ink-muted` icon, centred at most 360px wide; it scrolls rather than overflows in a short space. No emoji, no exclamation marks.
- `illustration` is the app's own artwork in place of the icon: its mascot in a small scene that says what is true (a file moved without changes, nothing selected). Use it in an app's detail panes, in theme colours, with the same scene for the same state everywhere; lists and dialogs keep the icon. `progress` still shows the spinner.
- `progress` is the loading state of the same place: a 24px Spinner in `ink-muted` replaces the icon (it waits 150ms, so quick loads never flash), the title says what is loading ("Loading history…") and is announced politely. `progressValue` adds a determinate bar under the title when the share is known. Use it, not a bare centred text or spinner, wherever a pane waits for its content.
- `compact` is the in-pane size for small islands and detail panes: `body` title, `caption` message, `space-6` around it. Every empty, loading and failed state of one app uses the same size in the same kind of place.
- Motion: Icon, headline, text and action enter one after the other, once (MM-67); the progress spinner waits 150ms before it shows.
