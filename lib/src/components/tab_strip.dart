import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../foundation/meridian_icons.g.dart';
import '../foundation/meridian_interaction.dart';
import '../foundation/meridian_layout.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_tokens.g.dart';
import 'actions.dart';
import 'inputs.dart';
import 'tooltip.dart';

/// One open document of a [MeridianTabStrip].
@immutable
class MeridianStripTab<T extends Object, G extends Object> {
  const MeridianStripTab({
    required this.id,
    required this.label,
    this.group,
    this.leading,
    this.tooltip,
    this.dirty = false,
    this.renamable = true,
    this.renamePlaceholder,
    this.semanticLabel,
  });

  /// A stable identity: a new id grows its tab in, a missing one collapses
  /// its tab out.
  final T id;
  final String label;

  /// The [MeridianStripGroup] the tab belongs to. A group's tabs stand side
  /// by side, after its chip.
  final G? group;

  /// A mark before the label (an icon, a spinner), at the small icon size.
  final Widget? leading;

  /// Shown on hover; the label by default.
  final String? tooltip;

  /// A `warning` dot after the label for unsaved changes.
  final bool dirty;

  /// Whether a second click on the active tab names it in place (with
  /// [MeridianTabStrip.onRenameTab]).
  final bool renamable;

  /// The name an emptied field falls back to, shown as its placeholder.
  final String? renamePlaceholder;

  /// Overrides the announced name; the label by default.
  final String? semanticLabel;
}

/// Tabs kept together under a chip of a [color], with an optional [name]
/// and [icon]. A [collapsed] group shows only its chip and the tab count.
@immutable
class MeridianStripGroup<G extends Object> {
  const MeridianStripGroup({
    required this.id,
    required this.color,
    this.name = '',
    this.icon,
    this.collapsed = false,
    this.label,
  });

  final G id;

  /// Usually a `series` colour; the chip is a tint of it and the rule under
  /// the group is drawn in it.
  final Color color;
  final String name;

  /// A Meridian icon name drawn in [color] before the name, or alone.
  final String? icon;
  final bool collapsed;

  /// What tooltips and screen readers call an unnamed group ("Violet
  /// group"); [name] otherwise.
  final String? label;
}

/// The strings a [MeridianTabStrip] shows or announces. Each one falls back
/// to English.
@immutable
class MeridianTabStripLabels {
  const MeridianTabStripLabels({
    this.close,
    this.collapseGroup,
    this.expandGroup,
    this.group,
    this.renameTab,
    this.renameGroup,
    this.groupNamePlaceholder,
    this.moveLeft,
    this.moveRight,
    this.dirty,
  });

  /// `Close <tab>`.
  final String Function(String tab)? close;

  /// `Collapse <group>`, the chip's tooltip while the group is open.
  final String Function(String group)? collapseGroup;

  /// `Expand <group>`.
  final String Function(String group)? expandGroup;

  /// `<group>, tab group, <count> tabs`, the chip's announced name.
  final String Function(String group, int count)? group;

  /// The name field of a tab being renamed.
  final String? renameTab;

  /// The name field of a group being renamed.
  final String? renameGroup;

  /// Shown in an empty group name field.
  final String? groupNamePlaceholder;

  /// Screen reader actions that move a tab one place.
  final String? moveLeft;
  final String? moveRight;

  /// How a dirty tab is announced.
  final String? dirty;
}

/// A browser-style strip of document tabs on `ground`.
///
/// Tabs share the width (between `tabPillMinWidth` and `tabLabelMaxWidth`)
/// and scroll when they do not fit. The active tab is a `pane` pill that
/// glides between tabs. Tabs and group chips are dragged straight along the
/// strip: the others make room as the drag passes them, a group's chip
/// carries the whole group, and a tab joins a group once it passes the
/// group's chip or its last tab. At a group's end the rule under the group
/// shows whether the tab is in; a short nudge outwards takes it out.
/// Escape cancels a drag.
class MeridianTabStrip<T extends Object, G extends Object>
    extends StatefulWidget {
  const MeridianTabStrip({
    required this.tabs,
    required this.activeTab,
    required this.onActivate,
    super.key,
    this.groups = const [],
    this.onClose,
    this.onMoveTab,
    this.onMoveGroup,
    this.onContextMenu,
    this.onRenameTab,
    this.onToggleGroup,
    this.onGroupContextMenu,
    this.onRenameGroup,
    this.nameMaxLength,
    this.labels = const MeridianTabStripLabels(),
  });

  /// In order; a group's tabs stand side by side.
  final List<MeridianStripTab<T, G>> tabs;
  final List<MeridianStripGroup<G>> groups;
  final T? activeTab;
  final ValueChanged<T> onActivate;

  /// Shows a close button on hover and on the active tab; a middle click
  /// also closes.
  final ValueChanged<T>? onClose;

  /// A tab dropped at [index] among the other tabs, in [group] or in none.
  /// `null` keeps tabs in place.
  final void Function(T tab, int index, G? group)? onMoveTab;

  /// A group's chip dropped so its tabs start at [index] among the other
  /// tabs. `null` keeps chips in place.
  final void Function(G group, int index)? onMoveGroup;

  /// A right click, the menu key or Shift+F10 on a tab, with the global
  /// position for the menu.
  final void Function(T tab, Offset position)? onContextMenu;

  /// A tab named in place (a second click on the active tab, or
  /// [MeridianTabStripState.renameTab]). An empty name asks for the
  /// default.
  final void Function(T tab, String name)? onRenameTab;

  /// A click on a group's chip.
  final ValueChanged<G>? onToggleGroup;
  final void Function(G group, Offset position)? onGroupContextMenu;
  final void Function(G group, String name)? onRenameGroup;

  /// The longest name a field takes in place.
  final int? nameMaxLength;
  final MeridianTabStripLabels labels;

  @override
  State<MeridianTabStrip<T, G>> createState() => MeridianTabStripState<T, G>();
}

/// A strip entry's key: `('tab', id)`, `('group', id)` or
/// `('closing', id)`.
typedef _Key = (String, Object);

/// A rectangle along the strip that moves to new targets over time.
class _Slot {
  _Slot(double x, double w) : _fromX = x, _toX = x, _fromW = w, _toW = w;

  double _fromX, _toX, _fromW, _toW;
  Duration _start = Duration.zero;
  Duration _length = Duration.zero;
  Curve _curve = MeridianDurations.layoutCurve;

  double _t(Duration now) => _length == Duration.zero
      ? 1
      : ((now - _start).inMicroseconds / _length.inMicroseconds).clamp(0, 1);

