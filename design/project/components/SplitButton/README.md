# SplitButton

A default command with separately reachable alternatives. Flutter:
`MeridianSplitButton`. The primary half uses Button; the caret uses IconButton
and anchors the menu to the whole compound control.

- Supply localized `label`, `optionsLabel`, `entries`, `onPressed`, and an `icon`
  for `compact` mode. `primaryKey` and `optionsKey` identify the two controls.
- `onPressed: null` disables only the default command. `optionsEnabled` controls
  the caret independently; unsupported folder Save must not hide file Save As.
- `loading` suppresses primary activation while retaining its focus, and uses
  Button's delayed spinner. `success` uses Button's edge-triggered confirmation.
  The menu remains independently available; consumers disable affected entries.
- Compact mode keeps the accessible command name and renders an icon with the
  same loading/confirmation owner. It is a primary Button, not a copied spinner.
- Keep both controls in start-to-end reading order and let labels grow at 200%
  text. Escape dismisses the menu and returns keyboard focus to its caret.
- Size, rank, focus nodes and disabled reasons follow the existing primitives.
  The consumer owns output, busy admission, localization and menu decisions.
