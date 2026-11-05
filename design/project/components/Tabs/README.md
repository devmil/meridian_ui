# Tabs

A row of tabs. Flutter: `MeridianTabs` with `MeridianTab`s.

- **underline** (default) switches views inside an island: `label` type, `ink-muted` idle, `ink` and semibold when active, with a 2px `accent` rule that slides under the active tab.
- **pill** switches open documents on `ground` (repositories, mailboxes, notebooks): the active tab is a `pane` pill with `shadow-pane`, so it reads as the top of the island below. A 6px `warning` dot marks unsaved changes; `onClose` adds a close button on hover, on keyboard focus and on the active tab (hidden close buttons take no clicks; screen readers always find them, named by `closeLabel`).
- The consumer provides `tabs` (`label`, optional `icon`, `count`, `dirty`, `enabled`, `semanticLabel`), `index`, `onChanged`, and `dirtyLabel` to localize how a dirty tab is announced. The count and dirty state are read with the label ("Drafts, 3, unsaved changes").
- Arrow keys, Home and End move the selection and keyboard focus together, skip disabled tabs, follow the reading direction and scroll the tab into view.
- Motion: The rule or pill glides to the active tab; `tabKeys` grow new tabs in and collapse closed ones (MM-26, MM-27).
