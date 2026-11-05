# StatusDot

A 6px state dot with its label: running, synced, offline. Flutter: `MeridianStatusDot`.

- The consumer provides `tone` (`neutral`, `accent`, `success`, `warning`, `danger`, `attention`), `label` (or `semanticLabel` when the label is elsewhere in the row) and `halo` for a live or running state.
- Never colour alone: the label or a glyph always goes with it.
- Motion: `live` pulses a halo; it holds still with reduce motion (MM-69).
