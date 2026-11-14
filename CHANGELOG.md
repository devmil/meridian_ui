# Changelog

## 1.18.0 - 2026-11-14

- Add `MeridianLicenseDialog` and `showMeridianLicenses`, a Meridian
  replacement for Material's `showLicensePage`. It reads `LicenseRegistry`
  (or a `licenses` stream), lists the app header and the packages on
  `ground` with a filter and per-package license counts, and shows the
  selected package's licenses on `raised` as selectable `caption` text
  with hairlines between licenses. Up and Down move between packages.
  Below 640px of dialog width or at touch density the list and a package
  take turns with a back button. New `licenseDialogWidth`,
  `licenseDialogHeight`, `licenseDialogPackageListWidth`,
  `licenseDialogPagedBreakpoint`, `licenseTextMaxWidth` and
  `licenseIndent` layout values and English and German strings.
  Guideline, web preview, gallery entry, Widgetbook use case and widget
  tests. GitLama and ProcessLama show their licenses with it.

## 1.17.2 - 2026-11-05

- Single-line `MeridianTextField` grows to fit its scaled editable line and
  borders. Density and explicit heights are minimums; small numeric fields
  remain readable at 200% text. Add scale coverage and a playground knob.

## 1.17.1 - 2026-10-30

- `showMeridianDialog` handles Escape on the dialog route's focus scope, so
  Escape closes a dialog (or is swallowed when `dismissOnEscape` is off) even
  before anything in it has focus. A `MeridianSettingsDialog` opened by a
  keyboard shortcut now closes with Escape straight away.

## 1.17.0 - 2026-10-30

- `MeridianTextField` takes `underlay`, painted inside the well under the
  text, its selection and the caret at the size of the text area, for line
  marks an editor draws behind its text. It takes no taps and is not
  announced. Guideline, Widgetbook knob and tests. GitLama paints its merge
  result's chosen blocks with it, so a selection over them stays visible.

## 1.16.0 - 2026-10-29

- Add `MeridianSteps` and `MeridianStep`: a compact line of named steps
  that shows which are done (a `success` check, muted label), which is
  current (a filled `accent` marker with its number, `body-strong` label)
  and which are upcoming (an outlined marker with its number, muted label),
  joined by short `line-strong` hairlines. `current` runs from 0 to
  `steps.length` (every step done). When the labels do not fit, all but the
  current label hide and the current one ellipsizes; below the markers'
  width the line clips. Each step announces its label, state and position
  ("2 of 4", localized in English and German); steps are not interactive.
  New `stepMarker`, `stepMarkerTouch`, `stepMarkerPaddingX`,
  `stepCheckIcon`, `stepCheckIconTouch` and `stepConnectorLength` layout
  values. Guideline, web preview, gallery entry, Widgetbook use case and
  widget tests. GitLama uses it in its merge-conflict resolver.

## 1.15.0 - 2026-10-20

- Add immediate `onDoubleTap` pointer actions to `MeridianInteraction`. ListRow now shares this behavior; Enter and Space remain single activations. Include a Widgetbook knob, guideline and regression coverage.

## 1.14.0 - 2026-10-15

- `MeridianSettingsDialog` takes `page`, for apps that move between pages
  themselves (a link from one page to another), and `footer`, a line under
  the pages that stays in view for a failed change. `MeridianSettingsPage`
  takes a `key` for its list entry. Guideline, Widgetbook knob and tests.
  GitLama moves its settings window onto the dialog.

## 1.13.0 - 2026-10-15

- Add `MeridianSettingsDialog` and `MeridianSettingsPage`: a settings
  window with a title bar and ✕, the pages listed on `ground` as NavRows
  and the selected page (heading, description, rows) beside them. It is
  840px wide (`settingsDialogWidth`) so SettingsRows stay side by side,
  keeps one height (`settingsDialogHeight`, 640px, at most 85% of the
  window) while pages change, and scrolls each page from the top. Up and
  Down in the list move between pages. Below 600px of dialog width
  (`settingsDialogPagedBreakpoint`) and at touch density the list becomes
  a Select. Guideline, web preview, gallery entry, Widgetbook use case and
  widget tests.

## 1.12.1 - 2026-10-14

- `MeridianSharedHorizontalScroll` keeps its horizontal scrollbar below the
  rows: while the text is wider than its column the rows end
  `MeridianLayout.scrollbarGutter` (12px) above the bottom, so the
  scrollbar no longer covers the last line of a code view or diff scrolled
  to the end. Text that fits keeps the full height. Guideline and tests.

## 1.12.0 - 2026-10-14

- Add syntax colours for code. Twelve `syntax-*` tokens (comment, keyword,
  string, number, type, function, variable, constant, operator, punctuation,
  attribute, tag) for light and dark, shared by every brand, generated as
  `MeridianSyntaxColors` and read through `MeridianTheme.syntax`. Each
  passes 4.5:1 on `pane`, `pane-alt`, `raised`, `pane-hover`, `success-bg`
  and `danger-bg` in all six brands (72 new floors). None is a status
  colour; plain code stays `ink`.
- Add `MeridianSyntaxKind`, `MeridianSyntaxRun` and `MeridianSyntaxPalette`:
  a palette built for the opaque surfaces behind a line (fill, marks,
  blended selection) keeps `ink` for any category below 4.5:1 there, and
  `span(text, runs)` returns the exact text with only the colour changed.
  Runs are UTF-16 ranges; a list that is out of order, overlaps, leaves the
  text or splits a surrogate pair leaves the whole line plain.
  `meridianSyntaxRunsValid` and `meridianContrastRatio` are public.
- `MeridianCodeLines` takes `syntax`, category runs by line. Guideline,
  gallery, Widgetbook knob and tests.
- The Dialog guideline source carries the 1.11.0 close-button rule, which
  had only been written into the generated README.

## 1.11.0 - 2026-10-14

- Add `onClose` to `MeridianDialog`: a close button at the end of the title
  row for dialogs that inform or manage rather than ask, so they close like
  a `MeridianPanel` instead of with a footer "Close" button. Questions keep
  Cancel and the verb. Guideline, Widgetbook use case and widget tests.

## 1.10.0 - 2026-10-14