  double x(Duration now) =>
      _fromX + (_toX - _fromX) * _curve.transform(_t(now));

  double w(Duration now) =>
      _fromW + (_toW - _fromW) * _curve.transform(_t(now));

  double get targetW => _toW;

  bool animating(Duration now) => _t(now) < 1;

  void moveTo(
    double x,
    double w,
    Duration now,
    Duration length, {
    Curve curve = MeridianDurations.layoutCurve,
  }) {
    if (x == _toX && w == _toW) return;
    _fromX = this.x(now);
    _fromW = this.w(now);
    _toX = x;
    _toW = w;
    _start = now;
    _length = length;
    _curve = curve;
  }

  void jump(double x, double w) {
    _fromX = _toX = x;
    _fromW = _toW = w;
    _length = Duration.zero;
  }
}

/// One entry of the strip in order: a group's chip, a tab, or a closing
/// tab still collapsing.
sealed class _Entry<T extends Object, G extends Object> {
  const _Entry(this.group);

  final MeridianStripGroup<G>? group;
  _Key get key;
}

final class _ChipEntry<T extends Object, G extends Object>
    extends _Entry<T, G> {
  const _ChipEntry(MeridianStripGroup<G> super.group, this.count);

  final int count;

  @override
  MeridianStripGroup<G> get group => super.group!;

  @override
  _Key get key => ('group', group.id);
}

final class _TabEntry<T extends Object, G extends Object> extends _Entry<T, G> {
  const _TabEntry(this.tab, super.group, {this.closing = false});

  final MeridianStripTab<T, G> tab;
  final bool closing;

  /// Folded away inside a collapsed group.
  bool get hidden => group?.collapsed ?? false;

  @override
  _Key get key => (closing ? 'closing' : 'tab', tab.id);
}

/// Where a drag would drop: after [slot] entries of the strip without the
/// dragged ones, in [group] (tabs only).
typedef _Drop<G> = ({int slot, G? group});

class _Drag<T extends Object, G extends Object> {
  _Drag.tab(this.tab, this.grab, this.pointer) : group = null, down = pointer;
  _Drag.group(this.group, this.grab, this.pointer) : tab = null, down = pointer;

  final T? tab;
  final G? group;

  /// Where the pointer went down. The drag moves nothing until the pointer
  /// has left it by `tabDragThreshold`; released before, it was a click.
  final double down;
  var started = false;

  /// Where the pointer took hold, from the dragged entry's start.
  final double grab;

  /// The pointer along the strip's content.
  double pointer;

  /// The pointer's global position, for scrolling at the edges.
  Offset global = Offset.zero;
}

