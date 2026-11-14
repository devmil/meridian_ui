import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:meridian_ui/meridian_ui.dart';

/// Builds one gallery section.
typedef SectionBuilder = Widget Function(String title, List<Widget> children);

/// The Motion sections of the gallery, labelled with the MM ids of
/// design/project/guides/40-motion.md like the Meridian Motion Lab. Use the
/// toolbar's Speed and Reduce motion switches to review them.
List<Widget> motionSections(BuildContext context, SectionBuilder section) => [
  section('Motion: helpers', [
    Text(
      'Every row of the motion guide, with its MM id. Slow it down with '
      'Speed; Reduce motion shows each fallback.',
      style: context.meridian.text.body.copyWith(
        color: context.meridian.colors.inkMuted,
      ),
    ),
    const SizedBox(height: MeridianSpace.space5),
    const _HelpersDemo(),
    const SizedBox(height: MeridianSpace.space5),
    const _GlideDemo(),
  ]),
  section('Motion: controls (MM-01 to MM-17)', [const _ControlsDemo()]),
  section('Motion: lists and navigation (MM-20 to MM-30)', [
    const _ListsDemo(),
  ]),
  section('Motion: overlays (MM-40 to MM-50)', [const _OverlaysDemo()]),
  section('Motion: feedback and containers (MM-60 to MM-78)', [
    const _FeedbackDemo(),
  ]),
];

/// A small MM id tag, as in the prototype.
class MotionId extends StatelessWidget {
  const MotionId(this.id, {super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    final meridian = context.meridian;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: meridian.colors.accentSoft,
        borderRadius: BorderRadius.circular(meridian.radius.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MeridianSpace.space2,
          vertical: MeridianSpace.space1,
        ),
        child: Text(
          id,
          style: meridian.text.codeSm.copyWith(
            color: meridian.colors.accentInk,
          ),
        ),
      ),
    );
  }
}

/// One labelled demo: an id, a title, the stage and its trigger.
class MotionDemo extends StatelessWidget {
  const MotionDemo({
    super.key,
    required this.id,
    required this.title,
    required this.child,
    this.trigger,
    this.triggerLabel = 'Play',
  });

  final String id;
  final String title;
  final Widget child;
  final VoidCallback? trigger;
  final String triggerLabel;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 260,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.meridian.colors.paneAlt,
        border: Border.all(color: context.meridian.colors.line),
        borderRadius: BorderRadius.circular(context.meridian.radius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MeridianSpace.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: MeridianSpace.space4,
          children: [
            Wrap(
              spacing: MeridianSpace.space3,
              runSpacing: MeridianSpace.space2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                MotionId(id),
                Text(title, style: context.meridian.text.bodyStrong),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Center(child: child),
            ),
            if (trigger != null)
              MeridianButton(
                label: triggerLabel,
                size: MeridianControlSize.small,
                onPressed: trigger,
              ),
          ],
        ),
      ),
    ),
  );
}

class _HelpersDemo extends StatefulWidget {
  const _HelpersDemo();

  @override
  State<_HelpersDemo> createState() => _HelpersDemoState();
}

class _HelpersDemoState extends State<_HelpersDemo> {
  final _clearController = TextEditingController(text: 'Commit subject');
  var _clearSequence = 0;
  var _swap = 0;
  var _number = 9;
  var _revealed = true;
  var _entrance = 0;
  var _drawn = true;
  var _shake = 0;
  var _live = true;
  var _attention = 0;
  var _pressed = false;

