# Avatar

A person's initials on a categorical colour (`series-1` … `series-8`) picked from a stable hash of their name, so the same person keeps the same colour everywhere. Flutter: `MeridianAvatar`.

- The consumer provides `name`, optional `colorKey` (hash an email address instead), `size` (16px in rows, 20px in touch rows, 28px in headers, 40px `xLarge` for a person's card), `monogram` (the app's own initials, at most two characters) and `image` (a picture replaces the fill, same size and shape; the initials show while it loads and when it fails; a loaded picture sits on `pane`, so a logo with a transparent background never shows the fill or initials through it).
- Decorative: it always sits next to the name as text, so it is hidden from assistive technology.
- `onPressed` makes it a button for something about the person (a profile, an offer to load pictures): it gets the focus ring and pressed state, `tooltip` (the name by default) on hover, and is announced as a button with that name.
- The initials scale down to fit the circle at large text sizes; the circle keeps its size.
- Motion: A loaded image fades in over the initials (MM-71).
