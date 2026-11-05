# Radio

One choice from a short, visible set (two to five options). Flutter: `MeridianRadio` (build a group as a column of radios sharing `groupValue`).

- The consumer provides `value`, `groupValue`, `onChanged`, `label` and an optional `description`.
- Round 16px, `accent` fill with an `on-accent` centre dot when chosen. More than five options, or options that switch a view, go to Select or Segmented.
- Motion: The dot pops in on `spring-pop` and shrinks out over `motion-exit` (MM-13).
