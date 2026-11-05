# AppBar

The top bar of a touch screen, on `ground`. Flutter: `MeridianAppBar`.

- The consumer provides `title` (`heading` type), an optional `subtitle` (a `caption` line in `ink-muted`: the save state, a location), `leading` (back or menu IconButton), `actions` (IconButtons), `elevated` (a `line` hairline once content scrolls under it) and `centerTitle`.
- Without `leading` it shows a back button when the route can be popped, or a menu button that opens the Scaffold's Drawer (`automaticallyImplyLeading`).
- 56px tall plus the status bar inset (the hairline is drawn over the bar, not added to it), no elevation, no colour fill. The title follows large text up to 134% and shows in full as its tooltip, so the bar never grows. Desktop windows use the toolbar (ToolbarButtons on `ground`) instead.
