import 'package:flutter/widgets.dart';
import 'package:meridian_ui/meridian_ui.dart';

/// A [MeridianTabStrip] that keeps its own tabs: drags, closes, renames
/// and group toggles all take effect, as they would in an app.
class TabStripDemo extends StatefulWidget {
  const TabStripDemo({
    super.key,
    this.count = 6,
    this.grouped = true,
    this.collapsed = false,
    this.groupIcon = true,
    this.dirty = true,
  });

  final int count;
  final bool grouped;
  final bool collapsed;
  final bool groupIcon;
  final bool dirty;

  @override
  State<TabStripDemo> createState() => _TabStripDemoState();
}

const _repositories = [
  'GitLama',
  'CrossProton',
  'Mimameidr',
  'Nibluma',
  'meridian_ui',
  'devmil-git',
];

class _TabStripDemoState extends State<TabStripDemo> {
  late List<(String, int?)> _tabs;
  late Map<int, (String, bool)> _groups;
  final Map<String, String> _names = {};
  String? _active;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(TabStripDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count ||
        oldWidget.grouped != widget.grouped ||
        oldWidget.collapsed != widget.collapsed) {
      _reset();
    }
  }

  void _reset() {
    _tabs = [
      for (var i = 0; i < widget.count; i++)
        (
          i < _repositories.length ? _repositories[i] : 'Repository ${i + 1}',
          widget.grouped && (i == 1 || i == 2) ? 1 : null,
        ),
    ];
    _groups = {if (widget.grouped) 1: ('Apps', widget.collapsed)};
    _active = _tabs.first.$1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.meridian.colors;
    final used = {for (final (_, group) in _tabs) group};
    return MeridianTabStrip<String, int>(
      tabs: [
        for (final (id, group) in _tabs)
          MeridianStripTab(
            id: id,
            label: _names[id] ?? id,
            group: group,
            dirty: widget.dirty && id == _tabs.first.$1,
            leading: MeridianIcon(
              MeridianIcons.folder,
              size: MeridianIconSize.small,
              color: colors.inkMuted,
            ),
          ),
      ],
      groups: [
        for (final MapEntry(key: id, value: (name, collapsed))
            in _groups.entries)
          if (used.contains(id))
            MeridianStripGroup(
              id: id,
              color: colors.series[5],
              name: name,
              icon: widget.groupIcon ? MeridianIcons.star : null,
              collapsed: collapsed,
              label: 'Violet group',
            ),
      ],
      activeTab: _active,
      onActivate: (id) => setState(() => _active = id),
      onClose: (id) => setState(() {
        final index = _tabs.indexWhere((tab) => tab.$1 == id);
        _tabs.removeAt(index);
        if (_active == id) {
          _active = _tabs.isEmpty
              ? null
              : _tabs[index.clamp(0, _tabs.length - 1)].$1;
        }
      }),
      onMoveTab: (id, index, group) => setState(() {
        _tabs.removeWhere((tab) => tab.$1 == id);
        _tabs.insert(index, (id, group));
      }),
      onMoveGroup: (group, index) => setState(() {
        final members = [
          for (final tab in _tabs)
            if (tab.$2 == group) tab,
        ];
        _tabs.removeWhere((tab) => tab.$2 == group);
        _tabs.insertAll(index, members);
      }),
      onRenameTab: (id, name) =>
          setState(() => name.isEmpty ? _names.remove(id) : _names[id] = name),
      onToggleGroup: (id) => setState(() {
        final (name, collapsed) = _groups[id]!;
        _groups[id] = (name, !collapsed);
        // A collapsed group never hides the active tab.
        if (!collapsed &&
            _tabs.any((tab) => tab.$1 == _active && tab.$2 == id)) {
          _active = _tabs
              .where((tab) => tab.$2 != id)
              .map((tab) => tab.$1)
              .firstOrNull;
          if (_active == null) _groups[id] = (name, false);
        }
      }),
      onRenameGroup: (id, name) =>
          setState(() => _groups[id] = (name, _groups[id]!.$2)),
    );
  }
}
