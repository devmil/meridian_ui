# Steps

A compact line of named steps showing which are done, which is current and which are still to come: a guided workflow such as resolving a merge conflict (Pick, Review, Resolve, Continue). Flutter: `MeridianSteps` with `MeridianStep`s.

- The consumer provides `steps` (`MeridianStep`: a short `label` and an optional `key`; at least one), `current` (the active step's index; steps before it are done, steps after it upcoming, `steps.length` marks every step done) and an optional `semanticLabel` naming the line.
- One row. Each step is a round marker (`stepMarker`, 16px; 20px at touch density) and its label in `body`, `space-2` apart; steps are joined by a 16px `line-strong` hairline (`stepConnectorLength`) with `space-3` on either side.
- Done: a `success` check on `success-bg`, the label in `ink-muted`. Current: a filled `accent` marker with its number in `on-accent`, the label in `body-strong` `ink`. Upcoming: a `line-strong` outlined marker with its number and label in `ink-muted`. Numbers use the Count type (10px, tabular).
- When the line is narrower than every label needs, the labels of all but the current step hide (their markers stay) and the current label ellipsizes; narrower than the markers themselves, the line clips. It never overflows.
- Steps are not interactive: they show progress, they do not navigate. Every step announces its label, its state (done, current, upcoming) and its position ("2 of 4"), also while its label is hidden.
- Keep labels to a word or two and the line to a handful of steps. Put it at the top of the workflow it tracks; the workflow's own buttons move between steps.
