import 'meridian_tokens.g.dart';

/// Component dimensions that are not tokens.
///
/// Carried over from GitLama's Meridian reference (bundle.css and
/// specs). Add a value here only when a component guideline names it.
abstract final class MeridianLayout {
  // Focus and lines
  static const double focusRingWidth = 2;
  static const double focusRingOffset = 1;
  static const double hairline = 1;
  static const double scrollbarThickness = 6;
  static const double scrollbarThicknessHover = 8;

  /// The strip a scrollbar takes beside content it must not cover: the
  /// hovered thumb with its margin on both sides.
  static const double scrollbarGutter = 12;

  // Window chrome
  static const double macOSTrafficLightInset = 78;
  static const double statusBarHeight = 24;

  // Toolbar button
  static const double toolbarButtonHeight = 44;
  static const double toolbarButtonMinWidth = 48;
  static const double toolbarButtonCompactWidth = 36;
  static const double toolbarLabelGap = 3;
  static const double toolbarBadgeTop = 3;
  static const double toolbarBadgeRight = 4;
  static const double splitCaretWidth = 14;
  static const double splitCaretIconSize = 10;

  // Breadcrumbs: the narrowest the first crumb ellipsizes to before the
  // last crumb gives way.
  static const double breadcrumbMinWidth = 48;

  // Tabs
  static const double tabStripHeight = 34;
  static const double tabPillHeight = 26;
  static const double tabRuleHeight = 2;

  // Tab strip (MeridianTabStrip)
  static const double tabSeparatorHeight = 14;
  static const double tabGroupChipHeight = 20;
  static const double tabGroupChipLabelMaxWidth = 120;
  static const double tabGroupChipEditWidth = 140;
  static const double tabGroupDot = 8;

  /// The group rule's gap above the strip's bottom edge.
  static const double tabGroupRuleInset = 1;

  /// How far past a group's last tab a dragged tab leaves the group.
  static const double tabGroupEdgeShift = 24;

  /// How far a pressed tab moves before it is dragged.
  static const double tabDragThreshold = 4;

  /// A drag this close to a strip's edge scrolls it, by
  /// [tabStripScrollRate] of the overshoot per frame.
  static const double tabStripScrollEdge = 32;
  static const double tabStripScrollRate = 0.25;

  // Navigation (sidebar)
  static const double sidebarMinWidth = 200;
  static const double sidebarMaxWidth = 360;
  static const double sidebarRailWidth = 56;
  static const double navSectionHeight = 26;
  static const double treeIndent = 14;
  static const double chevronSize = 12;

  // Islands
  static const double islandMinWidth = 320;
  static const double floatingPanelHeaderHeight = 44;

  // Controls
  static const double textFieldMinWidth = 200;
  static const double selectMinWidth = 160;
  static const double segmentedTrackPadding = 2;
  static const double checkboxSize = 16;
  static const double checkboxRadius = 4;
  static const double checkboxIconSize = 12;
  static const double radioDot = 6;
  static const double switchWidth = 30;
  static const double switchHeight = 18;
  static const double switchThumb = 14;
  static const double switchThumbInset = 2;

  /// A slider thumb's scale while hovered or dragged (MM-15).
  static const double sliderThumbActiveScale = 1.15;

  /// How much wider the thumb gets while pressed (14 → 18 px, MM-12).
  static const double switchThumbStretch = 4;
  static const double switchThumbTravel = 12;
  static const double sliderTrack = 2;
  static const double sliderThumb = 12;
  static const double kbdHeight = 18;
  static const double kbdMinWidth = 18;
  static const double kbdPaddingX = 4;
  static const double kbdGap = 3;
  static const double countHeight = 16;
  static const double countMinWidth = 16;
  static const double countPaddingX = 5;
  static const double spinnerSize = 12;
  static const double spinnerStroke = 2;
  static const double progressHeight = 2;

  /// Default decorative peak-envelope height; consumers may fit a media strip.
  static const double waveformHeight = 24;

  /// A silent peak remains a thin center tick, separate from meter thickness.
  static const double waveformMinimumPeakHeight = 1;

  static const double meterHeight = 3;
  static const double progressIndeterminateFraction = 0.3;
  static const double statusDot = 6;
  static const double chipHeight = 22;
  static const double chipHeightTouch = 32;
  static const double avatarSmall = 16;
  static const double avatarMedium = 20;
  static const double avatarLarge = 28;
  static const double avatarXLarge = 40;

  // Floating surfaces
  static const double menuMinWidth = 200;
  static const double menuMaxWidth = 360;
  static const double menuMaxHeight = 420;
  static const double popoverMaxHeight = 480;
  static const double popoverWidth = 280;
  static const double dialogWidth = 460;

  /// A yes/no question: a title, one or two sentences, Cancel and the verb
  /// (`showMeridianConfirm`). The same value as [dialogWidth].
  static const double dialogConfirmWidth = dialogWidth;

  /// A form of a few fields or settings rows: a name and a target, a
  /// credential, the options of one operation.
  static const double dialogFormWidth = 560;

