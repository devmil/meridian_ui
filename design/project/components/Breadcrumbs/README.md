# Breadcrumbs

A one-line trail of where the person is: a commit, the folders of a path, a file. Flutter: `MeridianBreadcrumbs` with `MeridianBreadcrumb`s.

- Each crumb takes a `label`, an optional `leading` (a small icon, or an icon with a short code such as a commit hash), `mono` (the label in `code-sm` for identifiers), `onActivate` (click, Enter or Space; without it the crumb is plain text), `onContextMenu` (a secondary click, the context-menu key or Shift+F10, with the global position for the app's native menu), `semanticLabel` and `emphasis` (`body-strong` in `ink`: the current location, usually the last crumb).
- The trail takes `crumbs`, `onOverflow` (the hidden crumbs and a position: the app shows them in a native menu), an optional `overflowLabel` for the `…` crumb and a `semanticLabel` that names the trail as a header.
- Crumbs are separated by a small `chevron-right` (`chevron-left` right to left) in `ink-faint`. Labels are `body` in `ink-muted` and turn `ink` on hover.
- The first and last crumbs never fold. When the row is too narrow, the middle crumbs fold from the second onwards into one `…` crumb, keeping the crumbs nearest the end; then the first crumb's label ellipsizes (down to 48px), and only then the last's. Folded crumbs leave the focus order.
- Interactive crumbs are `size-control-sm` tall with `space-2` padding and `radius-sm`; hover `pane-hover` (following the surface), pressed adds 4% `ink`, keyboard focus the `focus` ring. A click does not move focus. They read as buttons; a crumb with only a context menu reads as text with a long-press action.
- Activating a crumb moves to that place; it never changes the crumbs' order. Keep the trail short: one target, its folders, one leaf. Don't put commands in it; they go in the bar's buttons and the crumbs' context menus.
- Motion: The hover fill fades in over `motion-hover`; folding and unfolding the middle is instant, so the trail never moves under the pointer.
