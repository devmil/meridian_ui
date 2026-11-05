# MiddleEllipsis

One line of text that keeps both ends when it is too long: a branch, a file path, an identifier. Flutter: `MeridianMiddleEllipsis`.

- Use it where the end of a name tells instances apart (`feature/login-form` and `feature/login-flow`). Titles, sentences and labels keep the end ellipsis of `Text`.
- The consumer provides the `text`, an optional `style` merged over the ambient text style, and an optional `semanticsLabel`. Assistive technology always reads the complete text.
- The width follows the shown text up to the available width, so a chip or pill around it hugs the name and never reserves its maximum. Give the parent a maximum width, not a fixed one.
- The text never wraps, and whole characters are kept: an emoji or a combined letter is not split. Show the complete text in a tooltip where the shortened one can appear.
