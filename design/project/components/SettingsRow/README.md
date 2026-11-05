# SettingsRow

A settings form row. Flutter: `MeridianSettingsRow` inside `MeridianSettingsGroup`.

- On desktop the label is right-aligned in a 200px column, the controls sit left in the next column, and `help` goes below them in `caption` `ink-muted` (at most 380px). Below 520px wide and at touch density the label stacks above the controls.
- The consumer provides `label`, `children` (the controls) and `help`. SettingsGroup lays rows out 16px apart under an optional `overline` title.
- In a dialog form set `fitLabels` on the SettingsGroup: the label column hugs the group's widest label (never wider than 200px) with 12px to the controls, so a short label such as "Remote" sits beside its control instead of floating in a wide column. A row with an empty label lines a checkbox up with the controls above it. The fitted form stacks only when the controls would get narrower than a select.
- Changes apply straight away, confirmed by the control's own state: no Save button, no floating labels, no cards.
