# ColumnHeader

A column heading of a table: the label, and the sort arrow on the column the table is sorted by. Flutter: `MeridianColumnHeader`.

- The consumer provides `label` (short, sentence case), `sortDirection` (`ascending`, `descending`, or `null` when the table is not sorted by it), `alignEnd` for numeric columns so the heading sits over the numbers, `onPressed` (sort by it, or reverse the order) and `onContextMenu` (the column menu at the pointer: show, hide and reset columns). `sortedAscendingLabel` and `sortedDescendingLabel` are announced with the label.
- It fills the header cell it sits in. Put the header row on `pane-alt` with a `line` hairline below; the heading hovers with `pane-hover`. `caption` type in `ink-muted`; the sorted column is `ink` at weight 600 with a 12px arrow.
- Resizing and reordering columns stay with the table: put a resize grip on the cell's edge and offer every drag as a menu item too.
