# Count

A pill number: unread mail, items to act on, section totals. Flutter: `MeridianCount`.

- The consumer provides `label` and `tone`: **neutral** (`line`), **accent** (something actionable: unread, commits to pull), **attention** (work to do: conflicts, pending review), **danger** (failures), **quiet** (a bare `ink-muted` number in section headers).
- 16px tall (it grows with large text instead of clipping), 10px semibold tabular figures. Give it a `semanticLabel` ("12 unread") when the number alone is ambiguous.
- Motion: Whole numbers roll digit by digit; `emphasizeIncrease` pops on increase (MM-70).
