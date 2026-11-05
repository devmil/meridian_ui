# ColorChoiceRow

Choosing a colour for something the person names: a label, a tab group, a repository, a calendar. Flutter: `MeridianColorChoiceRow`.

- The theme's eight categorical colours (`series-1` … `series-8`) as ColorSwatches, optionally led by a "No colour" swatch (`allowNone`) and followed by a ColorWell for any other colour (`allowCustom`). A categorical choice follows light and dark; a custom one stays the same in both.
- The consumer provides `value` (a `MeridianSeriesColor`, a `MeridianCustomColor` or `null` for none) and `onChanged` (`null` disables the row); optional `series` (which colours, in order), `noneLabel`, `customLabel`, `seriesLabels` and `pickerLabels`.
- The swatches are named with Meridian's own localized colour names: Blue, Teal, Amber, Orange, Rose, Violet, Cyan, Olive (Blau, Petrol, Bernstein, Orange, Rosa, Violett, Cyan, Oliv). The well is named by its hex value once it holds a colour, and keeps a custom colour while a palette colour is chosen, so it can be chosen again.
- Swatches wrap `space-2` apart; at touch density each keeps its 48px target.