- Add the `vaultlama` brand for VaultLama, the Vaultwarden password
  manager: a midnight-violet accent (`#463878` light, `#D6C3FA` dark),
  brand ground `#231B3F` / `#31285A`, cool midnight neutrals, platform
  faces, radii 4 / 7 / 10 / 14 / 20 and regular density. All 54 contrast
  floors pass in both themes. The accent keeps at least 20.9 ΔE2000 from
  every other brand accent and 36 from the status colours (8.5 and 24
  under simulated protanopia, deuteranopia and tritanopia).
- The website lists the sixth brand.

## 1.9.1 - 2026-10-13

- One-line `MeridianListRow`s give the title priority over the inline
  subtitle. The title keeps its natural width (with `titleTrailing` and
  `match` highlighting) up to the row's width less the gap and a subtitle
  ellipsis; the subtitle takes the rest and truncates first. Before, title
  and subtitle each got at most half the width, so a long branch name
  ellipsized beside a short subtitle and empty space. When not even the
  ellipsis fits, the title takes the whole line. Two-line rows are
  unchanged.

## 1.9.0 - 2026-10-13

- Add `MeridianWaveform`, a bounded decorative peak envelope with optional
  confirmed progress, reading-direction-aware rendering and immutable input.
  Media decoding and accessible seeking remain with the consumer. Include
  guideline, web preview, gallery, Widgetbook controls and widget tests.
- Include the existing range-slider focus, pointer, semantic and touch contract
  tests in the committed package inventory.

## 1.8.0 - 2026-10-13

- Add `checked` (`bool?`) to `MeridianListRow` for multi-select checklists
  such as picking files for a partial stash. `null` (the default) keeps
  today's row. Otherwise the row starts with the Checkbox mark before
  `leading`, with the Checkbox's visuals and motion, following the row's
  hover, press and disabled state; on a solid selection it inverts to
  `on-accent`. A tap, Space or Enter runs `onTap` and the caller toggles the
  value; the mark is not a separate focus stop. The row reads as a checkbox
  with that state instead of a button. Include the guideline, a gallery
  checklist and a `Checked` knob on the List row playground.

## 1.7.1 - 2026-10-13

- Segmented tiles and their track grow above the density minimum when scaled
  label glyphs need more height. Small filters no longer clip or shift their
  labels at enlarged text sizes; the default control extent is unchanged.
- Section headers with a `middle` give it all the width the heading leaves,
  so the actions sit at the strip's end. The heading keeps its natural width
  up to half the strip; before, the middle got only half the free width and
  the actions landed beside it.

## 1.7.0 - 2026-10-13

- Add `MeridianRangeSlider` and `MeridianRangeValues` for controlled intervals,
  with independent handle focus and slider semantics, bounded keyboard movement,
  RTL interaction, optional snapping and commit callbacks. Include a component
  guideline, gallery, configurable Widgetbook playground and website specimen.
- Add the Lucide skip-back, step-back, step-forward, volume-2 and volume-x icons
  from the existing pinned upstream version; retain each source license header.

## 1.6.2 - 2026-10-12

- Preserve the exact reviewed Mono font notice bytes on Windows Git checkouts.
  The hashed OFL asset is marked `-text`; a clean `core.autocrlf=true` checkout
  now retains the manifest byte count and digest. Font and notice contents,
  widgets and themes are unchanged.

## 1.6.1 - 2026-10-11

- Complete `showMeridianPopover` after the route's reverse transition and
  overlay removal. Hosts can await actual teardown before resizing or opening
  follow-up UI. Results and cancellation semantics are unchanged; callers
  still check their invoking context after awaiting. Pointer, keyboard,
  Escape, barrier, reduced-motion, reopen and caller-unmount regressions cover
  the handoff alongside the existing gallery and Widgetbook popover.

## 1.6.0 - 2026-10-11

From the GitLama architecture review (WS6). Additive: existing APIs keep
their behaviour except where noted.

- Add `MeridianLocalizations`: Meridian's own English and German strings,
  resolved from the nearest locale without setup, through
  `MeridianLocalizations.delegate`, or from a `MeridianLocalizationsScope`.
  `MeridianColorPicker` (and `MeridianColorWell`) now take unset labels from
  it, so a German locale shows German picker labels; English is unchanged.
- Dialog contract: `showMeridianConfirm` takes `content`, `width`,
  `barrierDismissible` and `confirmIcon`; its guideline requires the verb on
  the primary button. `MeridianLayout.dialogConfirmWidth` (460, the same as
  `dialogWidth`), `dialogFormWidth` (560) and `dialogWorkflowWidth` (760)
  name the three dialog widths.
- Enter submits dialogs: `MeridianDialog` provides a
  `MeridianDialogSubmitScope`, and a single-line `MeridianTextField` without
  its own `onSubmitted` runs the dialog's primary action on Enter (or shakes
  the dialog when it is disabled), keeping focus in the field. Behaviour
  change: Enter in such a field used to end editing only. Opt out per field
  with `submitsDialog: false`.
- Add `MeridianFindBar` with `MeridianFindBarLabels`: a controlled in-content
  find bar with a localized "3 of 12" counter, Previous/Next (Enter and
  Shift+Enter), optional case, whole-word and regular-expression toggles,
  trailing owner controls, Close (Escape clears, then closes), a stacked
  narrow layout and a reduced-motion-aware reveal.
- Add `MeridianSectionHeader` (and `MeridianSectionHeaderSize`); the
  `MeridianIsland` header is built from it and gains `icon`, `leading`,
  `count` and `headerDivider`. Its title now takes the free width instead of
  at most half of it, and a long subtitle ellipsizes instead of overflowing.
- Add `MeridianSplitPane` (and `MeridianSplitPinned`): horizontal or vertical
  panes with a `MeridianResizeHandle`, ratio or pinned-extent sizing, minimum
  sizes, change and change-end callbacks, keyboard steps, reset, RTL and an
  adjustable announcement.
- Add `MeridianCodeLines`, `MeridianCodeGutter`, `MeridianCodeMarker`,
  `MeridianLineMarks`, `MeridianSharedHorizontalScroll` and
  `MeridianHorizontalShift`: numbered monospace lines with gutter markers,
  marked ranges and one shared horizontal offset.
- `MeridianEmptyState` gains `progress`, `progressValue` and `compact` for
  loading states in panes.
- Add `MeridianColorChoiceRow` with `MeridianColorChoice`,
  `MeridianSeriesColor` and `MeridianCustomColor`: the categorical colours
  with Meridian's localized names, an optional "No colour" swatch and a
  custom colour well.
