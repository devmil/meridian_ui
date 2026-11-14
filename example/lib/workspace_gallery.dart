import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:meridian_ui/meridian_ui.dart';

import 'motion_gallery.dart';
import 'syntax_sample.dart';

/// Sample source the find bar and the code view search.
const sampleSource = [
  'import "package:meridian_ui/meridian_ui.dart";',
  '',
  'void main() {',
  '  final greeting = "Hello, Meridian";',
  '  print(greeting);',
  '  // A line long enough to scroll sideways together with every other line of this view.',
  '  print(greeting.toUpperCase());',
  '}',
];

/// The workspace section: find bar, section headers, split pane, code
/// lines, loading states, colour choices and the dialog contract.
Widget workspaceSection(BuildContext context, SectionBuilder section) =>
    section('Workspace: find, headers, split panes and code', const [
      WorkspaceDemos(),
    ]);

class WorkspaceDemos extends StatefulWidget {
  const WorkspaceDemos({super.key});

  @override
  State<WorkspaceDemos> createState() => _WorkspaceDemosState();
}

class _WorkspaceDemosState extends State<WorkspaceDemos> {
  final _query = TextEditingController();
  final _scroll = ScrollController();
  var _caseSensitive = false;
  var _matches = <int, List<TextRange>>{};
  int? _current;
  var _findVisible = true;
  var _ratio = 0.4;
  MeridianColorChoice? _color = const MeridianSeriesColor(1);
  var _loading = 0.4;

