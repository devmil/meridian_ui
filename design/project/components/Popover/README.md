# Popover

A floating panel under a trigger for a small task that is more than a list of commands: a filtered folder picker, a label picker with check boxes, a colour palette. Flutter: `MeridianPopoverAnchor` (wraps a trigger), `showMeridianPopover` (at a rect, returns what the content pops), `MeridianPopoverSurface` (docked).

- The consumer provides the content and optionally `width` (280px by default) and `maxHeight` (the content scrolls beyond it). The content owns its focus; the popover's route autofocuses into it.
- `raised`, `radius-xl`, `shadow-float`, like Menu. It opens below the trigger (above when there is no room). Escape and a click outside close it; the content closes it with `Navigator.pop`, optionally with a result.
- `showMeridianPopover` returns that result after the reverse transition and overlay removal complete. Wait for it before resizing the host, releasing caller-owned presentation state or opening follow-up UI; check that the invoking context is still mounted before using it.
- Use a Menu for commands; use a popover when the content needs a field, check boxes or its own layout. Keep it to one task; bigger work belongs in a Dialog.
- Motion: Grows from its anchor over `motion-overlay` and leaves in `motion-exit` (MM-40, MM-41).
