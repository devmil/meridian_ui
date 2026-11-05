# Icons

172 Lucide icons (lucide-static 1.37.0, ISC; the upstream licence header is kept in every file), named by their Lucide name. They are single-ink `currentColor` SVGs: the tiles here show them in black, but in the product they are tinted `ink` at rest, `ink-muted` when idle and `on-accent` on an accent fill.

- 24×24 viewBox, 2px stroke, round caps and joins. Draw at 16px (`size-icon`), 14px in chips and small controls, 18px with a 1.75 stroke in the toolbar, 20px at touch density.
- Groups: navigation, actions, status, objects, mail, system, notes, development. The full list with groups is `tokens/icons.json` in `meridian_ui`; Flutter names them in `MeridianIcons`.
- An app adds icons (GitLama's Git verbs) through `MeridianIconSet`, from the same Lucide version. No icon fonts, no Unicode action glyphs, no emoji, no second icon family.
