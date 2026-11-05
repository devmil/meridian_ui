# IconButton

A single-icon command for toolbars, island headers and row hover actions. Flutter: `MeridianIconButton`.

- The consumer provides `icon`, a required `label` (the tooltip and the accessible name), `onPressed`, `size: small` in rows and headers, `active` for toggles (`accent-soft` fill, `accent-ink` icon) and `onGround` when it sits on `ground` (hover `ground-hover`; defaults to the surface it is in).
- Hover follows the surface: on a hovered or selected row (or inside a field) the button darkens that fill instead of painting `pane-hover`, so it never vanishes into a hovered row. Rows publish their fill through `MeridianSurfaceScope`; a custom table wraps its cells in `MeridianSurfaceScope.withFill`.
- `canRequestFocus: false` for row actions of a tree or table and find-bar arrows: a click leaves keyboard focus with the list or field. Offer the same command through the list's keys or menu.
- Idle icons are `ink-muted` and turn `ink` on hover. On a solid `accent` fill (a focused selection) they are `on-accent-muted` and turn `on-accent` on hover, whatever `color` asks for, so row actions stay visible on the selected row. Use an icon button only where the icon is unambiguous (search, close, more, pin). Anything else is a Button with a label.
- Motion: Presses to 0.97; `active` changes fade over `motion-select`; `turns` rotates a chevron; `nudge` moves the icon 2px on activation (MM-02, MM-05, MM-07).
