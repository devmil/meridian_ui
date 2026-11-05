# Drawer

The navigation drawer of a phone layout: the app's destinations on a side sheet that slides in from the leading edge over `scrim`. Flutter: `MeridianDrawer` in `Scaffold.drawer`.

- The consumer provides the `child` (NavRows in a padded list, wrapped in a `SafeArea`), an optional `semanticLabel` (defaults to the platform's "Navigation menu") and `width` (304px, never more than the window minus 56px).
- `pane`, trailing corners `radius-xl`, `shadow-float`. `MeridianAppBar` shows the menu button that opens it; the scrim closes it.
- Wider layouts show the same NavRows in a sidebar instead of a drawer. With reduce motion an app may show them in a Sheet.
