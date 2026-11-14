# meridian_ui

Meridian is the shared design system for GitLama, CrossProton, Mimameidr, Nibluma and ShotLama, and for every Flutter app that comes after them. It grew out of GitLama's Meridian 3.0: the same islands on a tinted ground, one accent spent on intent, hierarchy through weight rather than size, and focus as a place. The Git-specific parts stay in GitLama.

This package holds three things:

| Path | What it is |
|---|---|
| `tokens/meridian.tokens.json` | The shared core: surfaces, ink, status and categorical colours for light and dark, the type scales (desktop and touch), spacing, radii, shadows, sizes, motion. The single token source. |
| `tokens/brands/*.json` | One brand per app: its accent family for light and dark, fonts, radius scale, default density and optional own neutrals. |
| `lib/` | The Flutter library: theme, tokens (generated), brands (generated), the interaction layer, icons and the primitive widgets. |
| `design/` | The design system documentation (brand book, component guidelines) that is published as the Meridian Design System artifact. `design/project/tokens.json` is generated. |
| `example/` | The gallery and Widgetbook component browser. |
| `webfront/` | The public landing page, with a compiled Widgetbook published beneath it. |

## Explore Meridian

Run the gallery with `cd example && flutter run -d macos`, or the isolated
component browser with `cd example && flutter run -d chrome -t lib/widgetbook.dart`.
The public landing page lives in `webfront/`. The `Publish Meridian Pages`
workflow builds Widgetbook beneath it and publishes the site with GitHub Pages.
See `webfront/README.md`.

The Meridian mark is `webfront/favicon.svg`. `python3 tool/build_site_icons.py`
writes its PNG copies to `webfront/icons/` (32 to 1024 px).

## Use it in an app

```yaml
# pubspec.yaml: pin the commit the app was migrated to
dependencies:
  meridian_ui:
    git:
      url: https://github.com/devmil/meridian_ui.git
      ref: <commit sha>
```

A `path: ../meridian_ui` dependency is fine while developing Meridian and an app side by side; commit the pinned git reference.

```dart
import 'package:meridian_ui/meridian_ui.dart';

MeridianApp(
  theme: MeridianTheme.resolve(brand: MeridianBrands.crossproton, brightness: Brightness.light),
  darkTheme: MeridianTheme.resolve(brand: MeridianBrands.crossproton, brightness: Brightness.dark),
  home: const MeridianGround(child: InboxScreen()),
);
```

Meridian has no Material dependency (since 2.0.0). `MeridianApp` is a `WidgetsApp` with a Meridian theme, `MeridianPageRoute`s, `MeridianScrollBehavior` and Meridian's strings; `MeridianScaffold` frames a screen. To show Meridian inside another shell, put a `MeridianThemeScope` above it.

Read tokens through the theme, never as literals:

```dart
final m = context.meridian;            // MeridianTheme.of(context)
Text('Inbox', style: m.text.bodyStrong);
ColoredBox(color: m.colors.paneAlt);
BorderRadius.circular(m.radius.lg);
const SizedBox(width: MeridianSpace.space4);
```