  @override
  void dispose() {
    _clearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meridian = context.meridian;
    const labels = ['Fetch', 'Pull', 'Push'];
    return Wrap(
      spacing: MeridianSpace.space4,
      runSpacing: MeridianSpace.space4,
      children: [
        MotionDemo(
          id: 'Text clear',
          title: 'Programmatic clear',
          triggerLabel: 'Clear or refill',
          trigger: () => setState(() {
            if (_clearController.text.isEmpty) {
              _clearController.text = 'Commit subject';
            } else {
              _clearController.clear();
              _clearSequence++;
            }
          }),
          child: SizedBox(
            width: 240,
            child: MeridianTextField(
              controller: _clearController,
              programmaticClearSequence: _clearSequence,
              placeholder: 'Subject',
            ),
          ),
        ),
        MotionDemo(
          id: 'MM-02',
          title: 'Press scale',
          triggerLabel: _pressed ? 'Release' : 'Press',
          trigger: () => setState(() => _pressed = !_pressed),
          child: MeridianPressScale(
            pressed: _pressed,
            child: const MeridianButton(label: 'Commit', onPressed: _noop),
          ),
        ),
        MotionDemo(
          id: 'Swap',
          title: 'Content swap (rise)',
          trigger: () => setState(() => _swap++),
          child: MeridianSwap(
            swapKey: _swap,
            style: MeridianSwapStyle.rise,
            child: Text(labels[_swap % 3], style: meridian.text.title),
          ),
        ),
        MotionDemo(
          id: 'MM-70',
          title: 'Rolling number',
          trigger: () => setState(() => _number++),
          child: MeridianRollingNumber(
            value: _number,
            popOnIncrease: true,
            style: meridian.text.title,
          ),
        ),
        MotionDemo(
          id: 'MM-22',
          title: 'Reveal',
          trigger: () => setState(() => _revealed = !_revealed),
          child: MeridianReveal(
            visible: _revealed,
            child: const MeridianBanner(
              tone: MeridianBannerTone.info,
              message: 'Revealed',
            ),
          ),
        ),
        MotionDemo(
          id: 'MM-67',
          title: 'Entrance, staggered',
          trigger: () => setState(() => _entrance++),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: MeridianSpace.space3,
            children: [
              for (var i = 0; i < 6; i++)
                MeridianEntrance(
                  key: ValueKey((_entrance, i)),
                  entranceKey: ('gallery-entrance', _entrance, i),
                  index: i,
                  child: const MeridianStatusDot(
                    tone: MeridianStatusTone.accent,
                  ),
                ),
            ],
          ),
        ),
        MotionDemo(
          id: 'MM-04',
          title: 'Stroke',
          trigger: () => setState(() => _drawn = !_drawn),
          child: MeridianStrokeIcon(
            'circle-check',
            drawn: _drawn,
            size: 32,
            duration: MeridianDurations.select,
            color: meridian.colors.success,
          ),
        ),
        MotionDemo(
          id: 'MM-09',
          title: 'Shake',
          trigger: () => setState(() => _shake++),
          child: MeridianShake(
            trigger: _shake,
            child: const MeridianTextField(
              label: 'Name',
              placeholder: 'Required',
            ),
          ),
        ),
        MotionDemo(
          id: 'MM-69',
          title: 'Live pulse',
          trigger: () => setState(() => _live = !_live),
          child: MeridianPulse(
            active: _live,
            color: meridian.colors.success,
            size: 6,
            child: const MeridianStatusDot(tone: MeridianStatusTone.success),
          ),
        ),
        MotionDemo(
          id: 'MM-23',
          title: 'Attention',
          trigger: () => setState(() => _attention++),
          child: MeridianAttention(
            trigger: _attention,
            child: Padding(
              padding: const EdgeInsets.all(MeridianSpace.space3),
              child: Text('Changed underneath', style: meridian.text.body),
            ),
          ),
        ),
      ],
    );
  }
}

void _noop() {}

class _GlideDemo extends StatefulWidget {
  const _GlideDemo();

  @override
  State<_GlideDemo> createState() => _GlideDemoState();
}

