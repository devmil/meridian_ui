import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meridian_ui/meridian_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'support.dart';

List<MeridianMenuEntry> _messageMenu({required bool shortcuts}) => [
  const MeridianMenuHeader('Message'),
  MeridianMenuItem(
    label: 'Reply',
    icon: MeridianIcons.reply,
    shortcut: shortcuts ? const ['⌘', 'R'] : null,
    onSelected: noop,
  ),
  MeridianMenuItem(
    label: 'Forward',
    icon: MeridianIcons.forward,
    shortcut: shortcuts ? const ['⌘', '⇧', 'F'] : null,
    onSelected: noop,
  ),
  MeridianMenuItem(
    label: 'Move to',
    icon: MeridianIcons.folderInput,
    children: [
      for (final folder in const ['Work', 'Travel', 'Receipts'])
        MeridianMenuItem(label: folder, onSelected: noop),
    ],
  ),
  const MeridianMenuItem(
    label: 'Mark as spam',
    icon: MeridianIcons.shieldAlert,
  ),
  const MeridianMenuDivider(),
  const MeridianMenuItem(
    label: 'Delete message',
    icon: MeridianIcons.trash2,
    danger: true,
    onSelected: noop,
  ),
];

List<MeridianSettingsPage> _settingsPages({required bool descriptions}) => [
  MeridianSettingsPage(
    label: 'Appearance',
    icon: MeridianIcons.palette,
    description: descriptions ? 'Theme and row density.' : null,
    builder: (context) => Stateful<String>(
      initial: 'System',
      builder: (context, value, set) => MeridianSettingsGroup(
        children: [
          MeridianSettingsRow(
            label: 'Theme',
            children: [
              MeridianSegmented<String>(
                label: 'Theme',
                value: value,
                segments: const [
                  MeridianSegment(value: 'System', label: 'System'),
                  MeridianSegment(value: 'Light', label: 'Light'),
                  MeridianSegment(value: 'Dark', label: 'Dark'),
                ],
                onChanged: set,
              ),
            ],
          ),
        ],
      ),
    ),
  ),
  MeridianSettingsPage(
    label: 'Notifications',
    icon: MeridianIcons.bell,
    description: descriptions ? 'What may interrupt you.' : null,
    builder: (context) => Stateful<bool>(
      initial: true,
      builder: (context, value, set) => MeridianSettingsGroup(
        children: [
          MeridianSettingsRow(
            label: 'Lock screen',
            help: 'Only the sender, never the text.',
            children: [
              MeridianSwitch(
                label: 'Show new mail on the lock screen',
                value: value,
                onChanged: set,
              ),
            ],
          ),
        ],
      ),
    ),
  ),
  MeridianSettingsPage(
    label: 'Remote hosts',
    icon: MeridianIcons.server,
    description: descriptions
        ? 'Computers reached through your SSH configuration.'
        : null,
    builder: (context) => const MeridianEmptyState(
      title: 'No remote hosts',
      icon: MeridianIcons.server,
    ),
  ),
];

