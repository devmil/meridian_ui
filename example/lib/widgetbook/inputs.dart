import '../shortcut_field_demo.dart';
import 'package:flutter/material.dart';
import 'package:meridian_ui/meridian_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'support.dart';

/// Content colours (a pen palette): never theme tokens.
const _penColors = [
  Color(0xFF18304F),
  Color(0xFF24715C),
  Color(0xFF315FA6),
  Color(0xFF943A55),
  Color(0xFFF4D864),
  Color(0xFFFFFFFF),
];

WidgetbookFolder inputsFolder() => WidgetbookFolder(
  name: 'Inputs',
  children: [
    WidgetbookComponent(
      name: 'Shortcut field',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) => preview(
            SizedBox(
              width: 260,
              child: ShortcutFieldDemo(
                label: context.knobs.string(
                  label: 'Label',
                  initialValue: 'Capture area',
                ),
                enabled: context.enabledKnob(),
                preparing: context.knobs.boolean(label: 'Preparing'),
                showLabel: context.knobs.boolean(
                  label: 'Show label',
                  initialValue: true,
                ),
                empty: context.knobs.boolean(label: 'Empty'),
                conflict: context.optionalText(
                  'Conflict',
                  'Already used by History.',
                  on: false,
                ),
              ),
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'States',
          builder: (context) => preview(
            wrap([
              const SizedBox(width: 260, child: ShortcutFieldDemo()),
              const SizedBox(
                width: 260,
                child: ShortcutFieldDemo(label: 'History', empty: true),
              ),
              const SizedBox(
                width: 260,
                child: ShortcutFieldDemo(preparing: true),
              ),
              const SizedBox(
                width: 260,
                child: ShortcutFieldDemo(enabled: false),
              ),
              const SizedBox(
                width: 260,
                child: ShortcutFieldDemo(conflict: 'Already used by History.'),
              ),
            ]),
          ),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Find bar',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final matches = context.knobs.int.slider(
              label: 'Matches',
              initialValue: 12,
              max: 200,
            );
            final current = context.knobs.intOrNull.slider(
              label: 'Current match',
              initialValue: 2,
              max: 199,
            );
            final searching = context.knobs.boolean(label: 'Searching');
            final caseToggle = context.knobs.boolean(
              label: 'Case toggle',
              initialValue: true,
            );
            final wordToggle = context.knobs.boolean(
              label: 'Whole word toggle',
            );
            final regexToggle = context.knobs.boolean(label: 'Regex toggle');
            final trailing = context.knobs.boolean(
              label: 'Trailing control',
              description: 'An owner control such as search scopes.',
            );
            final closable = context.knobs.boolean(
              label: 'Close button',
              initialValue: true,
            );
            final size = context.enumKnob(
              'Size',
              MeridianControlSize.values,
              initial: MeridianControlSize.small,
            );
            final width = context.knobs.double.slider(
              label: 'Field width',
              initialValue: MeridianLayout.findFieldWidth,
              min: MeridianLayout.findFieldMinWidth,
              max: 360,
              precision: 0,
            );
            final error = context.optionalText(
              'Error',
              'Not a valid regular expression',
              on: false,
            );
            final enabled = context.enabledKnob();
            final visible = context.knobs.boolean(
              label: 'Visible',
              initialValue: true,
            );
            return preview(
              Stateful<(bool, bool, bool)>(
                initial: (false, false, false),
                builder: (context, toggles, set) => MeridianFindBar(
                  controller: _findQuery,
                  matchCount: matches,
                  currentMatch: current,
                  searching: searching,
                  size: size,
                  fieldWidth: width,
                  error: error,
                  enabled: enabled,
                  visible: visible,
                  caseSensitive: toggles.$1,
                  onCaseSensitiveChanged: caseToggle
                      ? (v) => set((v, toggles.$2, toggles.$3))
                      : null,
                  wholeWord: toggles.$2,
                  onWholeWordChanged: wordToggle
                      ? (v) => set((toggles.$1, v, toggles.$3))
                      : null,
                  regex: toggles.$3,
                  onRegexChanged: regexToggle
                      ? (v) => set((toggles.$1, toggles.$2, v))
                      : null,
                  onNext: noop,
                  onPrevious: noop,
                  onClose: closable ? noop : null,
                  trailing: [
                    if (trailing)
                      MeridianIconButton(
                        label: 'Search scopes',
                        icon: MeridianIcons.listFilter,
                        size: size,
                        onPressed: noop,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Color choice row',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final none = context.knobs.boolean(
              label: 'No-colour swatch',
              initialValue: true,
            );
            final custom = context.knobs.boolean(
              label: 'Custom colour well',
              initialValue: true,
            );
            final count = context.knobs.int.slider(
              label: 'Series colours',
              initialValue: 8,
              min: 1,
              max: 8,
            );
            final enabled = context.enabledKnob();
            return preview(
              Stateful<MeridianColorChoice?>(
                initial: const MeridianSeriesColor(0),
                builder: (context, value, set) => MeridianColorChoiceRow(
                  value: value,
                  allowNone: none,
                  allowCustom: custom,
                  series: [for (var i = 0; i < count; i++) i],
                  onChanged: enabled ? set : null,
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Text field',
      useCases: [
        WidgetbookUseCase(name: 'Playground', builder: _textFieldPlayground),
        WidgetbookUseCase(
          name: 'Default and error',
          builder: (_) => preview(
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MeridianTextField(
                  label: 'Project name',
                  placeholder: 'Enter a name',
                ),
                SizedBox(height: MeridianSpace.space4),
                MeridianTextField(
                  label: 'Email address',
                  error: 'Enter a valid email address',
                ),
              ],
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'Search',
          builder: (context) {
            final count = context.optionalText('Result count', '12 / 480');
            final size = context.enumKnob('Size', MeridianControlSize.values);
            return preview(
              MeridianTextField(
                variant: MeridianTextFieldVariant.search,
                size: size,
                label: 'Filter processes',
                showLabel: false,
                placeholder: 'Filter processes',
                trailingText: count,
                clearLabel: 'Clear filter',
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Multiline',
          builder: (context) {
            final minLines = context.knobs.int.slider(
              label: 'Minimum lines',
              initialValue: 3,
              min: 1,
              max: 8,
            );
            final maxLength = context.knobs.intOrNull.slider(
              label: 'Maximum length',
              initialValue: 140,
              min: 20,
              max: 400,
              defaultToNull: true,
            );
            return preview(
              MeridianTextField(
                label: 'Notes',
                placeholder: 'Grows as you type',
                minLines: minLines,
                maxLines: null,
                maxLength: maxLength,
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Checkbox',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final label = context.knobs.string(
              label: 'Label',
              initialValue: 'Include attachments',
            );
            final description = context.optionalText(
              'Description',
              'Files are added to the archive.',
              on: false,
            );
            final tristate = context.knobs.boolean(
              label: 'Tristate',
              description: 'Starts mixed, as for a partly selected group.',
            );
            final enabled = context.enabledKnob();
            return preview(
              Stateful<bool?>(
                key: ValueKey(tristate),
                initial: tristate ? null : true,
                builder: (context, value, set) => MeridianCheckbox(
                  label: label,
                  description: description,
                  tristate: tristate,
                  value: value,
                  onChanged: enabled ? set : null,
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Switch',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final label = context.knobs.string(
              label: 'Label',
              initialValue: 'Finger drawing',
            );
            final description = context.optionalText(
              'Description',
              'One finger writes; two fingers scroll and zoom.',
            );
            final labelFirst = context.knobs.boolean(
              label: 'Label first',
              description: 'The settings layout: label left, switch right.',
              initialValue: true,
            );
            final showLabel = context.knobs.boolean(
              label: 'Show label',
              initialValue: true,
            );
            final enabled = context.enabledKnob();
            return preview(
              Stateful<bool>(
                initial: true,
                builder: (context, value, set) => MeridianSwitch(
                  label: label,
                  description: description,
                  labelFirst: labelFirst,
                  showLabel: showLabel,
                  value: value,
                  onChanged: enabled ? set : null,
                ),
              ),
              maxWidth: 420,
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Radio',
      useCases: [
        WidgetbookUseCase(
          name: 'Group',
          builder: (context) {
            final descriptions = context.knobs.boolean(label: 'Descriptions');
            final enabled = context.enabledKnob();
            return preview(
              Stateful<String>(
                initial: 'thread',
                builder: (context, value, set) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: MeridianSpace.space4,
                  children: [
                    for (final (id, label, description) in const [
                      (
                        'thread',
                        'Group by conversation',
                        'Replies stay with the message they answer.',
                      ),
                      (
                        'flat',
                        'Show every message',
                        'One row per message, newest first.',
                      ),
                    ])
                      MeridianRadio<String>(
                        label: label,
                        description: descriptions ? description : null,
                        value: id,
                        groupValue: value,
                        onChanged: enabled ? set : null,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Segmented',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final content = context.knobs.object.segmented<String>(
              label: 'Content',
              options: const ['Label and icon', 'Label', 'Icon'],
            );
            final size = context.enumKnob('Size', MeridianControlSize.values);
            final expand = context.knobs.boolean(label: 'Expand');
            final manual = context.knobs.boolean(
              label: 'Manual activation',
              description:
                  'Arrow keys move focus; Space or Enter selects. For choices '
                  'that are slow to apply.',
            );
            final gridDisabled = context.knobs.boolean(
              label: 'Disable Grid',
              description:
                  'One unavailable option: muted, skipped by the arrow keys, '
                  'its tooltip says why.',
            );
            final enabled = context.enabledKnob();
            final labels = content != 'Icon';
            final icons = content != 'Label';
            return preview(
              Stateful<String>(
                initial: 'list',
                builder: (context, value, set) => MeridianSegmented<String>(
                  label: 'Layout',
                  value: value,
                  size: size,
                  expand: expand,
                  manualActivation: manual,
                  segments: [
                    for (final (id, label, icon) in const [
                      ('list', 'List', MeridianIcons.list),
                      ('tree', 'Tree', MeridianIcons.listTree),
                      ('grid', 'Grid', MeridianIcons.layoutGrid),
                    ])
                      if (gridDisabled && id == 'grid')
                        MeridianSegment(
                          value: id,
                          label: labels ? label : null,
                          icon: icons ? icon : null,
                          tooltip: labels
                              ? 'Needs a wider window'
                              : 'Grid: needs a wider window',
                          enabled: false,
                        )
                      else
                        MeridianSegment(
                          value: id,
                          label: labels ? label : null,
                          icon: icons ? icon : null,
                          tooltip: labels ? null : label,
                        ),
                  ],
                  onChanged: enabled ? set : null,
                ),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Enlarged labels',
          builder: (context) => preview(
            MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: Stateful<String>(
                initial: 'all',
                builder: (context, value, set) => MeridianSegmented<String>(
                  label: 'Show',
                  value: value,
                  size: MeridianControlSize.small,
                  segments: const [
                    MeridianSegment(value: 'all', label: 'All'),
                    MeridianSegment(value: 'user', label: 'User'),
                    MeridianSegment(value: 'background', label: 'Background'),
                  ],
                  onChanged: set,
                ),
              ),
            ),
            maxWidth: 320,
          ),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Slider',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final max = context.knobs.double.slider(
              label: 'Maximum',
              initialValue: 10,
              min: 1,
              max: 100,
              divisions: 99,
              precision: 0,
            );
            final stepped = context.knobs.boolean(
              label: 'Whole steps',
              description: 'Snaps to steps of 1.',
            );
            final enabled = context.enabledKnob();
            return preview(
              Stateful<double>(
                key: ValueKey(max),
                initial: max * 0.4,
                builder: (context, value, set) => MeridianSlider(
                  label: 'Stroke width',
                  value: value,
                  max: max,
                  step: stepped ? 1 : null,
                  valueLabel: (v) => '${v.toStringAsFixed(1)} mm',
                  onChanged: enabled ? set : null,
                ),
              ),
              maxWidth: 360,
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Range slider',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final min = context.knobs.double.slider(
              label: 'Minimum',
              initialValue: 0,
              min: -100,
              max: 0,
              precision: 0,
            );
            final max = context.knobs.double.slider(
              label: 'Maximum',
              initialValue: 10,
              min: 1,
              max: 100,
              precision: 0,
            );
            final startLabel = context.knobs.string(
              label: 'Start label',
              initialValue: 'Range start',
            );
            final endLabel = context.knobs.string(
              label: 'End label',
              initialValue: 'Range end',
            );
            final stepped = context.knobs.boolean(label: 'Whole steps');
            final customLabel = context.knobs.boolean(
              label: 'Custom value label',
              initialValue: true,
            );
            final reportEnd = context.knobs.boolean(
              label: 'Show committed interval',
            );
            final enabled = context.enabledKnob();
            final width = context.knobs.double.slider(
              label: 'Width',
              initialValue: 360,
              min: 100,
              max: 480,
              precision: 0,
            );
            return preview(
              Stateful<(MeridianRangeValues, MeridianRangeValues?)>(
                key: ValueKey((min, max)),
                initial: (
                  MeridianRangeValues(
                    min + (max - min) * 0.2,
                    min + (max - min) * 0.8,
                  ),
                  null,
                ),
                builder: (context, state, set) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MeridianRangeSlider(
                      startLabel: startLabel,
                      endLabel: endLabel,
                      values: state.$1,
                      min: min,
                      max: max,
                      step: stepped ? 1 : null,
                      valueLabel: customLabel
                          ? (value) => '${value.toStringAsFixed(1)} s'
                          : null,
                      onChanged: enabled
                          ? (values) => set((values, state.$2))
                          : null,
                      onChangeEnd: reportEnd
                          ? (values) => set((state.$1, values))
                          : null,
                    ),
                    if (reportEnd && state.$2 != null)
                      Text(
                        '${state.$2!.start.toStringAsFixed(1)} – ${state.$2!.end.toStringAsFixed(1)}',
                      ),
                  ],
                ),
              ),
              maxWidth: width,
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Select',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final showLabel = context.knobs.boolean(
              label: 'Show label',
              initialValue: true,
            );
            final size = context.enumKnob('Size', MeridianControlSize.values);
            final expand = context.knobs.boolean(label: 'Expand');
            final animate = context.knobs.boolean(
              label: 'Animate value',
              description: 'The chosen value rises into the trigger.',
            );
            final options = context.knobs.int.slider(
              label: 'Options',
              initialValue: 4,
              min: 2,
              max: 12,
            );
            final enabled = context.enabledKnob();
            final values = [
              'Newest first',
              'Oldest first',
              'Sender',
              'Size',
              for (var i = 5; i <= options; i++) 'Custom order $i',
            ].take(options).toList();
            return preview(
              Stateful<String>(
                key: ValueKey(options),
                initial: values.first,
                builder: (context, value, set) => MeridianSelect<String>(
                  label: 'Sort by',
                  showLabel: showLabel,
                  size: size,
                  expand: expand,
                  animateValue: animate,
                  value: value,
                  values: values,
                  valueLabel: (v) => v,
                  onChanged: enabled ? set : null,
                ),
              ),
              maxWidth: 420,
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Enlarged value',
          builder: (context) => preview(
            MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: MeridianSelect<String>(
                value: 'WebP (verlustbehaftet)',
                values: const ['PNG', 'JPEG', 'WebP (verlustbehaftet)'],
                valueLabel: (value) => value,
                label: 'Format',
                showLabel: true,
                expand: true,
                onChanged: (_) {},
              ),
            ),
            maxWidth: 320,
          ),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Color swatch',
      useCases: [
        WidgetbookUseCase(
          name: 'Palette',
          builder: (context) {
            final enabled = context.enabledKnob();
            return preview(
              Stateful<int>(
                initial: 0,
                builder: (context, value, set) =>
                    wrap(spacing: MeridianSpace.space2, [
                      for (final (i, color) in _penColors.indexed)
                        MeridianColorSwatch(
                          color: color,
                          label: 'Pen colour ${i + 1}',
                          selected: i == value,
                          onPressed: enabled ? () => set(i) : null,
                        ),
                    ]),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Color picker',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final model = context.enumKnob(
              'Sliders',
              MeridianColorModel.values,
            );
            final layout = context.enumKnob(
              'Layout',
              MeridianColorPickerLayout.values,
            );
            final groups = context.knobs.boolean(
              label: 'Swatch groups',
              description: 'A palette and recent colours above the wheel.',
              initialValue: true,
            );
            final original = context.knobs.boolean(
              label: 'Original colour',
              description: 'The colour before the edit; a tap restores it.',
              initialValue: true,
            );
            final enabled = context.enabledKnob();
            return preview(
              Stateful<Color>(
                key: ValueKey(model),
                initial: _penColors[3],
                builder: (context, value, set) => MeridianColorPicker(
                  color: value,
                  model: model,
                  layout: layout,
                  original: original ? _penColors.first : null,
                  groups: groups
                      ? const [
                          MeridianColorGroup(
                            title: 'Palette',
                            colors: _penColors,
                          ),
                          MeridianColorGroup(
                            title: 'Recent',
                            colors: [Color(0xFF1A5F3C), Color(0xFFC2410C)],
                          ),
                        ]
                      : const [],
                  onChanged: enabled ? set : null,
                ),
              ),
              maxWidth: 480,
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Color well',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final custom = context.knobs.boolean(
              label: 'Custom colour',
              description: 'Starts with a custom colour rather than none.',
              initialValue: true,
            );
            final enabled = context.enabledKnob();
            return preview(
              Stateful<Color?>(
                key: ValueKey(custom),
                initial: custom ? const Color(0xFFC2410C) : null,
                builder: (context, value, set) => MeridianColorWell(
                  color: value,
                  label: 'Custom colour',
                  initial: _penColors.first,
                  selected: value != null,
                  groups: const [
                    MeridianColorGroup(title: 'Palette', colors: _penColors),
                  ],
                  onChanged: enabled ? set : null,
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Calendar',
      useCases: [
        WidgetbookUseCase(
          name: 'Inline',
          builder: (context) {
            final bounded = context.knobs.boolean(
              label: 'Limit to March',
              description: 'Days outside the range cannot be chosen.',
            );
            return preview(
              Center(
                child: Stateful<DateTime>(
                  initial: DateTime(2026, 3, 18),
                  builder: (context, value, set) => MeridianCalendar(
                    value: value,
                    firstDate: bounded ? DateTime(2026, 3) : DateTime(2026),
                    lastDate: bounded
                        ? DateTime(2026, 3, 31)
                        : DateTime(2026, 12, 31),
                    onChanged: set,
                  ),
                ),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Date picker',
          builder: (context) {
            final title = context.optionalText('Title', 'Due date');
            return preview(
              Stateful<DateTime>(
                initial: DateTime(2026, 3, 18),
                builder: (context, value, set) => Center(
                  child: MeridianButton(
                    label:
                        '${value.year}-'
                        '${value.month.toString().padLeft(2, '0')}-'
                        '${value.day.toString().padLeft(2, '0')}',
                    icon: MeridianIcons.calendar,
                    onPressed: () async {
                      final day = await showMeridianDatePicker(
                        context: context,
                        title: title,
                        initialDate: value,
                        firstDate: DateTime(2026),
                        lastDate: DateTime(2026, 12, 31),
                      );
                      if (day != null) set(day);
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Drop zone',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final state = context.enumKnob(
              'State',
              MeridianDropZoneState.values,
            );
            final label = context.knobs.string(
              label: 'Label',
              initialValue: 'Drop files to attach',
            );
            final message = context.optionalText('Message', 'Click to browse');
            final icon = context.requiredIconKnob(
              'Icon',
              initial: MeridianIcons.upload,
            );
            final browse = context.knobs.boolean(
              label: 'Can browse',
              initialValue: true,
            );
            return preview(
              MeridianDropZone(
                label: label,
                message: message,
                icon: icon,
                state: state,
                onBrowse: browse ? noop : null,
              ),
              maxWidth: 360,
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Suggestions',
      useCases: [
        WidgetbookUseCase(
          name: 'Search results',
          builder: (context) {
            final hints = context.knobs.boolean(
              label: 'Hints',
              initialValue: true,
            );
            return preview(
              Stateful<int>(
                initial: 0,
                builder: (context, value, set) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MeridianResultNavigation(
                      itemCount: 3,
                      selectedIndex: value,
                      onSelected: set,
                      onActivate: set,
                      child: const MeridianTextField(
                        label: 'Base branch',
                        icon: MeridianIcons.gitBranch,
                        placeholder: 'Arrow keys move through the results',
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
                            hint: hints ? 'ahead 3' : null,
                            icon: MeridianIcons.gitBranch,
                            highlighted: value == 0,
                            onTap: () => set(0),
                          ),
                          MeridianSuggestionRow(
                            label: 'feature/offline-sync',
                            icon: MeridianIcons.gitBranch,
                            highlighted: value == 1,
                            onTap: () => set(1),
                          ),
                          const MeridianSuggestionHeader('Remote branches'),
                          MeridianSuggestionRow(
                            label: 'origin/feature/search',
                            hint: hints ? 'origin' : null,
                            icon: MeridianIcons.cloud,
                            highlighted: value == 2,
                            onTap: () => set(2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              maxWidth: 360,
            );
          },
        ),
      ],
    ),
  ],
);

Widget _textFieldPlayground(BuildContext context) {
  final label = context.knobs.string(
    label: 'Label',
    initialValue: 'Display name',
  );
  final showLabel = context.knobs.boolean(
    label: 'Show label',
    initialValue: true,
  );
  final placeholder = context.optionalText('Placeholder', 'Michael');
  final variant = context.enumKnob('Variant', MeridianTextFieldVariant.values);
  final size = context.enumKnob('Size', MeridianControlSize.values);
  final icon = context.iconKnob('Icon');
  final trailingText = context.optionalText('Trailing text', 'px', on: false);
  final message = context.optionalText(
    'Message',
    'Shown to people you write to.',
  );
  final error = context.optionalText(
    'Error',
    'Enter a name of at least 2 characters',
    on: false,
  );
  final monospace = context.knobs.boolean(label: 'Monospace');
  final obscure = context.knobs.boolean(label: 'Obscure text');
  final readOnly = context.knobs.boolean(label: 'Read only');
  final enabled = context.enabledKnob();
  final underlay = context.knobs.boolean(label: 'Underlay');
  return preview(
    MeridianTextField(
      label: label,
      showLabel: showLabel,
      placeholder: placeholder,
      variant: variant,
      size: size,
      icon: icon,
      trailingText: trailingText,
      message: message,
      error: error,
      monospace: monospace,
      obscureText: obscure,
      readOnly: readOnly,
      enabled: enabled,
      // A mark under the first line, kept clear of the selection colour.
      underlay: underlay
          ? Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: MeridianTheme.of(context).text.body.fontSize! * 1.5,
                child: ColoredBox(
                  color: MeridianTheme.of(context).colors.attentionBg,
                ),
              ),
            )
          : null,
    ),
    maxWidth: 420,
  );
}

/// The find bar playground's query, kept across knob changes.
final _findQuery = TextEditingController(text: 'greeting');
