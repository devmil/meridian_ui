# Toast

A transient confirmation that floats at the bottom of the window: "Archived 3 messages", with at most one action, usually Undo. Flutter: `showMeridianToast` (renders a `MeridianToast`).

- The consumer provides `message`, `tone` (`neutral`, `success`, `warning`, `error`), optional `actionLabel` and `onAction`, and `duration` (`motion-toast`, 4 s; `motion-toast-action`, 8 s with an action). `overlay` sends it to another window's or route's overlay, for a toast that must outlive the surface it comes from (Undo send after a composer window closed).
- `raised`, `radius-xl`, `shadow-float`, 360px at most; it arrives on a spring (see Motion). Errors that need a decision are banners or dialogs, never toasts. Apps with an operation log (GitLama's Logbook) put results there instead.
- For a result that arrives after the screen that started the work has closed, take `Overlay.of(context, rootOverlay: true)` before the `await` and call `showMeridianToastIn(overlay, …)`. `hideMeridianToast()` fades out a toast whose news has been superseded.
- A long action or enlarged text moves the action below the message when they cannot fit beside each other. Both rows stay within the toast width; the message remains complete.
- One toast at a time: a new one replaces the current one. Hovering or focusing it pauses the countdown, which resumes when the pointer and focus leave. It fades out when it goes, is announced to assistive technology on every platform, and keeps local `Theme` overrides.
- Motion: Arrives from below (and the trailing side on desktop) on `spring-gentle`; an action toast shows a shrinking time rule that pauses on hover; it leaves 8px outwards (MM-49, MM-50).
