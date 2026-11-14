import 'shortcut_field_demo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'motion_gallery.dart';
import 'screenshots.dart';
import 'tab_strip_demo.dart';
import 'workspace_gallery.dart';

void main() => runApp(const MeridianGalleryApp());

/// Every Meridian primitive for every brand, theme and density.
class MeridianGalleryApp extends StatefulWidget {
  const MeridianGalleryApp({super.key});

  @override
  State<MeridianGalleryApp> createState() => _MeridianGalleryAppState();
}

class _MeridianGalleryAppState extends State<MeridianGalleryApp> {
  MeridianBrand _brand = MeridianBrands.gitlama;
  Brightness _brightness = Brightness.light;
  MeridianDensity? _density;
  var _reduceMotion = false;
  final _page = GlobalKey(debugLabel: 'gallery-page');

  @override
  void dispose() {
    timeDilation = 1;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (screenshotMode) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => captureGallery(
          page: _page,
          apply: (shot) async => setState(() {
            _brand = shot.brand;
            _brightness = shot.brightness;
            _density = shot.density;
          }),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    MeridianTheme theme(Brightness b) =>
        MeridianTheme.resolve(brand: _brand, brightness: b, density: _density);
    return MeridianApp(
      title: 'Meridian gallery',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: _brightness == Brightness.dark
          ? MeridianThemeMode.dark
          : MeridianThemeMode.light,
      // Screenshots switch themes instantly.
      themeAnimationDuration: screenshotMode
          ? Duration.zero
          : MeridianDurations.overlay,
      // The Reduce motion switch stands in for the platform setting.
      builder: (context, app) => _reduceMotion
          ? MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: app ?? const SizedBox.shrink(),
            )
          : app ?? const SizedBox.shrink(),
      home: _Gallery(
        page: _page,
        brand: _brand,
        brightness: _brightness,
        density: _density ?? _brand.density,
        onBrand: (b) => setState(() {
          _brand = b;
          _density = null;
        }),
        onBrightness: (b) => setState(() => _brightness = b),
        onDensity: (d) => setState(() => _density = d),
        reduceMotion: _reduceMotion,
        onReduceMotion: (v) => setState(() => _reduceMotion = v),
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({
    required this.page,
    required this.brand,
    required this.brightness,
    required this.density,
    required this.onBrand,
    required this.onBrightness,
    required this.onDensity,
    required this.reduceMotion,
    required this.onReduceMotion,
  });

  final GlobalKey page;
  final MeridianBrand brand;
  final Brightness brightness;
  final MeridianDensity density;
  final ValueChanged<MeridianBrand> onBrand;
  final ValueChanged<Brightness> onBrightness;
  final ValueChanged<MeridianDensity> onDensity;
  final bool reduceMotion;
  final ValueChanged<bool> onReduceMotion;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  var _check = true;
  bool? _mixed;
  var _switch = true;
  var _radio = 'thread';
  var _segment = 'list';
  var _slider = 0.4;
  var _range = const MeridianRangeValues(0.2, 0.8);
  var _select = 'Newest first';
  var _tab = 0;
  var _docTab = 0;
  var _selectedRow = 1;
  var _stashPicks = {0, 2};
  var _chip = true;
  var _loading = false;
  var _copyConfirmed = false;
  var _projectsOpen = true;
  var _bannerVisible = true;
  var _panelVisible = true;
  var _panelMounted = true;
  var _skeletonRun = 0;
  var _sortColumn = 'cpu';
  var _sortDirection = MeridianSortDirection.descending;
  var _inspectorWidth = 260.0;
  var _swatch = 0;
  var _pickedColor = const Color(0xFF943A55);
  Color? _customColor;
  var _pageSize = 'A4';
  var _page = 3;
  var _day = DateTime(2026, 3, 18);
  var _drop = MeridianDropZoneState.idle;
  var _filter = 'all';
  var _busy = false;
  var _tool = 'pen';
  var _pageSelected = 1;

  void _toast(
    String message, {
    MeridianToastTone tone = MeridianToastTone.neutral,
  }) => showMeridianToast(context, message: message, tone: tone);

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _typography(context),
      _actions(context),
      _inputs(context),
      _navigation(context),
      _island(context),
      _checklist(context),
      _display(context),
      _feedback(context),
      _containers(context),
      _empty(context),
      _data(context),
      _collections(context),
      workspaceSection(context, _section),
      ...motionSections(context, _section),
      _documents(context),
    ];
    return MeridianScaffold(
      body: MeridianGround(
        child: SafeArea(
          child: screenshotMode
              // The whole page in one boundary, painted beyond the window.
              ? SingleChildScrollView(
                  child: RepaintBoundary(
                    key: widget.page,
                    child: MeridianGround(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _toolbar(context),
                          Padding(
                            padding: const EdgeInsets.all(MeridianSpace.space3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: sections,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _toolbar(context),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(MeridianSpace.space3),
                        children: sections,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _typography(BuildContext context) => _section('Typography', [
    for (final weight in [FontWeight.w400, FontWeight.w500, FontWeight.w700])
      Text(
        'Mono ${weight.value} · ÄÖÜ 0123456789',
        style: context.meridian.text.code.copyWith(fontWeight: weight),
      ),
  ]);

  Widget _actions(BuildContext context) => _section('Actions', [
    _CompactButtonDemo(),
    MeridianSplitButton(
      label: 'Save',
      optionsLabel: 'Save options',
      icon: MeridianIcons.save,
      onPressed: () {},
      entries: [
        MeridianMenuItem(label: 'Save as…', onSelected: () {}),
        MeridianMenuItem(label: 'Copy as file', onSelected: () {}),
      ],
    ),
    Wrap(
      spacing: MeridianSpace.space4,
      runSpacing: MeridianSpace.space4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        MeridianButton(
          label: 'Move 3 messages to archive',
          variant: MeridianButtonVariant.primary,
          shortcut: const ['⌘', '↵'],
          onPressed: () => showMeridianToast(
            context,
            message: 'Archived 3 messages',
            tone: MeridianToastTone.success,
            actionLabel: 'Undo',
            onAction: () {},
          ),
        ),
        MeridianButton(
          label: 'Export',
          icon: MeridianIcons.download,
          onPressed: () {},
        ),
        MeridianButton(
          label: 'Copy ID',
          icon: MeridianIcons.copy,
          variant: MeridianButtonVariant.quiet,
          success: _copyConfirmed,
          successReplacesLabel: true,
          onSuccessFinished: () => setState(() => _copyConfirmed = false),
          onPressed: _copyConfirmed
              ? null
              : () => setState(() => _copyConfirmed = true),
        ),
        MeridianButton(
          label: 'Delete notebook',
          variant: MeridianButtonVariant.danger,
          onPressed: () => showMeridianConfirm(
            context,
            title: 'Delete Linear algebra',
            description: '42 pages and 3 scans are removed from this device.',
            confirmLabel: 'Delete notebook',
            destructive: true,
          ),
        ),
        MeridianButton(
          label: 'Discard',
          icon: MeridianIcons.undo2,
          variant: MeridianButtonVariant.dangerQuiet,
          onPressed: () {},
        ),
        MeridianButton(
          label: _loading ? 'Syncing…' : 'Sync now',
          loading: _loading,
          onPressed: () {
            setState(() => _loading = true);
            Future<void>.delayed(const Duration(seconds: 2), () {
              if (mounted) setState(() => _loading = false);
            });
          },
        ),
        const MeridianButton(
          label: 'Send',
          onPressed: null,
          variant: MeridianButtonVariant.primary,
          disabledReason: 'Add a recipient first',
        ),
        MeridianButton(
          label: 'Filter',
          size: MeridianControlSize.small,
          icon: MeridianIcons.listFilter,
          onPressed: () {},
        ),
        MeridianIconButton(
          label: 'Search',
          icon: MeridianIcons.search,
          onPressed: () {},
        ),
        MeridianIconButton(
          label: 'Show as grid',
          icon: MeridianIcons.layoutGrid,
          active: true,
          onPressed: () {},
        ),
        MeridianIconButton(
          label: 'Pin',
          icon: MeridianIcons.pin,
          size: MeridianControlSize.small,
          onPressed: () {},
        ),
        MeridianButton(
          label: 'Preset 1 · 0.5 mm',
          leading: Container(
            width: MeridianSpace.space6,
            height: MeridianSpace.space6,
            decoration: BoxDecoration(
              color: _swatches[_swatch],
              shape: BoxShape.circle,
            ),
          ),
          onPressed: () {},
        ),
        MeridianFloatingButton(
          label: 'New notebook',
          icon: MeridianIcons.plus,
          onPressed: () {},
        ),
        MeridianFloatingButton(
          label: 'Scan pages',
          icon: MeridianIcons.scanLine,
          extended: true,
          onPressed: () {},
        ),
      ],
    ),
  ]);

  /// Content colours (a pen palette): never theme tokens.
  static const _swatches = [
    Color(0xFF18304F),
    Color(0xFF24715C),
    Color(0xFF315FA6),
    Color(0xFF943A55),
    Color(0xFFF4D864),
    Color(0xFFFFFFFF),
  ];

  int _suggestionIndex = 0;

  Widget _inputs(BuildContext context) => _section('Inputs', [
    const SizedBox(width: 260, child: ShortcutFieldDemo()),
    Wrap(
      spacing: MeridianSpace.space6,
      runSpacing: MeridianSpace.space5,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        const SizedBox(
          width: 260,
          child: MeridianTextField(
            label: 'Display name',
            placeholder: 'Michael',
            message: 'Shown to people you write to.',
          ),
        ),
        const SizedBox(
          width: 260,
          child: MeridianTextField(
            label: 'Server',
            placeholder: 'cloud.example.org',
            error: 'Enter a host name without https://',
          ),
        ),
        const SizedBox(
          width: 220,
          child: MeridianTextField(
            variant: MeridianTextFieldVariant.search,
            placeholder: 'Filter processes',
            trailingText: '12 / 480',
          ),
        ),
        MeridianSelect<String>(
          label: 'Sort by',
          value: _select,
          values: const ['Newest first', 'Oldest first', 'Sender', 'Size'],
          valueLabel: (v) => v,
          onChanged: (v) => setState(() => _select = v),
        ),
        MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: MeridianSelect<String>(
            label: 'Format at 200% text',
            showLabel: true,
            value: 'WebP (verlustbehaftet)',
            values: const ['PNG', 'JPEG', 'WebP (verlustbehaftet)'],
            valueLabel: (value) => value,
            onChanged: (_) {},
          ),
        ),
        MeridianSegmented<String>(
          label: 'Layout',
          value: _segment,
          segments: const [
            MeridianSegment(value: 'list', label: 'List', icon: 'list'),
            MeridianSegment(value: 'tree', label: 'Tree', icon: 'list-tree'),
            MeridianSegment(
              value: 'grid',
              icon: 'layout-grid',
              tooltip: 'Grid',
            ),
          ],
          onChanged: (v) => setState(() => _segment = v),
        ),
        MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: MeridianSegmented<String>(
            label: 'Layout at 200% text',
            value: _segment,
            size: MeridianControlSize.small,
            segments: const [
              MeridianSegment(value: 'list', label: 'List'),
              MeridianSegment(value: 'tree', label: 'Tree'),
            ],
            onChanged: (v) => setState(() => _segment = v),
          ),
        ),
      ],
    ),
    const SizedBox(height: MeridianSpace.space6),
    Wrap(
      spacing: MeridianSpace.space2,
      runSpacing: MeridianSpace.space2,
      children: [
        for (final (i, color) in _swatches.indexed)
          MeridianColorSwatch(
            color: color,
            label: 'Pen colour ${i + 1}',
            selected: _customColor == null && i == _swatch,
            onPressed: () => setState(() {
              _swatch = i;
              _customColor = null;
            }),
          ),
        MeridianColorWell(
          color: _customColor,
          label: 'Custom colour',
          initial: _swatches[_swatch],
          selected: _customColor != null,
          groups: const [
            MeridianColorGroup(title: 'Palette', colors: _swatches),
          ],
          onChanged: (color) => setState(() => _customColor = color),
        ),
        MeridianColorSwatch(
          color: _swatches.first,
          label: 'Unavailable colour',
          selected: false,
          onPressed: null,
        ),
      ],
    ),
    const SizedBox(height: MeridianSpace.space6),
    SizedBox(
      width: 320,
      child: MeridianSelect<String>(
        label: 'Page size',
        showLabel: true,
        expand: true,
        value: _pageSize,
        values: const ['A4', 'A5', 'Letter'],
        valueLabel: (v) => v,
        onChanged: (v) => setState(() => _pageSize = v),
      ),
    ),
    const SizedBox(height: MeridianSpace.space6),
    const SizedBox(
      width: 420,
      child: MeridianTextField(
        label: 'Notes',
        placeholder: 'Grows as you type',
        minLines: 3,
      ),
    ),
    const SizedBox(height: MeridianSpace.space6),
    Wrap(
      spacing: MeridianSpace.space7,
      runSpacing: MeridianSpace.space4,
      children: [
        MeridianCheckbox(
          label: 'Include attachments',
          value: _check,
          onChanged: (v) => setState(() => _check = v),
        ),
        MeridianCheckbox(
          label: 'Some pages selected',
          tristate: true,
          value: _mixed,
          onChanged: (v) => setState(() => _mixed = v ? true : null),
        ),
        MeridianSwitch(
          label: 'Check mail automatically',
          value: _switch,
          onChanged: (v) => setState(() => _switch = v),
        ),
        SizedBox(
          width: 320,
          child: MeridianSwitch(
            label: 'Finger drawing',
            description: 'One finger writes; two fingers scroll and zoom.',
            labelFirst: true,
            value: _switch,
            onChanged: (v) => setState(() => _switch = v),
          ),
        ),
        MeridianRadio<String>(
          label: 'Group by conversation',
          value: 'thread',
          groupValue: _radio,
          onChanged: (v) => setState(() => _radio = v),
        ),
        MeridianRadio<String>(
          label: 'Show every message',
          value: 'flat',
          groupValue: _radio,
          onChanged: (v) => setState(() => _radio = v),
        ),
      ],
    ),
    const SizedBox(height: MeridianSpace.space6),
    SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MeridianResultNavigation(
            itemCount: 3,
            selectedIndex: _suggestionIndex,
            onSelected: (index) => setState(() => _suggestionIndex = index),
            onActivate: (index) => setState(() => _suggestionIndex = index),
            child: const MeridianTextField(
              label: 'Base branch',
              icon: MeridianIcons.gitBranch,
              placeholder: 'fea',
            ),
          ),
          const SizedBox(height: MeridianSpace.space2),
          MeridianSuggestionSurface(
            maxHeight: 180,
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                const MeridianSuggestionHeader('Local branches'),
                MeridianSuggestionRow(
                  label: 'feature/search',
                  hint: 'ahead 3',
                  icon: MeridianIcons.gitBranch,
                  highlighted: _suggestionIndex == 0,
                  onTap: () => setState(() => _suggestionIndex = 0),
                ),
                MeridianSuggestionRow(
                  label: 'feature/offline-sync',
                  icon: MeridianIcons.gitBranch,
                  highlighted: _suggestionIndex == 1,
                  onTap: () => setState(() => _suggestionIndex = 1),
                ),
                const MeridianSuggestionHeader('Remote branches'),
                MeridianSuggestionRow(
                  label: 'origin/feature/search',
                  hint: 'origin',
                  icon: MeridianIcons.cloud,
                  highlighted: _suggestionIndex == 2,
                  onTap: () => setState(() => _suggestionIndex = 2),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: MeridianSpace.space5),
    SizedBox(
      width: 280,
      child: MeridianSlider(
        label: 'Stroke width',
        value: _slider,
        onChanged: (v) => setState(() => _slider = v),
      ),
    ),
    const SizedBox(height: MeridianSpace.space6),
    SizedBox(
      width: 280,
      child: MeridianRangeSlider(
        startLabel: 'Range start',
        endLabel: 'Range end',
        values: _range,
        onChanged: (values) => setState(() => _range = values),
      ),
    ),
    const SizedBox(height: MeridianSpace.space6),
    // Wide beside the wheel on a desktop page, stacked on a phone.
    ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: MeridianColorPicker(
        color: _pickedColor,
        original: _swatches[_swatch],
        groups: const [MeridianColorGroup(title: 'Palette', colors: _swatches)],
        onChanged: (color) => setState(() => _pickedColor = color),
      ),
    ),
  ]);

  Widget _navigation(BuildContext context) {
    final colors = context.meridian.colors;
    return _section('Navigation', [
      MeridianTabs(
        tabs: const [
          MeridianTab(label: 'Overview'),
          MeridianTab(label: 'Threads', count: 12),
          MeridianTab(label: 'Environment'),
          MeridianTab(label: 'Billing', enabled: false),
        ],
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
      const SizedBox(height: MeridianSpace.space4),
      MeridianGround(
        child: MeridianTabs(
          style: MeridianTabsStyle.pill,
          tabs: const [
            MeridianTab(label: 'GitLama', dirty: true),
            MeridianTab(label: 'CrossProton'),
            MeridianTab(label: 'Mimameidr'),
          ],
          index: _docTab,
          onChanged: (i) => setState(() => _docTab = i),
          onClose: (i) => _toast('Closed tab ${i + 1}'),
        ),
      ),
      const SizedBox(height: MeridianSpace.space4),
      // Drag tabs and the group's chip; a tab joins the group past its chip.
      const MeridianGround(child: TabStripDemo()),
      const SizedBox(height: MeridianSpace.space4),
      const MeridianSteps(
        semanticLabel: 'Resolve conflicts',
        current: 2,
        steps: [
          MeridianStep(label: 'Pick'),
          MeridianStep(label: 'Review'),
          MeridianStep(label: 'Resolve'),
          MeridianStep(label: 'Continue'),
        ],
      ),
      const SizedBox(height: MeridianSpace.space4),
      SizedBox(
        width: 280,
        child: MeridianGround(
          child: Padding(
            padding: const EdgeInsets.all(MeridianSpace.space3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MeridianNavSection(
                  title: 'Folders',
                  action: MeridianIconButton(
                    label: 'New folder',
                    icon: MeridianIcons.plus,
                    size: MeridianControlSize.small,
                    onPressed: () {},
                  ),
                  children: [
                    MeridianNavRow(
                      label: 'Inbox',
                      icon: MeridianIcons.inbox,
                      count: 12,
                      countTone: MeridianCountTone.accent,
                      selected: true,
                      onTap: () {},
                    ),
                    MeridianNavRow(
                      label: 'Projects',
                      icon: MeridianIcons.folder,
                      expandable: true,
                      expanded: _projectsOpen,
                      onToggleExpanded: () =>
                          setState(() => _projectsOpen = !_projectsOpen),
                      onTap: () {},
                    ),
                    if (_projectsOpen)
                      MeridianNavRow(
                        label: 'Meridian',
                        icon: MeridianIcons.tag,
                        iconColor: colors.series[5],
                        depth: 1,
                        onTap: () {},
                      ),
                    MeridianNavRow(
                      label: 'main',
                      icon: MeridianIcons.gitBranch,
                      current: true,
                      onTap: () {},
                    ),
                    MeridianNavRow(
                      label: 'Shared (offline)',
                      icon: MeridianIcons.users,
                      enabled: false,
                      onTap: () {},
                    ),
                  ],
                ),
                MeridianNavSection(
                  title: 'Labels',
                  count: 2,
                  collapsible: true,
                  children: [
                    MeridianNavRow(
                      label: 'Work',
                      icon: MeridianIcons.tag,
                      iconColor: colors.series[1],
                      drop: MeridianDropFeedback.accept,
                      onTap: () {},
                    ),
                    MeridianNavRow(
                      label: 'Family',
                      icon: MeridianIcons.tag,
                      iconColor: colors.series[3],
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _island(BuildContext context) {
    const rows = [
      ('Anna Berg', 'Quarterly report draft', '09:41'),
      ('Proton', 'Your security key was added', '08:12'),
      ('Jonas Weber', 'Re: Mimameidr beta 14', 'Yesterday'),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: MeridianSpace.space3),
      child: MeridianIsland(
        title: 'Inbox',
        subtitle: const Text('3 of 1,204'),
        actions: [
          MeridianIconButton(
            label: 'Filter',
            icon: MeridianIcons.listFilter,
            size: MeridianControlSize.small,
            onPressed: () {},
          ),
          MeridianIconButton(
            label: 'More',
            icon: MeridianIcons.ellipsis,
            size: MeridianControlSize.small,
            onPressed: () {},
          ),
        ],
        child: MeridianList(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < rows.length; i++)
              MeridianListRow(
                leading: MeridianAvatar(
                  name: rows[i].$1,
                  size: context.meridian.density.isTouch
                      ? MeridianAvatarSize.medium
                      : MeridianAvatarSize.small,
                ),
                title: rows[i].$1,
                subtitle: rows[i].$2,
                meta: rows[i].$3,
                emphasized: i == 0,
                selected: i == _selectedRow,
                twoLine: context.meridian.density.isTouch,
                hoverActions: [
                  MeridianIconButton(
                    label: 'Archive',
                    icon: MeridianIcons.archive,
                    size: MeridianControlSize.small,
                    onPressed: () {},
                  ),
                  MeridianIconButton(
                    label: 'Delete',
                    icon: MeridianIcons.trash2,
                    size: MeridianControlSize.small,
                    onPressed: () {},
                  ),
                ],
                onTap: () => setState(() => _selectedRow = i),
                onDoubleTap: () => _toast('Opened “${rows[i].$2}”'),
                onContextMenu: (position) => showMeridianContextMenu(
                  context,
                  globalPosition: position,
                  entries: [
                    MeridianMenuItem(
                      label: 'Reply',
                      icon: 'reply',
                      onSelected: () {},
                    ),
                    MeridianMenuItem(
                      label: 'Move to archive',
                      icon: 'archive',
                      onSelected: () {},
                    ),
                  ],
                ),
              ),
            const MeridianListRow(
              title: 'Mailer daemon',
              subtitle: 'Account removed',
              meta: 'Mon',
              enabled: false,
            ),
            MeridianListRow(
              title: 'Quarterly report draft',
              match: 'report',
              titleTrailing: const MeridianCount(label: '2'),
              meta: 'Tue',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  /// A multi-select checklist built from list rows (`checked`).
  Widget _checklist(BuildContext context) {
    const files = [
      ('lib/app/workspace.dart', 'Modified', '+12 -3', MeridianIcons.fileDiff),
      ('lib/app/stash_dialog.dart', 'Added', '+48', MeridianIcons.filePlus),
      ('test/stash_test.dart', 'Modified', '+6 -1', MeridianIcons.fileDiff),
      ('README.md', 'Deleted', '-20', MeridianIcons.fileText),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: MeridianSpace.space3),
      child: MeridianIsland(
        title: 'Stash files',
        subtitle: Text('${_stashPicks.length} of ${files.length}'),
        child: MeridianList(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final (i, file) in files.indexed)
              MeridianListRow(
                checked: _stashPicks.contains(i),
                leading: MeridianIcon(file.$4),
                title: file.$1,
                subtitle: file.$2,
                meta: file.$3,
                onTap: () => setState(
                  () => _stashPicks = _stashPicks.contains(i)
                      ? ({..._stashPicks}..remove(i))
                      : {..._stashPicks, i},
                ),
              ),
            const MeridianListRow(
              checked: false,
              leading: MeridianIcon(MeridianIcons.lock),
              title: 'pubspec.lock',
              subtitle: 'Locked',
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _display(BuildContext context) {
    final colors = context.meridian.colors;
    return _section('Display', [
      Wrap(
        spacing: MeridianSpace.space4,
        runSpacing: MeridianSpace.space4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const MeridianTooltip(
            message: 'A Meridian tooltip',
            child: MeridianChip(label: 'Hover me'),
          ),
          MeridianSelectableText(
            '3f2a9c1e7b4d',
            style: context.meridian.text.code,
          ),
          const MeridianKbd(keys: ['⌘', 'K']),
          // Appears while ⌘ is held, as on buttons and title-bar hints.
          const MeridianKbd(
            keys: ['⌘', 'P'],
            reveal: MeridianKbdReveal.whileModifierHeld,
          ),
          // Hugs a short name; keeps both ends of a long one.
          for (final name in const [
            'main',
            'origin/feature/update-route-dialog-when-offline',
          ])
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: MeridianLayout.chipMaxWidth,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: colors.lineStrong),
                  borderRadius: BorderRadius.circular(
                    context.meridian.radius.sm,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MeridianSpace.space3,
                    vertical: MeridianSpace.space1,
                  ),
                  child: MeridianMiddleEllipsis(
                    name,
                    style: context.meridian.text.caption,
                  ),
                ),
              ),
            ),
          const MeridianCount(label: '3'),
          const MeridianCount(label: '12', tone: MeridianCountTone.accent),
          const MeridianCount(label: '2', tone: MeridianCountTone.attention),
          const MeridianCount(label: '1', tone: MeridianCountTone.danger),
          const MeridianAvatar(name: 'Michael Lamers'),
          const MeridianAvatar(
            name: 'Anna Berg',
            size: MeridianAvatarSize.large,
          ),
          MeridianChip(
            label: 'Unread',
            selected: _chip,
            onPressed: () => setState(() => _chip = !_chip),
          ),
          MeridianChip(
            label: 'anna@example.org',
            removeLabel: 'Remove anna@example.org',
            onRemove: () => _toast('Removed anna@example.org'),
          ),
          MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: MeridianChip(
              label: 'Enlarged label',
              selected: true,
              onPressed: () {},
            ),
          ),
          MeridianChip(label: 'Work', dotColor: colors.series[1]),
          const MeridianChip(
            label: 'Encrypted',
            tone: MeridianChipTone.success,
            icon: 'lock',
          ),
          MeridianChip(
            label: 'Over quota',
            tone: MeridianChipTone.warning,
            onPressed: () {},
          ),
          MeridianChip(
            label: 'Read-only',
            enabled: false,
            onPressed: () {},
            onRemove: () {},
          ),
          const MeridianStatusDot(
            label: 'Running',
            tone: MeridianStatusTone.success,
            halo: true,
          ),
          const MeridianStatusDot(
            label: 'Stopped',
            tone: MeridianStatusTone.warning,
          ),
          const MeridianSpinner(),
        ],
      ),
    ]);
  }

  Widget _feedback(BuildContext context) => _section('Feedback', [
    Wrap(
      spacing: MeridianSpace.space4,
      runSpacing: MeridianSpace.space4,
      children: [
        MeridianButton(
          label: 'Neutral toast',
          onPressed: () => _toast('Draft saved'),
        ),
        MeridianButton(
          label: 'Success toast',
          onPressed: () =>
              _toast('Synced 12 notebooks', tone: MeridianToastTone.success),
        ),
        MeridianButton(
          label: 'Warning toast',
          onPressed: () =>
              _toast('Storage is 90% full', tone: MeridianToastTone.warning),
        ),
        MeridianButton(
          label: 'Error toast',
          onPressed: () => _toast(
            'Could not reach the server',
            tone: MeridianToastTone.error,
          ),
        ),
      ],
    ),
    const SizedBox(height: MeridianSpace.space5),
    MeridianToast(
      message: 'Saved to /exports/Project review.png',
      tone: MeridianToastTone.success,
      actionLabel: 'Show in Folder',
      onAction: () => _toast('Folder requested'),
      liveRegion: false,
    ),
    const SizedBox(height: MeridianSpace.space5),
    SizedBox(
      width: 320,
      child: MeridianWaveform(
        peaks: List.generate(64, (i) => (i * 17 % 31) / 30),
        progress: 0.37,
      ),
    ),
    const SizedBox(height: MeridianSpace.space4),
    const SizedBox(width: 320, child: MeridianProgressBar(track: true)),
    const SizedBox(height: MeridianSpace.space4),
    const SizedBox(
      width: 320,
      child: MeridianProgressBar(value: 0.62, track: true),
    ),
    const SizedBox(height: MeridianSpace.space4),
    const SizedBox(
      width: 160,
      child: MeridianMeter(value: 0.78, warningAt: 0.5, dangerAt: 0.9),
    ),
    const SizedBox(height: MeridianSpace.space5),
    if (_bannerVisible)
      MeridianBanner(
        title: 'Sync paused.',
        message:
            'The server asked for a new password. Sign in again to continue.',
        tone: MeridianBannerTone.attention,
        actions: [
          MeridianButton(
            label: 'Sign in',
            size: MeridianControlSize.small,
            onPressed: () {},
          ),
        ],
        onDismiss: () => setState(() => _bannerVisible = false),
      )
    else
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: MeridianButton(
          label: 'Show the dismissed banner',
          variant: MeridianButtonVariant.quiet,
          onPressed: () => setState(() => _bannerVisible = true),
        ),
      ),
    const SizedBox(height: MeridianSpace.space3),
    MeridianBanner(
      title: 'Could not send “Quarterly report”.',
      message:
          'The attachment is larger than 25 MB. Remove it or share a link '
          'instead.',
      tone: MeridianBannerTone.error,
      actions: [
        MeridianButton(
          label: 'Open draft',
          size: MeridianControlSize.small,
          onPressed: () {},
        ),
        MeridianButton(
          label: 'Share a link',
          size: MeridianControlSize.small,
          variant: MeridianButtonVariant.quiet,
          onPressed: () {},
        ),
      ],
    ),
    const SizedBox(height: MeridianSpace.space3),
    SizedBox(
      height: 160,
      child: SingleChildScrollView(
        child: MeridianBanner(
          message:
              'The background could not be prepared. The accepted document remains available while you retry.',
          tone: MeridianBannerTone.error,
          actions: [
            MeridianButton(
              label: 'Prepare the background again',
              size: MeridianControlSize.small,
              onPressed: () {},
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: MeridianSpace.space3),
    const MeridianBanner(
      message: 'Messages older than 30 days are kept on the server only.',
    ),
    const SizedBox(height: MeridianSpace.space5),
    Row(
      children: [
        Text('Skeleton', style: context.meridian.text.label),
        const SizedBox(width: MeridianSpace.space4),
        MeridianButton(
          label: 'Load again',
          size: MeridianControlSize.small,
          onPressed: () => setState(() => _skeletonRun++),
        ),
      ],
    ),
    const SizedBox(height: MeridianSpace.space4),
    Column(
      key: ValueKey(_skeletonRun),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final width in [220.0, 300.0, 180.0]) ...[
          MeridianSkeleton(
            width: width,
            delay: screenshotMode
                ? Duration.zero
                : MeridianDurations.skeletonDelay,
          ),
          const SizedBox(height: MeridianSpace.space4),
        ],
      ],
    ),
  ]);

  Widget _containers(BuildContext context) {
    final meridian = context.meridian;
    return _section('Containers', [
      Wrap(
        spacing: MeridianSpace.space4,
        runSpacing: MeridianSpace.space4,
        children: [
          MeridianButton(
            label: 'Open dialog',
            onPressed: () => showMeridianDialog<void>(
              context: context,
              builder: (context) => MeridianDialog(
                title: 'Export 3 notebooks',
                description:
                    'A PDF per notebook, with scans at full resolution.',
                content: MeridianCheckbox(
                  label: 'Include page backgrounds',
                  value: true,
                  onChanged: (_) {},
                ),
                onSubmit: () => Navigator.pop(context),
                actions: [
                  MeridianButton(
                    label: 'Cancel',
                    variant: MeridianButtonVariant.quiet,
                    onPressed: () => Navigator.pop(context),
                  ),
                  MeridianButton(
                    label: 'Export 3 notebooks',
                    variant: MeridianButtonVariant.primary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
          MeridianButton(
            label: 'Open shaped palette surface',
            variant: MeridianButtonVariant.secondary,
            onPressed: () => showMeridianDialog<void>(
              context: context,
              builder: (dialogContext) => MeridianDialogSurface(
                maxWidth: 360,
                borderRadius: BorderRadius.circular(
                  dialogContext.meridian.radius.lg,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(MeridianSpace.space6),
                  child: Text('Palette route controls this corner radius.'),
                ),
              ),
            ),
          ),
          MeridianButton(
            label: 'Open scaffold',
            variant: MeridianButtonVariant.secondary,
            onPressed: () => Navigator.of(context).push(
              MeridianPageRoute<void>(
                builder: (context) => MeridianScaffold(
                  appBar: const MeridianAppBar(title: 'Scaffold'),
                  drawer: MeridianDrawer(
                    child: Builder(
                      builder: (context) => ListView(
                        padding: const EdgeInsets.all(MeridianSpace.space3),
                        children: [
                          MeridianNavRow(
                            label: 'Back to the gallery',
                            icon: MeridianIcons.arrowLeft,
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  body: const Center(
                    child: MeridianSelectableText('Select and copy me'),
                  ),
                ),
              ),
            ),
          ),
          MeridianButton(
            label: 'Open settings dialog',
            variant: MeridianButtonVariant.secondary,
            onPressed: () => showMeridianDialog<void>(
              context: context,
              builder: (_) => MeridianSettingsDialog(
                title: 'Settings',
                pages: [
                  for (final (label, icon) in const [
                    ('Appearance', MeridianIcons.palette),
                    ('Notifications', MeridianIcons.bell),
                    ('Remote hosts', MeridianIcons.server),
                  ])
                    MeridianSettingsPage(
                      label: label,
                      icon: icon,
                      description: 'Settings for ${label.toLowerCase()}.',
                      builder: (_) => Text('$label settings go here.'),
                    ),
                ],
              ),
            ),
          ),
          MeridianButton(
            label: 'Open license dialog',
            variant: MeridianButtonVariant.secondary,
            onPressed: () => showMeridianLicenses(
              context: context,
              applicationName: 'Meridian',
              applicationVersion: '1.18.0',
              licenses: _demoLicenses,
            ),
          ),
          MeridianButton(
            label: 'Open sheet',
            onPressed: () => showMeridianSheet<void>(
              context: context,
              builder: (context) => MeridianSheet(
                title: 'Pen',
                child: Padding(
                  padding: const EdgeInsets.all(MeridianSpace.space8),
                  child: MeridianSlider(
                    label: 'Stroke width',
                    value: 0.3,
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
          MeridianMenuAnchor(
            entries: [
              const MeridianMenuHeader('Message'),
              MeridianMenuItem(
                label: 'Reply',
                icon: 'reply',
                shortcut: const ['⌘', 'R'],
                onSelected: () {},
              ),
              MeridianMenuItem(
                label: 'Forward',
                icon: 'forward',
                onSelected: () {},
              ),
              MeridianMenuItem(
                label: 'Move to archive',
                icon: 'archive',
                hint: 'A',
                onSelected: () {},
              ),
              MeridianMenuItem(
                label: 'Export…',
                icon: 'save',
                onSelected: () => showMeridianDialog<void>(
                  context: context,
                  builder: (context) => MeridianDialog(
                    title: 'Export message',
                    content: const Text(
                      'The menu has closed before this dialog opens.',
                    ),
                    actions: [
                      MeridianButton(
                        label: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
              const MeridianMenuItem(
                label: 'Mark as spam',
                icon: 'shield-alert',
              ),
              const MeridianMenuDivider(),
              MeridianMenuItem(
                label: 'Delete message',
                icon: 'trash-2',
                danger: true,
                onSelected: () {},
              ),
            ],
            builder: (context, open) => MeridianButton(
              label: 'Open menu',
              trailingIcon: MeridianIcons.chevronDown,
              onPressed: open,
            ),
          ),
          if (!_panelVisible)
            MeridianButton(
              label: 'Show panel',
              onPressed: () => setState(() {
                _panelVisible = true;
                _panelMounted = true;
              }),
            ),
        ],
      ),
      const SizedBox(height: MeridianSpace.space6),
      Wrap(
        spacing: MeridianSpace.space6,
        runSpacing: MeridianSpace.space6,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: [
          SizedBox(
            height: 220,
            child: MeridianDrawer(
              width: 260,
              child: ListView(
                padding: const EdgeInsets.all(MeridianSpace.space3),
                children: [
                  MeridianNavRow(
                    label: 'Library',
                    icon: MeridianIcons.bookOpen,
                    selected: true,
                    onTap: () {},
                  ),
                  MeridianNavRow(
                    label: 'Archive',
                    icon: MeridianIcons.archive,
                    onTap: () {},
                  ),
                  MeridianNavRow(
                    label: 'Trash',
                    icon: MeridianIcons.trash2,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 220, height: 220, child: _ScrollbarDemo()),
          if (_panelMounted)
            MeridianPanel(
              title: 'Inspector',
              visible: _panelVisible,
              onHidden: () => setState(() => _panelMounted = false),
              onClose: () => setState(() => _panelVisible = false),
              actions: [
                MeridianIconButton(
                  label: 'Pin panel',
                  icon: MeridianIcons.pin,
                  size: MeridianControlSize.small,
                  onPressed: () {},
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Linear algebra', style: meridian.text.bodyStrong),
                  const SizedBox(height: MeridianSpace.space2),
                  Text(
                    '42 pages · edited 2 hours ago',
                    style: meridian.text.caption.copyWith(
                      color: meridian.colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MeridianDisclosure(
                  title: 'Advanced options',
                  trailing: const MeridianCount(
                    label: '2',
                    semanticLabel: '2 changed',
                  ),
                  initiallyExpanded: true,
                  child: MeridianCheckbox(
                    label: 'Keep a local copy',
                    value: _check,
                    onChanged: (v) => setState(() => _check = v),
                  ),
                ),
                const MeridianDisclosure(
                  title: 'Developer settings',
                  child: Text('Nothing here yet.'),
                ),
                const MeridianDisclosure(
                  title: 'Managed by your organisation',
                  enabled: false,
                  child: SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: MeridianSpace.space6),
      Text('App bar (touch screens)', style: meridian.text.label),
      const SizedBox(height: MeridianSpace.space3),
      ClipRRect(
        borderRadius: BorderRadius.circular(meridian.radius.lg),
        child: MeridianAppBar(
          title: 'Notebooks',
          subtitle: 'Saved on this device',
          elevated: true,
          leading: MeridianIconButton(
            label: 'Back',
            icon: MeridianIcons.arrowLeft,
            onPressed: () {},
          ),
          actions: [
            MeridianIconButton(
              label: 'Search',
              icon: MeridianIcons.search,
              onPressed: () {},
            ),
            MeridianIconButton(
              label: 'More',
              icon: MeridianIcons.ellipsis,
              onPressed: () {},
            ),
          ],
        ),
      ),
      const SizedBox(height: MeridianSpace.space6),
      MeridianSettingsGroup(
        title: 'Appearance',
        children: [
          MeridianSettingsRow(
            label: 'Theme',
            help: 'Follows the system unless you pick one.',
            children: [
              MeridianSegmented<Brightness>(
                label: 'Theme',
                value: widget.brightness,
                segments: const [
                  MeridianSegment(
                    value: Brightness.light,
                    label: 'Light',
                    icon: 'sun',
                  ),
                  MeridianSegment(
                    value: Brightness.dark,
                    label: 'Dark',
                    icon: 'moon',
                  ),
                ],
                onChanged: widget.onBrightness,
              ),
            ],
          ),
          MeridianSettingsRow(
            label: 'Notifications',
            children: [
              MeridianSwitch(
                label: 'Show new mail on the lock screen',
                value: _switch,
                onChanged: (v) => setState(() => _switch = v),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: MeridianSpace.space6),
      // A dialog form: the label column hugs "Remote".
      MeridianSettingsGroup(
        title: 'Dialog form',
        fitLabels: true,
        children: [
          MeridianSettingsRow(
            label: 'Remote',
            children: [
              MeridianSelect<String>(
                label: 'Remote',
                value: 'origin',
                values: const ['origin', 'upstream'],
                valueLabel: (value) => value,
                expand: true,
                onChanged: (_) {},
              ),
            ],
          ),
          MeridianSettingsRow(
            label: '',
            children: [
              MeridianCheckbox(
                label: 'Fetch all remotes',
                value: _switch,
                onChanged: (v) => setState(() => _switch = v),
              ),
            ],
          ),
        ],
      ),
    ]);
  }

  Widget _empty(BuildContext context) {
    const search = MeridianIsland(
      title: 'Search results',
      expandChild: true,
      child: MeridianEmptyState(
        icon: 'text-search',
        title: 'No messages match “invoice 2025”',
        message: 'Try fewer words or search all folders.',
      ),
    );
    final welcome = MeridianIsland(
      expandChild: true,
      child: MeridianEmptyState(
        headline: true,
        title: 'Welcome to Meridian',
        message: 'Open a folder to start, or create your first notebook.',
        action: MeridianButton(
          label: 'Create a notebook',
          variant: MeridianButtonVariant.primary,
          onPressed: () {},
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < MeridianLayout.compactBreakpoint) {
          return Column(
            children: [
              const SizedBox(height: 240, child: search),
              const SizedBox(height: MeridianSpace.space3),
              SizedBox(height: 320, child: welcome),
            ],
          );
        }
        return SizedBox(
          height: 280,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(child: search),
              const SizedBox(width: MeridianSpace.space3),
              Expanded(child: welcome),
            ],
          ),
        );
      },
    );
  }

  /// Column headers, a property list, a resize handle and a status bar:
  /// the pieces of a desktop data window.
  Widget _data(BuildContext context) {
    final meridian = context.meridian;
    Widget header(String id, String label, {bool alignEnd = false}) =>
        MeridianColumnHeader(
          label: label,
          alignEnd: alignEnd,
          sortDirection: _sortColumn == id ? _sortDirection : null,
          sortedAscendingLabel: 'sorted ascending',
          sortedDescendingLabel: 'sorted descending',
          onPressed: () => setState(() {
            if (_sortColumn == id) {
              _sortDirection = _sortDirection == MeridianSortDirection.ascending
                  ? MeridianSortDirection.descending
                  : MeridianSortDirection.ascending;
            } else {
              _sortColumn = id;
              _sortDirection = MeridianSortDirection.descending;
            }
          }),
          onContextMenu: (position) => showMeridianContextMenu(
            context,
            globalPosition: position,
            entries: [
              MeridianMenuItem(label: 'PID', checked: true, onSelected: () {}),
              MeridianMenuItem(label: 'GPU', checked: false, onSelected: () {}),
              const MeridianMenuDivider(),
              MeridianMenuItem(label: 'Reset columns', onSelected: () {}),
            ],
          ),
        );
    final table = MeridianIsland(
      expandChild: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: meridian.colors.paneAlt,
            child: SizedBox(
              height: MeridianSize.islandHeader,
              child: Row(
                children: [
                  Expanded(child: header('name', 'Name')),
                  SizedBox(
                    width: 80,
                    child: header('pid', 'PID', alignEnd: true),
                  ),
                  SizedBox(
                    width: 80,
                    child: header('cpu', 'CPU', alignEnd: true),
                  ),
                ],
              ),
            ),
          ),
          const Expanded(
            child: MeridianEmptyState(
              icon: 'list-tree',
              title: 'Click a heading to sort',
              message: 'Right-click it for the column menu.',
            ),
          ),
        ],
      ),
    );
    const inspector = MeridianIsland(
      title: 'Dock',
      expandChild: true,
      padding: EdgeInsets.all(MeridianSpace.space6),
      child: SingleChildScrollView(
        child: MeridianPropertyList(
          properties: [
            MeridianProperty(label: 'Parent PID', value: '1', monospace: true),
            MeridianProperty(label: 'User', value: 'michael (501)'),
            MeridianProperty(label: 'Status', value: 'Running'),
            MeridianProperty(
              label: 'Executable',
              value:
                  '/System/Library/CoreServices/Dock.app/Contents/MacOS/Dock',
              monospace: true,
            ),
          ],
        ),
      ),
    );
    return _section('Data and window', [
      LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: 260,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: table),
              MeridianResizeHandle(
                semanticLabel: 'Resize inspector',
                onDrag: (delta) => setState(
                  () => _inspectorWidth = (_inspectorWidth - delta).clamp(
                    160.0,
                    constraints.maxWidth / 2,
                  ),
                ),
                onReset: () => setState(() => _inspectorWidth = 260),
              ),
              SizedBox(
                width: _inspectorWidth.clamp(0, constraints.maxWidth / 2),
                child: inspector,
              ),
            ],
          ),
        ),
      ),
      const MeridianStatusBar(
        leading: [
          MeridianStatusDot(
            tone: MeridianStatusTone.success,
            halo: true,
            label: 'Live, polling every second',
          ),
        ],
        trailing: [Text('412 processes')],
      ),
      Text(
        'Buttons and the status bar grow with enlarged text. '
        'Their token heights are minimums.',
        style: context.meridian.text.caption,
      ),
    ]);
  }

  Widget _collections(BuildContext context) {
    final meridian = context.meridian;
    return _section('Collections and transfer', [
      MeridianSegmented<String>(
        label: 'Show',
        value: _filter,
        manualActivation: true,
        size: MeridianControlSize.small,
        segments: const [
          MeridianSegment(value: 'all', label: 'All'),
          MeridianSegment(value: 'unread', label: 'Unread'),
        ],
        onChanged: (v) => setState(() => _filter = v),
      ),
      const SizedBox(height: MeridianSpace.space5),
      Wrap(
        spacing: MeridianSpace.space5,
        runSpacing: MeridianSpace.space5,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          MeridianPopoverAnchor(
            width: 260,
            builder: (context, open) => MeridianButton(
              label: 'Move to…',
              icon: MeridianIcons.folderInput,
              trailingIcon: MeridianIcons.chevronDown,
              onPressed: open,
            ),
            popoverBuilder: (context) => Padding(
              padding: const EdgeInsets.all(MeridianSpace.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MeridianTextField(
                    label: 'Filter folders',
                    showLabel: false,
                    placeholder: 'Filter folders',
                    variant: MeridianTextFieldVariant.search,
                    clearLabel: 'Clear filter',
                    autofocus: true,
                  ),
                  const SizedBox(height: MeridianSpace.space3),
                  for (final folder in ['Work', 'Travel', 'Receipts'])
                    MeridianListRow(
                      title: folder,
                      leading: const MeridianIcon(
                        MeridianIcons.folder,
                        size: MeridianIconSize.small,
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _toast('Moved to $folder');
                      },
                    ),
                ],
              ),
            ),
          ),
          const MeridianAvatar(
            name: 'Ada Lovelace',
            monogram: 'AL',
            size: MeridianAvatarSize.xLarge,
          ),
          const SizedBox(
            width: 220,
            child: MeridianTextField(
              label: 'Recipients',
              showLabel: false,
              placeholder: 'Plain field inside a chip row',
              variant: MeridianTextFieldVariant.plain,
            ),
          ),
        ],
      ),
      const SizedBox(height: MeridianSpace.space5),
      MeridianIsland(
        child: MeridianSelectionBar(
          label: '3 selected',
          clearLabel: 'Clear',
          overflowLabel: 'More actions',
          onClear: () => _toast('Selection cleared'),
          actions: [
            MeridianSelectionAction(
              child: MeridianIconButton(
                label: 'Archive',
                icon: MeridianIcons.archive,
                size: MeridianControlSize.small,
                onPressed: () => _toast('Archived 3 messages'),
              ),
              overflow: MeridianMenuItem(
                label: 'Archive',
                icon: MeridianIcons.archive,
                onSelected: () => _toast('Archived 3 messages'),
              ),
            ),
            MeridianSelectionAction(
              child: MeridianMenuAnchor(
                entries: [
                  MeridianMenuItem(
                    label: 'Move to',
                    icon: MeridianIcons.folderInput,
                    children: [
                      for (final folder in ['Work', 'Travel', 'Receipts'])
                        MeridianMenuItem(
                          label: folder,
                          onSelected: () => _toast('Moved to $folder'),
                        ),
                    ],
                  ),
                  MeridianMenuItem(
                    label: 'Label as',
                    icon: MeridianIcons.tag,
                    children: [
                      for (final (i, label) in ['Meridian', 'Family'].indexed)
                        MeridianMenuItem(
                          label: label,
                          leading: Container(
                            width: MeridianLayout.statusDot,
                            height: MeridianLayout.statusDot,
                            decoration: BoxDecoration(
                              color: meridian.colors.series[i * 3],
                              shape: BoxShape.circle,
                            ),
                          ),
                          onSelected: () => _toast('Labelled $label'),
                        ),
                    ],
                  ),
                ],
                builder: (context, open) => MeridianIconButton(
                  label: 'Organize',
                  icon: MeridianIcons.folder,
                  size: MeridianControlSize.small,
                  onPressed: open,
                ),
              ),
            ),
            MeridianSelectionAction(
              child: MeridianIconButton(
                label: 'Delete',
                icon: MeridianIcons.trash2,
                size: MeridianControlSize.small,
                onPressed: () => _toast('Deleted 3 messages'),
              ),
              overflow: MeridianMenuItem(
                label: 'Delete',
                icon: MeridianIcons.trash2,
                danger: true,
                onSelected: () => _toast('Deleted 3 messages'),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: MeridianSpace.space5),
      MeridianPagination(
        page: _page,
        pageCount: 12,
        previousLabel: 'Previous page',
        nextLabel: 'Next page',
        pageLabel: (p) => 'Page $p',
        jumpLabel: 'Page',
        pageCountLabel: (n) => 'of $n',
        onPageSelected: (p) => setState(() => _page = p),
      ),
      const SizedBox(height: MeridianSpace.space5),
      Wrap(
        spacing: MeridianSpace.space5,
        runSpacing: MeridianSpace.space5,
        children: [
          SizedBox(
            width: 260,
            child: MeridianDropZone(
              label: 'Drop files to attach',
              message: 'Click to browse',
              state: _drop,
              onBrowse: () => setState(
                () => _drop =
                    MeridianDropZoneState.values[(_drop.index + 1) %
                        MeridianDropZoneState.values.length],
              ),
            ),
          ),
          MeridianCalendar(
            value: _day,
            firstDate: DateTime(2026),
            lastDate: DateTime(2026, 12, 31),
            onChanged: (day) => setState(() => _day = day),
          ),
          SizedBox(
            width: 260,
            height: 140,
            child: Stack(
              children: [
                Positioned.fill(
                  child: MeridianIsland(
                    padding: const EdgeInsets.all(MeridianSpace.space5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MeridianButton(
                          label: 'Verify for 2 seconds',
                          onPressed: () async {
                            setState(() => _busy = true);
                            await Future<void>.delayed(
                              const Duration(seconds: 2),
                            );
                            if (mounted) setState(() => _busy = false);
                          },
                        ),
                        const SizedBox(height: MeridianSpace.space4),
                        MeridianButton(
                          label: 'Pick a date',
                          icon: MeridianIcons.calendar,
                          onPressed: () async {
                            final day = await showMeridianDatePicker(
                              context: context,
                              initialDate: _day,
                              firstDate: DateTime(2026),
                              lastDate: DateTime(2026, 12, 31),
                            );
                            if (day != null) setState(() => _day = day);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_busy)
                  Positioned.fill(
                    child: MeridianBusyOverlay(
                      message: 'Verifying…',
                      action: MeridianButton(
                        label: 'Cancel',
                        variant: MeridianButtonVariant.quiet,
                        onPressed: () => setState(() => _busy = false),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ]);
  }

  /// The desktop toolbar. On a phone it scrolls sideways instead of
  /// overflowing.
  Widget _toolbar(BuildContext context) {
    final meridian = context.meridian;
    final commands = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MeridianToolbarButton(
          label: 'New',
          icon: MeridianIcons.squarePlus,
          onPressed: () {},
        ),
        MeridianToolbarButton(
          label: 'Refresh',
          icon: MeridianIcons.refreshCw,
          badge: 4,
          onPressed: () {},
        ),
        MeridianToolbarButton(
          label: 'Send',
          icon: MeridianIcons.send,
          onPressed: () {},
          menuLabel: 'More send options',
          menu: [
            MeridianMenuItem(
              label: 'Send later…',
              icon: 'clock',
              onSelected: () {},
            ),
          ],
        ),
      ],
    );
    final settings = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(meridian.brand.name, style: meridian.text.bodyStrong),
        const SizedBox(width: MeridianSpace.space5),
        MeridianSelect<MeridianBrand>(
          label: 'Brand',
          value: widget.brand,
          values: MeridianBrands.all,
          valueLabel: (b) => b.name,
          onChanged: widget.onBrand,
          width: 170,
        ),
        const SizedBox(width: MeridianSpace.space4),
        MeridianSelect<MeridianDensity>(
          label: 'Density',
          value: widget.density,
          values: MeridianDensity.values,
          valueLabel: (d) => d.name,
          onChanged: widget.onDensity,
          width: 150,
        ),
        const SizedBox(width: MeridianSpace.space4),
        // Slow motion for review: Flutter's global timeDilation.
        MeridianSegmented<double>(
          label: 'Speed',
          value: timeDilation,
          segments: const [
            MeridianSegment(value: 1, label: '1×'),
            MeridianSegment(value: 2, label: '0.5×'),
            MeridianSegment(value: 5, label: '0.2×'),
          ],
          onChanged: (v) => setState(() => timeDilation = v),
        ),
        const SizedBox(width: MeridianSpace.space4),
        MeridianSwitch(
          label: 'Reduce motion',
          value: widget.reduceMotion,
          onChanged: widget.onReduceMotion,
        ),
        const SizedBox(width: MeridianSpace.space4),
        MeridianIconButton(
          label: widget.brightness == Brightness.dark
              ? 'Use light theme'
              : 'Use dark theme',
          icon: widget.brightness == Brightness.dark
              ? MeridianIcons.sun
              : MeridianIcons.moon,
          onPressed: () => widget.onBrightness(
            widget.brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
          ),
        ),
      ],
    );
    return SizedBox(
      height: MeridianSize.toolbar,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: MeridianSpace.space5),
          child: ConstrainedBox(
            // Commands left, settings right when there is room; one
            // scrolling row when there is not.
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth - MeridianSpace.space5 * 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                commands,
                const SizedBox(width: MeridianSpace.space5),
                settings,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _documents(BuildContext context) {
    final meridian = context.meridian;
    MeridianIconButton tool(String id, String label, String icon) =>
        MeridianIconButton(
          label: label,
          icon: icon,
          active: _tool == id,
          onPressed: () => setState(() => _tool = id),
        );
    return _section('Documents: canvas, paper and tool dock', [
      ClipRRect(
        borderRadius: BorderRadius.circular(meridian.radius.md),
        child: SizedBox(
          height: 320,
          child: MeridianCanvas(
            child: Stack(
              children: [
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: MeridianSpace.space6,
                    children: [
                      for (var i = 0; i < 3; i++)
                        SizedBox(
                          width: 80,
                          child: GestureDetector(
                            onTap: () => setState(() => _pageSelected = i),
                            child: MeridianPaper(
                              color: const Color(0xFFFFFFFF),
                              aspectRatio: 210 / 297,
                              selected: i == _pageSelected,
                              semanticLabel: 'Page ${i + 1} of 3',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MeridianSpace.space6,
                  child: Center(
                    child: MeridianToolDock(
                      semanticLabel: 'Tools',
                      children: [
                        tool('pen', 'Pen', MeridianIcons.pencil),
                        tool('eraser', 'Eraser', MeridianIcons.eraser),
                        const MeridianToolDockDivider(),
                        for (final (i, color) in _swatches.take(2).indexed)
                          MeridianColorSwatch(
                            color: color,
                            label: 'Pen colour ${i + 1}',
                            selected: i == _swatch,
                            onPressed: () => setState(() => _swatch = i),
                          ),
                        const MeridianToolDockDivider(),
                        MeridianIconButton(
                          label: 'Undo',
                          icon: MeridianIcons.undo2,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: MeridianSpace.space3),
    child: MeridianIsland(
      title: title,
      padding: const EdgeInsets.all(MeridianSpace.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
}

/// A list whose scrollbar shows while the pointer is over it or it scrolls.
class _ScrollbarDemo extends StatefulWidget {
  const _ScrollbarDemo();

  @override
  State<_ScrollbarDemo> createState() => _ScrollbarDemoState();
}

class _ScrollbarDemoState extends State<_ScrollbarDemo> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MeridianIsland(
    expandChild: true,
    child: MeridianScrollbar(
      controller: _controller,
      child: ListView(
        controller: _controller,
        padding: const EdgeInsets.all(MeridianSpace.space3),
        children: [
          for (var index = 1; index <= 24; index += 1)
            MeridianNavRow(
              label: 'Notebook $index',
              icon: MeridianIcons.bookOpen,
              onTap: () {},
            ),
        ],
      ),
    ),
  );
}

class _CompactButtonDemo extends StatefulWidget {
  @override
  State<_CompactButtonDemo> createState() => _CompactButtonDemoState();
}

class _CompactButtonDemoState extends State<_CompactButtonDemo> {
  bool _compact = false;
  @override
  Widget build(BuildContext context) => MeridianButton(
    label: 'Toggle compact presentation',
    icon: MeridianIcons.save,
    tooltip: 'Toggle compact presentation',
    iconOnly: _compact,
    onPressed: () => setState(() => _compact = !_compact),
  );
}

Stream<LicenseEntry> _demoLicenses() async* {
  yield const LicenseEntryWithLineBreaks(
    ['meridian_ui'],
    'MIT License\n\nCopyright (c) Devmil\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software.',
  );
  yield const LicenseEntryWithLineBreaks(
    ['JetBrains Mono'],
    'SIL OPEN FONT LICENSE Version 1.1\n\nPREAMBLE\n\n  The goals of the Open Font License are to stimulate worldwide development of collaborative font projects.',
  );
  yield const LicenseEntryWithLineBreaks([
    'lucide',
  ], 'ISC License\n\nCopyright (c) Lucide Contributors');
}
