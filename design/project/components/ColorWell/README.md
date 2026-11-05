# ColorWell

Any other colour, beside a palette: the swatch at the end of a row of `ColorSwatch`es that opens a `ColorPicker` in a popover, as a desktop app offers a custom colour. Flutter: `MeridianColorWell`.

- The consumer provides `color` (the custom colour, `null` while there is none), `label` ("Custom colour"), `onChanged` (every change while the picker is open, so the owner shows it at once; `null` disables the well), optional `onChangeEnd`, `selected` (the custom colour is the chosen one), `initial` (where the picker starts without a `color`: usually the palette colour in use) and the picker's `groups`, `model` and `labels`.
- A swatch-sized disc of hues around the custom colour, edged and ringed like a `ColorSwatch`; without a colour, the hues around a `pane` centre with a plus. Selected adds the 2px `accent` ring.
- Its popover is 472px wide and holds a wide `ColorPicker` with the colour before the edit as its original. A click outside or Escape closes it and focus returns to the well. Keep a Cancel in the surrounding dialog: changes apply while the popover is open.
