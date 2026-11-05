# Skeleton

A placeholder bar for content that is loading. Flutter: `MeridianSkeleton`.

- The consumer provides `width` and `height` (10px by default). Use a few bars of different widths per row, matching the row they stand in for. `pane-hover` on `radius-xs`; it breathes gently, with no shimmer, so a loading list stays calm.
- Show skeletons only for loads that take longer than about 300ms: pass `delay: MeridianDurations.skeletonDelay` and the bar appears only after it (its space is kept meanwhile).
- Motion: Breathes between 0.55 and 1; `MeridianSkeleton.swap` crossfades the loaded content in (MM-64).
