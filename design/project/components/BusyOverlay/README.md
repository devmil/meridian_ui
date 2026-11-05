# BusyOverlay

Covers a page or island while a blocking operation runs (signing in, verifying a code): the content dims under a light `scrim` and takes no input, and a `raised` pill shows a spinner with what is happening. Flutter: `MeridianBusyOverlay`.

- The consumer provides an optional `message` ("Verifying…"), announced when the overlay appears, and an optional `action`, usually a quiet Cancel button, that stays usable at the pill's end. Stack it over the surface that waits, not over the whole window, and keep keyboard focus out of the covered content too.
- Say what is happening in the user's words ("Merging main into release…"), not how it is recorded.
- Prefer a Button's `loading` state and keep the rest usable; use the overlay only when nothing on the surface may change until the operation ends.
- Motion: Blocks input at once and shows after 150ms (MM-68).
