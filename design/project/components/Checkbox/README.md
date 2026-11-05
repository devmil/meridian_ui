# Checkbox

An option that applies when a command runs ("Include attachments", "Sign this commit"). Flutter: `MeridianCheckbox`.

- The consumer provides `label`, `value`, `onChanged` (`null` disables), optional `description` (a `caption` line) and `tristate` for a partial selection (`null` value shows the mixed state, announced as mixed rather than checked).
- 16px box, `control-edge` border, `accent` fill with an `on-accent` check when on. Clicking the label toggles it; Space toggles it when focused.
- Settings that apply straight away are Switches, not checkboxes.
- Motion: The fill pops from 0.6 on `spring-pop` and the check draws in 140ms after 40ms; unchecking fades and erases it (MM-11).
