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
| `MeridianTextField` | `MeridianTextField` | Default, Search, Plain; `clearLabel`, `error`, `rejectCount` shake. The label stays outside |
| `MeridianSwitch` | `MeridianSwitch` | `description`, `showLabel`, `labelFirst` |
| `MeridianSegmented` | `MeridianSegmented` | Arrow, Home and End keys skip disabled segments; `manualActivation`; shares width when narrow |
| `MeridianChip` | `MeridianChip` | Tones, filter `selected`, `removable` with its own button |
| `MeridianSpinner`, `MeridianProgressBar` | Spinner, ProgressBar | 150ms appearance delay; completion hold and fade |
| `MeridianBanner` | `MeridianBanner` | Tones, up to two actions, reveal and collapse |
| `MeridianEmptyState` | `MeridianEmptyState` | `progress`, `compact`, `headline`; staggered entrance once |
| `MeridianIsland`, `MeridianGround` | Island, Ground | `shadow-pane` edge; focus halo |
| `MeridianIcon`, `MeridianText`, `MeridianFocusRing`, `MeridianShadow` | — | Building blocks for app components |

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

Rules that the tests enforce:

- A zero duration must land on the terminal state. Animate the property
  itself (a `Behavior` or a `to:` value). Never scale a reveal by the duration.
- Keep `Easing.BezierSpline` lists short. Qt 6.12 corrupted its heap with
  45–70-segment splines. The generator emits 10, and `tst_motion` guards it.
- Do not hold `Repeater.itemAt()` results in bindings. They outlive the
  delegate during teardown and crashed Qt. Publish delegate geometry with
  `Binding { when: … }` instead (see `MeridianSegmented`).

## Verifying

```bash
tool/verify_qml.sh                       # generated files, qmllint (0 warnings), Qt Quick Test
qml -I qml qml/gallery/main.qml          # the gallery: brand, theme, density, reduce motion
```

`qml/tests/tst_gallery.qml` is also a layout test. It scrolls the gallery to the
end at 390 px and 1280 px, across densities, themes and brands, and fails when
anything overflows. `qml/tools/capture_gallery.qml` writes PNGs for design
review into the working directory.