- `MeridianAvatar` gains `onPressed` and `tooltip`; add
  `MeridianStatusBarItem` (icon, swapping label, max width, optional quiet
  button).
- New layout constants: `findFieldWidth`, `findFieldMinWidth`,
  `splitPaneMinExtent`, `codeLineHeight`, `codeGutterWidth`,
  `codeMarkerWidth`, `emptyStateProgressWidth`; `MeridianOpacity.avatarPressed`.
- Add the companion package `packages/meridian_native_menus` 1.0.0: native
  macOS, Windows and Linux menus for `MeridianMenuEntry` models, a native
  context-menu region and text-editing menu. `meridian_ui` does not depend on
  it.
- Guidelines, gallery, Widgetbook Playgrounds and tests for all of the above.

## 1.5.0 - 2026-10-07

- Add the shared shortcut recorder with keycaps, recording, clear and conflict
  presentation. Applications own validation, registration and persistence.
  Keyboard cancellation is idempotent before an owner acknowledges it; long
  keycaps wrap within bounded width at enlarged text sizes.
- Integrate the validated ShotLama branch's Select/Chip enlarged-label handling,
  split-button API, compact button padding, reduced-motion immediate resize and
  scrolling Banner action layout with the current main disabled segments and
  Breadcrumbs/PathTree additions. Preserve the existing branding and icon set.

## 1.4.0 - 2026-10-06

- Add `MeridianSegment.enabled` (default `true`): a disabled segment reads
  `ink-faint`, ignores taps, clicks, Space and Enter, and is skipped by the
  arrow keys, Home and End, so `onChanged` never receives its value. Its
  `tooltip` serves as the disabled reason and still shows on hover; its
  semantics report `enabled: false` under the segment's own label. The
  selected value may be a disabled segment: the tile stays on it with muted
  ink. Guideline, gallery knob, web preview and tests updated.

## 1.3.0 - 2026-10-06

- Add `MeridianBreadcrumbs` and `MeridianBreadcrumb`: a one-line location
  trail with small `chevron-right` separators in `ink-faint`. Crumbs take a
  label, an optional leading widget, `mono` (`code-sm`), `emphasis`
  (`body-strong`), `onActivate` (click, Enter, Space) and `onContextMenu`
  (secondary click, the context-menu key, Shift+F10, with a global
  position). When the row is too narrow the middle crumbs fold into one `…`
  crumb that reports the hidden crumbs through `onOverflow`; the first
  crumb's label ellipsizes before the last one's. Guideline, gallery entry,
  web preview and tests included.
