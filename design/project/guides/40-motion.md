# Motion

Meridian moves like a well-made native app. Motion shows where something came from and where it went. It confirms that an action landed, and it is gone before anyone waits for it. This guide is the motion contract for every app built on `meridian_ui`. The primitives implement the shared catalogue below, so an app gets it by using them. App-specific moments (GitLama's commit landing, for example) are built from the same tokens and helpers and documented in that app.

## Principles

1. **Motion explains change.** Only animate a state change the person caused or needs to notice. Nothing moves at rest, apart from the few live indicators listed here (spinner, indeterminate progress, the live status halo).
2. **Things travel.** An indicator glides from the old item to the new one instead of jumping: the selection bar, the segmented tile, the tab rule and the menu highlight. A row that moves between lists travels there.
3. **Fast in, faster out.** Entrances take 100–240 ms. Exits take about 70% of their entrance and use the exit curve. Nothing in the working UI runs longer than 320 ms, except the attention tint fading back (900 ms, and it never blocks) and the rare celebrate moment (520 ms).
4. **Never in the way.** Every animation can be interrupted and retargets from where it is now. Input is never blocked, and focus never waits for an animation. A second click in the middle of a transition wins.
5. **Physics for direct manipulation.** Springs drive what the pointer grabs, throws or toggles (drag, reorder, switch, press release, glides), so a quick repeat never feels mechanical. Timed curves drive everything the app does on its own.
6. **One voice per region.** In a region, one thing leads and everything else waits or fades. Lists stagger their entrance: at most 6 items, 18 ms apart. The rest appear together.
7. **Small distances.** Things rise 4 px (overlays), 6 px (content swaps), 8 px (dialogs) or 12 px (toasts). Nothing flies across the screen, apart from items travelling to a place the person can see.
8. **Reduce motion is a first-class mode.** With the platform's reduce-motion setting on, movement becomes an instant state change or a crossfade of at most 100 ms. Springs, shakes, pulses, pops and staggers are off. Celebrate moments become their static end state. Spinners turn once per 2 s.
9. **Only transform, opacity and colour.** Animate position, scale, opacity, colour, clip and stroke progress. Layout (height or width) is only animated with `motion-layout` for insert, remove and reveal. Never animate layout inside a scrolling list's item builder.

## Tokens

All motion values live in `tokens/meridian.tokens.json` under `motion`. The generator emits them as `MeridianDurations`, `MeridianCurves`, `MeridianSprings` and `MeridianMotionScales`. Use them through `MeridianMotion.of(context, …)` so reduce motion is honoured automatically.

### Durations

| Token | ms | Curve | Use |
|---|---|---|---|
| `motion-hover` | 80 | linear | Hover fill in (existing) |
| `motion-hover-out` | 160 | linear | Hover fill out: slower, so sweeping the pointer across rows leaves a soft trail |
| `motion-press` | 60 | exit | Press-in: a control scales to `press-scale` |
| `motion-quick` | 100 | standard | Small flips: icon swap, count roll, check stroke, chevron rotate, colour-only changes |
| `motion-select` | 120 | standard | Selection fill, toggles, tab rule when not springing (existing, curve moves from easeOut to standard) |
| `motion-exit` | 100 | exit | Anything leaving: overlays, toasts, rows, hover actions |
| `motion-overlay` | 140 | enter | Menus, popovers, tooltips entering (existing, curve moves to enter) |
| `motion-dialog` | 200 | enter | Dialog and sheet surface entering; scrim fade |
| `motion-layout` | 200 | standard | Size changes: disclosure, banner, row insert or remove, button width, reveal |
| `motion-sheet` | 240 | enter | Sheets and side panels sliding in (existing, curve moves from easeOutCubic to enter) |
| `motion-emphasized` | 240 | standard | Values in live lists and meters moving to a new value (existing, curve moves from easeOutCubic to standard) |
| `motion-highlight` | 320 | standard | An app's signature moment, e.g. an item travelling to its new home |
| `motion-celebrate` | 520 | standard | A rare success moment; at most one per action the person took |
| `motion-attention` | 900 | exit-soft | A changed item's `accent-soft` tint fading back to normal |
| `motion-reduced-fade` | 100 | linear | The crossfade that replaces movement under reduce motion (`MeridianMotion.fade`) |
| `motion-nudge` | 90 | standard | A toolbar icon's nudge out (MM-07); the return is `spring-snappy` |
| `motion-shake-field`, `motion-shake-surface` | 240, 280 | linear | One field or dialog shake (MM-09, MM-47) |
| `motion-hold` | 900 | — | How long a success check stays (MM-04) |
| `motion-progress-hold` | 300 | — | A progress bar at 100% waits this long before it fades (MM-63) |
| `motion-march` | 600 | linear | One period of a drop zone's marching dashes (MM-77) |
| `motion-stagger` | 18 | — | Delay between successive items in an entrance; at most `motion-stagger-max` (6) items are staggered |
| `motion-spinner-delay` | 150 | — | Wait before a spinner or busy state appears, so fast work never flashes |
| `motion-tooltip-wait` | 500 | — | Delay before a tooltip shows (existing) |
| `motion-tooltip-warm` | 800 | — | Reserved: after a tooltip hides, the next one within this window will show at once (needs a Meridian tooltip, see MM-44) |
| `motion-pulse` | 1600 | standard | One loop of a live halo |
| `motion-skeleton-pulse` | 1200 | standard | One half-cycle of a skeleton's breathing |
| `motion-spinner`, `-reduced`, `motion-progress`, `motion-skeleton-delay`, `motion-toast`, `motion-toast-action` | as today | | Unchanged |

### Curves

| Token | Definition | Feel |
|---|---|---|
| `curve-standard` | cubic-bezier(0.2, 0, 0, 1) | Moves and changes that start and end on screen |
| `curve-enter` | cubic-bezier(0.05, 0.7, 0.1, 1) | Arrivals: fast start, long gentle landing |
| `curve-exit` | cubic-bezier(0.3, 0, 0.8, 0.15) | Departures: accelerate away |
| `curve-exit-soft` | cubic-bezier(0.4, 0, 1, 1) | Tints and highlights fading back |
| `linear` | linear | Hover fills, loops |

### Springs

Springs are described as stiffness and damping ratio, with a mass of 1. A spring has no fixed duration; the settle times below are what the prototype and the tests use. Flutter builds them with `SpringDescription.withDampingRatio`. The web uses a generated `linear()` easing.

| Token | Stiffness | Damping ratio | Within 1% of rest after | Use |
|---|---|---|---|---|
| `spring-snappy` | 600 | 0.86 | 190 ms (0.5% overshoot) | Glides (selection bar, segmented tile, tab rule, menu highlight), switch thumb, press release |
| `spring-gentle` | 300 | 0.9 | 300 ms | Drag settle, reorder, travelling items, toasts arriving |
| `spring-pop` | 520 | 0.55 | 380 ms (12.6% overshoot; the visible part is over by 250 ms) | Count increase, badge appearing, radio dot, check box fill: small rewards |

### Scales and distances

| Token | Value | Use |
|---|---|---|
| `press-scale` | 0.97 (touch 0.96) | Buttons, icon buttons, toolbar buttons, chips, rows with a tap action on touch |
| `overlay-enter-scale` | 0.98 | Menus, popovers and tooltips grow from their anchor edge |
| `dialog-enter-scale` | 0.96 | Dialogs grow from the centre |
| `pop-scale` | 1.12 | Peak of a pop |
| `lift-scale` | 1.02 | An item being dragged |
| `rise-overlay` | 4 px | Overlays (existing `overlayRise`) |
| `rise-content` | 6 px | Content swaps, banners, empty states |
| `rise-dialog` | 8 px | Dialogs |
| `offset-toast` | 12 px | Toasts arriving |
| `shake-field` | 3 px, 3 cycles, 240 ms | A field rejecting a submit |
| `shake-surface` | 4 px, 3 cycles, 280 ms | A dialog rejecting Enter |
| `nudge` | 2 px | Toolbar icon nudge (MM-07) |
| `stagger-max` | 6 | Items staggered in one entrance |
| `pulse-scale` | 2.2 | A live halo's size at the end of its loop |
| `glide-max-rows` | 8 | Longer selection jumps crossfade instead of gliding |

## Helpers in `meridian_ui`

Apps build their own motion only from these helpers, so reduce motion and interruption work everywhere.

| Helper | What it does |
|---|---|
| `MeridianMotion.of(context, duration)` / `.reduced(context)` | Existing: the token, or zero under reduce motion. New: `MeridianMotion.fade(context, duration)` returns the token, or at most 100 ms under reduce motion (for the crossfades that replace movement), and `MeridianMotion.curve(context, curve)` returns `Curves.linear` under reduce motion |
| `MeridianMotionMemory` | The seen-set that stops recycled list rows from replaying one-time effects (`MeridianEntrance`, `MeridianAttention`, `MeridianTravel`). `MeridianMotionMemory.of(context)` returns the nearest `MeridianMotionScope`'s memory, or a process-wide default, so apps get it without wrapping anything. For design review, slow everything with Flutter's `timeDilation` (the gallery has a 1× / 2× / 5× switch) |
| `MeridianSpringController` | A thin wrapper over `AnimationController.animateWith(SpringSimulation)` that retargets from the current value and velocity |
| `MeridianPressScale` | Built into `MeridianInteraction` behind `pressScale: true`, which the components in MM-02 set. Scales the child to `press-scale` on pointer down (60 ms, exit) and springs back (`spring-snappy`). Keyboard activation plays a 60 ms press and release. App widgets built on `MeridianInteraction` opt in the same way |
| `MeridianGlide` | Paints one indicator (a rounded fill, rule or tile) under a set of items and springs it to the selected item's rect. Used by Segmented, Tabs, Menu, Pagination and `MeridianList` |
| `MeridianSelectionGlide` | `MeridianGlide` for fixed-extent scrolling lists. It paints the selection bar in a layer under the rows, from the selected index and the scroll offset. Rows then paint their selected fill transparent. Jumps longer than 8 rows or off screen crossfade instead |
| `MeridianSwap` | Crossfade between two children keyed by value, with an optional `rise` (content swap) or `roll` (up for increase, down for decrease) direction |
| `MeridianRollingNumber` | A number that rolls digit by digit when its value changes and pops (`spring-pop`) on increase when `popOnIncrease` is set |
| `MeridianReveal` | Insert and remove with `motion-layout`: size from 0 plus fade (insert); fade out (`motion-exit`) then collapse (remove) |
| `MeridianEntrance` | A one-time fade and rise (`rise-content`) when a keyed item first appears, with an optional stagger index. Remembers seen keys in `MeridianMotionMemory` |
| `MeridianStroke` | Draws a Lucide-style path progressively (check marks, strike-throughs, rings) |
| `MeridianShake` | A horizontal shake of `shake-field` or `shake-surface`, triggered by a counter |
| `MeridianPulse` | A halo that grows to 2.2× and fades, looping every `motion-pulse` (live indicators only) |
| `MeridianAttention` | Tints its child `accent-soft` and fades back over `motion-attention`, triggered by a counter |
| `MeridianLift` | Drag feedback: `lift-scale`, `shadow-float`, and a `spring-gentle` settle on drop |
| `MeridianTravel` | Flies a snapshot of a widget from one global rect to another (`motion-highlight`, `spring-gentle`), for items moving between lists or into a new home. The source and destination hide their real child while it flies |

## The shared catalogue

Every row is implemented in `meridian_ui`, so every app gets it without extra code. IDs are referenced by implementation plans and tests.

### Controls

| ID | Component | Moment | Motion | Reduce motion |
|---|---|---|---|---|
| MM-01 | All interactive controls | Hover | Fill in `motion-hover`, out `motion-hover-out` | Same |
| MM-02 | Button, IconButton, ToolbarButton, Chip, FloatingButton | Press | `MeridianPressScale`: 0.97 in 60 ms, spring back | No scale; fill only |
| MM-03 | Button | Loading starts | The icon crossfades to the spinner (`motion-quick`, spinner scales 0.8 → 1). The spinner itself waits `motion-spinner-delay`. The width change animates with `motion-layout` | Instant swap |
| MM-04 | Button | `success` flag set | Spinner or icon → `check` drawn by `MeridianStroke` over 160 ms. It stays 900 ms, then crossfades back to the normal icon. `successReplacesLabel` crossfades the whole content to a centred check without changing width; `onSuccessFinished` reports the completed hold, canceled by new loading, cleared success or disposal | Static check for 900 ms; whole-content replacement keeps its fade |
| MM-05 | IconButton (toggle) | `active` changes | Fill and icon colour `motion-select`. Chevron and disclosure icons rotate (90° or 180°) with `motion-quick` | Instant |
| MM-06 | ToolbarButton | Badge appears / disappears / changes | Appear: scale 0 → 1 with `spring-pop`. Disappear: scale to 0.6 and fade (`motion-exit`). Change: `MeridianRollingNumber` with pop on increase | Instant |
| MM-07 | ToolbarButton | Activated | The icon nudges once in its semantic direction: 2 px over 90 ms out, spring back. The direction is set by the new `nudge` property (`up`, `down`, `left`, `right`, `rotate`). Apps choose it: GitLama's Push nudges up, Pull and Fetch down. `rotate` turns the icon one full turn on `spring-snappy` instead | None |
| MM-08 | TextField | Focus | The border colour animates with `motion-quick`; the 1 px outer halo grows from 0 to 1 px (`motion-quick`, standard) | Instant |
| MM-09 | TextField | Error on submit | `MeridianShake(shake-field)` once. The message reveals with `MeridianReveal` and rises `rise-overlay`. Errors shown while typing do not shake | Message crossfades in |
| MM-10 | TextField | Trailing count or text changes | `MeridianSwap(roll)` | Instant |
| MM-11 | Checkbox | Checked | The box fill scales 0.6 → 1 with `spring-pop` while its colour animates (`motion-quick`). The check draws by `MeridianStroke` over 140 ms, starting 40 ms in. Unchecked: the fill fades (`motion-exit`) and the check is erased back. Mixed: the dash draws from the centre outwards | Instant |
| MM-12 | Switch | Toggled | The thumb travels with `spring-snappy`. While pressed, the thumb stretches from 14 to 18 px towards the travel direction. The track colour follows `motion-select` | Thumb jumps, colour crossfades |
| MM-13 | Radio | Selected | The inner dot scales 0 → 1 with `spring-pop`; the previous dot shrinks out (`motion-exit`) | Instant |
| MM-14 | Segmented | Selection changes | `MeridianGlide`: the raised tile springs (`spring-snappy`) to the new segment's position and width; labels crossfade colour (`motion-select`) | Tile jumps |
| MM-15 | Slider | Hover or drag | The thumb scales 1 → 1.15 (`motion-quick`); the value bubble rises `rise-overlay` and fades in; the track fill follows the pointer exactly (no lag) | No scale |
| MM-16 | Select | Menu open | The chevron rotates 180° (`motion-quick`) while the menu is open | Instant |

| MM-17 | Kbd | The shortcut is pressed while visible | The cap sinks 1 px and loses its lip for 80 ms (`MeridianKbd(pressed:)`, driven by `MeridianHeldModifiers`) | Same, without the translate |

`MeridianSelect.animateValue` opts a select into `MeridianSwap(rise)` for programmatic and menu-driven value changes. The trigger keeps its menu and focus state while the label changes. The motion gallery's Select example exercises it.

For an owner-driven clear, increment `MeridianTextField.programmaticClearSequence`
in the rebuild that follows clearing its controller. The field keeps its
editable state and focus while a non-interactive, semantics-free snapshot of
the previous text fades over `motion-quick`. User edits and the clear button do
not trigger this effect; a new keystroke ends a running fade.

For an action whose label changes in place, set `MeridianButton.animateLabel`.
It uses `MeridianSwap(rise)` for the label and the button's existing
`MeridianResize` for the width. The accessible action label updates at once. Reduced-motion and explicit zero-duration resizing uses immediate geometry rather than a zero-duration `AnimatedSize`; changing that preference retains the child state and focus.

### Lists and navigation

| ID | Component | Moment | Motion | Reduce motion |
|---|---|---|---|---|
| MM-20 | `MeridianList` / ListRow | Selection moves | `MeridianSelectionGlide` springs the selection bar from the old row to the new one (`spring-snappy`). Rows up to 8 away glide; longer or off-screen jumps crossfade (`motion-quick`) | Instant |
| MM-21 | ListRow | Hover actions show | Fade in and slide 4 px from the trailing edge (`motion-quick`); out with `motion-exit` | Fade only |
| MM-22 | ListRow | Row inserted / removed (live data) | `MeridianReveal` | Instant |
| MM-23 | ListRow | Row changed by an external event the person should notice | `MeridianAttention` once | Same, 300 ms |
| MM-24 | NavSection, Disclosure | Expand / collapse | The chevron rotates (`motion-quick`); children reveal with `MeridianReveal` (height plus fade), and on expand the first 6 child rows stagger in (`MeridianEntrance`) | Instant |
| MM-25 | NavRow | Becomes current | The current indicator (icon tint and weight) crossfades (`motion-select`); when the old current row is visible, the check icon travels to the new row with `spring-snappy` | Instant |
| MM-26 | Tabs | Selection changes | Underline or pill: `MeridianGlide` with `spring-snappy` | Instant |
| MM-27 | Tabs | Tab opened / closed | Opened: the width grows from 0 (`motion-layout`) while the content fades in. Closed: the content fades (`motion-exit`), then the width collapses (`motion-layout`) and neighbours slide in | Instant |
| MM-28 | Tabs | Drag reorder | `MeridianLift` on the dragged tab; the others spring out of the way (`spring-gentle`); drop settles with `spring-gentle` | Instant |
| MM-29 | Pagination | Page changes | The current pill glides (`MeridianGlide`) | Instant |
| MM-30 | SelectionBar | Appears / count changes | Rises from the bottom 12 px with `spring-gentle` and fades in; the count rolls | Fade |

### Overlays

| ID | Component | Moment | Motion | Reduce motion |
|---|---|---|---|---|
| MM-40 | Menu, Popover, Suggestions | Open | Fade plus `overlay-enter-scale` → 1 and `rise-overlay`, from the anchor edge (the transform origin is the edge nearest the anchor), over `motion-overlay` with `curve-enter` | Fade 100 ms |
| MM-41 | Menu, Popover, Suggestions | Close | Fade and scale to 0.98 over `motion-exit` | Instant |
| MM-42 | Menu, Suggestions | Highlight moves | None: the highlight fill and the row's on-accent ink move to the new row in the same frame, for pointer and keyboard alike. A gliding fill trails the pointer, and a menu must track it like a native one | Instant |
| MM-43 | Menu | Submenu opens | Existing 200 ms intent delay; the submenu enters from its side 4 px (MM-40 otherwise) | Fade |
| MM-44 | `MeridianTooltip` | Show / hide | Waits `motion-tooltip-wait`, leaves over `motion-exit`; the widgets layer's `RawTooltip` fades it. A warm-up (the next tooltip showing at once within `motion-tooltip-warm`) needs a Meridian tooltip and is not part of this release; the token is reserved for it | Same |
| MM-45 | Dialog | Open | The scrim fades in over `motion-dialog`. The surface fades in, scales `dialog-enter-scale` → 1 and rises `rise-dialog`, over `motion-dialog` with `curve-enter` | Fade 100 ms |
| MM-46 | Dialog | Close | Surface and scrim fade over `motion-exit`; the surface scales to 0.98 | Instant |
| MM-47 | Dialog | Enter pressed while the primary action is disabled | `MeridianShake(shake-surface)` on the surface; the disabled reason's tooltip shows | Tooltip only |

An anchored palette can pass a changing `borderRadius` to
`MeridianDialogSurface`. Paint and clipping use the same radius while the
route grows from its trigger.
| MM-48 | Sheet, Panel | Open / close | As today (`motion-sheet`); a released drag settles with `spring-gentle` from the release velocity | Fade |

Keep `MeridianPanel` mounted while closing by setting `visible: false`; remove
it from the parent after `onHidden`. Use `MeridianRemovingRow.delay` to stagger
a short batch of removals. Reduce motion skips the delay.
`MeridianOverlayEntrance` is public for a prompt mounted directly in a Stack.
| MM-49 | Toast | Arrive | From `offset-toast` below (touch) or below-right (desktop) with `spring-gentle`, fading in over `motion-quick`. Toasts already shown slide to make room (`spring-gentle`). Action toasts show a 1 px `line-strong` time rule along their bottom that shrinks over the toast's lifetime and pauses on hover or focus | Fade; the rule is static |
| MM-50 | Toast | Leave | Fade and move 8 px outwards over `motion-exit` | Instant |

### Feedback and containers

| ID | Component | Moment | Motion | Reduce motion |
|---|---|---|---|---|
| MM-60 | Spinner | Appears | Waits `motion-spinner-delay`, then fades in over `motion-quick` | Same |
| MM-61 | ProgressBar | Value changes | As today (`motion-emphasized`) | Instant |
| MM-62 | ProgressBar | Indeterminate → determinate | The sweep bar morphs into the value bar: its start slides to 0 and its end to the value, with `motion-layout` | Instant |
| MM-63 | ProgressBar | Reaches 100% | Holds 300 ms, then fades out over `motion-exit` (unless `persistent`) | Instant hide |
| MM-64 | Skeleton | Visible | Opacity breathes 0.55 ↔ 1 (`motion-skeleton-pulse`, standard, alternating). Replaced content crossfades in over `motion-quick` | Static 0.7 |
| MM-65 | Banner | Shown / dismissed | `MeridianReveal`; the content rises `rise-content` on entry | Instant |
| MM-66 | Banner | Tone changes (e.g. attention → success) | The fill and icon colours animate over `motion-layout`; the icon swaps with `MeridianSwap` (scale 0.8 → 1) | Instant |
| MM-67 | EmptyState | First shown | Icon, headline, text and action enter with `MeridianEntrance`, staggered | Instant |
| MM-68 | BusyOverlay | Shown | Waits `motion-spinner-delay`, fades in over `motion-quick` | Same |
| MM-69 | StatusDot | `live: true` | `MeridianPulse` | Static halo at 40% |
| MM-70 | Count | Value changes | `MeridianRollingNumber`; pop on increase when `emphasizeIncrease: true` | Instant |
| MM-71 | Avatar | Image loaded | Fades in over the initials (`motion-quick`) | Instant |
| MM-72 | Chip | Removed | Fades and shrinks its width to 0 (`motion-layout`) | Instant |
| MM-73 | Island | Gains / loses keyboard focus | The halo fades in over `motion-select` and out over `motion-hover-out` | Instant |
| MM-74 | Island | Content replaced (the app switches what an island shows) | `MeridianSwap(rise)`: the new content rises `rise-content` and fades in over `motion-select`; the old fades over `motion-exit`. Skipped when switches come faster than 150 ms apart (keyboard scrubbing) | Crossfade 100 ms |
| MM-75 | ResizeHandle | Hover | After 150 ms, a 2 px `accent` line grows from its centre along the handle (`motion-quick`) | Instant |
| MM-76 | StatusBar | Text changes | `MeridianSwap(rise)`, 3 px | Instant |
| MM-77 | DropZone | Drag enters | The dashed edge becomes `accent` and its dashes march (a 600 ms loop) while hovered; the fill fades to `accent-soft` | No march |
| MM-78 | Window (desktop) | App loses or regains focus | Every `accent` selection crossfades to `accent-soft` and back (`motion-select`) | Instant |

## Performance and correctness

- Animate with `Transform`, `Opacity`/`FadeTransition`, `DecoratedBox` colour, clip or `CustomPainter` progress. `AnimatedSize` and `SizeTransition` are only allowed inside `MeridianReveal` and `MeridianGlide`.
- Every controller and `CurvedAnimation` is owned for the lifetime of its animated item and disposed with that item. Rebuilding a stable item must reuse its animation so controller listeners cannot accumulate. No `pumpAndSettle` in tests while a loop (spinner, pulse, skeleton) is on screen; pump explicit durations.
- A virtualised list never starts an animation from an item builder without a stable key in `MeridianMotionMemory`. Scrolling must never replay an entrance, attention tint or travel.
- Only one `MeridianTravel` flies per region at a time. A second one first lands the previous flight instantly.
- Measure with the performance overlay: no animation may drop the raster or UI thread below 120 fps on the reference MacBook at 1440 × 900.
- Motion is part of the component contract. Tests pump the duration and assert start, middle and end values, and assert zero duration under `MediaQuery(disableAnimations: true)`.

## Implementation notes (0.9.0)

What the Flutter package added beyond the tables above, and where it differs from them.

- **Glides.** `MeridianGlide` also has `MeridianGlide.custom(selection:, child:, indicator:, foreground:)` with `MeridianGlideTarget(selected:)` markers, so a component keeps its own flexible layout (Segmented, Tabs, Pagination). The indicator is measured during layout, never a frame late. A different target claiming the selection glides even when the previous one is already gone. `foreground: true` is a travelling mark (the NavRow check, MM-25): painted over the items only while it travels, while the target hides its own copy. Targets are measured by layout offsets: a press scale between target and glide is ignored.
- **Other helpers.** `MeridianResize` (width follows content over `motion-layout`, MM-03), `MeridianNudgeIcon` and `MeridianNudge` (MM-07), `MeridianTurns` (MM-05), `MeridianSelectionFill` (the selection bar under a `MeridianSelectionGlide`), `MeridianRemovingRow` (MM-22), `MeridianSwap` styles `slide` and a `fit`, `MeridianReveal.appear` and `onHidden`, `MeridianPulse.spread` (a ring, for one-off halos around a button).
- **Selection style.** `MeridianTheme.resolve(selection: MeridianSelectionStyle.soft)` keeps selected rows `accent-soft` with the normal inks even in a focused island (the island's halo shows focus). `strong`, the default, is solid `accent` while the island has focus. MM-78 applies to `strong` only.
- **Window focus.** `MeridianGround` installs `MeridianWindowFocusScope`; `MeridianWindowFocus.of(context)` is false while the app is not `resumed`.
- **Stroke timings.** The 160ms success check and the 140ms checkbox check with its 40ms delay are `MeridianLayout.successCheckDraw`, `checkboxCheckDraw` and `checkboxCheckDelay`; they are not tokens.
- **Stroke icons.** `circle-check` uses the shipped Lucide geometry (`m16 9-5.5 5.5L8 12`).
- **Not implemented.** MM-48's `spring-gentle` settle after a sheet drag (Flutter's bottom sheet settles with its own simulation). MM-28 (Tabs have no reorder).
- **Toast countdown.** Hover and focus pause it and it resumes with the time left.
- **Web rendition.** `tool/generate.py` writes `design/project/motion.css` (`--motion-*`, `--curve-*`, `--spring-*` as `linear()` sampled every 8ms to within 0.1% of rest, with `--spring-*-duration`); `components/bundle.css` imports it.

## Lazy glide targets

A custom glide can wrap a sliver viewport. Selected targets may attach, detach
or return during layout. Coalesce ancestor geometry invalidation after that
frame, and discard the update if its render object has detached. Animation
ticks outside layout still update normally. The gallery's Lazy glide replay
scrolls the selected row out and back into a 4,000-row list. Test both recycling
and disposal with a pending update; an eager list does not cover this lifecycle.
