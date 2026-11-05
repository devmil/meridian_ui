# NavRow

Rows of a navigation sidebar (folders, labels, views, branches), grouped under a NavSection. Flutter: `MeridianNavRow` inside `MeridianNavSection`.

- The sidebar sits straight on `ground`, not in an island. Rows are `size-row` tall with `radius-sm` inset hover on `ground-hover`. The active row is `accent-soft`; while the sidebar has keyboard focus it is solid `accent`.
- NavSection provides `title` (set as an `overline`), an optional `count`, and an `action` icon button revealed on hover or keyboard focus (always visible on touch); `collapsible` sections fold from their header (a 48px target at touch density), with Enter and Space as well as a click.
- NavRow provides `label`, `icon` (with optional `iconColor`, a `series` colour for labels), `count` (quiet by default; `accent` for unread), `depth` (14px per level), `expandable`/`expanded` with `onToggleExpanded`, `current` (where the person is: a check mark and `body-strong`), `selected`, `enabled`, `onTap`, `onContextMenu`. Arrow right and left expand and collapse; the chevron is its own focusable target (48px at touch density) and assistive technology gets expand and collapse actions.
- `leading` puts a picture in the icon slot instead of `icon` (an app's own icon, an avatar), at the density's small icon size.
- Rows grow past `size-row` only when large text needs the room.
- On phones the same rows go in a Drawer (`MeridianDrawer`) that the app bar's menu button opens.
- `drop` shows feedback while something is dragged over the row (mail onto a folder): `accept` paints `accent-soft` with an `accent` edge and `accent-ink` text, `reject` fades the row to `ink-faint`. The app owns the drag target.
- Motion: Sections reveal their rows and stagger the first six in; the current check travels between rows of a section (MM-24, MM-25).