- Add `MeridianPathTree.flatten` and `MeridianPathTreeRow`: pure flattening
  of '/'-separated paths into list or tree rows (folders first by name,
  files by a comparator, backslashes as separators, empty segments dropped,
  collapsed folders, every folder's descendant items).
- Add the Lucide `app-window` icon (`MeridianIcons.appWindow`).
- Add `MeridianLayout.breadcrumbMinWidth`.

## 1.2.0 - 2026-10-05

- GitLama moves from Git ember back to blue: cerulean `#056CB3` light and `#5BB1FE` dark. Ember sat too close to the `danger` red of error markers. The cerulean sits further from CrossProton's violet than the original polar blue and stays clear of Nibluma's petrol. The `brand` grounds return to `#14242B` / `#1F3A48`. Token names and APIs are unchanged.

## 1.1.1 - 2026-10-05

- Menu and context-menu highlights move to the hovered or keyboard row in the
  same frame instead of gliding after the pointer (MM-42). The row's fill and
  on-accent ink switch together; pressed rows darken the highlight.


## 1.1.0 - 2026-10-05

- Give the Lama apps distinct hues. Mimameidr (ProcessLama) moves from signal blue to signal green (`#0E7C59` light, `#24C27D` dark), GitLama from polar blue to Git ember (`#C8421F` / `#F77C56`) and ShotLama from iris to magenta (`#B8338F` / `#E977BB`). Their whole accent families and `brand` grounds follow; CrossProton and Nibluma are unchanged. Token names and APIs are unchanged.

## 1.0.0

- Rename the unpublished capture app brand to ShotLama (`MeridianBrands.shotlama`, brand ID `shotlama`), preserving its iris colors, graphite neutrals and density. Consumers must use the new brand identifier.

## 0.14.1 - 2026-10-05

- Anchored and context menus wait for their exit transition and overlay removal
  before dispatching a selected action. Follow-up dialogs can open and reopen
  after pointer or keyboard selection, including reduced motion.
- A menu selection is discarded when its invoking context unmounts before
  teardown completes.

## 0.14.0 - 2026-10-05

- Buttons can crossfade their whole content to a centred success check with
  `successReplacesLabel`, preserving width, focus and the accessible label.
- `onSuccessFinished` reports a completed confirmation hold once. New loading,
  cleared success or disposal cancels the callback, and rebuilds cannot change
  which operation owns it.

## 0.13.3 - 2026-10-05

- Toast actions move below the message when their labels cannot fit beside it.
  Long filenames and enlarged text stay readable, with bounded action controls.

## 0.13.2 - 2026-10-04

- Labelled buttons grow vertically when enlarged text needs more than the
  density's minimum height. Small zoom buttons and regular action labels no
  longer clip at 200% text.
- Status bars use their token height as a minimum and grow to fit enlarged
  text and embedded controls. Consumers must allow that content height.

## 0.13.1 - 2026-10-03

- Under a `MeridianMenuPresenter`, a menu with a `MeridianMenuCustom`
  block (in a submenu too) stays a Meridian menu. A native menu cannot
  show custom content, so presenting it left the block out.

## 0.13.0 - 2026-10-03

- `MeridianColorPicker.layout` arranges the picker for a desktop: `wide`
  puts the wheel at the start with the hex field, model and sliders beside
  it; `stacked` keeps the wheel above them. The default, `auto`, is wide
  from 440 px at a desktop density, so a picker in a dialog or popover no
  longer stands twice as tall as it is wide.
- `MeridianColorWell` offers any other colour beside a palette: a
  swatch-sized ring of hues around the custom colour (a plus while there is
  none) that opens a wide `MeridianColorPicker` in a popover. Changes reach
  the owner while the popover is open; Escape or a click outside closes it
  and focus returns to the well.

## 0.12.1 - 2026-10-03

- `MeridianColorPicker`'s wheel stays at full brightness. Dark colours,
  such as most ink, turned the whole wheel nearly black; the thumb and the
  brightness slider still show the colour itself.

## 0.12.0 - 2026-10-03

- `MeridianColorPicker` picks any colour by eye or by number: titled rows
  of swatches (`MeridianColorGroup`: a palette, recent colours, colours in
  the document), a hue and saturation wheel, the original colour above the
  new one beside a hex field, and HSB or RGB sliders. Every value can be
  set exactly from the keyboard, a drag on the wheel never scrolls the
  surface it sits in, the picker keeps the colour's alpha, and a grey keeps
  the hue the wheel was turned to. `MeridianColorPickerLabels` localizes it.
- `MeridianSlider.track` paints a colour channel's range as a gradient
  track in place of the `accent` fill.
- Regenerated the Avatar and Menu guidelines, which had fallen behind
  `design/src/components.py`.
- A menu row's text and icons turn light when the gliding highlight reaches
  it, not when the highlight moves. A row that the pointer or arrow keys had
  just reached no longer reads light on light while the fill was on its way,
  and a row whose submenu is open goes back to dark text once the fill moves
  to another row.
- `MeridianGlideTarget.builder` builds an item with the ink it needs where
  the indicator is: `onIndicator` is true while the gliding indicator covers
  most of the item.

## 0.11.2 - 2026-10-03

- Include the Mono OFL notice as a runtime asset alongside the font faces.

## 0.11.1 - 2026-10-03

- Bundle authentic JetBrains Mono Medium and Bold at weights 500 and 700.
  Regular and the OFL notice retain their existing bytes. Font source hashes
  and native weight metadata are verified.

## 0.11.0 - 2026-10-03

- Add the ShotLama brand with iris accents, graphite neutrals, platform typography and regular desktop density. The gallery, Widgetbook and website include it.

- `MeridianAvatar` puts a loaded `image` on `pane`, so a logo with a
  transparent background no longer shows the colour fill and initials through
  it.
- Reuse and dispose `MeridianSwap` curves so repeated content rebuilds no longer retain animation listeners and increase memory use.
- `MeridianTextField.scrollController` lets an owner read and drive the scroll
  offset of a multi-line field, to keep an editor in step with another pane.
- Add `MeridianResultNavigation` for arrow/Enter result selection while a search field retains focus.
- Update glide indicators when selected targets resize inside scrolling lists.
- Widgetbook covers every component group, with knobs on each `Playground`
  use case and separate addons for brand, theme, density, reduced motion and
  speed. A test opens every use case at 390 px and 1280 px in regular and
  touch density.
- The landing page adds a component catalogue, a live Widgetbook preview, a
  token overview and code samples. Its brand cards now state each brand's
  accent, density and typeface.
- `tool/build_site_icons.py` writes PNG copies of the Meridian mark to
  `webfront/icons/`.

### Added

- `MeridianBusyOverlay.action` puts one control, usually a quiet Cancel
  button, at the end of the busy pill. It stays usable while the covered
  surface takes no input.
- `MeridianTabStrip` is a browser-style strip of open documents. Tabs share
  the width and scroll when they no longer fit; the active pill glides; new
  tabs grow in and closed ones collapse out. Tabs and group chips drag
  straight along the strip while the others make room. A tab joins a group
  once it passes the group's chip or between its tabs; at the group's end its
  rule shows membership and a short nudge outwards leaves. A dragged chip
  carries its group. Groups have a tinted chip with an optional icon, a rule
  in their colour, collapse to a counted chip and are named in place, like
  tabs. Escape cancels a drag; assistive technology gets move actions. The
  gallery, Widgetbook and the landing page's live preview show it.
- `MeridianInputModality.changes` notifies when the last input switches
  between keyboard and pointer, so an affordance revealed by hover or keyboard
  focus can hide again after a pointer press elsewhere.
- `MeridianScrollbar` is the scrollbar of one scroll view that chooses when its
  thumb shows: while the pointer is over the view and while it scrolls
  (`hover`, the default), only while it scrolls, or always. The thumb fades and
  takes no room.
- `MeridianMiddleEllipsis` shows one line of text and keeps both ends when it
  is too long. Its width follows the shown text, and it chooses the shortened
  text during layout instead of measuring in `build`.
- `MeridianSelect.animateValue` rises a changed value label while retaining
  the select trigger, menu, and focus state. The motion gallery exercises it.
- `MeridianDialogSurface.borderRadius` lets anchored palette routes animate
  their corner shape while the shared surface keeps its paint and clip aligned.
- `MeridianPanel.visible` and `onHidden` keep a closing panel mounted for its
  exit. `MeridianRemovingRow.delay` staggers a batch of row removals.
- `MeridianOverlayEntrance` is exported for an anchored prompt that opens
  without a route.
- `MeridianTextField.programmaticClearSequence` fades the old text after an
  owner clears its controller while keeping the editable field and focus.
  The motion gallery includes a clear and refill demo.
- `MeridianButton.animateLabel` rises a changing action label into place while
  its width follows; the motion gallery includes a changing action demo.

### Fixed

- `MeridianKbd` keycaps keep their own height inside a taller slot (a pill or
  row that centres its children) instead of stretching to it and being clipped
  by a rounded container.

## 0.9.1 — 2026-09-28

- Defer and coalesce custom-glide geometry invalidation when lazy slivers recycle
  their selected target during layout. Detached owners discard queued updates.
- Add a 4,000-row recycling regression and gallery case.

## 0.9.0 — 2026-09-27

Meridian's motion system (design/project/guides/40-motion.md): tokens,
helpers and every row of the shared catalogue (MM-01 to MM-78) in the
components, plus a lighter selection style.

### Added

- Motion tokens: `MeridianCurves` (standard, enter, exit, exitSoft),
  `MeridianSprings` (snappy, gentle, pop), `MeridianMotionScales`, and new
  `MeridianDurations` (hoverOut, press, quick, exit, dialog, layout,
  highlight, celebrate, attention, reducedFade, stagger, spinnerDelay,
  shakeField, shakeSurface, nudge, hold, progressHold, tooltipWarm, pulse,
  skeletonPulse, march). `design/project/tokens.json` carries the motion
  object; `design/project/motion.css` has them as CSS custom properties.
- Foundation: `MeridianMotion.fade`, `.curve`, `.pressScale`,
  `meridianHoverDuration`, `MeridianMotionMemory`, `MeridianMotionScope`,
  `MeridianSpringController`, `MeridianAnimatedValue`, `MeridianWindowFocus`
  and `MeridianWindowFocusScope`.
- Helpers: `MeridianPressScale`, `MeridianSwap`, `MeridianRollingNumber`,
  `MeridianReveal`, `MeridianRemovingRow`, `MeridianResize`,
  `MeridianEntrance`, `MeridianStroke`, `MeridianStrokeIcon`,
  `MeridianShake`, `MeridianPulse`, `MeridianAttention`, `MeridianGlide`
  (with `.custom` and `MeridianGlideTarget`), `MeridianSelectionGlide`,
  `MeridianSelectionFill`, `MeridianLift`, `MeridianTravel`,
  `MeridianNudgeIcon`, `MeridianTurns`.
- New properties: `MeridianInteraction.pressScale`; `MeridianButton.success`;
  `nudge` on `MeridianIconButton` and `MeridianToolbarButton`;
  `MeridianIconButton.turns`; `MeridianTextField.rejectCount`;
  `MeridianKbd.pressed`; `MeridianHeldModifiers.keys`;
  `MeridianMenuAnchor.onOpenChanged`; `MeridianList.builder(selectedIndex:)`;
  `MeridianListRow.revealKey` and `attention`; `MeridianTabs.tabKeys`;
  `MeridianSelectionBar.visible`; `showMeridianDialog(transitionBuilder:,
  transitionDuration:, reverseTransitionDuration:)`;
  `MeridianDialog.submitDisabled`; `MeridianDialogSurface.rejectCount`;
  `MeridianPanel.origin`; `MeridianSpinner.delayed`;
  `MeridianProgressBar.persistent`; `MeridianSkeleton.swap`;
  `MeridianBanner.visible`; `MeridianStatusDot.live`;
  `MeridianCount.emphasizeIncrease`; `MeridianChip.visible`;
  `MeridianIsland.contentKey`.
- `MeridianSelectionStyle` and `buildMeridianTheme(selection:)`: `soft`
  keeps selected rows `accent-soft` with the normal inks in a focused
  island.
- `tool/check_motion_usage.py`: rejects literal curves, durations and
  springs, size animation outside the two helpers, and direct reads of the
  reduce-motion flag in `lib/src`.
- Gallery: Speed (1×, 0.5×, 0.2×) and Reduce motion switches, and Motion
  sections labelled with MM ids.

### Changed

- Curves: `select` easeOut → standard, `overlay` easeOut → enter, `sheet`
  easeOutCubic → enter, `emphasized` easeOutCubic → standard.
- Every catalogue row plays in the components: hover fills fade out slower
  than in; buttons, icon buttons, toolbar buttons, floating buttons,
  pressable chips and page buttons press-scale; segmented tiles, tab rules
  and pills, pagination and menu highlights glide; switches, checkboxes and
  radios spring; menus, popovers and dialogs grow from their anchor and
  leave in 100 ms (they had no exit); toasts arrive on a spring and their
  countdown pauses instead of restarting; spinners and busy overlays wait
  150 ms; progress bars fade after reaching 100%; skeletons breathe.
- `MeridianIconButton`, `MeridianToolbarButton`, `MeridianSelect` and
  `MeridianList` are stateful internally; their constructors are unchanged.

### Migration

No code changes are required. To use MM-04, MM-07, MM-09, MM-20, MM-23,
MM-47, MM-69, MM-70 and MM-74, set the new properties. A progress bar that
should stay at 100% needs `persistent: true`. Tests that `pumpAndSettle`
while a skeleton or an active drop zone is on screen must pump explicit
durations instead.

## 0.8.1 — 2026-09-27

From GitLama's Changes list: the stage and discard hover actions on the
focused (solid `accent`) selected file row painted `ink-muted` on `accent`
and could not be seen.

### Fixed

- `MeridianIconButton` on a solid `accent` surface (`MeridianSurfaceScope`
  fill, as a focused `MeridianListRow` selection publishes it) uses
  `on-accent-muted` at rest and `on-accent` on hover, press and toggle;
  disabled is `on-accent-muted` at half opacity. Guideline, web rendition
  and test.

## 0.8.0 — 2026-09-27

From GitLama's dialog review: a fetch dialog's single "Remote" label sat
right-aligned in the 200px settings column, leaving the form stranded in the
middle of the dialog.

### Added

- `MeridianSettingsGroup.fitLabels`: the label column hugs the group's
  widest `MeridianSettingsRow` label (at most the 200px settings column)
  with `space-5` to the controls, for forms in dialogs. A row with an empty
  label lines a checkbox up with the controls; a fitted form stacks only when
  its controls would get narrower than `selectMinWidth`. Groups without it
  lay out as before. Guideline, web rendition, gallery entry and tests.

## 0.7.1 — 2026-09-26

### Fixed

- A brand without a sans of its own (Nibluma's platform face) left
  `fontFamily` unset, so text below no `Material` (dialogs and sheets over
  `MaterialApp`'s fallback style) inherited `monospace`. `MeridianTextStyles`
  now names the platform's family as Material's typography does (Roboto,
  the SF system face, Segoe UI); `MeridianTextStyles.platformSans` exposes
  it. Found in Nibluma's first review captures on 0.7.0.

## 0.7.0 — 2026-09-26

From Nibluma's design review: a notes app needs warm paper rather than the
shared cool neutrals, a desk for its pages and one floating tool palette.
Public APIs only gained classes, properties and a token; brands without the
new fields render exactly as before.

### Added

- Brand neutrals: a brand file may carry `neutrals` for light and dark,
  replacing any of the surface, canvas, scrim, ink, line and control-edge
  tokens (`NEUTRAL_KEYS` in `tool/generate.py`). `MeridianNeutralColors`,
  `MeridianBrand.lightNeutrals` / `darkNeutrals` / `neutralsFor`, and an
  optional third argument to `MeridianColors.resolve`. Status and series
  colours stay shared; the generator checks every contrast floor against
  the brand's own neutrals and rejects unknown keys.
- The `canvas` colour token: the desk behind documents (page feeds, scan
  and image viewers, print previews), with floors for `ink`, `ink-muted`
  and `focus` on it.
- `MeridianCanvas`, `MeridianPaper` (a page with a content colour,
  `shadow-pane` edge, 2px corners and an outside `accent` ring when
  selected) and `MeridianToolDock` with `MeridianToolDockDivider` (the
  floating `raised` tool palette, horizontal or vertical), with
  `MeridianLayout.paperRadius`, `toolDockPadding` and
  `toolDockDividerLength`.
- `MeridianFonts.displayForTitle` (default `true`: titles keep following
  `display`) and `MeridianFonts.displayWeight`, so an editorial serif can
  be kept for the display style at a lighter weight. Brand files set them
  as `fonts.display.titles` and `fonts.display.weight`.
- Guidelines, previews and web renditions for Canvas, Paper and ToolDock;
  a gallery section and tests for them and for brand neutrals.

### Fixed

- The ColorSwatch web preview drew its check in `pane` or `ink`, which
  vanished on dark swatches in dark themes; it now contrasts with the
  swatch, as the Flutter widget does.
- `MeridianSelectionBar` budgeted each command at the small control extent,
  so at touch density (48px targets) a narrow bar overflowed instead of
  moving commands into its menu.
- The gallery layout test scrolled a fixed distance and never reached the
  last sections at 390px; it now steps to the end of the page and asserts
  the last section was laid out.

### Changed

- Nibluma's brand: petrol accent (`#0B6477` / `#5CC0CF`) instead of jade,
  which sat too close to `success`; warm paper neutrals with blue-black
  ink; the platform UI face instead of bundled Roboto; Literata 500 for
  `display` only, titles in the sans; radii 6 / 10 / 12 / 18 / 24.
  Nibluma adopts it when it moves its pinned `ref`.

## 0.6.1 — 2026-09-26

### Fixed

- `MeridianPagination` page buttons hug their numbers again. The current
  page filled the whole width in a narrow pane and pushed the other pages
  and the jump field onto lines of their own.

## 0.6.0 — 2026-09-26

From CrossProton's move onto the package: a desktop mail client with user
theme packages, folder trees, drag and drop and search. Public APIs only
gained widgets, properties, functions, constants and icons.

### Added

- Themes people pick or edit: `buildMeridianTheme` and
  `MeridianTheme.resolve` take replacement `colors`, `typeScale` and
  `shadows`. `MeridianColors.copyWith`, `MeridianTypeScale.copyWith` and
  `MeridianShadowsTint.tinted` derive them from the brand; a font family
  named on a type-scale entry wins over the brand's. `MeridianTheme.lerp`
  animates the corner radii when the theme changes.
- Menus: submenus (`MeridianMenuItem.children`, opened on hover after
  200ms, with →, Enter or a click, closed with ← and Escape), a `leading`
  picture in the icon slot, `labelStyle` for items that preview themselves,
  `MeridianMenuCustom` for a short non-command block (the person a contact
  menu is about), and type-ahead.
- `MeridianPopoverAnchor`, `showMeridianPopover` and
  `MeridianPopoverSurface`: a floating panel under a trigger for a small
  task (a filtered folder picker, a label picker with check boxes).
- `MeridianPagination`: numbered pages with previous and next, collapsed
  around the current page, and an optional field to jump to a page.
- `MeridianSelectionBar` and `MeridianSelectionAction`: the count of
  selected items with their commands, which move into an overflow menu when
  the bar is narrow.
- `MeridianDropZone` with `MeridianDropZoneState` (idle, active, invalid):
  a dashed target for dropped files that can also browse.
- `MeridianCalendar` and `showMeridianDatePicker` (with a `locale`), with
  full keyboard navigation.
- `MeridianBusyOverlay`: dims a surface that must not change while a
  blocking operation runs, with a spinner and a message.
- `MeridianNavRow.drop` (`MeridianDropFeedback`): accept and reject
  feedback while something is dragged over a row.
- `MeridianSegmented.manualActivation`: the arrows move focus and Enter or
  Space selects, for segments whose change is expensive (it reloads a list).
- `MeridianTextFieldVariant.plain` for a field inside a surface that is
  already a field; `MeridianTextField.clearLabel` (a clear button while the
  field holds text) and `onTap`.
- `MeridianAvatarSize.xLarge` (40px) and `MeridianAvatar.monogram`; an
  avatar image that fails to load falls back to the initials.
- `MeridianSuggestionRow.leading`.
- `MeridianTextStyles.match`: the style of the part of a text that matches
  a query, as list rows use it.
- `MeridianLayout` constants for the new primitives and
  `MeridianOpacity.busyScrim`.
- 23 Lucide 1.37.0 icons: `bold`, `italic`, `underline`, `strikethrough`,
  `list-ordered`, `text-quote`, `code-xml`, `remove-formatting`,
  `text-align-start`, `text-align-center`, `text-align-end`,
  `text-align-justify`, `octagon-alert`, `folder-input`, `book-user`,
  `calendar-clock`, `search-x`, `square-check`, `bug`, `ratio`, `blocks`,
  `rows-3` and `trash`.
- Guidelines and previews for Popover, Pagination, SelectionBar, DropZone,
  Calendar and BusyOverlay; gallery entries for them, a submenu, a drop
  target and the new field and avatar options.

### Fixed

- `MeridianResizeHandle` follows the pointer from where it went down
  instead of lagging by the drag slop.
- Suggestion lists count as part of their text field for tap-outside
  handling, so choosing a row with the pointer no longer unfocuses the
  field first.

## 0.5.0 — 2026-09-26

From Nibluma's move onto the package: a touch app with a pen canvas,
scanning and offline storage. Public APIs only gained widgets, properties,
functions, constants and icons.

### Added

- `MeridianFloatingButton`: the one prominent floating command of a touch
  screen, 56px, optionally `extended` with its label.
- `MeridianColorSwatch`: a colour choice for palettes (pen, cover, label
  colours), with a contrasting check, an `accent` ring and a 48px target at
  touch density.
- `MeridianDrawer`: the navigation drawer for `Scaffold.drawer` on phones.
  `buildMeridianTheme` sets the drawer scrim to `scrim`.
- `MeridianAppBar.subtitle` and `automaticallyImplyLeading`: a back button
  on poppable routes, or a menu button that opens the Scaffold's drawer.
- `MeridianSwitch.description`, shown under the label and read as the hint.
- `MeridianSelect.showLabel` (the label above the trigger, for forms) and
  `expand` (fill the width).
- `MeridianButton.leading`: a small picture instead of an icon (a colour
  dot, a pen preset).
- `MeridianDialogSurface.alignment`, for palettes anchored to an edge.
- `showMeridianToastIn(overlay, …)` for results that arrive after the
  screen that started the work has closed, and `hideMeridianToast()`.
- `MeridianLayout.floatingButtonSize`, `swatchSize`, `swatchSizeTouch`,
  `swatchRingWidth`, `swatchRingGap`, `drawerWidth` and
  `appBarTitleMaxTextScale`.
- 14 Lucide 1.37.0 icons: `arrow-down-a-z`, `chevrons-right`, `circle`,
  `cloud-check`, `gallery-horizontal`, `graduation-cap`, `hourglass`,
  `image-plus`, `images`, `lasso-select`, `move-diagonal-2`,
  `paint-bucket`, `pointer` and `unlink`.
- Guidelines and previews for FloatingButton, ColorSwatch and Drawer;
  gallery entries for them, a described switch, a labelled full-width
  select, a button with a leading picture and an app bar subtitle.

### Fixed

- `MeridianListRow` and `MeridianNavRow` grow when large text needs more
  than the density's row height instead of overflowing (two-line rows
  overflowed at 200% text). They still never stretch to the height they
  are offered.
- The `MeridianAppBar` title follows large text only up to 134%, as
  platform app bars do, so a title with a subtitle no longer overflows the
  56px bar.
- `MeridianBanner` actions are separate buttons for assistive technology
  again; the title and message form one node, the live region for `error`
  and `attention`.
- Dialogs (`MeridianDialog`, `MeridianDialogSurface`) rise above the
  on-screen keyboard.

## 0.4.0 — 2026-09-26

From GitLama review feedback.

### Added

- `MeridianKbd.reveal` with `MeridianKbdReveal.whileModifierHeld`: keycaps
  on permanent chrome appear only while one of their command modifiers
  (⌘, Ctrl, ⌥) is held, and take no space otherwise. `MeridianKbd.padding`
  collapses with them. `MeridianButton.shortcutReveal` passes it through.
- `MeridianHeldModifiers`: the command modifiers currently held, listening
  to the keyboard only while something listens to it.
- `MeridianInteraction.focusOnPointer`: whether a pointer press takes focus.
- `MeridianSelect.minWidth`.

### Changed

- `MeridianToolbarButton` (face and split caret) no longer takes focus on a
  click. Focus stays where the person was working, so a dialog the command
  opened no longer returns focus, and a focus ring, to the toolbar.
- A `MeridianSelect` without a `width` fits its longest choice instead of
  the current one, so it keeps its size when the value changes, and its
  chevron sits at the trailing edge instead of after the text.

## 0.3.1 — 2026-09-26

### Fixed

- A `MeridianSegmented` that hugs its labels (no `expand`) shrinks and
  ellipsizes them in a narrow space instead of overflowing; with room it
  still takes its natural width.

- Selectable `MeridianPropertyList` values use the
  `MeridianMenuPresenter`'s text context menu, like text fields, so an app
  with native menus never shows Flutter's toolbar for selected text.

## 0.3.0 — 2026-09-26

From GitLama's move onto the package, the app Meridian was extracted
from. Public APIs only gained widgets, properties, constants and icons.

### Added

- `MeridianMenuPresenter`: routes every Meridian menu (menu anchors, split
  toolbar buttons, `MeridianSelect`, context menus) to a callback, so a
  desktop app can show the operating system's native menus from the same
  `MeridianMenuItem` model.
- `MeridianDialogSurface`: the dialog surface on its own for dialogs with
  their own layout (command palette, settings window, full-window review).
  `MeridianDialog` now builds on it.
- `MeridianSuggestionSurface`, `MeridianSuggestionRow` and
  `MeridianSuggestionHeader`: completions under a field (branch names,
  recipients, tags) with a keyboard highlight that never takes focus from
  the field. `MeridianLayout.suggestionMaxHeight`.
- `MeridianTextField.fieldKey`, `showLabel`, `expands`, `height`,
  `spellCheckConfiguration` and `contextMenuBuilder`.
- `MeridianListRow.match` (the filter text, set in bold underlined
  `accent` in the title), `titleTrailing` and `semanticValue`.
- `MeridianDisclosure.header`: richer header content that grows to fit.
- 27 Lucide 1.37.0 icons: `badge-check`, `binary`, `brush-cleaning`,
  `columns-2`, `file-diff`, `file-input`, `file-output`, `file-search`,
  `file-user`, `folder-clock`, `folder-closed`, `folder-git-2`,
  `folder-symlink`, `git-compare-arrows`, `git-fork`, `git-pull-request`,
  `key`, `layout-template`, `life-buoy`, `list-filter-plus`,
  `message-square-text`, `pilcrow`, `rows-2`, `signature`, `spell-check`,
  `square-terminal` and `wrap-text`.
- Guideline and preview for Suggestions; gallery entries for suggestions
  and a filtered list row.

### Fixed

- A dialog opened from another dialog or a menu keeps the scrim that is
  already there instead of dimming the window a second time.
- `showMeridianConfirm` with `destructive` starts on Cancel again, and a
  dialog action with `autofocus` keeps its focus. The dialog took focus in
  a post-frame callback before Flutter applied the pending autofocus.
- A `MeridianDialog` placed inline (a gallery specimen) no longer takes
  keyboard focus; only a dialog in a dialog route does.
- A control with `canRequestFocus: false` (a row action, a find-bar arrow)
  no longer rebuilds on every frame. `MeridianInteraction` and its
  `FocusableActionDetector` both set the node's focusability and undid
  each other, so screens with such a control never settled. It is now kept
  out of focus with `ExcludeFocus`.

## 0.2.2 — 2026-09-26

### Fixed

- A control no longer shows its keyboard focus ring when focus returns to it
  after a menu or dialog it opened was used with the mouse (for example the
  caret of a split toolbar button). Flutter's desktop highlight mode is
  always traditional, so the ring now also requires the last input to have
  been a key (`MeridianInputModality`, like the web's `:focus-visible`).

### Added

- `MeridianInputModality`.

## 0.2.1 — 2026-09-26

### Fixed

- Hover fills no longer flash dark as they fade in or out. Components
  animated between a light fill and `Colors.transparent`, which is
  transparent *black*, so the in-between frames were translucent grey.
  `meridianClear(color)` is the colour at zero alpha;
  `MeridianInteractionState.fill` and `MeridianRowColors` use it, as do
  every animated edge, rule and fill in the components. A contract test
  rejects new `Colors.transparent` uses in components, and hover tests
  sample the fill mid-animation.

### Added

- `meridianClear`.

## 0.2.0 — 2026-09-26

Data and window primitives from Mimameidr's migration, the first app on
Meridian. Public APIs only gained widgets, constants and icons.

### Added

- `MeridianPropertyList` / `MeridianProperty`: labelled read-only values for
  inspectors and detail islands, side by side when wide and stacked when
  narrow or at touch density; monospace values use `code` with tabular
  figures.
- `MeridianColumnHeader` and `MeridianSortDirection`: a sortable table
  heading with the sort arrow, end alignment for numeric columns and a
  column menu on secondary click.
- `MeridianResizeHandle`: the island gutter as a drag, arrow-key and
  double-click-to-reset resize handle.
- `MeridianStatusBar`: the 24px window status strip on `ground`.
- Icons `case-sensitive`, `whole-word`, `regex`, `bookmark-plus`,
  `circle-play`, `circle-pause`, `circle-stop` and `octagon-x`.
- `MeridianNavRow.leading`: an app icon or avatar in the icon slot.
- `MeridianIconButton.canRequestFocus`: row actions and find-bar arrows
  that leave keyboard focus with their list or field.
- `MeridianLayout.propertyLabelColumn`, `propertyStackFactor`,
  `sortIconSize`, `resizeRule` and `resizeKeyboardStep`.
- Gallery section "Data and window"; guidelines and previews for the four
  new components.

### Fixed

- Controls on a hovered or selected row no longer vanish into it on hover.
  `MeridianSurfaceScope.fill` carries the paint behind a row's content (and
  a field's well), and `MeridianIconButton` and quiet `MeridianButton`s
  hover by darkening it (`MeridianSurfaceScope.hoverFillOf`; a solid
  `accent` selection brightens instead). Before, a hover action on a
  hovered `MeridianListRow` painted the same `pane-hover` as the row, so
  its hover flashed for a frame and disappeared. `MeridianListRow`
  (trailing and hover actions), `MeridianNavSection` (header action) and
  `MeridianTextField` (trailing) publish their fill; tables and trees
  built from `MeridianRowColors` should wrap cells in
  `MeridianSurfaceScope.withFill`.
- Quiet buttons on `ground` hover with `ground-hover`, as the design
  rules say, instead of `pane-hover`.
- `MeridianStatusDot` ellipsizes its label instead of overflowing in a
  narrow space.
- `design/src/components.py` carries the 0.1.1 guideline text again, so
  regenerating no longer reverts the component READMEs.

## 0.1.1 — 2026-09-25

First validation pass: the package now compiles, analyzes clean, and is
covered by widget tests for every primitive. Public APIs only gained
optional parameters.

### Added

- `MeridianTextScope`: body text in `ink` plus a transparent Material
  ancestor. `MeridianGround` and every overlay use it, which fixes red
  fallback text and the TextField "No Material widget" crash.
- `MeridianList` / `MeridianList.builder`: the `space-3` list inset.
- `MeridianInteractionState.fill` and `meridianPressed`: the pressed state
  (hover plus 4% `ink`), now on every control.
- Motion tokens `motion-progress`, `motion-skeleton-delay`, `motion-toast`,
  `motion-toast-action`, `motion-spinner-reduced`; new `MeridianLayout` and
  `MeridianOpacity` constants replace literals in the components.
- `MeridianIconSet(package:)` (`null` in the package's own tests); value
  equality for `MeridianTheme`, `MeridianBrand`, `MeridianFonts` and
  `MeridianIconSet`.
- Optional parameters: `MeridianTab.enabled`/`semanticLabel`,
  `MeridianTabs.dirtyLabel`, `MeridianNavRow.enabled`, `MeridianChip.enabled`,
  `MeridianDisclosure.enabled`, `MeridianDialog.onSubmit`,
  `showMeridianDialog(dismissOnEscape:)`, `MeridianSkeleton.delay`,
  `MeridianToast.liveRegion`, `MeridianToolbarButton.menuLabel`,
  `MeridianMenuSurface.onDismiss`/`initialHighlight`.

### Fixed

- Touch targets: the 48px area grows inside the gesture detector, so its
  margin is tappable, and stretched controls stay full width. Island, panel
  and nav-section headers, tree chevrons and chip remove buttons reach 48px
  at touch density.
- Focus ring: only for keyboard focus, and only on the control that has
  primary focus (no double ring when focus is inside a row's action).
- Tabs: the underline follows its tab after scrolling; arrow keys, Home and
  End move focus with the selection and skip disabled tabs; hidden close
  buttons take no clicks but stay in semantics; count and dirty state are
  announced.
- ListRow: single taps are no longer delayed by `onDoubleTap`; hover actions
  stay while focused and replace only `meta`; disabled rows fade entirely;
  the height no longer animates (two-line rows overflowed mid-transition).
- Toast: one at a time, pauses on hover and focus, fades out, is announced,
  and disposes its overlay entry and timer. Dialogs and toasts keep local
  `Theme` overrides.
- Dialog: scrolling body, wrapping actions, full-width stacked actions at
  touch on phones, Escape even when the scrim cannot dismiss, Enter submits.
- Banner stacks its actions by width, not only at touch density; EmptyState
  scrolls in short spaces; SettingsRow keeps its label beside the first
  control in bounded layouts; Count, Kbd and Avatar handle large text.
- Slider (`min == max`, step 0, unbounded width, RTL arrows, final
  `onChangeEnd` value), mixed checkbox semantics, loading buttons keep
  focus, menu keyboard highlight and Escape, ProgressBar animation control
  and RTL, Sheet above the keyboard, AppBar exactly 56px, Panel Escape and
  padding, Kbd density caption, generated Dart formatted by the generators.

## 0.1.0 — 2026-09-25

- First release of Meridian as a shared system, generalized from GitLama Meridian 3.0.
- Shared core tokens (light and dark), desktop and touch type scales, four densities including touch.
- Brands for GitLama, CrossProton, Mimameidr and Nibluma, contrast-checked in both themes.
- Primitives: actions, inputs, menus, navigation, display, feedback and containers (see README).
- Lucide 1.37.0 icon set (164 icons) and JetBrains Mono.
