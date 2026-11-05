# Banner

A persistent inline message about the state of the island or screen it sits in. Flutter: `MeridianBanner`.

- The consumer provides `message`, an optional bold `title` sentence, `tone` (`info`, `success`, `warning`, `attention`, `error`), at most two small `actions` (asserted in debug builds), and `onDismiss`.
- `radius-lg`, tinted in the tone's `-bg` colour, no border, the tone's icon. Use **attention** (orange) for work to do (a paused sync, a conflict to resolve); **error** only for failures.
- Say what happened, then what to do: "Could not send “Quarterly report”. The attachment is larger than 25 MB. Remove it or share a link instead." Transient results ("Archived 3 messages") are Toasts, not banners.
- Actions sit at the right, centred on the text; at touch density, below 480px wide and with enlarged text they go under the text instead. A bounded scrolling feedback area keeps the complete message and recovery controls reachable.
- Assistive technology reads the title and message as one node (a live region for `error` and `attention`); the actions stay separate buttons.
- Motion: `visible` reveals and collapses it; a tone change fades the colours and swaps the icon (MM-65, MM-66).
