# Tooltip

A short label that appears while the pointer rests on a control, on a long press, or on keyboard request. Flutter: `MeridianTooltip`, on the widgets layer's `RawTooltip`.

- The consumer provides `message` (or `richMessage`), `excludeFromSemantics` (when the control already announces the same text), `preferBelow`, `waitDuration` and `triggerMode`. `MeridianTooltipState.ensureTooltipVisible()` shows it from code (a dialog's disabled reason).
- An `ink` chip with `caption` text in `pane`, corners `radius-sm`, `space-3` by `space-2` padding, at most 320px wide (`tooltipMaxWidth`), 4px below the target or above it when there is no room.
- It waits `motion-tooltip-wait` before it shows and leaves over `motion-exit` (MM-44). An empty message adds nothing.
- Every Meridian control that has only an icon names itself with one: IconButtons, ToolbarButtons, swatches, chips' remove buttons, the title of an app bar. Don't put actions or long help in a tooltip.
