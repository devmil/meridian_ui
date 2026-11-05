# Kbd

Keyboard keys for a shortcut, in menus, tooltips, buttons and the palette footer. Flutter: `MeridianKbd`. Keycaps wrap under bounded width; a long label wraps within its cap rather than clipping at enlarged text sizes.

- Pass `keys` in the platform's glyphs: ⌘ ⇧ ⌥ ↵ on macOS, the words Ctrl, Shift, Alt, Enter elsewhere. Never mix a spelled-out modifier with glyphs in one app. `onAccent` inside an `accent` fill (primary button, highlighted menu row).
- Hints on permanent chrome (buttons, a title-bar field) set `reveal: whileModifierHeld`: the keycaps appear, and take space, only while one of their command modifiers (⌘, Ctrl, ⌥) is held, so the hint shows when the person reaches for the shortcut. Shift never reveals; keys without a command modifier always show. Menus, the palette and shortcut references keep the default `always`.
- 18px keycaps on `pane-alt` with a `line-strong` edge and a 1px lip, `caption` type of the active density in `ink-muted`; keycaps grow with large text.
- Motion: `pressed` (or holding the whole chord) sinks the cap 1px and drops its lip (MM-17).