**Fonts.** The brand names its families; the app bundles them. JetBrains Mono ships with this package and is the default `mono`. CrossProton registers Inter, Mimameidr Geist and Geist Mono, Nibluma Literata (its UI face is the platform's), each in its own `pubspec.yaml`, exactly as today.

**Icons.** `MeridianIcon('circle-check')` draws from the Lucide set in `assets/icons/` (names in `MeridianIcons`). An app adds or overrides icons without touching this package:

```dart
MeridianTheme.resolve(
  brand: MeridianBrands.gitlama,
  brightness: Brightness.light,
  icons: const MeridianIconSet(extra: {'stash': 'assets/icons/lucide/stash.svg'}),
);
```

**App-specific tokens.** Tokens that only one app needs (GitLama's diff and lane colours, CrossProton's privacy spark, Mimameidr's live dot) live in that app as its own `MeridianThemeExtension`, passed through `MeridianTheme.resolve(extensions: [...])` and read with `context.meridian.extension<GitColors>()`. When a second app needs the same token, it moves here.

## The primitives

| Group | Widgets |
|---|---|
| App | `MeridianApp`, `MeridianThemeMode`, `MeridianScaffold`, `MeridianPageRoute` / `MeridianPageTransition`, `MeridianScrollBehavior` |
| Foundation | `MeridianTheme`, `MeridianThemeScope` / `AnimatedMeridianTheme`, `MeridianThemeExtension`, `MeridianDates`, `MeridianLocalizations` (English and German), `MeridianBrand`, `MeridianBrands`, `MeridianDensity`, `MeridianInteraction`, `MeridianIcon`, `MeridianSurfaceScope`, `MeridianRowColors`, `MeridianHairline` |
| Actions | `MeridianButton`, `MeridianSplitButton`, `MeridianIconButton`, `MeridianToolbarButton`, `MeridianFloatingButton` |
| Inputs | `MeridianShortcutField`, `MeridianTextField` / `MeridianEditableText`, `MeridianFindBar`, `MeridianCheckbox`, `MeridianSwitch`, `MeridianRadio`, `MeridianSegmented`, `MeridianSlider`, `MeridianSelect`, `MeridianColorSwatch`, `MeridianColorChoiceRow`, `MeridianSuggestionSurface` / `MeridianSuggestionRow` / `MeridianSuggestionHeader`, `MeridianCalendar` / `showMeridianDatePicker`, `MeridianDropZone` |
| Menus | `MeridianMenuAnchor`, `MeridianMenuSurface`, `showMeridianMenu`, `showMeridianContextMenu`, `MeridianMenuPresenter` (native menus), `MeridianPopoverAnchor` / `MeridianPopoverSurface` / `showMeridianPopover` |
| Navigation | `MeridianListRow`, `MeridianNavSection`, `MeridianNavRow`, `MeridianTabs`, `MeridianTabStrip`, `MeridianAppBar`, `MeridianDrawer`, `MeridianPagination`, `MeridianSelectionBar`, `MeridianBreadcrumbs` / `MeridianBreadcrumb`, `MeridianSteps` / `MeridianStep`, `MeridianPathTree` (path flattening for file lists and trees) |
| Display | `MeridianTooltip`, `MeridianSelectableText` / `MeridianSelectionArea` (and the text menu: `MeridianTextMenuRequest`, `meridianTextMenu`), `MeridianKbd`, `MeridianCount`, `MeridianAvatar`, `MeridianChip`, `MeridianStatusDot`, `MeridianMiddleEllipsis` |
| Feedback | `MeridianBanner`, `MeridianToast` / `showMeridianToast` / `showMeridianToastIn`, `MeridianSpinner`, `MeridianProgressBar`, `MeridianMeter`, `MeridianEmptyState`, `MeridianSkeleton`, `MeridianBusyOverlay` |
| Documents | `MeridianCanvas`, `MeridianPaper`, `MeridianToolDock` / `MeridianToolDockDivider` |
| Containers | `MeridianGround`, `MeridianIsland`, `MeridianSectionHeader`, `MeridianSplitPane`, `MeridianDisclosure`, `MeridianDialog` / `MeridianDialogSurface` / `showMeridianDialog` / `showMeridianConfirm` / `MeridianDialogSubmitScope`, `MeridianSheet` / `showMeridianSheet`, `MeridianPanel`, `MeridianSettingsGroup`, `MeridianSettingsRow`, `MeridianSettingsDialog`, `MeridianLicenseDialog` / `showMeridianLicenses`, `MeridianScrollbar` |
| Data | `MeridianPropertyList` / `MeridianProperty`, `MeridianColumnHeader`, `MeridianCodeLines` / `MeridianCodeGutter` / `MeridianLineMarks` / `MeridianSharedHorizontalScroll` / `MeridianHorizontalShift` |
| Window | `MeridianResizeHandle`, `MeridianStatusBar` / `MeridianStatusBarItem` |

Every control has rest, hover, pressed, keyboard focus, disabled and (where it applies) loading and error states. There is no ripple anywhere. At touch density every control keeps a 48px hit target.

## Change or extend Meridian

1. **A token.** Edit `tokens/meridian.tokens.json` (or a brand file), then run `python3 tool/generate.py`. It regenerates `lib/src/foundation/meridian_tokens.g.dart`, `meridian_brands.g.dart` and `design/project/tokens.json`, and fails if any text, icon or focus pair drops below its contrast floor in any brand or theme. `python3 tool/generate.py --check` is the CI guard.
2. **A brand** (a new app). Add `tokens/brands/<app>.json` with the full accent family for light and dark, its fonts, optional radius scale and default density, and only if the app needs them its own `neutrals` (the keys in `NEUTRAL_KEYS`). Run the generator. The app then uses `MeridianBrands.<app>`.
3. **A primitive.** A widget belongs here when two apps need it, or when it is clearly generic (a table header, a property list, a resize handle). Domain widgets stay in the app, built from these primitives. If an existing primitive can do it with one more property, extend that instead.
   1. Build `Meridian<Name>` in `lib/src/components/` from tokens, `MeridianInteraction` (hover, press, focus), `MeridianMotion` (durations) and semantics. Put new dimensions in `MeridianLayout`, never as literals. Export new files from `lib/meridian_ui.dart`.
   2. Add a widget test (tap, keyboard, disabled, narrow space, touch density) and a gallery entry in `example/`. The gallery test lays out every section at 390px and 1280px in regular and touch density; it catches overflow the unit tests miss.
   3. Add a Widgetbook component to the group's file in `example/lib/widgetbook/`, with a `Playground` use case whose knobs cover the properties. The Widgetbook test opens every use case at both widths and densities. If the landing page lists the component, add it to the catalogue in `webfront/index.html`.
   4. Write the guideline and preview in `design/src/components.py` and run `python3 design/src/components.py`. It writes `design/project/components/<Name>/README.md` and `preview.html` for every component, so edit guidelines there, not in the generated READMEs.
   5. Add the web rendition to `design/src/bundle.src.js` (and the `M` export), its styles to `design/project/components/bundle.css`, its name to `COMPONENTS` in `tool/build_bundle.py`, then run `python3 tool/build_bundle.py`. Republish the design system.
4. **An icon.** Add the Lucide name to `tokens/icons.json` in its group and run `python3 tool/sync_icons.py <lucide-static>/icons` with lucide-static 1.37.0 (`npm pack lucide-static@1.37.0`). Copy the new SVGs to `design/project/assets/Icons/`, update the count in its README and rebuild the bundle. Never mix Lucide versions.
5. **Release it.** Bump `version` in `pubspec.yaml` (new widgets or properties: minor; a removed or renamed token or property: major), add a `CHANGELOG.md` entry, run the checks below, and push to `main`. Apps move to the new commit deliberately by updating their pinned `ref`.

## Check

```sh
python3 tool/generate.py --check
python3 tool/check_motion_usage.py
python3 tool/build_site_icons.py --check
python3 tool/check_fonts.py
python3 tool/test_font_checkout.py
dart format --set-exit-if-changed lib test example/lib example/test
flutter analyze
flutter test
cd example && flutter analyze && flutter test && flutter run -d macos
cd ../packages/meridian_native_menus && dart format --set-exit-if-changed lib test && flutter analyze && flutter test
```

The root analysis excludes `packages/`; each companion package is analysed
and tested on its own. `packages/meridian_native_menus` shows Meridian's
menus as native menus (see its README); apps that keep Meridian's own menus
do not depend on it.

The web button rendition has a headless lifecycle contract in
`tool/test_button_preview.cjs`. Install `react@18.3.1` and
`react-test-renderer@18.3.1` in an isolated test directory, then run
`NODE_PATH=<test-directory>/node_modules node --test tool/test_button_preview.cjs tool/test_chip_preview.cjs tool/test_split_button_preview.cjs tool/test_shortcut_field_preview.cjs`.
It checks the real React components, confirmation lifecycle with a controlled timer,
and enlarged chip typography; browser layout and
physical motion review remain separate checks.

## Licences

Meridian is released under the MIT License (`LICENSE`). Lucide icons: ISC (upstream header kept in every SVG). JetBrains Mono: SIL Open Font License 1.1 (`assets/fonts/OFL.txt`). See `THIRD_PARTY_NOTICES.md`.
