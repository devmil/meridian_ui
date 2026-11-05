# Shortcut field

An explicitly armed keyboard recorder. Flutter: `MeridianShortcutField`.

- The consumer supplies localized `label`, `emptyLabel`, `recordingLabel`,
  `preparingLabel` and `clearLabel`, displayed `keys`, controlled `recording`
  and `preparing` state, record/cancel/clear callbacks and an optional `conflict`
  slot. `showLabel: false` keeps the accessible label in a settings row.
- The application owns registration, validation, conflicts and persistence.
  Suspend global shortcut admission before setting `recording: true`. Use
  `preparing` while that admission drains. Close or retire the recording owner
  when its surface unmounts; the primitive owns only its two focus nodes.
- One real non-modifier key-down emits a `MeridianShortcutStroke` with physical
  and logical key identities and modifier booleans; it never copies the typed
  character. Modifier-only, synthesized and repeated events do not emit.
- Unmodified Escape cancels. Plain Tab and Shift+Tab cancel and leave normal
  traversal intact. The application may support modified Escape/Tab chords.
  Losing capture focus or disabling the field cancels; the application decides
  when to exit recording after an accepted stroke.
- Keycaps wrap at narrow widths. Height is the density control minimum and grows
  with enlarged text. Clear is a separately named keyboard/semantic action;
  disabled fields record and clear nothing. Conflict content is a live region.
- Use Meridian interaction fills and focus feedback, `control-edge`, `pane`,
  `radius-md`, body/label text, space-3/4 and `MeridianKbd`. Do not put native
  hotkey registration, OS key-name assumptions or app error codes in the field.
