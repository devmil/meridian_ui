# Progress

Spinner, progress bar and meter. Flutter: `MeridianSpinner`, `MeridianProgressBar`, `MeridianMeter`.

- **Spinner**: 12px, replaces an icon while something runs (a loading Button keeps its label). Turns once per 700ms, 2s with reduce motion.
- **ProgressBar**: a 2px `accent` rule; indeterminate (a sliding 30% bar) until progress is known, then determinate; the indeterminate bar sweeps ease-in-out over 1.1s (`motion-progress`) and holds still with reduce motion. Set `track` for a standalone bar on a `line` track; leave it off when it runs along an edge (the bottom of a title pill, the top of an island).
- **Meter**: a 3px value bar for a metric (CPU, storage, quota), always next to its number. The fill animates toward new values and turns `warning` or `danger` past `warningAt` and `dangerAt`.
- ProgressBar and Meter need a bounded width (a `SizedBox`, `Expanded` or stretched column); debug builds assert it.
- Motion: The sweep morphs into the value bar; at 100% the bar holds 300ms and fades unless `persistent`; the Spinner waits 150ms before it shows (MM-60 to MM-63).
