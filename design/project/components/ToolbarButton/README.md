# ToolbarButton

A primary command in a desktop title bar: an 18px icon (1.75 stroke) over a `caption` label, on `ground`. Flutter: `MeridianToolbarButton`.

- The consumer provides `icon`, `label`, `onPressed`, an optional `badge` (a count to act on, shown as an `accent` Count) and `menu` (a split caret for variants: Send → Send later, Pull → Rebase) with `menuLabel` naming the caret ("More send options"). The badge is read as the button's value; the menu opens under the whole split button and at least as wide.
- Commands go left, the app's centre piece (GitLama's Compass, a search field) in the middle, view toggles and settings right as IconButtons. No border; hover `ground-hover`. Hide the caption with `showLabel: false` in narrow windows; the label stays the tooltip.
- A click does not take focus, as in native title bars: focus stays where the person was working, and a dialog the command opens hands it back there. Tab still reaches the buttons.
- Motion: Presses to 0.97; `nudge` moves the icon in its direction (Push up, Pull and Fetch down, Refresh a turn); the `badge` pops in, rolls, and shrinks away (MM-02, MM-06, MM-07).
