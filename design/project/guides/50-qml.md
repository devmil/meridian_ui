# Meridian in Qt Quick (QML)

Rust + Qt Quick desktop apps use the same Meridian as the Flutter apps: the same
tokens, brands, densities, motion contract and Lucide icons, rendered by a QML
module in `qml/Meridian`. Nothing in it is copied by hand from the Flutter
library. The token files, the layout constants in `meridian_layout.dart` and the
icon SVGs feed `tool/generate_qml.py`. `tool/generate.py` runs it, so
`python3 tool/generate.py --check` fails when the QML rendition is stale.

## Using it in an app

Pin a commit of `meridian_ui` and ship `qml/Meridian` inside the app's own Qt
resource (vendored with a recorded commit and content hash, or through a build
step that copies it from a pinned checkout). Import it as `import Meridian` with
the parent of `Meridian/` on the import path.

```qml
import Meridian

ApplicationWindow {
    Component.onCompleted: {
        Theme.brand = "crossproton"          // a brand id from Tokens.brandIds
        Theme.mode = Theme.System            // System, Light, Dark
        Theme.density = Theme.Regular        // or -1 for the brand's default
    }
    color: Theme.colors.ground
}
```

The app supplies `Theme.reducedMotion` from its preference OR'd with the
platform setting. Qt has no portable reduce-motion signal.

Colour roles keep their token names in camel case, except the `on-…` roles:
QML reads a property named `on` + capital letter as a signal handler, so
`on-accent`, `on-accent-muted`, `on-danger` and `on-attention` are
`Theme.colors.inkOnAccent`, `inkOnAccentMuted`, `inkOnDanger` and
`inkOnAttention`.

Read values through the theme, never as literals: `Theme.colors.paneAlt`,
`Theme.type.bodyStrong` with `Theme.type.bodyStrongLineHeight`,
`Theme.radius.lg`, `Theme.space.s4`, `Theme.size.row` (density-resolved),
`Metrics.dialogWidth`, `Motion.select`.

## What the module holds

| File | Source | What |
|---|---|---|
| `Tokens.qml` | generated | Palettes per brand × theme, brands, spacing, sizes, radii, shadows, durations, curves, springs, scales |
| `ColorScheme.qml`, `TypeScale.qml` | generated | Typed colour roles and type roles (`font` + line height), resolved by `Theme` |
| `Metrics.qml` | generated from `meridian_layout.dart` | `MeridianLayout` geometry and `MeridianOpacity` (as `opacity…`) |
| `IconData.qml` | generated from `assets/icons` | Lucide outlines as SVG path data |
| `Theme.qml`, `Motion.qml` | hand-written | Resolution of brand, mode, density and reduce motion; blend helpers |
| `Meridian*.qml` | hand-written | The primitives |

## Primitives

Built on `QtQuick.Templates`, so behaviour, accessibility, keyboard activation
and `visualFocus` come from Qt while the look is entirely Meridian's. Never
style a stock Qt Quick Controls control in an app: add or extend a primitive here.