  /// A workflow that shows its material while it asks: a list to pick
  /// from, a preview, a command and its output, several steps.
  static const double dialogWorkflowWidth = 760;
  static const double dialogMaxWidth = 560;
  static const double toastWidth = 360;
  static const double sheetMaxWidth = 560;
  static const double sheetHandleWidth = 36;
  static const double sheetHandleHeight = 4;
  static const double settingsLabelColumn = 200;
  static const double settingsHelpMaxWidth = 380;
  static const double settingsStackBreakpoint = 520;

  /// A `MeridianSettingsDialog`: wide enough that its pages keep settings
  /// rows side by side next to the page list.
  static const double settingsDialogWidth = 840;

  /// The tallest a `MeridianSettingsDialog` grows (it keeps this height
  /// while pages change, at most [dialogMaxHeightFraction] of the window).
  static const double settingsDialogHeight = 640;

  /// The page list of a `MeridianSettingsDialog`.
  static const double settingsDialogPageListWidth = 200;

  /// Below this dialog width a `MeridianSettingsDialog` swaps its page list
  /// for a select above the page.
  static const double settingsDialogPagedBreakpoint = 600;

  /// A `MeridianLicenseDialog`: wide enough for license text to keep
  /// readable lines next to the package list.
  static const double licenseDialogWidth = 960;

  /// The tallest a `MeridianLicenseDialog` grows (at most
  /// [dialogMaxHeightFraction] of the window).
  static const double licenseDialogHeight = 720;

  /// The package list of a `MeridianLicenseDialog`.
  static const double licenseDialogPackageListWidth = 260;

  /// Below this dialog width a `MeridianLicenseDialog` shows the package
  /// list and one package's licenses one at a time.
  static const double licenseDialogPagedBreakpoint = 640;

  /// The widest a line of license text grows.
  static const double licenseTextMaxWidth = 720;

  /// Each indent level of a license paragraph.
  static const double licenseIndent = 16;
  static const double emptyStateIconSize = 24;
  static const double emptyStateMaxWidth = 360;

  /// The determinate bar of a loading `MeridianEmptyState`.
  static const double emptyStateProgressWidth = 160;

  // Motion
  /// How long a success check takes to draw (MM-04, NM-62).
  static const Duration successCheckDraw = Duration(milliseconds: 160);

  /// How long a checkbox's check takes to draw, and its delay (MM-11).
  static const Duration checkboxCheckDraw = Duration(milliseconds: 140);
  static const Duration checkboxCheckDelay = Duration(milliseconds: 40);

  /// How far a status bar text rises when it changes (MM-76).
  static const double statusBarRise = 3;

  // Overlays
  /// How far a selection bar or toast moves as it leaves (MM-30, MM-50).
  static const double selectionBarLeave = 8;

  /// How far menus, popovers and panels rise as they fade in. The same
  /// value as [MeridianMotionScales.riseOverlay], which new code uses.
  static const double overlayRise = MeridianMotionScales.riseOverlay;
  static const double panelWidth = 420;
  static const double dialogMaxHeightFraction = 0.85;

  // Additions from the 0.1.1 validation pass (actions, inputs, menu)
  static const double switchWidthTouch = 42;
  static const double switchHeightTouch = 26;
  static const double switchThumbTouch = 22;
  static const double switchThumbShadowBlur = 2;
  static const double switchThumbShadowOffset = 1;
  static const double sliderThumbTouch = 20;
  static const double sliderThumbBorder = 2;
  static const double sliderThumbBorderActive = 3;
  static const double sliderDefaultWidth = 160;

  /// A colour channel slider's gradient track (`MeridianSlider.track`,
  /// 0.12.0).
  static const double sliderColorTrack = 8;
  static const double sliderColorTrackTouch = 12;
  static const double checkboxLabelOffset = 1;

  // Additions from the 0.1.1 validation pass (navigation, display)
  static const double rowTwoLineExtra = 16;
  static const double rowTwoLineExtraTouch = 20;
  static const double tabPillMinWidth = 110;
  static const double tabLabelMaxWidth = 200;
  static const double tabCloseSize = 16;
  static const double tabCloseIconSize = 12;
  static const double navChevronTarget = 20;
  static const double chipMaxWidth = 220;
  static const double chipRemoveSize = 18;
  static const double chipRemoveSizeTouch = 28;
  static const double chipRemoveIconSize = 12;
  static const double countFontSize = 10;
  static const double countLineHeight = 1.6;
  static const double avatarFontSmall = 8;
  static const double avatarFontMedium = 9;
  static const double avatarFontLarge = 11;
  static const double avatarFontXLarge = 14;
  static const double statusHaloSpread = 3;

  // Additions from the 0.1.1 validation pass (feedback, containers)
  static const double bannerIconNudge = 1;
  static const int bannerMaxActions = 2;
  static const double bannerStackBreakpoint = 480;
  static const double skeletonHeight = 10;

  // Data and window (0.2.0)
  static const double propertyLabelColumn = 112;

