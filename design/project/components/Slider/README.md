# Slider

A continuous value: stroke width, zoom, opacity, a before/after comparison. Flutter: `MeridianSlider`.

- The consumer provides `label`, `value`, `onChanged`, `min`/`max`, optional `step` (snapping and the keyboard step; default 5% of the range), `valueLabel` (how to announce the value: "2.5 pt") and `onChangeEnd` (called with the final value after a drag, a tap or each keyboard step).
- A 2px `line-strong` rail with an `accent` fill and a 12px `pane` thumb ringed in `accent` (20px at touch density). Arrow keys (following the reading direction), Home and End move it. `min == max` is allowed; without a bounded width it takes 160px. Show the number next to it when the exact value matters.
- `track` replaces the rail and fill with a gradient for a colour channel (hue, red, brightness): 8px tall (12px at touch density) with a 1px `line-strong` edge. Build it with `AlignmentDirectional` ends so it turns with a right-to-left slider.
- Motion: The thumb grows to 1.15 while hovered or dragged; the fill follows the pointer exactly (MM-15).