| QML | Flutter | Notes |
|---|---|---|
| `MeridianButton` | `MeridianButton` | Variants Primary, Secondary, Quiet, Danger, DangerQuiet; `loading`, `success`, `iconOnly`. Connect commands to `activated`, which does not fire while `loading` |
| `MeridianIconButton` | `MeridianIconButton` | `text` is the accessible name; `active`, `surfaceColor`, `turns`, `nudgeDirection` |
| `MeridianTextField` | `MeridianTextField` | Default, Search, Plain; `clearLabel`, `error`, `rejectCount` shake. The label stays outside. `keyFilter` sees every key press first and consumes it by returning true (a suggestion list under the caret); `MeridianTextArea` has the same |
| `MeridianTextMenu` | `MeridianTextMenuRequest` with the native text menu builder | The text editing menu inside every `MeridianTextField`, `MeridianTextArea` and `MeridianSelectableText`: Cut, Copy, Paste, Select All, each only when it applies (none of Cut or Copy for a password; Copy and Select All for read-only text), in the platform's own menu at the pointer on a secondary click or at the cursor on the Menu key or Shift+F10. It takes no focus. Localize with `Theme.textMenuLabels` |
| `MeridianSwitch` | `MeridianSwitch` | `description`, `showLabel`, `labelFirst` |
| `MeridianSegmented` | `MeridianSegmented` | Arrow, Home and End keys skip disabled segments; `manualActivation`; shares width when narrow |
| `MeridianChip` | `MeridianChip` | Tones, filter `selected`, `removable` with its own button |
| `MeridianSpinner`, `MeridianProgressBar` | Spinner, ProgressBar | 150ms appearance delay; completion hold and fade |
| `MeridianBanner` | `MeridianBanner` | Tones, up to two actions, reveal and collapse |
| `MeridianEmptyState` | `MeridianEmptyState` | `progress`, `compact`, `headline`; staggered entrance once |
| `MeridianIsland`, `MeridianGround` | Island, Ground | `shadow-pane` edge; focus halo |
| `MeridianToast` + `MeridianToastHost` | Toast | One at a time; `show()` returns an id that `actionTriggered` reports (Undo); hover or focus pauses the countdown |
| `MeridianDialog`, `MeridianConfirm` | Dialog, showMeridianConfirm | Width classes Confirm/Form/Workflow; Enter submits or shakes when `submitDisabled`; a destructive confirm starts on Cancel |
| `MeridianDialogSurface` | `MeridianDialogSurface` | A modal surface for a custom layout: the dialog's scrim, surface, entrance and Escape without title, padding or footer; `fillWindow` fills the window less `margin` (`space-3`) for workflows such as a review; set `label` for its accessible name |
| `MeridianMenu`, `MeridianMenuItem`, `MeridianMenuSeparator` | Menu | Type-ahead, submenus, `danger`, `shortcut`, `hint`, `dotColor`; `nativeMenu: true` uses Qt's platform menu |
| `MeridianPopover` | Popover | One task with fields or its own layout |
| `MeridianNavRow` | NavRow | `current`, `sidebarFocused` (solid accent), `depth`, expand with ←/→, `dropState` |
| `MeridianListRow` | ListRow | Inset selection bar, `islandFocused`, `emphasized`, `dimmed`, `twoLine`, hover actions replace `meta` (give them `surfaceColor: row.fillColor`); `leading`, `titleTrailing` and `trailing` components frame the title |
| `MeridianRadio` | `MeridianRadio` | Round box, `accent` when chosen, `on-accent` dot pops in; siblings are exclusive (or use a ButtonGroup); `description` caption |
| `MeridianKbd` | `MeridianKbd` | One `pane-alt` cap per key with a `line-strong` edge and bottom shadow; `pressed` sinks it; `onAccent` on accent fills. Modifier-hold reveal stays with the caller |
| `MeridianColorSwatch` | `MeridianColorSwatch` | Content `color` disc with a `line-strong` edge; `selected` adds a check (contrasting with the colour) and a 2px `accent` ring; `text` names it for the tooltip |
| `MeridianColorPicker` | `MeridianColorPicker` | Offered `groups` of swatches, a hue/saturation wheel (arrow keys step, Shift for 10), before/after preview (tap restores `original`), hex field, HSB/RGB sliders on gradient tracks; `edited` follows every change, `editFinished` ends one; wide at `colorPickerWide` |
| `MeridianColorWell` | `MeridianColorWell` | A hue ring with the custom colour (or a plus) that opens the picker in a popover; `edited`/`editFinished` pass through; focus returns on close |
| `MeridianColorChoiceRow` | `MeridianColorChoiceRow` | `value` is `{series}`, `{custom: "#RRGGBB"}` or null; optional none swatch, the eight series colours, a custom well that keeps its colour; `chosen(choice)` |
| `MeridianFindBar` | `MeridianFindBar` | Controlled: the owner searches and sets `matchCount`, `currentMatch` (from 0) and `searching`; `edited`, Enter `next`, Shift+Enter `previous` (also before a search); Escape clears, then emits `closeRequested` when `closable`; case/word/regex toggles via `*Shown`; field gives way first, stacks above the buttons when narrow; set every label from the app's catalog |
| `MeridianPulse` | `MeridianPulse` | A halo behind its content: a disc growing to `pulse-scale` × `size` (content width when 0) while fading from `opacity-pulse-start`, looping every `motion-pulse` while `active`; `once` plays one loop per activation; `spread` ≥ 0 draws a ring growing that far past the content's edge (`radius` follows the content). Reduced motion: a static disc at `opacity-static-halo` for looping discs, nothing otherwise |
| `MeridianPanel` | `MeridianPanel` | Floating `raised` card with `shadow-float`, title row, `actions` and close; grows from `transformOrigin` with the overlay entrance, `shown: false` plays the exit and emits `hidden`; Escape asks to close |
| `MeridianSteps` | `MeridianSteps` | Pill markers (done: check on `success-bg`; current: `accent`; upcoming: outline) and labels joined by `line-strong` connectors; only the current label (ellipsized) when all do not fit; `current` = count marks all done |
| `MeridianBusyOverlay` | `MeridianBusyOverlay` | Fill the held region; it takes input at once and fades in after `motion-spinner-delay`; `scrim` at the busy share, raised card with an accent spinner, `message` and one child action (Cancel) |
| `MeridianShortcutField` | `MeridianShortcutField` | Controlled recorder: `recordRequested`, then the next non-modifier key-down as `recorded(key, modifiers)`; Escape, Tab and focus loss `cancelRecording`; bound `keys` as caps with a clear button; `conflictText` below in `danger`. Validation and storage stay with the caller |
| `MeridianTextArea` | `MeridianTextField` (`maxLines` > 1) | Default field edge, focus edge and halo; grows from `minimumLines` to `maximumLines`, then scrolls; an explicit height fills; set `Accessible.name` |
| `MeridianBreadcrumbs` | `MeridianBreadcrumbs` | First and last crumb stay; middle crumbs fold into “…” (`overflowRequested` with their indices) from the left; the last crumb elides; crumbs are data (`label`, `icon`, `prefix`, `mono`, `emphasis`, `enabled`) |
| `MeridianPagination` | Pagination | Seven pages in full, else first, last and neighbours |
| `MeridianSelectionBar` | SelectionBar | Count, actions, clear; rises in on `spring-gentle` |
| `MeridianDropZone` | DropZone | Idle/Active/Invalid; marching dashes; also a browse button |
| `MeridianDatePicker` | DatePicker | Locale-aware weeks; one tab stop with arrow, Page and Home/End keys; range limits |
| `MeridianSettingsRow` | SettingsRow | 200px label column; stacks below 520px and at touch density |
| `MeridianSurface`, `MeridianIcon`, `MeridianText`, `MeridianFocusRing`, `MeridianShadow` | — | Building blocks for app components. `MeridianText.tabular` gives tabular figures without replacing the role's font |