class MeridianTabStripState<T extends Object, G extends Object>
    extends State<MeridianTabStrip<T, G>>
    with SingleTickerProviderStateMixin {
  final Map<_Key, _Slot> _slots = {};
  _Slot? _indicator;
  T? _indicatorFor;
  late final Ticker _ticker = createTicker(_tick);
  final ScrollController _scroll = ScrollController();
  final GlobalKey _content = GlobalKey();
  var _built = false;

  /// Closed tabs still collapsing, with the place they stood and the group
  /// they were in.
  final List<(MeridianStripTab<T, G>, int)> _closing = [];

  _Drag<T, G>? _drag;

  /// The tab width of the last layout, for a drop that ends between frames.
  double _tabWidth = MeridianLayout.tabLabelMaxWidth;

  /// The order a drop asked for, kept until the owner's tabs change (or
  /// briefly, if they never do).
  List<(T, G?)>? _pending;
  List<(T, G?)>? _pendingBase;
  Timer? _pendingTimeout;

  T? _renamingTab;
  G? _renamingGroup;

  /// The active tab clicked last, until the double-click time runs out.
  T? _lastTap;
  Timer? _lastTapTimeout;

  /// Edits [tab]'s name in place.
  void renameTab(T tab) {
    if (widget.onRenameTab == null) return;
    setState(() {
      _renamingGroup = null;
      _renamingTab = tab;
    });
  }

  /// Edits [group]'s name in place.
  void renameGroup(G group) {
    if (widget.onRenameGroup == null) return;
    setState(() {
      _renamingTab = null;
      _renamingGroup = group;
    });
  }

  /// The frame clock: animations and double clicks follow frames, not the
  /// wall clock.
  Duration get _now => SchedulerBinding.instance.currentSystemFrameTimeStamp;

  List<(T, G?)> _order(List<MeridianStripTab<T, G>> tabs) => [
    for (final tab in tabs) (tab.id, tab.group),
  ];

  static bool _sameOrder<T, G>(List<(T, G?)> a, List<(T, G?)> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void didUpdateWidget(MeridianTabStrip<T, G> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final after = {for (final tab in widget.tabs) tab.id};
    if (_renamingTab case final id? when !after.contains(id)) {
      _renamingTab = null;
    }
    if (_renamingGroup case final id?
        when !widget.groups.any((group) => group.id == id)) {
      _renamingGroup = null;
    }
    if (_pendingBase case final base?
        when !_sameOrder(base, _order(widget.tabs))) {
      _clearPending();
    }
    if (_drag case final drag?) {
      // The dragged tab or group closed underneath the drag.
      if ((drag.tab != null && !after.contains(drag.tab)) ||
          (drag.group != null &&
              !widget.groups.any((group) => group.id == drag.group))) {
        _endDrag(drop: false);
      }
    }
    if (MeridianMotion.reduced(context)) return;
    for (final (index, tab) in oldWidget.tabs.indexed) {
      if (after.contains(tab.id)) continue;
      _closing
        ..removeWhere((ghost) => ghost.$1.id == tab.id)
        ..add((tab, index));
      // The ghost takes over the closed tab's place.
      if (_slots.remove(('tab', tab.id)) case final slot?) {
        _slots[('closing', tab.id)] = slot;
      }
    }
  }

  @override
  void dispose() {
    _pendingTimeout?.cancel();
    _lastTapTimeout?.cancel();
    HardwareKeyboard.instance.removeHandler(_onKey);
    _ticker.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _clearPending() {
    _pending = null;
    _pendingBase = null;
    _pendingTimeout?.cancel();
    _pendingTimeout = null;
  }

  void _tick(Duration _) {
    if (!mounted) return;
    _autoScroll();
    final now = _now;
    final moving =
        (_drag?.started ?? false) ||
        (_indicator?.animating(now) ?? false) ||
        _slots.values.any((slot) => slot.animating(now));
    setState(() {});
    if (!moving) _ticker.stop();
  }

  void _animate() {
    if (!_ticker.isActive) _ticker.start();
  }

  // ------------------------------------------------------------- layout

  /// The strip's live entries in [order]: each group's chip before its
  /// first tab.
  List<_Entry<T, G>> _entries(List<(T, G?)> order) {
    final tabsById = {for (final tab in widget.tabs) tab.id: tab};
    final groupsById = {for (final group in widget.groups) group.id: group};
    final counts = <G, int>{};
    for (final (_, group) in order) {
      if (group != null) counts[group] = (counts[group] ?? 0) + 1;
    }
    final seen = <G>{};
    return [
      for (final (id, groupId) in order)
        if (tabsById[id] case final tab?)
          if (groupsById[groupId] case final group?) ...[
            if (seen.add(group.id))
              _ChipEntry<T, G>(group, counts[group.id] ?? 0),
            _TabEntry<T, G>(tab, group),
          ] else
            _TabEntry<T, G>(tab, null),
    ];
  }

  /// [entries] with the closing tabs where they stood among the tabs.
  List<_Entry<T, G>> _withGhosts(List<_Entry<T, G>> entries) {
    if (_closing.isEmpty) return entries;
    final result = [...entries];
    for (final (tab, index) in _closing) {
      var at = 0;
      var tabs = 0;
      while (at < result.length && tabs < index) {
        if (result[at] is _TabEntry<T, G>) tabs++;
        at++;
      }
      result.insert(at, _TabEntry<T, G>(tab, null, closing: true));
    }
    return result;
  }

  double _chipWidth(_ChipEntry<T, G> chip) => _GroupChip.widthFor(
    context,
    chip.group,
    chip.count,
    editing: chip.group.id == _renamingGroup,
  );

  /// The width [entry] takes in the strip.
  double _width(_Entry<T, G> entry, double tabWidth) => switch (entry) {
    _ChipEntry() => _chipWidth(entry),
    _TabEntry(closing: true) => 0,
    _TabEntry() when entry.hidden => 0,
    _TabEntry() => tabWidth,
  };

  /// Where each of [entries] starts with [widths]: a `space-2` gap follows
  /// every entry that takes room.
  List<double> _starts(List<double> widths) {
    final starts = <double>[];
    var x = 0.0;
    for (final width in widths) {
      starts.add(x);
      if (width > 0) x += width + MeridianSpace.space2;
    }
    return starts;
  }

  // --------------------------------------------------------------- drag

  /// The live entries without the dragged tab or group.
  List<_Entry<T, G>> _rest(List<_Entry<T, G>> entries, _Drag<T, G> drag) => [
    for (final entry in entries)
      if (switch (entry) {
        _TabEntry(closing: true) => false,
        _TabEntry(:final tab) =>
          tab.id != drag.tab &&
              (drag.group == null || entry.group?.id != drag.group),
        _ChipEntry(:final group) => group.id != drag.group,
      })
        entry,
  ];

  /// The drop nearest to where the dragged entry's start is now.
  _Drop<G> _dropAt(
    List<_Entry<T, G>> rest,
    List<double> widths,
    double start,
    _Drag<T, G> drag,
  ) {
    final starts = _starts(widths);
    double startOf(int slot) => slot < rest.length
        ? starts[slot]
        : (rest.isEmpty
              ? 0
              : starts.last +
                    (widths.last > 0 ? widths.last + MeridianSpace.space2 : 0));
    final candidates = <(_Drop<G>, double)>[];
    for (var slot = 0; slot <= rest.length; slot++) {
      final previous = slot > 0 ? rest[slot - 1] : null;
      final next = slot < rest.length ? rest[slot] : null;
      // A collapsed group's folded tabs travel with its chip.
      if (next is _TabEntry<T, G> && next.hidden) continue;
      final open = previous?.group != null && !previous!.group!.collapsed
          ? previous.group
          : null;
      final inside = open != null && next?.group?.id == open.id;
      if (drag.group != null) {
        // A group never lands inside another.
        if (!inside) candidates.add(((slot: slot, group: null), startOf(slot)));
        continue;
      }
      if (open == null) {
        candidates.add(((slot: slot, group: null), startOf(slot)));
        continue;
      }
      candidates.add(((slot: slot, group: open.id), startOf(slot)));
      // At the group's end a short nudge outwards leaves it.
      if (!inside) {
        candidates.add((
          (slot: slot, group: null),
          startOf(slot) + MeridianLayout.tabGroupEdgeShift,
        ));
      }
    }
    var best = candidates.first;
    for (final candidate in candidates.skip(1)) {
      if ((candidate.$2 - start).abs() < (best.$2 - start).abs()) {
        best = candidate;
      }
    }
    return best.$1;
  }

  /// The order with the dragged tab or group at [drop].
  List<(T, G?)> _dropped(
    List<_Entry<T, G>> rest,
    _Drag<T, G> drag,
    _Drop<G> drop,
  ) {
    final before = rest.take(drop.slot).whereType<_TabEntry<T, G>>();
    final after = rest.skip(drop.slot).whereType<_TabEntry<T, G>>();
    final moved = drag.tab != null
        ? [(drag.tab as T, drop.group)]
        : [
            for (final tab in widget.tabs)
              if (tab.group == drag.group) (tab.id, tab.group),
          ];
    return [
      for (final entry in before) (entry.tab.id, entry.group?.id),
      ...moved,
      for (final entry in after) (entry.tab.id, entry.group?.id),
    ];
  }

  Offset _local(Offset global) {
    final box = _content.currentContext?.findRenderObject();
    return box is RenderBox ? box.globalToLocal(global) : global;
  }

  void _startDrag(_Key key, DragStartDetails details) {
    final slot = _slots[key];
    if (slot == null) return;
    final pointer = _local(details.globalPosition).dx;
    final grab = pointer - slot.x(_now);
    final drag = switch (key) {
      ('tab', final T id) => _Drag<T, G>.tab(id, grab, pointer),
      ('group', final G id) => _Drag<T, G>.group(id, grab, pointer),
      _ => null,
    };
    if (drag == null) return;
    drag.global = details.globalPosition;
    _drag = drag;
  }

  void _updateDrag(DragUpdateDetails details) {
    final drag = _drag;
    if (drag == null) return;
    drag
      ..pointer = _local(details.globalPosition).dx
      ..global = details.globalPosition;
    if (!drag.started) {
      if ((drag.pointer - drag.down).abs() < MeridianLayout.tabDragThreshold) {
        return;
      }
      drag.started = true;
      HardwareKeyboard.instance.addHandler(_onKey);
      _clearPending();
    }
    setState(() {});
    _animate();
  }

  /// A press that never became a drag acts as the click it was.
  void _released(_Key key) {
    final drag = _drag;
    if (drag == null) return;
    if (drag.started) {
      setState(() => _endDrag(drop: true));
      return;
    }
    _drag = null;
    switch (key) {
      case ('tab', final T id):
        final tab = widget.tabs.where((tab) => tab.id == id).firstOrNull;
        if (tab != null) _tapped(tab);
      case ('group', final G id):
        widget.onToggleGroup?.call(id);
    }
  }

  bool _onKey(KeyEvent event) {
    if (!(_drag?.started ?? false) || event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.escape) return false;
    setState(() => _endDrag(drop: false));
    return true;
  }

  /// Ends the drag; with [drop], reports where it landed and keeps that
  /// order until the owner's tabs follow.
  void _endDrag({required bool drop}) {
    final drag = _drag;
    if (drag == null) return;
    HardwareKeyboard.instance.removeHandler(_onKey);
    _drag = null;
    if (!drag.started) return;
    _animate();
    if (!drop) return;
    final base = _order(widget.tabs);
    final rest = _rest(_entries(base), drag);
    // Where the pointer is now, even if no frame has shown it yet.
    final landed = _dropAt(
      rest,
      [for (final entry in rest) _width(entry, _tabWidth)],
      drag.pointer - drag.grab,
      drag,
    );
    final order = _dropped(rest, drag, landed);
    if (_sameOrder(order, base)) return;
    _pending = order;
    _pendingBase = base;
    _pendingTimeout?.cancel();
    _pendingTimeout = Timer(MeridianDurations.attention, () {
      if (mounted) setState(_clearPending);
    });
    final others = rest.take(landed.slot).whereType<_TabEntry<T, G>>().length;
    if (drag.tab case final tab?) {
      widget.onMoveTab?.call(tab, others, landed.group);
    } else if (drag.group case final group?) {
      widget.onMoveGroup?.call(group, others);
    }
  }

  /// Scrolls while a drag holds the pointer near the strip's edges.
  void _autoScroll() {
    final drag = _drag;
    if (drag == null || !drag.started || !_scroll.hasClients) return;
    final viewport = context.findRenderObject();
    if (viewport is! RenderBox) return;
    final local = viewport.globalToLocal(drag.global).dx;
    const edge = MeridianLayout.tabStripScrollEdge;
    double delta = 0;
    if (local < edge) delta = -(edge - local);
    if (local > viewport.size.width - edge) {
      delta = local - (viewport.size.width - edge);
    }
    if (delta == 0) return;
    final position = _scroll.position;
    final next = (position.pixels + delta * MeridianLayout.tabStripScrollRate)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (next == position.pixels) return;
    final moved = next - position.pixels;
    _scroll.jumpTo(next);
    drag.pointer += moved;
  }

  // ------------------------------------------------------------ actions

  void _tapped(MeridianStripTab<T, G> tab) {
    final active = tab.id == widget.activeTab;
    // A second click on the active tab names it.
    if (active &&
        _lastTap == tab.id &&
        tab.renamable &&
        widget.onRenameTab != null) {
      _forgetTap();
      renameTab(tab.id);
      return;
    }
    // Only a click on the tab that was already active counts towards a
    // second click.
    _forgetTap();
    if (active) {
      _lastTap = tab.id;
      _lastTapTimeout = Timer(kDoubleTapTimeout, _forgetTap);
    }
    widget.onActivate(tab.id);
  }

  void _forgetTap() {
    _lastTap = null;
    _lastTapTimeout?.cancel();
    _lastTapTimeout = null;
  }

  void _finishTabRename(T tab, String? name) {
    if (_renamingTab != tab) return;
    setState(() => _renamingTab = null);
    if (name != null) widget.onRenameTab?.call(tab, name);
  }

  void _finishGroupRename(G group, String? name) {
    if (_renamingGroup != group) return;
    setState(() => _renamingGroup = null);
    if (name != null) widget.onRenameGroup?.call(group, name);
  }

  /// Moves [tab] one place for assistive technology: past its neighbour,
  /// into or out of a group at the group's edge.
  void _step(MeridianStripTab<T, G> tab, int delta) {
    final order = _order(widget.tabs);
    final index = order.indexWhere((entry) => entry.$1 == tab.id);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= order.length) return;
    final rest = [...order]..removeAt(index);
    final before = target > 0 ? rest[target - 1].$2 : null;
    final after = target < rest.length ? rest[target].$2 : null;
    final group = before != null && before == after
        ? before
        : tab.group != null && (before == tab.group || after == tab.group)
        ? tab.group
        : null;
    widget.onMoveTab?.call(tab.id, target, group);
  }

  // ------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final reduced = MeridianMotion.reduced(context);
    final layoutDuration = MeridianMotion.of(context, MeridianDurations.layout);
    return SizedBox(
      height: MeridianLayout.tabStripHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final now = _now;
          // Closed tabs leave once collapsed.
          _closing.removeWhere((ghost) {
            final slot = _slots[('closing', ghost.$1.id)];
            return slot == null || (slot.targetW == 0 && !slot.animating(now));
          });
          final drag = _drag?.started ?? false ? _drag : null;
          final base = _entries(_pending ?? _order(widget.tabs));
          var entries = _withGhosts(base);
          final chipsWidth = entries.whereType<_ChipEntry<T, G>>().fold(
            0.0,
            (sum, chip) => sum + _chipWidth(chip),
          );
          final shownTabs = entries
              .whereType<_TabEntry<T, G>>()
              .where((entry) => !entry.closing && !entry.hidden)
              .length;
          final shown =
              shownTabs + entries.whereType<_ChipEntry<T, G>>().length;
          final gaps = math.max(0, shown - 1) * MeridianSpace.space2;
          final available = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : shownTabs * MeridianLayout.tabLabelMaxWidth + chipsWidth + gaps;
          final tabWidth = _tabWidth = shownTabs == 0
              ? MeridianLayout.tabLabelMaxWidth
              : ((available - chipsWidth - gaps) / shownTabs).clamp(
                  MeridianLayout.tabPillMinWidth,
                  MeridianLayout.tabLabelMaxWidth,
                );

          // While dragging, the others make room where the drag would land.
          final dragged = <_Key>{};
          var dragStart = 0.0;
          if (drag != null) {
            final rest = _rest(base, drag);
            final restWidths = [
              for (final entry in rest) _width(entry, tabWidth),
            ];
            dragStart = drag.pointer - drag.grab;
            final drop = _dropAt(rest, restWidths, dragStart, drag);
            // The rest keep their chips (even one whose last tab is out on
            // the drag); the dragged entries go in at the drop.
            final moving = [
              for (final entry in base)
                if (!rest.contains(entry))
                  if (entry is _TabEntry<T, G>)
                    _TabEntry<T, G>(
                      entry.tab,
                      drag.tab != null
                          ? widget.groups
                                .where((group) => group.id == drop.group)
                                .firstOrNull
                          : entry.group,
                    )
                  else
                    entry,
            ];
            dragged.addAll(moving.map((entry) => entry.key));
            entries = _withGhosts([
              ...rest.take(drop.slot),
              ...moving,
              ...rest.skip(drop.slot),
            ]);
          }

          final widths = [for (final entry in entries) _width(entry, tabWidth)];
          final starts = _starts(widths);
          final animate = _built && !reduced;

          // Each entry heads for its place; a dragged one follows the
          // pointer.
          final live = <_Key>{};
          var blockOffset = 0.0;
          for (final (index, entry) in entries.indexed) {
            final key = entry.key;
            live.add(key);
            final width = widths[index];
            var x = starts[index];
            if (dragged.contains(key)) {
              x = dragStart + blockOffset;
              if (width > 0) blockOffset += width + MeridianSpace.space2;
            }
            final slot = _slots[key];
            if (slot == null) {
              // A new tab grows in where it stands.
              _slots[key] = _Slot(x, animate ? 0 : width)
                ..moveTo(x, width, now, layoutDuration);
            } else if (dragged.contains(key)) {
              slot.jump(x, width);
            } else {
              slot.moveTo(
                x,
                width,
                now,
                animate ? layoutDuration : Duration.zero,
              );
            }
          }
          _slots.removeWhere((key, _) => !live.contains(key));

          // The active pill glides to the active tab.
          final active = widget.activeTab;
          final _Key? activeKey = active == null ? null : ('tab', active);
          final activeSlot = activeKey == null ? null : _slots[activeKey];
          if (activeSlot != null) {
            final index = entries.indexWhere((entry) => entry.key == activeKey);
            final x = dragged.contains(activeKey)
                ? activeSlot.x(now)
                : starts[index];
            final width = widths[index];
            final indicator = _indicator;
            if (indicator == null || !animate) {
              _indicator = _Slot(x, width);
            } else if (dragged.contains(activeKey)) {
              indicator.jump(x, width);
            } else if (_indicatorFor != widget.activeTab) {
              indicator.moveTo(
                x,
                width,
                now,
                MeridianMotion.of(context, MeridianDurations.select),
                curve: MeridianDurations.selectCurve,
              );
            } else {
              indicator.moveTo(x, width, now, layoutDuration);
            }
            _indicatorFor = widget.activeTab;
          } else {
            _indicator = null;
            _indicatorFor = null;
          }
          _built = true;
          if (_slots.values.any((slot) => slot.animating(now)) ||
              (_indicator?.animating(now) ?? false)) {
            _animate();
          }

          final children = <Widget>[];
          final lifted = <Widget>[];

          // Rules run under each open group's chip and tabs.
          final spans = <G, (double, double, Color)>{};
          for (final entry in entries) {
            final group = entry.group;
            if (group == null || group.collapsed) continue;
            if (entry is _TabEntry<T, G> && entry.closing) continue;
            final slot = _slots[entry.key]!;
            final left = slot.x(now);
            final right = left + slot.w(now);
            final span = spans[group.id];
            spans[group.id] = span == null
                ? (left, right, group.color)
                : (math.min(span.$1, left), math.max(span.$2, right), span.$3);
          }
          for (final MapEntry(key: id, value: (left, right, color))
              in spans.entries) {
            children.add(
              Positioned(
                key: ValueKey(('tab-group-rule', id)),
                left: left,
                width: math.max(0, right - left),
                bottom: MeridianLayout.tabGroupRuleInset,
                height: MeridianLayout.tabRuleHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(
                      MeridianRadiusScale.pill,
                    ),
                  ),
                ),
              ),
            );
          }

          if (_indicator case final indicator?) {
            children.add(
              Positioned(
                key: const ValueKey('tab-strip-indicator'),
                left: indicator.x(now),
                width: indicator.w(now),
                top: 0,
                bottom: 0,
                child: Center(
                  child: SizedBox(
                    height: MeridianLayout.tabPillHeight,
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.pane,
                        borderRadius: BorderRadius.circular(meridian.radius.md),
                        boxShadow: meridian.shadows.shadowPane,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          // Resting tabs have no fill: a hairline in the gap marks where
          // one ends. The active pill already has its own edge.
          for (var index = 0; index < entries.length - 1; index++) {
            final entry = entries[index];
            if (entry is! _TabEntry<T, G> || entry.closing || entry.hidden) {
              continue;
            }
            _Entry<T, G>? next;
            for (var after = index + 1; after < entries.length; after++) {
              if (widths[after] > 0) {
                next = entries[after];
                break;
              }
            }
            final separated =
                next is _TabEntry<T, G> &&
                drag == null &&
                entry.tab.id != widget.activeTab &&
                next.tab.id != widget.activeTab;
            final slot = _slots[entry.key]!;
            children.add(
              Positioned(
                key: ValueKey(('tab-separator', entry.tab.id)),
                left: slot.x(now) + slot.w(now),
                width: MeridianSpace.space2,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: separated ? 1 : 0,
                    duration: MeridianMotion.of(
                      context,
                      MeridianDurations.exit,
                    ),
                    child: SizedBox(
                      width: MeridianLayout.hairline,
                      height: MeridianLayout.tabSeparatorHeight,
                      child: ColoredBox(color: colors.lineStrong),
                    ),
                  ),
                ),
              ),
            );
          }

          var right = 0.0;
          for (final (index, entry) in entries.indexed) {
            final slot = _slots[entry.key]!;
            final x = slot.x(now);
            final width = slot.w(now);
            right = math.max(right, x + width);
            final isLifted = dragged.contains(entry.key);
            var body = _entry(entry, tabWidth, lifted: isLifted);
            final full = entry is _TabEntry<T, G> ? tabWidth : widths[index];
            if (width < full - 0.5) {
              // Growing in or collapsing: laid out whole, clipped.
              body = ClipRect(
                child: OverflowBox(
                  alignment: AlignmentDirectional.centerStart,
                  minWidth: full,
                  maxWidth: full,
                  child: body,
                ),
              );
            }
            if (entry is _TabEntry<T, G> && entry.closing) {
              body = Opacity(
                opacity: (width / tabWidth).clamp(0.0, 1.0),
                child: body,
              );
            }
            final positioned = Positioned(
              key: ValueKey(entry.key),
              left: x,
              width: width,
              top: 0,
              bottom: 0,
              child: body,
            );
            (isLifted ? lifted : children).add(positioned);
          }
          children.addAll(lifted);

          final total = math.max(
            right,
            starts.isEmpty ? 0.0 : starts.last + widths.last,
          );
          final content = SizedBox(
            key: _content,
            width: total,
            child: Stack(clipBehavior: Clip.none, children: children),
          );
          return SizedBox(
            width: math.min(total, available),
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: content,
            ),
          );
        },
      ),
    );
  }

  Widget _entry(_Entry<T, G> entry, double tabWidth, {required bool lifted}) {
    final labels = widget.labels;
    switch (entry) {
      case _ChipEntry(:final group, :final count):
        final editing = !lifted && group.id == _renamingGroup;
        Widget chip = _GroupChip(
          group: group,
          count: count,
          width: _chipWidth(entry),
          editing: editing,
          lifted: lifted,
          labels: labels,
          maxLength: widget.nameMaxLength,
          onToggle: widget.onToggleGroup == null
              ? null
              : () => widget.onToggleGroup!(group.id),
          onContextMenu: widget.onGroupContextMenu == null
              ? null
              : (position) => widget.onGroupContextMenu!(group.id, position),
          onRenamed: (name) => _finishGroupRename(group.id, name),
        );
        if (widget.onMoveGroup != null && !editing) {
          chip = _dragHandle(entry.key, chip);
        }
        return chip;
      case _TabEntry(:final tab, closing: true):
        // Closed: fades while it collapses.
        return IgnorePointer(
          child: ExcludeSemantics(
            child: ExcludeFocus(
              child: _pill(tab, tabWidth, lifted: false, ghost: true),
            ),
          ),
        );
      case _TabEntry(:final tab):
        final hidden = entry.hidden;
        Widget pill = _pill(tab, tabWidth, lifted: lifted);
        if (hidden) {
          pill = IgnorePointer(
            child: ExcludeSemantics(child: ExcludeFocus(child: pill)),
          );
        } else if (widget.onMoveTab != null && tab.id != _renamingTab) {
          pill = _dragHandle(entry.key, pill);
        }
        return pill;
    }
  }

  Widget _dragHandle(_Key key, Widget child) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    dragStartBehavior: DragStartBehavior.down,
    onHorizontalDragStart: (details) => _startDrag(key, details),
    onHorizontalDragUpdate: _updateDrag,
    onHorizontalDragEnd: (_) => _released(key),
    onHorizontalDragCancel: () => setState(() => _endDrag(drop: false)),
    child: child,
  );

  Widget _pill(
    MeridianStripTab<T, G> tab,
    double width, {
    required bool lifted,
    bool ghost = false,
  }) {
    final labels = widget.labels;
    final onClose = widget.onClose;
    final onContextMenu = widget.onContextMenu;
    final index = widget.tabs.indexWhere((other) => other.id == tab.id);
    return _TabPill(
      key: ValueKey(('tab-pill', tab.id)),
      label: tab.label,
      tooltip: tab.tooltip ?? tab.label,
      semanticLabel: [
        tab.semanticLabel ?? tab.label,
        if (tab.dirty) labels.dirty ?? 'unsaved changes',
      ].join(', '),
      leading: tab.leading,
      dirty: tab.dirty,
      width: width,
      selected: !ghost && tab.id == widget.activeTab,
      lifted: lifted,
      editing: !ghost && !lifted && tab.id == _renamingTab,
      renamePlaceholder: tab.renamePlaceholder ?? tab.label,
      renameLabel: labels.renameTab ?? 'Tab name',
      maxLength: widget.nameMaxLength,
      closeLabel: labels.close?.call(tab.label) ?? 'Close ${tab.label}',
      onActivate: ghost ? null : () => _tapped(tab),
      onClose: ghost || onClose == null ? null : () => onClose(tab.id),
      onRenamed: (name) => _finishTabRename(tab.id, name),
      onContextMenu: ghost || onContextMenu == null
          ? null
          : (position) => onContextMenu(tab.id, position),
      moveActions: ghost || widget.onMoveTab == null
          ? const {}
          : {
              if (index > 0)
                CustomSemanticsAction(
                  label: labels.moveLeft ?? 'Move left',
                ): () =>
                    _step(tab, -1),
              if (index >= 0 && index < widget.tabs.length - 1)
                CustomSemanticsAction(
                  label: labels.moveRight ?? 'Move right',
                ): () =>
                    _step(tab, 1),
            },
    );
  }
}

