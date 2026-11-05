# ColorSwatch

One colour in a palette: a pen colour, a cover colour, a label colour. Flutter: `MeridianColorSwatch`; build a palette as a `Wrap` of swatches `space-2` apart.

- The consumer provides `color` (content, not a theme token: it never changes with the theme), `label` (names the colour for the tooltip and assistive technology: "Blue", "Ink #18304F"), `selected` and `onPressed` (`null` disables it).
- A disc with a 1px `line-strong` edge, so white still reads on white; hover darkens the edge to `ink-muted`. Selected adds a check in a colour that contrasts with the disc and a 2px `accent` ring 2px outside. 24px, 32px at touch density with a 48px target. Disabled fades the disc to 50%.
- Selection is also announced (selected state), never shown by colour alone.
