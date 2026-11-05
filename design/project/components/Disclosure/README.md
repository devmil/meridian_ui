# Disclosure

A collapsible group with a chevron header, instead of Material's ExpansionTile. Flutter: `MeridianDisclosure`.

- The consumer provides `title`, `child`, `initiallyExpanded` or a controlled `expanded` with `onExpansionChanged`, an optional `trailing` widget (read separately by assistive technology) and `enabled`. `header` replaces the title text with richer content (a commit subject with its author line); the header grows to fit it and `title` stays the accessible name.
- A row-height header: 12px `chevron-right`/`chevron-down` in `ink-muted`, a `label` title, `pane-hover` on hover (`ground-hover` on `ground`), plus 4% `ink` while pressed, `ink-faint` when disabled; the body indents 16px. It exposes its expanded state to assistive technology.
- Motion: The chevron turns and the body reveals (MM-24).