/// A pill being edited: no hover, no press.
const _idle = MeridianInteractionState(
  hovered: false,
  pressed: false,
  focused: false,
  enabled: true,
);

/// Opens a context menu for the menu key or Shift+F10 on [child].
Widget _menuKeys(Widget child, ValueChanged<Offset> onContextMenu) => Focus(
  canRequestFocus: false,
  skipTraversal: true,
  onKeyEvent: (node, event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.contextMenu ||
            (event.logicalKey == LogicalKeyboardKey.f10 &&
                HardwareKeyboard.instance.isShiftPressed))) {
      final box = node.context?.findRenderObject();
      if (box is RenderBox) {
        onContextMenu(box.localToGlobal(Offset(0, box.size.height)));
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  },
  child: child,
);

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.tooltip,
    required this.semanticLabel,
    required this.dirty,
    required this.width,
    required this.selected,
    required this.lifted,
    required this.editing,
    required this.renamePlaceholder,
    required this.renameLabel,
    required this.closeLabel,
    required this.onRenamed,
    required this.moveActions,
    this.leading,
    this.maxLength,
    this.onActivate,
    this.onClose,
    this.onContextMenu,
    super.key,
  });

  final String label;
  final String tooltip;
  final String semanticLabel;
  final Widget? leading;
  final bool dirty;
  final double width;
  final bool selected;

  /// The dragged pill paints its own fill: the active pill's indicator
  /// stays in the strip.
  final bool lifted;
  final bool editing;
  final String renamePlaceholder;
  final String renameLabel;
  final int? maxLength;
  final String closeLabel;
  final VoidCallback? onActivate;
  final VoidCallback? onClose;
  final ValueChanged<String?> onRenamed;
  final ValueChanged<Offset>? onContextMenu;
  final Map<CustomSemanticsAction, VoidCallback> moveActions;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final radius = BorderRadius.circular(meridian.radius.md);
    final onContextMenu = this.onContextMenu;
    Widget pill(MeridianInteractionState state) {
      final content = AnimatedContainer(
        duration: meridianHoverDuration(context, state.hovered),
        // Close keeps the trailing edge whatever the label's width.
        width: width,
        height: MeridianLayout.tabPillHeight,
        padding: const EdgeInsetsDirectional.only(
          start: MeridianSpace.space4,
          end: MeridianSpace.space3,
        ),
        decoration: BoxDecoration(
          color: lifted
              ? colors.pane
              : !selected && (state.hovered || editing)
              ? colors.groundHover
              : meridianClear(colors.groundHover),
          borderRadius: radius,
        ),
        // Editing in place draws the field's focus edge on the pill.
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: editing ? colors.focus : meridianClear(colors.focus),
          ),
        ),
        child: Row(
          children: [
            if (leading case final leading?) ...[
              leading,
              const SizedBox(width: MeridianSpace.space3),
            ],
            Expanded(
              child: editing
                  ? _InlineName(
                      initial: label,
                      placeholder: renamePlaceholder,
                      label: renameLabel,
                      maxLength: maxLength,
                      height:
                          MeridianLayout.tabPillHeight - MeridianSpace.space2,
                      onDone: onRenamed,
                    )
                  : Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: meridian.text.label.copyWith(
                              color: selected || lifted || state.hovered
                                  ? colors.ink
                                  : colors.inkMuted,
                            ),
                          ),
                        ),
                        _DirtyDot(dirty: dirty),
                      ],
                    ),
            ),
            const SizedBox(width: MeridianSpace.space3),
            if ((selected || lifted || state.hovered) &&
                !editing &&
                onClose != null)
              _Close(label: closeLabel, onPressed: onClose!)
            else
              const SizedBox(width: MeridianLayout.tabCloseSize),
          ],
        ),
      );
      return lifted
          ? MeridianLift(lifted: true, borderRadius: radius, child: content)
          : content;
    }

    if (editing) return Center(child: pill(_idle));
    Widget result = MeridianTooltip(
      message: tooltip,
      child: Semantics(
        excludeSemantics: true,
        button: true,
        selected: selected,
        label: semanticLabel,
        onTap: onActivate,
        customSemanticsActions: moveActions,
        child: MeridianInteraction(
          onTap: onActivate,
          borderRadius: radius,
          // The strip is taller than a tab; the pill stays centred.
          builder: (context, state) => Center(child: pill(state)),
        ),
      ),
    );
    if (lifted) return result;
    result = GestureDetector(
      // A middle click closes the tab, as in browsers.
      onTertiaryTapUp: onClose == null ? null : (_) => onClose!(),
      onSecondaryTapUp: onContextMenu == null
          ? null
          : (details) => onContextMenu(details.globalPosition),
      child: result,
    );
    if (onContextMenu == null) return result;
    return _menuKeys(result, onContextMenu);
  }
}

