# Button

A labelled command. Flutter: `MeridianButton`.

The density's control height is a minimum. Enlarged text grows the button to
fit its label line and vertical padding; surrounding rows must permit that
height instead of clipping it back to the unscaled extent.

- **primary** at most once per island or screen, for the thing it exists to do (Send, Export, Commit). **secondary** is the default. **quiet** for inline and low-stakes actions. **danger** only inside a confirming dialog; in rows and headers use **dangerQuiet**.
- The consumer provides: `label` (verb plus object, sentence case: "Move 3 messages to archive", never "OK"), `onPressed` (`null` disables), optional `icon` (or `leading`, a small picture where no Lucide glyph fits: a colour dot, a pen preset), `trailingIcon`, `shortcut` (keys shown inside the button; `shortcutReveal: whileModifierHeld` shows them only while the modifier is held), `loading` (keeps the label, swaps the icon for a spinner), `disabledReason` (the tooltip that says why), `size: small` in island headers and rows, `expand` for full-width buttons on touch.
- `success` is edge-triggered: set it after confirmed output, then reset it before another operation. By default the leading icon becomes a check for `motion-hold`. `successReplacesLabel: true` crossfades the whole label and decorations to a centred check over `motion-quick`, keeping the content mounted so width and the accessible command name stay unchanged. Reduced motion keeps the crossfade with a static check.
- `onSuccessFinished` reports the completed hold once, bound to the callback supplied when `success` turned true. Starting `loading`, clearing `success`, or unmounting cancels the report. The consumer owns output success and any close action; do not report or retry external output from this presentation callback.
- `iconOnly` requires an icon and preserves the accessible label, tooltip, delayed spinner, confirmation and focus while drawing only the icon at the density control extent. Change this property on the existing owner during responsive layout; padding switches with the geometry so shrinking cannot temporarily squeeze the icon.
- The width follows the label; never fix it, German runs up to 40% longer.
- Height `size-control` (28px), `size-control-sm` (22px) small, `size-control-touch` (44px) at touch density with a 48px hit target. `label` type, `radius-md`, `space-5` padding.
- States: hover `pane-hover` (primary brightens), pressed adds 4% `ink`, keyboard focus a 2px `focus` ring 1px outside, disabled `ink-faint` on no fill (primary: `ink-muted` on `accent-soft`).
- Motion: Presses to 0.97 and springs back; `loading` swaps the icon for a spinner after 150ms; `success` holds a check for 900ms, optionally replacing the whole label while preserving width; `onSuccessFinished` reports only a completed hold (MM-02, MM-03, MM-04).