WidgetbookFolder containersFolder() => WidgetbookFolder(
  name: 'Containers',
  children: [
    WidgetbookComponent(
      name: 'Island',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final title = context.optionalText('Title', 'Project settings');
            final subtitle = context.optionalText('Subtitle', '3 of 12');
            final actions = context.knobs.int.slider(
              label: 'Header actions',
              initialValue: 1,
              max: 3,
            );
            final padding = context.knobs.double.slider(
              label: 'Padding',
              initialValue: MeridianSpace.space5,
              max: MeridianSpace.space10,
              precision: 0,
            );
            final icon = context.iconKnob('Header icon');
            final count = context.knobs.intOrNull.slider(
              label: 'Count',
              initialValue: 12,
              max: 999,
            );
            final divider = context.knobs.boolean(
              label: 'Header divider',
              initialValue: true,
            );
            const icons = [
              ('Filter', MeridianIcons.listFilter),
              ('Pin', MeridianIcons.pin),
              ('More', MeridianIcons.ellipsis),
            ];
            return onGround(
              MeridianIsland(
                title: title,
                icon: icon,
                count: count,
                headerDivider: divider,
                subtitle: subtitle == null ? null : Text(subtitle),
                padding: EdgeInsets.all(padding),
                actions: [
                  for (final (label, icon) in icons.take(actions))
                    MeridianIconButton(
                      label: label,
                      icon: icon,
                      size: MeridianControlSize.small,
                      onPressed: noop,
                    ),
                ],
                child: const Text(
                  'One focused work surface on the tinted ground.',
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Dialog',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final title = context.knobs.string(
              label: 'Title',
              initialValue: 'Export 3 notebooks',
            );
            final description = context.optionalText(
              'Description',
              'A PDF per notebook, with scans at full resolution.',
            );
            final content = context.knobs.boolean(
              label: 'Content',
              initialValue: true,
            );
            final width = context.knobs.double.slider(
              label: 'Width',
              initialValue: MeridianLayout.dialogWidth,
              min: 280,
              max: 720,
              precision: 0,
            );
            final submitDisabled = context.knobs.boolean(
              label: 'Submit disabled',
            );
            MeridianDialog dialog(BuildContext context) => MeridianDialog(
              title: title,
              description: description,
              width: width,
              submitDisabled: submitDisabled,
              content: content
                  ? Stateful<bool>(
                      initial: true,
                      builder: (context, value, set) => MeridianCheckbox(
                        label: 'Include page backgrounds',
                        value: value,
                        onChanged: set,
                      ),
                    )
                  : null,
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
                  onPressed: submitDisabled
                      ? null
                      : () => Navigator.pop(context),
                ),
              ],
            );
            return preview(
              Center(
                child: MeridianButton(
                  label: 'Open dialog',
                  onPressed: () => showMeridianDialog<void>(
                    context: context,
                    builder: dialog,
                  ),
                ),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Information',
          builder: (context) => preview(
            Center(
              child: MeridianButton(
                label: 'Open dialog',
                onPressed: () => showMeridianDialog<void>(
                  context: context,
                  builder: (context) => MeridianDialog(
                    title: 'Notebook details',
                    description: '42 pages, 3 scans, last opened today.',
                    width: MeridianLayout.dialogFormWidth,
                    onClose: () => Navigator.pop(context),
                    actions: [
                      MeridianButton(
                        label: 'Export…',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'Confirm',
          builder: (context) {
            final destructive = context.knobs.boolean(
              label: 'Destructive',
              initialValue: true,
            );
            final description = context.optionalText(
              'Description',
              '42 pages and 3 scans are removed from this device.',
            );
            final content = context.knobs.boolean(
              label: 'Content',
              description: 'A widget below the description.',
            );
            final width = context.knobs.object.dropdown<double>(
              label: 'Width',
              options: const [
                MeridianLayout.dialogConfirmWidth,
                MeridianLayout.dialogFormWidth,
                MeridianLayout.dialogWorkflowWidth,
              ],
              labelBuilder: (value) => switch (value) {
                MeridianLayout.dialogConfirmWidth => 'confirm (460)',
                MeridianLayout.dialogFormWidth => 'form (560)',
                _ => 'workflow (760)',
              },
            );
            final barrier = context.knobs.boolean(
              label: 'Scrim dismisses',
              initialValue: true,
            );
            final verb = context.knobs.string(
              label: 'Confirm label',
              initialValue: 'Delete notebook',
            );
            return preview(
              Center(
                child: MeridianButton(
                  label: verb,
                  variant: destructive
                      ? MeridianButtonVariant.danger
                      : MeridianButtonVariant.secondary,
                  onPressed: () => showMeridianConfirm(
                    context,
                    title: 'Delete Linear algebra',
                    description: description,
                    content: content
                        ? const MeridianPropertyList(
                            properties: [
                              MeridianProperty(label: 'Pages', value: '42'),
                              MeridianProperty(label: 'Scans', value: '3'),
                            ],
                          )
                        : null,
                    confirmLabel: verb,
                    destructive: destructive,
                    width: width,
                    barrierDismissible: barrier,
                  ),
                ),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Form submits on Enter',
          builder: (context) {
            final submits = context.knobs.boolean(
              label: 'Field submits dialog',
              initialValue: true,
            );
            final valid = context.knobs.boolean(
              label: 'Primary enabled',
              initialValue: true,
            );
            MeridianDialog dialog(BuildContext context) => MeridianDialog(
              title: 'Rename notebook',
              width: MeridianLayout.dialogFormWidth,
              onSubmit: valid ? () => Navigator.pop(context) : null,
              submitDisabled: !valid,
              content: MeridianTextField(
                label: 'Name',
                autofocus: true,
                submitsDialog: submits,
              ),
              actions: [
                MeridianButton(
                  label: 'Cancel',
                  variant: MeridianButtonVariant.quiet,
                  onPressed: () => Navigator.pop(context),
                ),
                MeridianButton(
                  label: 'Rename notebook',
                  variant: MeridianButtonVariant.primary,
                  disabledReason: valid ? null : 'Enter a name',
                  onPressed: valid ? () => Navigator.pop(context) : null,
                ),
              ],
            );
            return preview(
              Center(
                child: MeridianButton(
                  label: 'Rename…',
                  onPressed: () => showMeridianDialog<void>(
                    context: context,
                    builder: dialog,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Section header',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final title = context.optionalText('Title', 'Unstaged changes');
            final icon = context.iconKnob(
              'Icon',
              initial: MeridianIcons.folder,
            );
            final count = context.knobs.intOrNull.slider(
              label: 'Count',
              initialValue: 12,
              max: 999,
            );
            final caption = context.optionalText('Caption', '3 selected');
            final size = context.enumKnob(
              'Size',
              MeridianSectionHeaderSize.values,
            );
            final middle = context.knobs.boolean(
              label: 'Middle (filter field)',
            );
            final actions = context.knobs.int.slider(
              label: 'Actions',
              initialValue: 2,
              max: 3,
            );
            final divider = context.knobs.boolean(
              label: 'Divider',
              initialValue: true,
            );
            final filled = context.knobs.boolean(label: 'Fill (pane-alt)');
            const icons = [
              ('Stage all', MeridianIcons.plus),
              ('Discard all', MeridianIcons.undo2),
              ('More', MeridianIcons.ellipsis),
            ];
            return preview(
              Builder(
                builder: (context) => MeridianSectionHeader(
                  title: title,
                  icon: icon,
                  count: count,
                  caption: caption == null ? null : Text(caption),
                  size: size,
                  divider: divider,
                  color: filled ? context.meridian.colors.paneAlt : null,
                  middle: middle
                      ? const MeridianTextField(
                          variant: MeridianTextFieldVariant.search,
                          size: MeridianControlSize.small,
                          placeholder: 'Filter files',
                          width: 0,
                        )
                      : null,
                  actions: [
                    for (final (label, icon) in icons.take(actions))
                      MeridianIconButton(
                        label: label,
                        icon: icon,
                        size: MeridianControlSize.small,
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
      name: 'Split pane',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final axis = context.enumKnob('Axis', Axis.values);
            final initial = context.knobs.double.slider(
              label: 'Ratio',
              initialValue: 0.4,
              max: 1,
            );
            final minimum = context.knobs.double.slider(
              label: 'Minimum pane size',
              initialValue: 120,
              max: 300,
              precision: 0,
            );
            final divider = context.knobs.boolean(label: 'Divider');
            final focusable = context.knobs.boolean(
              label: 'In Tab order',
              initialValue: true,
            );
            return onGround(
              SizedBox(
                height: 320,
                child: Stateful<double>(
                  initial: initial,
                  builder: (context, ratio, set) => MeridianSplitPane(
                    axis: axis,
                    ratio: ratio,
                    initialRatio: initial,
                    firstMinExtent: minimum,
                    secondMinExtent: minimum,
                    divider: divider,
                    focusable: focusable,
                    semanticLabel: 'Resize lists',
                    onRatioChanged: set,
                    onReset: () => set(initial),
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
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Sheet',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final title = context.optionalText('Title', 'Pen');
            final handle = context.knobs.boolean(
              label: 'Handle',
              initialValue: true,
            );
            final dismissible = context.knobs.boolean(
              label: 'Dismissible',
              initialValue: true,
            );
            return preview(
              Center(
                child: MeridianButton(
                  label: 'Open sheet',
                  onPressed: () => showMeridianSheet<void>(
                    context: context,
                    isDismissible: dismissible,
                    builder: (context) => MeridianSheet(
                      title: title,
                      showHandle: handle,
                      actions: [
                        MeridianButton(
                          label: 'Done',
                          variant: MeridianButtonVariant.primary,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.all(MeridianSpace.space8),
                        child: Stateful<double>(
                          initial: 0.3,
                          builder: (context, value, set) => MeridianSlider(
                            label: 'Stroke width',
                            value: value,
                            onChanged: set,
                          ),
                        ),
                      ),
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
      name: 'Menu',
      useCases: [
        WidgetbookUseCase(
          name: 'Anchored menu',
          builder: (context) {
            final shortcuts = context.knobs.boolean(
              label: 'Shortcuts',
              initialValue: true,
            );
            final width = context.knobs.doubleOrNull.slider(
              label: 'Width',
              description: 'Null fits the longest entry.',
              initialValue: 260,
              min: 160,
              max: 400,
              precision: 0,
              defaultToNull: true,
            );
            return preview(
              Center(
                child: MeridianMenuAnchor(
                  width: width,
                  entries: _messageMenu(shortcuts: shortcuts),
                  builder: (context, open) => MeridianButton(
                    label: 'Open menu',
                    trailingIcon: MeridianIcons.chevronDown,
                    onPressed: open,
                  ),
                ),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Context menu',
          builder: (context) => preview(
            MeridianListRow(
              title: 'Quarterly report draft',
              subtitle: 'Right-click or long-press this row',
              onTap: noop,
              onContextMenu: (position) => showMeridianContextMenu(
                context,
                globalPosition: position,
                entries: _messageMenu(shortcuts: false),
              ),
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'Checked entries',
          builder: (_) => preview(
            Center(
              child: Stateful<Set<String>>(
                initial: const {'PID', 'CPU'},
                builder: (context, value, set) => MeridianMenuAnchor(
                  entries: [
                    const MeridianMenuHeader('Columns'),
                    for (final column in const ['PID', 'CPU', 'GPU', 'Memory'])
                      MeridianMenuItem(
                        label: column,
                        checked: value.contains(column),
                        onSelected: () => set(
                          value.contains(column)
                              ? ({...value}..remove(column))
                              : {...value, column},
                        ),
                      ),
                  ],
                  builder: (context, open) => MeridianButton(
                    label: '${value.length} columns',
                    icon: MeridianIcons.columns2,
                    trailingIcon: MeridianIcons.chevronDown,
                    onPressed: open,
                  ),
                ),
              ),
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'Dialog after selection',
          builder: (_) => preview(
            Builder(
              builder: (context) => Center(
                child: MeridianMenuAnchor(
                  entries: [
                    const MeridianMenuItem(label: 'Unavailable'),
                    MeridianMenuItem(
                      label: 'Export…',
                      icon: 'save',
                      onSelected: () => showMeridianDialog<void>(
                        context: context,
                        builder: (context) => MeridianDialog(
                          title: 'Export',
                          content: const Text(
                            'Close this dialog, then open the menu again.',
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
                  ],
                  builder: (context, open) => MeridianButton(
                    label: 'Open menu',
                    trailingIcon: MeridianIcons.chevronDown,
                    onPressed: open,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Popover',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final width = context.knobs.double.slider(
              label: 'Width',
              initialValue: 260,
              min: 200,
              max: 400,
              precision: 0,
            );
            final folders = context.knobs.int.slider(
              label: 'Folders',
              description: 'A long list scrolls inside the popover.',
              initialValue: 3,
              min: 1,
              max: 30,
            );
            return preview(
              Center(
                child: MeridianPopoverAnchor(
                  width: width,
                  builder: (context, open) => MeridianButton(
                    label: 'Move to…',
                    icon: MeridianIcons.folderInput,
                    trailingIcon: MeridianIcons.chevronDown,
                    onPressed: open,
                  ),
                  popoverBuilder: (context) => SingleChildScrollView(
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
                        for (var i = 0; i < folders; i++)
                          MeridianListRow(
                            title:
                                const [
                                  'Work',
                                  'Travel',
                                  'Receipts',
                                ].elementAtOrNull(i) ??
                                'Folder ${i + 1}',
                            leading: const MeridianIcon(
                              MeridianIcons.folder,
                              size: MeridianIconSize.small,
                            ),
                            onTap: () => Navigator.of(context).pop(),
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
      name: 'Panel',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final title = context.knobs.string(
              label: 'Title',
              initialValue: 'Inspector',
            );
            final visible = context.knobs.boolean(
              label: 'Visible',
              description: 'The panel stays mounted while it leaves.',
              initialValue: true,
            );
            final closable = context.knobs.boolean(
              label: 'Close button',
              initialValue: true,
            );
            final width = context.knobs.double.slider(
              label: 'Width',
              initialValue: MeridianLayout.panelWidth,
              min: 200,
              max: 480,
              precision: 0,
            );
            final meridian = context.meridian;
            return onGround(
              Center(
                child: MeridianPanel(
                  title: title,
                  visible: visible,
                  width: width,
                  onClose: closable ? noop : null,
                  actions: const [
                    MeridianIconButton(
                      label: 'Pin panel',
                      icon: MeridianIcons.pin,
                      size: MeridianControlSize.small,
                      onPressed: noop,
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
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Disclosure',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final title = context.knobs.string(
              label: 'Title',
              initialValue: 'Advanced options',
            );
            final count = context.knobs.boolean(
              label: 'Trailing count',
              initialValue: true,
            );
            final enabled = context.enabledKnob();
            return preview(
              MeridianDisclosure(
                title: title,
                initiallyExpanded: true,
                enabled: enabled,
                trailing: count
                    ? const MeridianCount(
                        label: '2',
                        semanticLabel: '2 changed',
                      )
                    : null,
                child: Stateful<bool>(
                  initial: true,
                  builder: (context, value, set) => MeridianCheckbox(
                    label: 'Keep a local copy',
                    value: value,
                    onChanged: set,
                  ),
                ),
              ),
              maxWidth: 360,
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Settings',
      useCases: [
        WidgetbookUseCase(
          name: 'Group and rows',
          builder: (context) {
            final title = context.optionalText('Title', 'Appearance');
            final fitLabels = context.knobs.boolean(
              label: 'Fit labels',
              description:
                  'The label column hugs the longest label, as in a dialog '
                  'form.',
            );
            final help = context.knobs.boolean(
              label: 'Help text',
              initialValue: true,
            );
            return onGround(
              Stateful<(String, bool)>(
                initial: const ('System', true),
                builder: (context, value, set) => MeridianSettingsGroup(
                  title: title,
                  fitLabels: fitLabels,
                  children: [
                    MeridianSettingsRow(
                      label: 'Theme',
                      help: help
                          ? 'Follows the system unless you pick one.'
                          : null,
                      children: [
                        MeridianSegmented<String>(
                          label: 'Theme',
                          value: value.$1,
                          segments: const [
                            MeridianSegment(value: 'System', label: 'System'),
                            MeridianSegment(
                              value: 'Light',
                              label: 'Light',
                              icon: MeridianIcons.sun,
                            ),
                            MeridianSegment(
                              value: 'Dark',
                              label: 'Dark',
                              icon: MeridianIcons.moon,
                            ),
                          ],
                          onChanged: (v) => set((v, value.$2)),
                        ),
                      ],
                    ),
                    MeridianSettingsRow(
                      label: 'Notifications',
                      children: [
                        MeridianSwitch(
                          label: 'Show new mail on the lock screen',
                          value: value.$2,
                          onChanged: (v) => set((value.$1, v)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Settings dialog',
          builder: (context) {
            final title = context.knobs.string(
              label: 'Title',
              initialValue: 'Settings',
            );
            final width = context.knobs.double.slider(
              label: 'Width',
              initialValue: MeridianLayout.settingsDialogWidth,
              min: 360,
              max: 1000,
              precision: 0,
            );
            final descriptions = context.knobs.boolean(
              label: 'Page descriptions',
              initialValue: true,
            );
            final footer = context.knobs.boolean(
              label: 'Footer',
              description: 'A line under the pages after a failed change.',
            );
            final initialPage = context.knobs.int.slider(
              label: 'Initial page',
              initialValue: 0,
              min: 0,
              max: 2,
            );
            return preview(
              Center(
                child: MeridianButton(
                  label: 'Open settings',
                  onPressed: () => showMeridianDialog<void>(
                    context: context,
                    builder: (context) => MeridianSettingsDialog(
                      title: title,
                      width: width,
                      initialPage: initialPage,
                      pages: _settingsPages(descriptions: descriptions),
                      footer: footer
                          ? Text(
                              'The settings could not be saved.',
                              style: TextStyle(
                                color: context.meridian.colors.danger,
                              ),
                            )
                          : null,
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
      name: 'License dialog',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final title = context.knobs.string(
              label: 'Title',
              initialValue: 'Licenses',
            );
            final width = context.knobs.double.slider(
              label: 'Width',
              initialValue: MeridianLayout.licenseDialogWidth,
              min: 360,
              max: 1200,
              precision: 0,
            );
            final application = context.knobs.boolean(
              label: 'Application header',
              description: 'Name, version and legalese above the list.',
              initialValue: true,
            );
            return preview(
              Center(
                child: MeridianButton(
                  label: 'Open licenses',
                  onPressed: () => showMeridianDialog<void>(
                    context: context,
                    builder: (context) => MeridianLicenseDialog(
                      title: title,
                      width: width,
                      applicationName: application ? 'Meridian' : null,
                      applicationVersion: application ? '1.18.0' : null,
                      applicationLegalese: application ? '© Devmil' : null,
                      licenses: _widgetbookLicenses,
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
      name: 'Scrollbar',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final visibility = context.knobs.object
                .segmented<MeridianScrollbarVisibility>(
                  label: 'Visibility',
                  options: MeridianScrollbarVisibility.values,
                  labelBuilder: (value) => value.name,
                );
            final rows = context.knobs.int.slider(
              label: 'Rows',
              initialValue: 24,
              min: 1,
              max: 60,
            );
            return preview(
              SizedBox(
                height: 240,
                child: MeridianIsland(
                  expandChild: true,
                  child: _ScrollbarList(visibility: visibility, rows: rows),
                ),
              ),
              maxWidth: 260,
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Drawer',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final width = context.knobs.double.slider(
              label: 'Width',
              initialValue: MeridianLayout.drawerWidth,
              min: 200,
              max: 400,
              precision: 0,
            );
            return MeridianGround(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: MeridianDrawer(
                  width: width,
                  semanticLabel: 'Navigation',
                  child: Stateful<String>(
                    initial: 'Library',
                    builder: (context, value, set) => ListView(
                      padding: const EdgeInsets.all(MeridianSpace.space3),
                      children: [
                        for (final (label, icon) in const [
                          ('Library', MeridianIcons.bookOpen),
                          ('Archive', MeridianIcons.archive),
                          ('Trash', MeridianIcons.trash2),
                        ])
                          MeridianNavRow(
                            label: label,
                            icon: icon,
                            selected: value == label,
                            onTap: () => set(label),
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
  ],
);

class _ScrollbarList extends StatefulWidget {
  const _ScrollbarList({required this.visibility, required this.rows});

  final MeridianScrollbarVisibility visibility;
  final int rows;

  @override
  State<_ScrollbarList> createState() => _ScrollbarListState();
}

class _ScrollbarListState extends State<_ScrollbarList> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MeridianScrollbar(
    controller: _controller,
    visibility: widget.visibility,
    child: ListView(
      controller: _controller,
      padding: const EdgeInsets.all(MeridianSpace.space3),
      children: [
        for (var index = 1; index <= widget.rows; index += 1)
          MeridianNavRow(
            label: 'Notebook $index',
            icon: MeridianIcons.bookOpen,
            onTap: noop,
          ),
      ],
    ),
  );
}

Stream<LicenseEntry> _widgetbookLicenses() async* {
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