class _Close extends StatelessWidget {
  const _Close({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final radius = BorderRadius.circular(meridian.radius.xs);
    return MeridianTooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        onTap: onPressed,
        child: MeridianInteraction(
          onTap: onPressed,
          borderRadius: radius,
          builder: (context, state) => AnimatedContainer(
            duration: meridianHoverDuration(
              context,
              state.hovered || state.pressed,
            ),
            width: MeridianLayout.tabCloseSize,
            height: MeridianLayout.tabCloseSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: state.fill(
                rest: meridianClear(colors.ink),
                hoverFill: colors.ink.withValues(
                  alpha: MeridianOpacity.primaryHoverOverlay,
                ),
                ink: colors.ink,
              ),
              borderRadius: radius,
            ),
            child: MeridianIcon(
              MeridianIcons.x,
              extent: MeridianLayout.tabCloseIconSize,
              color: state.hovered || state.pressed
                  ? colors.ink
                  : colors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// A group's chip, before its tabs: the icon and name (or a colour dot)
/// on a tint of the group's colour, and the tab count while collapsed or
/// dragged. A click collapses or expands the group.
class _GroupChip<G extends Object> extends StatelessWidget {
  const _GroupChip({
    required this.group,
    required this.count,
    required this.width,
    required this.editing,
    required this.lifted,
    required this.labels,
    required this.onRenamed,
    this.maxLength,
    this.onToggle,
    this.onContextMenu,
  });

  final MeridianStripGroup<G> group;
  final int count;
  final double width;
  final bool editing;
  final bool lifted;
  final MeridianTabStripLabels labels;
  final int? maxLength;
  final ValueChanged<String?> onRenamed;
  final VoidCallback? onToggle;
  final ValueChanged<Offset>? onContextMenu;

  static TextStyle _nameStyle(BuildContext context) =>
      MeridianTheme.of(context).text.label;

  static TextStyle _countStyle(BuildContext context) =>
      MeridianTextStyles.numeric(MeridianTheme.of(context).text.caption);

  /// The chip's width: the icon, the name up to its limit or the dot, and
  /// the count while collapsed.
  static double widthFor<G extends Object>(
    BuildContext context,
    MeridianStripGroup<G> group,
    int count, {
    required bool editing,
  }) {
    if (editing) return MeridianLayout.tabGroupChipEditWidth;
    final scaler = MediaQuery.textScalerOf(context);
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final icon = group.icon == null
        ? null
        : MeridianTheme.of(context).density.iconSmallSize;
    final name = group.name.isEmpty
        ? null
        : math.min(
            measure(group.name, _nameStyle(context)),
            MeridianLayout.tabGroupChipLabelMaxWidth,
          );
    var content = switch ((icon, name)) {
      (final icon?, final name?) => icon + MeridianSpace.space3 + name,
      (final icon?, null) => icon,
      (null, final name?) => name,
      (null, null) => MeridianLayout.tabGroupDot,
    };
    if (group.collapsed) {
      content += MeridianSpace.space3 + measure('$count', _countStyle(context));
    }
    // A lone mark sits in a square chip.
    final padding = name != null || group.collapsed
        ? MeridianSpace.space4
        : (MeridianLayout.tabGroupChipHeight -
                  (icon ?? MeridianLayout.tabGroupDot)) /
              2;
    return (content + padding * 2).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final meridian = MeridianTheme.of(context);
    final colors = meridian.colors;
    final color = group.color;
    final name = group.name.isNotEmpty
        ? group.name
        : group.label ?? 'Unnamed group';
    final radius = BorderRadius.circular(meridian.radius.md);
    final icon = group.icon;
    Widget chip(MeridianInteractionState state) => AnimatedContainer(
      duration: meridianHoverDuration(context, state.hovered),
      width: width,
      height: MeridianLayout.tabGroupChipHeight,
      padding: EdgeInsets.symmetric(
        horizontal: editing ? MeridianSpace.space3 : 0,
      ),
      decoration: BoxDecoration(
        // A lifted chip lays its tint over the pane's fill.
        color: lifted
            ? Color.alphaBlend(
                color.withValues(alpha: MeridianOpacity.tabGroupFillHover),
                colors.pane,
              )
            : color.withValues(
                alpha: state.hovered || editing
                    ? MeridianOpacity.tabGroupFillHover
                    : MeridianOpacity.tabGroupFill,
              ),
        borderRadius: radius,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: editing ? colors.focus : meridianClear(colors.focus),
        ),
      ),
      child: editing
          ? _InlineName(
              initial: group.name,
              placeholder: labels.groupNamePlaceholder ?? 'Name this group',
              label: labels.renameGroup ?? 'Group name',
              style: _nameStyle(context),
              maxLength: maxLength,
              height: MeridianLayout.tabGroupChipHeight,
              onDone: onRenamed,
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  MeridianIcon(
                    icon,
                    key: const ValueKey('tab-group-icon'),
                    size: MeridianIconSize.small,
                    color: color,
                  ),
                  if (group.name.isNotEmpty)
                    const SizedBox(width: MeridianSpace.space3),
                ],
                if (group.name.isNotEmpty)
                  Flexible(
                    child: Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _nameStyle(context).copyWith(color: colors.ink),
                    ),
                  )
                else if (icon == null)
                  Container(
                    width: MeridianLayout.tabGroupDot,
                    height: MeridianLayout.tabGroupDot,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (group.collapsed) ...[
                  const SizedBox(width: MeridianSpace.space3),
                  Text(
                    '$count',
                    style: _countStyle(context)
                        .copyWith(color: colors.inkMuted),
                  ),
                ],
              ],
            ),
    );
    final key = ValueKey(('tab-group-chip', group.id));
    if (editing) {
      return KeyedSubtree(
        key: key,
        child: Center(child: chip(_idle)),
      );
    }
    if (lifted) {
      return Center(
        key: key,
        child: MeridianLift(
          lifted: true,
          borderRadius: radius,
          child: chip(_idle),
        ),
      );
    }
    final action = group.collapsed
        ? labels.expandGroup?.call(name) ?? 'Expand $name'
        : labels.collapseGroup?.call(name) ?? 'Collapse $name';
    final onContextMenu = this.onContextMenu;
    Widget result = MeridianTooltip(
      message: action,
      child: Semantics(
        excludeSemantics: true,
        button: true,
        expanded: !group.collapsed,
        label:
            labels.group?.call(name, count) ?? '$name, tab group, $count tabs',
        onTap: onToggle,
        child: MeridianInteraction(
          key: key,
          onTap: onToggle,
          borderRadius: radius,
          builder: (context, state) => Center(child: chip(state)),
        ),
      ),
    );
    if (onContextMenu == null) return result;
    result = GestureDetector(
      onSecondaryTapUp: (details) => onContextMenu(details.globalPosition),
      child: result,
    );
    return _menuKeys(result, onContextMenu);
  }
}

/// A name edited in place: starts with [initial] selected; Enter or
/// leaving the field keeps it, Escape cancels (`null`).
class _InlineName extends StatefulWidget {
  const _InlineName({
    required this.initial,
    required this.placeholder,
    required this.label,
    required this.onDone,
    required this.height,
    this.style,
    this.maxLength,
  });

  final String initial;
  final double height;
  final String placeholder;
  final String label;
  final TextStyle? style;
  final int? maxLength;
  final ValueChanged<String?> onDone;

  @override
  State<_InlineName> createState() => _InlineNameState();
}

class _InlineNameState extends State<_InlineName> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.initial.length,
        );
  final FocusNode _focus = FocusNode(debugLabel: 'meridian-tab-name');
  var _done = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _finish(_controller.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _finish(String? name) {
    if (_done) return;
    _done = true;
    widget.onDone(name);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () => _finish(null),
    },
    child: Semantics(
      label: widget.label,
      textField: true,
      child: MeridianTextField(
        controller: _controller,
        focusNode: _focus,
        variant: MeridianTextFieldVariant.plain,
        size: MeridianControlSize.small,
        width: 0,
        height: widget.height,
        textStyle: widget.style ?? MeridianTheme.of(context).text.label,
        placeholder: widget.placeholder,
        maxLength: widget.maxLength,
        textInputAction: TextInputAction.done,
        onSubmitted: _finish,
      ),
    ),
  );
}