  /// A property list stacks its labels above the values when it is
  /// narrower than this many label columns.
  static const double propertyStackFactor = 2.5;
  static const double sortIconSize = 12;
  static const double resizeRule = 2;
  static const double resizeKeyboardStep = 16;

  // Suggestions (0.3.0)
  static const double suggestionMaxHeight = 240;

  // Touch additions (0.5.0, from Nibluma)
  static const double floatingButtonSize = 56;
  static const double swatchSize = 24;
  static const double swatchSizeTouch = 32;
  static const double swatchRingWidth = 2;
  static const double swatchRingGap = 2;

  // Colour picker (0.12.0)

  /// The hue and saturation wheel of a `MeridianColorPicker`.
  static const double colorWheel = 200;
  static const double colorWheelTouch = 240;

  /// The wheel's thumb, which shows the chosen colour.
  static const double colorWheelThumb = 16;
  static const double colorWheelThumbTouch = 24;
  static const double colorWheelThumbRing = 3;

  /// The width of the before-and-after colour preview beside the hex field.
  static const double colorPreview = 40;

  /// The narrowest a `MeridianColorPicker` puts its wheel beside its
  /// controls (0.13.0): the wheel, a `space-8` gap and a slider column.
  static const double colorPickerWide = 440;

  /// The popover a `MeridianColorWell` opens: a wide picker and its
  /// `space-6` padding.
  static const double colorWellPopover = 472;

  /// The share of a `MeridianColorWell`'s disc its colour fills inside the
  /// ring of hues.
  static const double colorWellCore = 0.6;
  static const double drawerWidth = 304;

  // Documents and tools (0.7.0, from Nibluma)
  /// Corner radius of a document page on the canvas: paper, not a card.
  static const double paperRadius = 2;

  /// Gap between the tool dock's edge and its buttons.
  static const double toolDockPadding = 4;

  /// Length of a divider between tool groups in the dock.
  static const double toolDockDividerLength = 24;

  /// The largest text scale an app bar title follows.
  static const double appBarTitleMaxTextScale = 1.34;

  // Collections and transfer (0.6.0)
  static const double paginationFieldWidth = 56;
  static const int paginationFieldMaxDigits = 9;

  /// Pages shown before the pagination collapses to first, last and the
  /// neighbours of the current page.
  static const int paginationFullRange = 7;
  static const double dropZoneMinHeight = 104;
  static const double dropZoneIconSize = 24;
  static const double dropZoneDash = 5;
  static const double dropZoneDashGap = 3;
  static const double calendarCell = 32;
  static const double calendarWidth = calendarCell * 7;
  static const double datePickerWidth = 300;

  // Find bar (1.6.0)
  /// The find field's width where there is room, and the narrowest it gets.
  static const double findFieldWidth = 200;
  static const double findFieldMinWidth = 120;

  // Split pane (1.6.0)
  /// The narrowest a pane of a `MeridianSplitPane` gets by default.
  static const double splitPaneMinExtent = 200;

  // Code lines (1.6.0)
  /// One unwrapped line of `code`, a line-number cell and the marker
  /// column of a `MeridianCodeGutter`.
  static const double codeLineHeight = 18;
  static const double codeGutterWidth = 44;
  static const double codeMarkerWidth = 18;

  // Steps (1.16.0)
  /// The round marker of a `MeridianSteps` step: a check, or the step's
  /// number in `countFontSize`.
  static const double stepMarker = 16;
  static const double stepMarkerTouch = 20;

  /// The marker's inset beside a number that outgrows the circle.
  static const double stepMarkerPaddingX = 3;

  /// The check inside a done step's marker.
  static const double stepCheckIcon = 10;
  static const double stepCheckIconTouch = 12;

  /// The hairline between two steps (with `space-3` on either side).
  static const double stepConnectorLength = 16;

  // Responsive
  static const double compactBreakpoint = 600;
  static const double mediumBreakpoint = 840;
}

/// Opacity values. Use only these with `withValues(alpha:)`.
abstract final class MeridianOpacity {
  static const double pressedOverlay = 0.04;
  static const double primaryHoverOverlay = 0.08;

  /// A tab group chip's tint of the group colour, at rest and hovered.
  static const double tabGroupFill = 0.18;
  static const double tabGroupFillHover = 0.28;
  static const double dimmedRow = 0.45;
  static const double switchThumbShadow = 0.25;
  static const double disabledContent = 0.5;
  static const double statusHalo = 0.25;

  /// Where a live halo's opacity starts each loop (MM-69).
  static const double pulseStart = 0.5;

  /// A live halo held still under reduce motion (MM-69).
  static const double staticHalo = 0.4;

  /// A breathing skeleton's lowest opacity, and its opacity held still
  /// under reduce motion (MM-64).
  static const double skeletonLow = 0.55;
  static const double skeletonStatic = 0.7;

  /// The scale a badge shrinks to as it leaves (MM-06).
  static const double badgeLeaveScale = 0.6;

  /// The share of `scrim` behind a busy overlay: the page stays readable.
  static const double busyScrim = 0.4;

  /// A pressable avatar while it is pressed.
  static const double avatarPressed = 0.85;
}
