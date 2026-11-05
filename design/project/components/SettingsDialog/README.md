# SettingsDialog

An app's settings window: pages listed at the start, the selected page beside them. Flutter: `MeridianSettingsDialog` with `showMeridianDialog`.

- Use it once settings outgrow one column of SettingsRows (more than about two screens, or groups as different as appearance, columns and remote hosts). A handful of rows stays a `MeridianDialog` with a SettingsGroup.
- The consumer provides `title` ("Settings", "Preferences"), `pages` (`MeridianSettingsPage`: `label`, `icon`, `description` saying what the page covers, and a `builder` for its SettingsGroups), `initialPage` (open on the page the person came for), `onPageChanged`, `onClose` (pops the route by default) and `footer`. A page's `key` names its list entry for tests. An app that moves between pages itself (a link from one page to another) passes `page` and stores what `onPageChanged` reports.
- `footer` is a line under the pages, in view while the page scrolls, for what the person must know about their last change ("That shortcut is already taken", "The settings could not be saved"): a `caption` in a live region, `danger` for failures. Leave it out when there is nothing to say.
- A title bar with ✕ over a hairline; the page list on `ground` (`settingsDialogPageListWidth`, 200px) with NavRows, a vertical hairline, and the page on `raised`: its label in `title`, the description in `caption` `ink-muted`, then the rows. 840px wide (`settingsDialogWidth`) so SettingsRows keep label and control side by side; 640px tall (`settingsDialogHeight`, at most 85% of the window) and the height holds while pages change. Each page scrolls on its own and starts at the top.
- Changes apply straight away: no Save, no Cancel, no footer. It closes with ✕ or Escape, like a Dialog that manages. A question a page needs (removing a host) opens its own Dialog on top.
- The selected NavRow is `accent-soft`, solid `accent` while the list has keyboard focus. Tab reaches the list, Up and Down move between pages, Enter or Space picks one.
- Below 600px of dialog width (`settingsDialogPagedBreakpoint`) and at touch density the list becomes a full-width Select above the page.
- Don't put commands that act on the whole dialog in a page, nest pages, or hide a page the person may need; show it with an explanation instead.