class _GlideDemoState extends State<_GlideDemo> {
  var _glide = 0;
  var _row = 2;
  var _lifted = false;
  final _left = ['README.md', 'lib/main.dart', 'pubspec.yaml'];
  final _right = <String>[];
  final _scroll = ScrollController();
  final _lazyScroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    _lazyScroll.dispose();
    super.dispose();
  }

  void _move(BuildContext context, String file) {
    MeridianTravel.capture(context, ('gallery-file', file));
    setState(() {
      if (_left.remove(file)) {
        _right.add(file);
      } else {
        _right.remove(file);
        _left.add(file);
      }
    });
  }

  Widget _list(List<String> files) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final file in files)
          MeridianTravel(
            key: ValueKey(file),
            travelKey: ('gallery-file', file),
            decoration: BoxDecoration(
              color: context.meridian.colors.raised,
              boxShadow: context.meridian.shadows.shadowFloat,
            ),
            child: Builder(
              builder: (context) => MeridianListRow(
                title: file,
                onTap: () => _move(context, file),
              ),
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final meridian = context.meridian;
    return Wrap(
      spacing: MeridianSpace.space4,
      runSpacing: MeridianSpace.space4,
      children: [
        MotionDemo(
          id: 'Glide',
          title: 'Indicator glide',
          trigger: () => setState(() => _glide = (_glide + 1) % 3),
          child: MeridianGlide(
            selectedIndex: _glide,
            itemCount: 3,
            spacing: MeridianSpace.space2,
            indicator: DecoratedBox(
              decoration: BoxDecoration(
                color: meridian.colors.accentSoft,
                borderRadius: BorderRadius.circular(meridian.radius.sm),
              ),
            ),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MeridianSpace.space4,
                vertical: MeridianSpace.space2,
              ),
              child: Text(['One', 'Two', 'Three'][i]),
            ),
          ),
        ),
        MotionDemo(
          id: 'Lazy glide',
          title: 'Recycle the selected row',
          trigger: () => _lazyScroll.jumpTo(_lazyScroll.offset == 0 ? 3000 : 0),
          child: SizedBox(
            height: meridian.density.rowExtent * 4,
            child: MeridianGlide.custom(
              selection: 0,
              indicator: ColoredBox(color: meridian.colors.accentSoft),
              child: CustomScrollView(
                controller: _lazyScroll,
                slivers: [
                  SliverFixedExtentList.builder(
                    itemExtent: meridian.density.rowExtent,
                    itemCount: 4000,
                    itemBuilder: (context, index) => MeridianGlideTarget(
                      selected: index == 0,
                      child: MeridianListRow(title: 'Row $index'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        MotionDemo(
          id: 'MM-20',
          title: 'Selection glide',
          trigger: () => setState(() => _row = (_row + 3) % 14),
          triggerLabel: 'Move 3',
          child: SizedBox(
            height: 120,
            child: MeridianSelectionGlide(
              controller: _scroll,
              itemExtent: meridian.density.rowExtent,
              selectedIndex: _row,
              indicator: DecoratedBox(
                decoration: BoxDecoration(
                  color: meridian.colors.accentSoft,
                  borderRadius: BorderRadius.circular(meridian.radius.sm),
                ),
              ),
              child: ListView.builder(
                controller: _scroll,
                itemExtent: meridian.density.rowExtent,
                itemCount: 14,
                itemBuilder: (context, i) => MeridianListRow(
                  title: 'Row ${i + 1}',
                  selected: i == _row,
                  onTap: () => setState(() => _row = i),
                ),
              ),
            ),
          ),
        ),
        MotionDemo(
          id: 'MM-28',
          title: 'Lift',
          triggerLabel: _lifted ? 'Drop' : 'Lift',
          trigger: () => setState(() => _lifted = !_lifted),
          child: MeridianLift(
            lifted: _lifted,
            child: const MeridianChip(label: 'feature/motion'),
          ),
        ),
        MotionDemo(
          id: 'Travel',
          title: 'Travel between lists',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: MeridianSpace.space3,
            children: [_list(_left), _list(_right)],
          ),
        ),
      ],
    );
  }
}

class _ControlsDemo extends StatefulWidget {
  const _ControlsDemo();

  @override
  State<_ControlsDemo> createState() => _ControlsDemoState();
}

class _ControlsDemoState extends State<_ControlsDemo> {
  var _alternateAction = false;
  var _loading = false;
  var _success = false;
  int? _badge = 2;
  final _branch = TextEditingController();
  var _rejects = 0;
  String? _error;
  var _check = false;
  var _switch = true;
  var _radio = 'merge';
  var _segment = 'unified';
  var _slider = 0.4;
  var _kbd = false;
  var _sort = 'Newest';

  @override
  void dispose() {
    _branch.dispose();
    super.dispose();
  }

  Future<void> _push() async {
    setState(() {
      _loading = true;
      _success = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _success = true;
    });
  }

  void _create() => setState(() {
    if (_branch.text.trim().isEmpty) {
      _rejects++;
      _error = 'Enter a branch name.';
    } else {
      _error = null;
    }
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: MeridianSpace.space4,
    runSpacing: MeridianSpace.space4,
    children: [
      MotionDemo(
        id: 'Button label',
        title: 'Changing action label',
        trigger: () => setState(() => _alternateAction = !_alternateAction),
        child: MeridianButton(
          label: _alternateAction ? 'Amend commit' : 'Commit',
          animateLabel: true,
          onPressed: () {},
        ),
      ),
      MotionDemo(
        id: 'MM-02 · 03 · 04',
        title: 'Press, loading, success',
        child: MeridianButton(
          label: 'Push',
          icon: MeridianIcons.arrowUp,
          variant: MeridianButtonVariant.primary,
          loading: _loading,
          success: _success,
          onPressed: _push,
        ),
      ),
      MotionDemo(
        id: 'MM-06 · 07',
        title: 'Toolbar nudge and badge',
        trigger: () => setState(
          () =>
              _badge = _badge == null ? 1 : (_badge! >= 3 ? null : _badge! + 1),
        ),
        triggerLabel: 'Badge',
        child: Wrap(
          children: [
            MeridianToolbarButton(
              label: 'Fetch',
              icon: MeridianIcons.arrowDownToLine,
              showLabel: false,
              nudge: MeridianNudge.down,
              onPressed: () {},
            ),
            MeridianToolbarButton(
              label: 'Push',
              icon: MeridianIcons.arrowUp,
              showLabel: false,
              nudge: MeridianNudge.up,
              onPressed: () {},
            ),
            MeridianToolbarButton(
              label: 'Refresh',
              icon: MeridianIcons.refreshCw,
              showLabel: false,
              nudge: MeridianNudge.rotate,
              badge: _badge,
              onPressed: () {},
            ),
          ],
        ),
      ),
      MotionDemo(
        id: 'MM-08 · 09 · 10',
        title: 'Text field',
        trigger: _create,
        triggerLabel: 'Create',
        child: MeridianTextField(
          label: 'New branch',
          controller: _branch,
          placeholder: 'feature/motion',
          rejectCount: _rejects,
          error: _error,
          trailingText: '${_branch.text.length}',
          onChanged: (_) => setState(() {}),
        ),
      ),
      MotionDemo(
        id: 'MM-11 · 12 · 13',
        title: 'Checkbox, switch, radio',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: MeridianSpace.space3,
          children: [
            MeridianCheckbox(
              value: _check,
              label: 'Prune on fetch',
              onChanged: (v) => setState(() => _check = v),
            ),
            MeridianSwitch(
              value: _switch,
              label: 'Autostash',
              onChanged: (v) => setState(() => _switch = v),
            ),
            Wrap(
              spacing: MeridianSpace.space4,
              children: [
                for (final v in ['merge', 'rebase'])
                  MeridianRadio<String>(
                    value: v,
                    groupValue: _radio,
                    label: v,
                    onChanged: (v) => setState(() => _radio = v),
                  ),
              ],
            ),
          ],
        ),
      ),
      MotionDemo(
        id: 'MM-14 · 15',
        title: 'Segmented and slider',
        child: Column(
          spacing: MeridianSpace.space4,
          children: [
            MeridianSegmented<String>(
              label: 'Diff',
              value: _segment,
              segments: const [
                MeridianSegment(value: 'unified', label: 'Unified'),
                MeridianSegment(value: 'split', label: 'Split'),
              ],
              onChanged: (v) => setState(() => _segment = v),
            ),
            MeridianSlider(
              label: 'Context',
              value: _slider,
              onChanged: (v) => setState(() => _slider = v),
            ),
          ],
        ),
      ),
      MotionDemo(
        id: 'MM-16 · 17',
        title: 'Select and keycap',
        trigger: () => setState(() => _kbd = !_kbd),
        triggerLabel: 'Press ⌘K',
        child: Wrap(
          spacing: MeridianSpace.space4,
          runSpacing: MeridianSpace.space3,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            MeridianSelect<String>(
              label: 'Sort',
              showLabel: false,
              value: _sort,
              values: const ['Newest', 'Oldest'],
              valueLabel: (v) => v,
              animateValue: true,
              onChanged: (value) => setState(() => _sort = value),
            ),
            MeridianKbd(keys: const ['⌘', 'K'], pressed: _kbd),
          ],
        ),
      ),
    ],
  );
}

class _ListsDemo extends StatefulWidget {
  const _ListsDemo();

  @override
  State<_ListsDemo> createState() => _ListsDemoState();
}

class _ListsDemoState extends State<_ListsDemo> {
  var _selected = 2;
  final _rows = [for (var i = 1; i <= 14; i++) 'feature/row-$i'];
  var _next = 15;
  final _attention = <String, int>{};
  final _removing = <String>{};
  var _current = 0;
  final _tabs = ['README.md', 'main.dart'];
  var _tab = 0;
  var _page = 2;
  var _picked = 0;

  @override
  Widget build(BuildContext context) {
    final meridian = context.meridian;
    return Wrap(
      spacing: MeridianSpace.space4,
      runSpacing: MeridianSpace.space4,
      children: [
        SizedBox(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: MeridianSpace.space3,
            children: [
              const Row(
                spacing: MeridianSpace.space3,
                children: [MotionId('MM-20 · 21 · 22 · 23')],
              ),
              MeridianIsland(
                child: SizedBox(
                  height: 200,
                  child: MeridianList.builder(
                    itemCount: _rows.length,
                    itemExtent: meridian.density.rowExtent,
                    selectedIndex: _selected.clamp(0, _rows.length - 1),
                    itemBuilder: (context, i) {
                      final name = _rows[i];
                      final row = MeridianListRow(
                        key: ValueKey(name),
                        title: name,
                        meta: '${i + 1}d',
                        revealKey: ('gallery-list', name),
                        attention: _attention[name] ?? 0,
                        selected: i == _selected,
                        onTap: () => setState(() => _selected = i),
                        hoverActions: [
                          MeridianIconButton(
                            label: 'Remove',
                            icon: MeridianIcons.trash2,
                            size: MeridianControlSize.small,
                            onPressed: () =>
                                setState(() => _removing.add(name)),
                          ),
                        ],
                      );
                      if (!_removing.contains(name)) return row;
                      return MeridianRemovingRow(
                        key: ValueKey(('removing', name)),
                        onRemoved: () => setState(() {
                          _removing.remove(name);
                          _rows.remove(name);
                        }),
                        child: row,
                      );
                    },
                  ),
                ),
              ),
              Wrap(
                spacing: MeridianSpace.space3,
                children: [
                  MeridianButton(
                    label: 'Add',
                    size: MeridianControlSize.small,
                    onPressed: () => setState(
                      () => _rows.insert(0, 'feature/row-${_next++}'),
                    ),
                  ),
                  MeridianButton(
                    label: 'Change underneath',
                    size: MeridianControlSize.small,
                    onPressed: () => setState(() {
                      final name = _rows[_selected.clamp(0, _rows.length - 1)];
                      _attention[name] = (_attention[name] ?? 0) + 1;
                    }),
                  ),
                  MeridianButton(
                    label: 'Move 3',
                    size: MeridianControlSize.small,
                    onPressed: () => setState(
                      () => _selected = (_selected + 3) % _rows.length,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          width: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: MeridianSpace.space3,
            children: [
              const MotionId('MM-24 · 25'),
              MeridianNavSection(
                title: 'Branches',
                collapsible: true,
                children: [
                  for (var i = 0; i < 7; i++)
                    MeridianNavRow(
                      label: 'branch-$i',
                      icon: MeridianIcons.gitBranch,
                      current: i == _current,
                      onTap: () => setState(() => _current = i),
                    ),
                ],
              ),
              const MeridianDisclosure(
                title: 'Disclosure',
                child: Text('Its body reveals and rises.'),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: MeridianSpace.space3,
            children: [
              const MotionId('MM-26 · 27 · 29 · 30'),
              MeridianTabs(
                style: MeridianTabsStyle.pill,
                index: _tab.clamp(0, _tabs.length - 1),
                tabs: [for (final t in _tabs) MeridianTab(label: t)],
                onChanged: (i) => setState(() => _tab = i),
                onClose: (i) => setState(() {
                  _tabs.removeAt(i);
                  if (_tab >= _tabs.length) _tab = _tabs.length - 1;
                }),
              ),
              MeridianButton(
                label: 'Open a tab',
                size: MeridianControlSize.small,
                onPressed: () =>
                    setState(() => _tabs.add('file-${_tabs.length + 1}.txt')),
              ),
              MeridianPagination(
                page: _page,
                pageCount: 6,
                previousLabel: 'Previous',
                nextLabel: 'Next',
                onPageSelected: (p) => setState(() => _page = p),
              ),
              MeridianButton(
                label: _picked == 0 ? 'Select items' : 'Select one more',
                size: MeridianControlSize.small,
                onPressed: () => setState(() => _picked++),
              ),
              MeridianSelectionBar(
                visible: _picked > 0,
                label: '$_picked selected',
                actions: const [],
                clearLabel: 'Clear',
                onClear: () => setState(() => _picked = 0),
                overflowLabel: 'More',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverlaysDemo extends StatelessWidget {
  const _OverlaysDemo();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: MeridianSpace.space4,
    runSpacing: MeridianSpace.space4,
    children: [
      MotionDemo(
        id: 'MM-16 · 40 · 41 · 42',
        title: 'Menu',
        child: MeridianMenuAnchor(
          entries: [
            for (final label in [
              'Checkout',
              'Rename…',
              'Merge into current',
              'Rebase onto',
              'Compare',
              'Copy name',
              'Push',
              'Delete',
            ])
              MeridianMenuItem(label: label, onSelected: () {}),
          ],
          builder: (context, open) => MeridianButton(
            label: 'Branch',
            trailingIcon: MeridianIcons.chevronDown,
            onPressed: open,
          ),
        ),
      ),
      MotionDemo(
        id: 'MM-40',
        title: 'Popover',
        child: MeridianPopoverAnchor(
          popoverBuilder: (context) => const Padding(
            padding: EdgeInsets.all(MeridianSpace.space5),
            child: Text('A popover grows from its anchor.'),
          ),
          builder: (context, open) =>
              MeridianButton(label: 'Details', onPressed: open),
        ),
      ),
      MotionDemo(
        id: 'MM-45 · 46 · 47',
        title: 'Dialog',
        child: MeridianButton(
          label: 'Delete branch…',
          onPressed: () => showMeridianDialog<void>(
            context: context,
            builder: (context) => const _ConfirmDialog(),
          ),
        ),
      ),
      MotionDemo(
        id: 'MM-48',
        title: 'Sheet',
        child: MeridianButton(
          label: 'Open sheet',
          onPressed: () => showMeridianSheet<void>(
            context: context,
            builder: (context) => const MeridianSheet(
              child: Padding(
                padding: EdgeInsets.all(MeridianSpace.space6),
                child: Text('A sheet slides in on the enter curve.'),
              ),
            ),
          ),
        ),
      ),
      MotionDemo(
        id: 'MM-49 · 50',
        title: 'Toasts',
        child: Wrap(
          spacing: MeridianSpace.space3,
          children: [
            MeridianButton(
              label: 'Toast',
              onPressed: () =>
                  showMeridianToast(context, message: 'Pushed to origin'),
            ),
            MeridianButton(
              label: 'With Undo',
              onPressed: () => showMeridianToast(
                context,
                message: 'Deleted draft',
                actionLabel: 'Undo',
                onAction: () {},
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ConfirmDialog extends StatefulWidget {
  const _ConfirmDialog();

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  var _sure = false;

  @override
  Widget build(BuildContext context) => MeridianDialog(
    title: 'Delete feature/motion',
    description: 'Press Enter before ticking the box to see the shake.',
    submitDisabled: !_sure,
    onSubmit: _sure ? () => Navigator.of(context).pop() : null,
    content: MeridianCheckbox(
      value: _sure,
      label: 'I understand',
      onChanged: (v) => setState(() => _sure = v),
    ),
    actions: [
      MeridianButton(
        label: 'Cancel',
        onPressed: () => Navigator.of(context).pop(),
      ),
      MeridianButton(
        label: 'Delete',
        variant: MeridianButtonVariant.danger,
        disabledReason: 'Tick the box first',
        onPressed: _sure ? () => Navigator.of(context).pop() : null,
      ),
    ],
  );
}

class _FeedbackDemo extends StatefulWidget {
  const _FeedbackDemo();

  @override
  State<_FeedbackDemo> createState() => _FeedbackDemoState();
}

class _FeedbackDemoState extends State<_FeedbackDemo> {
  double? _progress;
  var _loaded = false;
  var _banner = true;
  var _tone = MeridianBannerTone.attention;
  var _commit = 0;
  var _status = 0;
  var _drop = false;
  var _chip = true;

  Future<void> _run() async {
    setState(() => _progress = null);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    for (final v in [0.3, 0.7, 1.0]) {
      if (!mounted) return;
      setState(() => _progress = v);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: MeridianSpace.space4,
    runSpacing: MeridianSpace.space4,
    children: [
      MotionDemo(
        id: 'MM-60 · 62 · 63',
        title: 'Progress',
        trigger: _run,
        triggerLabel: 'Sync',
        child: SizedBox(
          width: 200,
          child: MeridianProgressBar(value: _progress, track: true),
        ),
      ),
      MotionDemo(
        id: 'MM-64',
        title: 'Skeleton',
        trigger: () => setState(() => _loaded = !_loaded),
        triggerLabel: _loaded ? 'Reload' : 'Load',
        child: MeridianSkeleton.swap(
          loaded: _loaded,
          skeleton: const MeridianSkeleton(width: 160),
          child: const Text('3 commits ahead'),
        ),
      ),
      MotionDemo(
        id: 'MM-65 · 66',
        title: 'Banner',
        trigger: () => setState(
          () => _tone = _tone == MeridianBannerTone.attention
              ? MeridianBannerTone.success
              : MeridianBannerTone.attention,
        ),
        triggerLabel: 'Tone',
        child: Column(
          children: [
            MeridianBanner(
              visible: _banner,
              tone: _tone,
              message: _tone == MeridianBannerTone.success
                  ? 'All conflicts resolved.'
                  : '2 conflicts left.',
            ),
            MeridianButton(
              label: _banner ? 'Hide' : 'Show',
              size: MeridianControlSize.small,
              onPressed: () => setState(() => _banner = !_banner),
            ),
          ],
        ),
      ),
      const MotionDemo(
        id: 'MM-69',
        title: 'Live status',
        child: MeridianStatusDot(label: 'Fetching', live: true),
      ),
      MotionDemo(
        id: 'MM-72',
        title: 'Chip removed',
        trigger: () => setState(() => _chip = !_chip),
        child: MeridianChip(label: 'needs-review', visible: _chip),
      ),
      MotionDemo(
        id: 'MM-74',
        title: 'Island content swap',
        trigger: () => setState(() => _commit++),
        triggerLabel: 'Next commit',
        child: SizedBox(
          width: 200,
          child: MeridianIsland(
            contentKey: _commit,
            padding: const EdgeInsets.all(MeridianSpace.space4),
            child: Text('Commit ${_commit + 1}'),
          ),
        ),
      ),
      MotionDemo(
        id: 'MM-75',
        title: 'Resize handle',
        child: SizedBox(
          height: 56,
          child: MeridianResizeHandle(
            direction: Axis.horizontal,
            semanticLabel: 'Resize',
            onDrag: (_) {},
          ),
        ),
      ),
      MotionDemo(
        id: 'MM-76',
        title: 'Status bar',
        trigger: () => setState(() => _status++),
        child: SizedBox(
          width: 200,
          child: MeridianStatusBar(
            leading: [
              Text(['Fetching…', 'Up to date', '2 behind'][_status % 3]),
            ],
          ),
        ),
      ),
      MotionDemo(
        id: 'MM-77',
        title: 'Drop zone',
        trigger: () => setState(() => _drop = !_drop),
        triggerLabel: 'Drag over',
        child: SizedBox(
          width: 200,
          child: MeridianDropZone(
            label: 'Drop a folder',
            state: _drop
                ? MeridianDropZoneState.active
                : MeridianDropZoneState.idle,
          ),
        ),
      ),
    ],
  );
}