/// A tab's unsaved-changes dot: pops in on `spring-pop`, shrinks out over
/// `motion-exit`.
class _DirtyDot extends StatefulWidget {
  const _DirtyDot({required this.dirty});

  final bool dirty;

  @override
  State<_DirtyDot> createState() => _DirtyDotState();
}

class _DirtyDotState extends State<_DirtyDot>
    with SingleTickerProviderStateMixin {
  late final MeridianSpringController _scale = MeridianSpringController(
    vsync: this,
    value: widget.dirty ? 1 : 0,
  );

  @override
  void didUpdateWidget(_DirtyDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dirty == oldWidget.dirty) return;
    if (widget.dirty) {
      _scale.animateTo(
        1,
        spring: MeridianSprings.pop,
        reduced: MeridianMotion.reduced(context),
      );
    } else {
      _scale.animateToTimed(
        0,
        duration: MeridianMotion.of(context, MeridianDurations.exit),
        curve: MeridianDurations.exitCurve,
      );
    }
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _scale.animation,
    builder: (context, child) {
      if (!widget.dirty && _scale.value <= 0) return const SizedBox.shrink();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: MeridianSpace.space2),
          Transform.scale(
            key: const ValueKey('tab-dirty-dot'),
            scale: math.max(0, _scale.value),
            child: child,
          ),
        ],
      );
    },
    child: Container(
      width: MeridianLayout.statusDot,
      height: MeridianLayout.statusDot,
      decoration: BoxDecoration(
        color: MeridianTheme.of(context).colors.warning,
        shape: BoxShape.circle,
      ),
    ),
  );
}