Domain components (a mail row, a recipient field) belong in the app, built
from these primitives and the tokens.

## Motion in QML

`Motion` mirrors `MeridianMotion`. Every duration is zero under reduce
motion, and curves become linear. `Motion.fade(ms)` caps a crossfade at
`motion-reduced-fade`, and `Motion.staggerDelay(i)` returns 0. Scales and
distances (`pressScale`, `riseContent`, `shakeFieldDistance`) collapse to rest.
Springs (`Motion.snappy`, `.gentle`, `.pop`) are `{ duration, curve }` for
`easing.type: Easing.BezierSpline`. The curve is a 10-segment cubic fit of the
spring, with the same settle time as the web rendition.

Live loops (the spinner, indeterminate progress, the live status halo,
`MeridianPulse`, the icon button spin) run only while `Motion.loopsActive`,
which follows `Application.state`. An unfocused, hidden or minimized window
holds them still, so it renders no frames at rest and wakes no CPU; they
continue when the application is active again. App loops of their own, such
as a skeleton pulse, gate their `running` on `Motion.loopsActive` too. Tests
may set it and restore the binding afterwards.

The motion helpers mirror Flutter's: `MeridianReveal`, `MeridianEntrance`
(with `MeridianMotionMemory`), `MeridianAttention`, `MeridianShake`,
`MeridianRollingNumber`, `MeridianResize`, `MeridianSwap`, `MeridianPulse`, and:

| QML | Notes |
|---|---|
| `MeridianRemovingRow` | Fades and collapses a leaving row, then emits `removed`. In a ListView delegate set `autoStart: false`, call `start()` from `ListView.onRemove` with `ListView.delayRemove` set, and clear it on `removed`. `delay` staggers a short batch |
| `MeridianLift` | Drag feedback: `lift-scale` and `shadow-float` while `lifted`, settling on `spring-gentle`. Wrap the drag proxy (created lifted) or the dragged row |
| `MeridianStroke`, `MeridianStrokeIcon` | Draw a path or a Lucide icon progressively with `ShapePath.trim` (Qt 6.10+): check marks, strike-throughs, connectors. `drawn`, `appear`, `duration`, `delay` |
| `MeridianSelectionGlide` | Declare inside a fixed-extent ListView; it sits under the rows in the view's content and springs to `selectedIndex`, crossfading jumps over `glide-max-rows` or off screen. Rows set `selectionGlided` (MeridianListRow) and paint their selected fill clear |
| `MeridianTravel` | `capture()` on the source before the move; the next instance with the same `travelKey` flies a snapshot (`grabToImage`) from there on `spring-gentle`, one flight per window. Captures older than `motion-celebrate` are dropped |

Rules that the tests enforce:

- A zero duration must land on the terminal state. Animate the property
  itself (a `Behavior` or a `to:` value). Never scale a reveal by the duration.
- Give an animated value a plain initial value, set once in
  `Component.onCompleted`, never a binding to the state it animates towards:
  the binding re-evaluates first and the value jumps to its end before the
  animation runs (`MeridianReveal` hid at once until 2.2.0).
- Keep `Easing.BezierSpline` lists short. Qt 6.12 corrupted its heap with
  45–70-segment splines. The generator emits 10, and `tst_motion` guards it.
- Publish a delegate's geometry to its owner with `Binding { when: … }`
  (see `MeridianSegmented`) rather than reading `Repeater.itemAt()` in a
  binding, which does not re-evaluate when the delegate moves or resizes.

## Verifying

```bash
tool/verify_qml.sh                       # generated files, qmllint (0 warnings), Qt Quick Test
qml -I qml qml/gallery/main.qml          # the gallery: brand, theme, density, reduce motion
```

`qml/tests/tst_gallery.qml` is also a layout test. It scrolls the gallery to the
end at 390 px and 1280 px, across densities, themes and brands, and fails when
anything overflows. `qml/tools/capture_gallery.qml` writes PNGs for design
review into the working directory.