  @override
  void dispose() {
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<int> get _matchLines => _matches.keys.toList()..sort();

  void _search(String query) {
    final found = <int, List<TextRange>>{};
    if (query.isNotEmpty) {
      final needle = _caseSensitive ? query : query.toLowerCase();
      for (final (index, line) in sampleSource.indexed) {
        final hay = _caseSensitive ? line : line.toLowerCase();
        var start = hay.indexOf(needle);
        while (start >= 0) {
          (found[index] ??= []).add(
            TextRange(start: start, end: start + needle.length),
          );
          start = hay.indexOf(needle, start + needle.length);
        }
      }
    }
    setState(() {
      _matches = found;
      _current = found.isEmpty ? null : 0;
    });
  }

  void _step(int delta) {
    final lines = _matchLines;
    if (lines.isEmpty) {
      _search(_query.text);
      return;
    }
    setState(() => _current = ((_current ?? -1) + delta) % lines.length);
  }

  Future<void> _confirm() async {
    final confirmed = await showMeridianConfirm(
      context,
      title: 'Delete branch feature/login',
      description: 'The branch has commits that are on no other branch.',
      content: const MeridianPropertyList(
        properties: [
          MeridianProperty(label: 'Commits', value: '3'),
          MeridianProperty(label: 'Last commit', value: '2 days ago'),
        ],
      ),
      confirmLabel: 'Delete branch',
      destructive: true,
      barrierDismissible: false,
    );
    if (mounted) {
      showMeridianToast(context, message: confirmed ? 'Deleted' : 'Kept');
    }
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: 'feature/login');
    final name = await showMeridianDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final valid = controller.text.trim().isNotEmpty;
          void submit() => Navigator.pop(context, controller.text.trim());
          return MeridianDialog(
            title: 'Rename branch',
            width: MeridianLayout.dialogFormWidth,
            onSubmit: valid ? submit : null,
            submitDisabled: !valid,
            content: MeridianTextField(
              label: 'New name',
              controller: controller,
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            actions: [
              MeridianButton(
                label: 'Cancel',
                variant: MeridianButtonVariant.quiet,
                onPressed: () => Navigator.pop(context),
              ),
              MeridianButton(
                label: 'Rename branch',
                variant: MeridianButtonVariant.primary,
                disabledReason: valid ? null : 'Enter a name',
                onPressed: valid ? submit : null,
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    if (name != null && mounted) {
      showMeridianToast(context, message: 'Renamed to $name');
    }
  }

  @override
  Widget build(BuildContext context) {
    final meridian = context.meridian;
    final lines = _matchLines;
    final current = _current == null ? null : lines[_current!];
    Widget caption(String text) => Padding(
      padding: const EdgeInsets.only(
        top: MeridianSpace.space6,
        bottom: MeridianSpace.space3,
      ),
      child: Text(
        text,
        style: meridian.text.caption.copyWith(color: meridian.colors.inkMuted),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        caption('Find bar over code lines (Enter, Shift+Enter, Escape)'),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: meridian.colors.line),
            borderRadius: BorderRadius.circular(meridian.radius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MeridianSectionHeader(
                icon: MeridianIcons.fileText,
                title: 'main.dart',
                caption: const Text('8 lines'),
                actions: [
                  MeridianIconButton(
                    label: _findVisible ? 'Hide find' : 'Find',
                    icon: MeridianIcons.search,
                    size: MeridianControlSize.small,
                    active: _findVisible,
                    onPressed: () =>
                        setState(() => _findVisible = !_findVisible),
                  ),
                ],
              ),
              MeridianFindBar(
                visible: _findVisible,
                controller: _query,
                matchCount: lines.length,
                currentMatch: _current,
                caseSensitive: _caseSensitive,
                onCaseSensitiveChanged: (value) {
                  _caseSensitive = value;
                  _search(_query.text);
                },
                onChanged: _search,
                onNext: () => _step(1),
                onPrevious: () => _step(-1),
                onClose: () => setState(() => _findVisible = false),
              ),
              SizedBox(
                height: 150,
                child: MeridianCodeLines(
                  lines: sampleSource,
                  controller: _scroll,
                  marks: _matches,
                  highlightedLines: _matches.keys.toSet(),
                  currentLine: current,
                  markers: const {
                    3: MeridianCodeMarker('+', semanticLabel: 'Added'),
                  },
                  syntax: sampleSyntax(sampleSource),
                ),
              ),
            ],
          ),
        ),
        caption('Section headers'),
        MeridianSectionHeader(
          title: 'Unstaged',
          count: 12,
          actions: [
            MeridianIconButton(
              label: 'Stage all',
              icon: MeridianIcons.plus,
              size: MeridianControlSize.small,
              onPressed: () {},
            ),
          ],
        ),
        const MeridianSectionHeader(
          title: 'Details',
          size: MeridianSectionHeaderSize.small,
          caption: Text('3 of 12'),
          divider: false,
        ),
        caption('Split pane (drag, arrow keys, double click resets)'),
        SizedBox(
          height: 140,
          child: MeridianSplitPane(
            ratio: _ratio,
            initialRatio: 0.4,
            firstMinExtent: 120,
            secondMinExtent: 120,
            semanticLabel: 'Resize lists',
            onRatioChanged: (value) => setState(() => _ratio = value),
            onReset: () => setState(() => _ratio = 0.4),
            first: const MeridianIsland(
              title: 'Staged',
              expandChild: true,
              child: Center(child: Text('Staged files')),
            ),
            second: const MeridianIsland(
              title: 'Unstaged',
              expandChild: true,
              child: Center(child: Text('Unstaged files')),
            ),
          ),
        ),
        caption('Loading states'),
        Wrap(
          spacing: MeridianSpace.space4,
          runSpacing: MeridianSpace.space4,
          children: [
            const SizedBox(
              width: 240,
              height: 150,
              child: MeridianEmptyState(
                title: 'Loading history…',
                progress: true,
                compact: true,
              ),
            ),
            SizedBox(
              width: 240,
              height: 170,
              child: MeridianEmptyState(
                title: 'Indexing files',
                message: '${(_loading * 100).round()}% done',
                progress: true,
                progressValue: _loading,
                compact: true,
                action: MeridianButton(
                  label: 'Step',
                  size: MeridianControlSize.small,
                  onPressed: () =>
                      setState(() => _loading = (_loading + 0.2) % 1.2),
                ),
              ),
            ),
          ],
        ),
        caption('Colour choice (localized names)'),
        MeridianColorChoiceRow(
          value: _color,
          allowNone: true,
          onChanged: (value) => setState(() => _color = value),
        ),
        caption('Dialog contract'),
        Wrap(
          spacing: MeridianSpace.space4,
          runSpacing: MeridianSpace.space3,
          children: [
            MeridianButton(
              label: 'Delete branch…',
              variant: MeridianButtonVariant.dangerQuiet,
              onPressed: () => unawaited(_confirm()),
            ),
            MeridianButton(
              label: 'Rename branch…',
              onPressed: () => unawaited(_rename()),
            ),
          ],
        ),
        caption('Status bar items and a pressable avatar'),
        Row(
          children: [
            MeridianAvatar(
              name: 'Ada Lovelace',
              size: MeridianAvatarSize.large,
              tooltip: 'Show profile',
              onPressed: () => showMeridianToast(context, message: 'Profile'),
            ),
            const SizedBox(width: MeridianSpace.space4),
            Expanded(
              child: MeridianStatusBar(
                leading: [
                  MeridianStatusBarItem(
                    icon: MeridianIcons.gitBranch,
                    label: 'feature/login',
                    maxWidth: 160,
                    tooltip: 'Switch branch',
                    onPressed: () {},
                  ),
                  const MeridianStatusBarItem(label: 'Ready'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
