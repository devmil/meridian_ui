import 'package:flutter/material.dart';
import 'package:meridian_ui/meridian_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import '../syntax_sample.dart';
import 'support.dart';

WidgetbookFolder dataFolder() => WidgetbookFolder(
  name: 'Data and window',
  children: [
    WidgetbookComponent(
      name: 'Waveform',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final count = context.knobs.int.slider(
              label: 'Peaks',
              initialValue: 64,
              min: 0,
              max: MeridianWaveform.maximumPeaks,
            );
            final amplitude = context.knobs.double.slider(
              label: 'Amplitude',
              initialValue: 0.8,
              min: 0,
              max: 1,
            );
            final height = context.knobs.double.slider(
              label: 'Height',
              initialValue: MeridianLayout.waveformHeight,
              min: 8,
              max: 72,
            );
            final progress = context.knobs.doubleOrNull.slider(
              label: 'Progress',
              initialValue: 0.37,
              min: 0,
              max: 1,
              defaultToNull: false,
            );
            return preview(
              SizedBox(
                width: 320,
                child: MeridianWaveform(
                  peaks: List.generate(
                    count,
                    (i) => ((i * 17 % 31) / 30) * amplitude,
                  ),
                  height: height,
                  progress: progress,
                ),
              ),
              maxWidth: 420,
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Property list',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final labelWidth = context.knobs.double.slider(
              label: 'Label width',
              initialValue: MeridianLayout.propertyLabelColumn,
              min: 60,
              max: 240,
              precision: 0,
            );
            final path = context.knobs.string(
              label: 'Executable',
              initialValue:
                  '/System/Library/CoreServices/Dock.app/Contents/MacOS/Dock',
            );
            final maxLines = context.knobs.intOrNull.slider(
              label: 'Executable lines',
              description: 'Null wraps as far as it needs.',
              initialValue: 1,
              min: 1,
              max: 4,
              defaultToNull: true,
            );
            final selectable = context.knobs.boolean(
              label: 'Selectable',
              initialValue: true,
            );
            return preview(
              MeridianPropertyList(
                labelWidth: labelWidth,
                properties: [
                  MeridianProperty(
                    label: 'Parent PID',
                    value: '1',
                    monospace: true,
                    selectable: selectable,
                  ),
                  MeridianProperty(
                    label: 'User',
                    value: 'michael (501)',
                    selectable: selectable,
                  ),
                  MeridianProperty(
                    label: 'Status',
                    value: 'Running',
                    selectable: selectable,
                  ),
                  MeridianProperty(
                    label: 'Executable',
                    value: path,
                    monospace: true,
                    maxLines: maxLines,
                    selectable: selectable,
                  ),
                ],
              ),
              maxWidth: 420,
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Column header',
      useCases: [
        WidgetbookUseCase(
          name: 'Sortable table',
          builder: (context) {
            final sortable = context.knobs.boolean(
              label: 'Sortable',
              initialValue: true,
            );
            const processes = [
              ('Dock', 412, 0.4),
              ('Finder', 388, 1.2),
              ('WindowServer', 151, 8.7),
              ('kernel_task', 0, 3.1),
            ];
            return onGround(
              Stateful<(String, MeridianSortDirection)>(
                initial: const ('cpu', MeridianSortDirection.descending),
                builder: (context, value, set) {
                  final (column, direction) = value;
                  final meridian = context.meridian;
                  final rows = [...processes]
                    ..sort((a, b) {
                      final order = switch (column) {
                        'name' => a.$1.toLowerCase().compareTo(
                          b.$1.toLowerCase(),
                        ),
                        'pid' => a.$2.compareTo(b.$2),
                        _ => a.$3.compareTo(b.$3),
                      };
                      return direction == MeridianSortDirection.ascending
                          ? order
                          : -order;
                    });
                  Widget header(String id, String label, {bool end = false}) =>
                      MeridianColumnHeader(
                        label: label,
                        alignEnd: end,
                        sortDirection: column == id ? direction : null,
                        sortedAscendingLabel: 'sorted ascending',
                        sortedDescendingLabel: 'sorted descending',
                        onPressed: sortable
                            ? () => set((
                                id,
                                column == id &&
                                        direction ==
                                            MeridianSortDirection.descending
                                    ? MeridianSortDirection.ascending
                                    : MeridianSortDirection.descending,
                              ))
                            : null,
                      );
                  Widget cell(String text) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MeridianSpace.space4,
                    ),
                    child: Text(
                      text,
                      textAlign: TextAlign.end,
                      style: MeridianTextStyles.numeric(meridian.text.code),
                    ),
                  );
                  return MeridianIsland(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                                  child: header('pid', 'PID', end: true),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: header('cpu', 'CPU', end: true),
                                ),
                              ],
                            ),
                          ),
                        ),
                        for (final (name, pid, cpu) in rows)
                          MeridianListRow(
                            title: name,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 80, child: cell('$pid')),
                                SizedBox(
                                  width: 80,
                                  child: cell('${cpu.toStringAsFixed(1)} %'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Resize handle',
      useCases: [
        WidgetbookUseCase(
          name: 'Split view',
          builder: (context) {
            final step = context.knobs.double.slider(
              label: 'Keyboard step',
              description: 'Focus the handle and use the arrow keys.',
              initialValue: MeridianLayout.resizeKeyboardStep,
              min: 4,
              max: 64,
              precision: 0,
            );
            return onGround(
              SizedBox(
                height: 220,
                child: LayoutBuilder(
                  builder: (context, constraints) => Stateful<double>(
                    initial: 220,
                    builder: (context, width, set) => Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Expanded(
                          child: MeridianIsland(
                            title: 'Processes',
                            expandChild: true,
                            child: MeridianEmptyState(
                              icon: MeridianIcons.arrowLeftRight,
                              title: 'Drag the divider',
                              message: 'Double-click it to reset.',
                            ),
                          ),
                        ),
                        MeridianResizeHandle(
                          semanticLabel: 'Resize inspector',
                          keyboardStep: step,
                          onDrag: (delta) => set(
                            (width - delta).clamp(
                              120.0,
                              constraints.maxWidth / 2,
                            ),
                          ),
                          onReset: () => set(220),
                        ),
                        SizedBox(
                          width: width.clamp(0, constraints.maxWidth / 2),
                          child: MeridianIsland(
                            title: 'Inspector',
                            expandChild: true,
                            padding: const EdgeInsets.all(MeridianSpace.space5),
                            child: Text('${width.round()} px wide'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Status bar',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final tone = context.enumKnob(
              'Tone',
              MeridianStatusTone.values,
              initial: MeridianStatusTone.success,
            );
            final status = context.knobs.string(
              label: 'Status',
              initialValue: 'Live, polling every second',
            );
            final total = context.knobs.int.slider(
              label: 'Processes',
              initialValue: 412,
              max: 2000,
            );
            final item = context.optionalText('Item', 'feature/login');
            final itemIcon = context.iconKnob(
              'Item icon',
              initial: MeridianIcons.gitBranch,
            );
            final pressable = context.knobs.boolean(
              label: 'Item pressable',
              initialValue: true,
            );
            final maxWidth = context.knobs.doubleOrNull.slider(
              label: 'Item max width',
              initialValue: 160,
              min: 60,
              max: 320,
              precision: 0,
            );
            return onGround(
              MeridianStatusBar(
                leading: [
                  if (item != null)
                    MeridianStatusBarItem(
                      label: item,
                      icon: itemIcon,
                      maxWidth: maxWidth,
                      tooltip: pressable ? 'Switch branch' : null,
                      onPressed: pressable ? noop : null,
                    ),
                  MeridianStatusDot(tone: tone, halo: true, label: status),
                ],
                trailing: [
                  MeridianRollingNumber(
                    value: total,
                    format: (value) => '$value processes',
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Code lines',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final query = context.optionalText('Marked text', 'greeting');
            final wrap = context.knobs.boolean(label: 'Wrap');
            final numbers = context.knobs.boolean(
              label: 'Line numbers',
              initialValue: true,
            );
            final markers = context.knobs.boolean(
              label: 'Gutter markers',
              initialValue: true,
            );
            final syntax = context.knobs.boolean(
              label: 'Syntax colours',
              initialValue: true,
            );
            final current = context.knobs.intOrNull.slider(
              label: 'Current line',
              initialValue: 3,
              max: _code.length - 1,
            );
            final selectable = context.knobs.boolean(
              label: 'Selectable',
              initialValue: true,
            );
            final first = context.knobs.int.slider(
              label: 'First line number',
              initialValue: 1,
              min: 1,
              max: 9999,
            );
            final marks = <int, List<TextRange>>{};
            if (query != null && query.isNotEmpty) {
              for (final (index, line) in _code.indexed) {
                var start = line.indexOf(query);
                while (start >= 0) {
                  (marks[index] ??= []).add(
                    TextRange(start: start, end: start + query.length),
                  );
                  start = line.indexOf(query, start + query.length);
                }
              }
            }
            return preview(
              SizedBox(
                height: 220,
                child: MeridianCodeLines(
                  lines: _code,
                  wrap: wrap,
                  showLineNumbers: numbers,
                  selectable: selectable,
                  firstLineNumber: first,
                  currentLine: current,
                  marks: marks,
                  highlightedLines: marks.keys.toSet(),
                  markers: markers
                      ? const {
                          3: MeridianCodeMarker('+', semanticLabel: 'Added'),
                          4: MeridianCodeMarker('-', semanticLabel: 'Removed'),
                        }
                      : const {},
                  syntax: syntax ? sampleSyntax(_code) : const {},
                  semanticLabel: 'Contents of main.dart',
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Code gutter',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final columns = context.knobs.int.slider(
              label: 'Number columns',
              initialValue: 2,
              max: 2,
            );
            final marker = context.optionalText('Marker', '+');
            final highlighted = context.knobs.boolean(label: 'Highlighted');
            final divider = context.knobs.boolean(
              label: 'Divider',
              initialValue: true,
            );
            return preview(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var line = 0; line < 4; line++)
                    MeridianCodeGutter(
                      numbers: [
                        for (var c = 0; c < columns; c++)
                          c == 0 && line == 2 ? null : 41 + line,
                      ],
                      marker: marker == null
                          ? null
                          : MeridianCodeMarker(
                              marker,
                              color: context.meridian.colors.success,
                            ),
                      showMarker: true,
                      highlighted: highlighted && line == 1,
                      divider: divider,
                      height: MeridianLayout.codeLineHeight,
                    ),
                ],
              ),
            );
          },
        ),
      ],
    ),
  ],
);

WidgetbookFolder documentsFolder() => WidgetbookFolder(
  name: 'Documents',
  children: [
    WidgetbookComponent(
      name: 'Canvas and paper',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final pages = context.knobs.int.slider(
              label: 'Pages',
              initialValue: 3,
              min: 1,
              max: 6,
            );
            final format = context.knobs.object.segmented<String>(
              label: 'Format',
              options: const ['A4', 'Letter', 'Square'],
            );
            // Content colours: paper never follows the theme.
            final paper = context.knobs.object.dropdown<(String, Color)>(
              label: 'Paper',
              options: const [
                ('White', Color(0xFFFFFFFF)),
                ('Cream', Color(0xFFFBF5E6)),
                ('Dark', Color(0xFF20242A)),
              ],
              labelBuilder: (value) => value.$1,
            );
            final ratio = switch (format) {
              'A4' => 210 / 297,
              'Letter' => 8.5 / 11,
              _ => 1.0,
            };
            return Stateful<int>(
              key: ValueKey(pages),
              initial: 0,
              builder: (context, value, set) => MeridianCanvas(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(MeridianSpace.space8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: MeridianSpace.space6,
                      children: [
                        for (var i = 0; i < pages; i++)
                          SizedBox(
                            width: 120,
                            child: GestureDetector(
                              onTap: () => set(i),
                              child: MeridianPaper(
                                color: paper.$2,
                                aspectRatio: ratio,
                                selected: i == value,
                                semanticLabel: 'Page ${i + 1} of $pages',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Tool dock',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final axis = context.enumKnob('Axis', Axis.values);
            final colors = context.knobs.int.slider(
              label: 'Colours',
              initialValue: 2,
              max: 4,
            );
            const pens = [
              Color(0xFF18304F),
              Color(0xFF24715C),
              Color(0xFF315FA6),
              Color(0xFF943A55),
            ];
            return Stateful<(String, int)>(
              initial: const ('pen', 0),
              builder: (context, value, set) => MeridianCanvas(
                child: Center(
                  child: MeridianToolDock(
                    axis: axis,
                    semanticLabel: 'Tools',
                    children: [
                      for (final (id, label, icon) in const [
                        ('pen', 'Pen', MeridianIcons.pencil),
                        ('marker', 'Highlighter', MeridianIcons.highlighter),
                        ('eraser', 'Eraser', MeridianIcons.eraser),
                      ])
                        MeridianIconButton(
                          label: label,
                          icon: icon,
                          active: value.$1 == id,
                          onPressed: () => set((id, value.$2)),
                        ),
                      if (colors > 0) const MeridianToolDockDivider(),
                      for (final (i, color) in pens.take(colors).indexed)
                        MeridianColorSwatch(
                          color: color,
                          label: 'Pen colour ${i + 1}',
                          selected: i == value.$2,
                          onPressed: () => set((value.$1, i)),
                        ),
                      const MeridianToolDockDivider(),
                      const MeridianIconButton(
                        label: 'Undo',
                        icon: MeridianIcons.undo2,
                        onPressed: noop,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
  ],
);

const _code = [
  'import "package:meridian_ui/meridian_ui.dart";',
  '',
  'void main() {',
  '  final greeting = "Hello, Meridian";',
  '  print(greeting);',
  '  // A line long enough to scroll sideways together with every other line.',
  '  print(greeting.toUpperCase());',
  '}',
];
