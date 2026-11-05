# Switch

A setting that applies straight away ("Check mail automatically", "Show live CPU tint"). Flutter: `MeridianSwitch`.

- The consumer provides `label` (required: it is also the accessible name), `value`, `onChanged`, an optional `description` (a `caption` line under the label, read as the hint), `showLabel: false` when a settings row already shows the label, `labelFirst` for touch settings lists (label left, track at the end).
- Track `line-strong` with a `control-edge` edge when off, `accent` when on; the thumb is `pane`. It grows at touch density. The change is confirmed by the switch itself: no Save button, no toast.
- Motion: The thumb springs across on `spring-snappy` and stretches towards its travel while pressed (MM-12).
