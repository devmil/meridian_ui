# Range slider

Select an interval with `MeridianRangeSlider` and immutable `MeridianRangeValues`.

- Provide distinct localized `startLabel` and `endLabel`, ordered `values`, and `onChanged`. The consumer owns the confirmed values; use `onChangeEnd` to commit a completed gesture. `valueLabel` announces domain units. `min`, `max` and optional `step` share the slider contract.
- The handles never cross. Clicking the rail selects the nearest endpoint; coincident handles retain the last focused endpoint. Each handle has its own keyboard focus and slider semantics. Tab visits start then end, arrows follow reading direction, Home/End reach that handle's permitted bounds.
- A null callback or zero span disables input. An unbounded parent uses the default slider width. Use the standard density thumb and hit-height tokens, accent interval fill, line-strong rail, keyboard focus ring and MM-15 thumb emphasis. Reduced motion removes enlargement.
- Preview is a static design specimen. Flutter owns interaction and accessible stepping.
