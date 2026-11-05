# PropertyList

A read-only list of labelled values for inspectors and detail islands: a process's parent and user, a commit's author and date, a message's headers. Flutter: `MeridianPropertyList` of `MeridianProperty`.

- The consumer provides `properties`: each a `label` (sentence case), a `value` (text; say "Unknown" or "-" rather than leaving it empty), `monospace` for identifiers, paths, numbers and commands, `selectable` (on by default, so values can be copied) and `maxLines` to clamp long values.
- Wide layouts put the `caption` label in an `ink-muted` 112px column (`labelWidth`) beside the value; below 2.5 label columns and at touch density the label stacks above it. Rows are `space-3` apart. Values are `body` in `ink`, or `code` with tabular figures when monospace.
- Group long lists with an `overline` heading or a hairline, not cards. Editable values belong in a SettingsRow, not here.
