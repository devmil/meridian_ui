import 'package:flutter/widgets.dart';
import 'package:meridian_ui/meridian_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import '../tab_strip_demo.dart';
import 'support.dart';

const _messages = [
  ('Anna Berg', 'Quarterly report draft', '09:41'),
  ('Proton', 'Your security key was added', '08:12'),
  ('Jonas Weber', 'Re: Mimameidr beta 14', 'Yesterday'),
  ('Grace Hopper', 'Notes from the compiler review', 'Mon'),
];

WidgetbookFolder navigationFolder() => WidgetbookFolder(
  name: 'Navigation',
  children: [
    WidgetbookComponent(
      name: 'List row',
      useCases: [
        WidgetbookUseCase(name: 'Playground', builder: _listRowPlayground),
        WidgetbookUseCase(
          name: 'Selection and metadata',
          builder: (_) => onGround(
            MeridianIsland(
              title: 'Inbox',
              subtitle: const Text('4 of 1,204'),
              child: Stateful<int>(
                initial: 1,
                builder: (context, value, set) => MeridianList(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final (i, message) in _messages.indexed)
                      MeridianListRow(
                        leading: MeridianAvatar(
                          name: message.$1,
                          size: context.meridian.density.isTouch
                              ? MeridianAvatarSize.medium
                              : MeridianAvatarSize.small,
                        ),
                        title: message.$1,
                        subtitle: message.$2,
                        meta: message.$3,
                        emphasized: i == 0,
                        selected: i == value,
                        twoLine: context.meridian.density.isTouch,
                        hoverActions: const [
                          MeridianIconButton(
                            label: 'Archive',
                            icon: MeridianIcons.archive,
                            size: MeridianControlSize.small,
                            onPressed: noop,
                          ),
                        ],
                        onTap: () => set(i),
                      ),
                    const MeridianListRow(
                      title: 'Archived project',
                      dimmed: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Sidebar',
      useCases: [
        WidgetbookUseCase(
          name: 'Sections and rows',
          builder: (context) {
            final collapsible = context.knobs.boolean(
              label: 'Collapsible sections',
              initialValue: true,
            );
            final counts = context.knobs.boolean(
              label: 'Counts',
              initialValue: true,
            );
            final countTone = context.enumKnob(
              'Inbox count tone',
              MeridianCountTone.values,
              initial: MeridianCountTone.accent,
            );
            final drop = context.enumKnob(
              'Drop feedback on Work',
              MeridianDropFeedback.values,
            );
            final colors = context.meridian.colors;
            return onGround(
              maxWidth: 280,
              Stateful<(String, bool)>(
                initial: const ('Inbox', true),
                builder: (context, value, set) {
                  final (selected, open) = value;
                  MeridianNavRow row(
                    String label,
                    String icon, {
                    int? count,
                    int depth = 0,
                    Color? iconColor,
                    MeridianDropFeedback drop = MeridianDropFeedback.none,
                  }) => MeridianNavRow(
                    label: label,
                    icon: icon,
                    iconColor: iconColor,
                    depth: depth,
                    drop: drop,
                    count: counts ? count : null,
                    countTone: label == 'Inbox'
                        ? countTone
                        : MeridianCountTone.quiet,
                    selected: selected == label,
                    onTap: () => set((label, open)),
                  );
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MeridianNavSection(
                        title: 'Folders',
                        collapsible: collapsible,
                        action: const MeridianIconButton(
                          label: 'New folder',
                          icon: MeridianIcons.plus,
                          size: MeridianControlSize.small,
                          onPressed: noop,
                        ),
                        children: [
                          row('Inbox', MeridianIcons.inbox, count: 12),
                          MeridianNavRow(
                            label: 'Projects',
                            icon: MeridianIcons.folder,
                            expandable: true,
                            expanded: open,
                            selected: selected == 'Projects',
                            onToggleExpanded: () => set((selected, !open)),
                            onTap: () => set(('Projects', open)),
                          ),
                          if (open) ...[
                            row('Meridian', MeridianIcons.folder, depth: 1),
                            row('Website', MeridianIcons.folder, depth: 1),
                          ],
                          row('Archive', MeridianIcons.archive, count: 204),
                          const MeridianNavRow(
                            label: 'Shared (offline)',
                            icon: MeridianIcons.users,
                            enabled: false,
                            onTap: noop,
                          ),
                        ],
                      ),
                      MeridianNavSection(
                        title: 'Labels',
                        count: counts ? 2 : null,
                        collapsible: collapsible,
                        children: [
                          row(
                            'Work',
                            MeridianIcons.tag,
                            iconColor: colors.series[1],
                            drop: drop,
                          ),
                          row(
                            'Family',
                            MeridianIcons.tag,
                            iconColor: colors.series[3],
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Tabs',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final style = context.enumKnob('Style', MeridianTabsStyle.values);
            final count = context.knobs.int.slider(
              label: 'Tabs',
              initialValue: 4,
              min: 2,
              max: 12,
            );
            final icons = context.knobs.boolean(label: 'Icons');
            final counts = context.knobs.boolean(
              label: 'Counts',
              initialValue: true,
            );
            final closable = context.knobs.boolean(
              label: 'Closable',
              description: 'Document tabs: each one gets a close button.',
            );
            final dirty = context.knobs.boolean(
              label: 'First tab has unsaved changes',
            );
            final scrollable = context.knobs.boolean(
              label: 'Scrollable',
              initialValue: true,
            );
            const names = [
              ('Overview', MeridianIcons.house),
              ('Threads', MeridianIcons.messageSquare),
              ('Environment', MeridianIcons.settings),
              ('Billing', MeridianIcons.fileText),
            ];
            final tabs = [
              for (var i = 0; i < count; i++)
                MeridianTab(
                  label: i < names.length ? names[i].$1 : 'Tab ${i + 1}',
                  icon: icons
                      ? (i < names.length
                            ? names[i].$2
                            : MeridianIcons.fileText)
                      : null,
                  count: counts && i == 1 ? 12 : null,
                  dirty: dirty && i == 0,
                  enabled: i != 3,
                ),
            ];
            final bar = Stateful<int>(
              key: ValueKey(count),
              initial: 0,
              builder: (context, value, set) => MeridianTabs(
                style: style,
                tabs: tabs,
                index: value,
                scrollable: scrollable,
                onChanged: set,
                onClose: closable ? (_) {} : null,
                closeLabel: (tab) => 'Close $tab',
                dirtyLabel: 'unsaved changes',
              ),
            );
            // Pill tabs sit on the ground, underline tabs on an island.
            return style == MeridianTabsStyle.pill
                ? onGround(bar)
                : preview(bar);
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Tab strip',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final count = context.knobs.int.slider(
              label: 'Tabs',
              initialValue: 6,
              min: 1,
              max: 14,
            );
            final grouped = context.knobs.boolean(
              label: 'Group',
              description: 'The second and third tab share a group.',
              initialValue: true,
            );
            final collapsed = context.knobs.boolean(label: 'Collapsed');
            final icon = context.knobs.boolean(
              label: 'Group icon',
              initialValue: true,
            );
            final dirty = context.knobs.boolean(
              label: 'First tab has unsaved changes',
              initialValue: true,
            );
            return onGround(
              TabStripDemo(
                count: count,
                grouped: grouped,
                collapsed: collapsed,
                groupIcon: icon,
                dirty: dirty,
              ),
              maxWidth: 1200,
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'App bar',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final title = context.knobs.string(
              label: 'Title',
              initialValue: 'Notebooks',
            );
            final subtitle = context.optionalText(
              'Subtitle',
              'Saved on this device',
            );
            final leading = context.knobs.boolean(
              label: 'Back button',
              initialValue: true,
            );
            final actions = context.knobs.int.slider(
              label: 'Actions',
              initialValue: 2,
              max: 3,
            );
            final elevated = context.knobs.boolean(
              label: 'Elevated',
              description: 'Content has scrolled beneath the bar.',
              initialValue: true,
            );
            final center = context.knobs.boolean(label: 'Center title');
            const icons = [
              ('Search', MeridianIcons.search),
              ('Filter', MeridianIcons.listFilter),
              ('More', MeridianIcons.ellipsis),
            ];
            return onGround(
              ClipRRect(
                borderRadius: BorderRadius.circular(context.meridian.radius.lg),
                child: MeridianAppBar(
                  title: title,
                  subtitle: subtitle,
                  elevated: elevated,
                  centerTitle: center,
                  automaticallyImplyLeading: false,
                  leading: leading
                      ? const MeridianIconButton(
                          label: 'Back',
                          icon: MeridianIcons.arrowLeft,
                          onPressed: noop,
                        )
                      : null,
                  actions: [
                    for (final (label, icon) in icons.take(actions))
                      MeridianIconButton(
                        label: label,
                        icon: icon,
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
      name: 'Breadcrumbs',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final width = context.knobs.double.slider(
              label: 'Width',
              initialValue: 560,
              min: 160,
              max: 600,
            );
            return preview(
              Stateful<String>(
                initial: 'Activate a crumb, or right-click one',
                builder: (context, value, set) {
                  final meridian = context.meridian;
                  MeridianBreadcrumb folder(String name) => MeridianBreadcrumb(
                    label: name,
                    onActivate: () => set('Reveal folder $name'),
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: width),
                        child: MeridianBreadcrumbs(
                          semanticLabel: 'Location',
                          onOverflow: (hidden, _) => set(
                            'Menu of ${hidden.map((c) => c.label).join(', ')}',
                          ),
                          crumbs: [
                            MeridianBreadcrumb(
                              label: 'Move Meridian to 1.1.1',
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const MeridianIcon(
                                    MeridianIcons.gitCommitHorizontal,
                                    size: MeridianIconSize.small,
                                  ),
                                  const SizedBox(width: MeridianSpace.space2),
                                  Text('434cdea0', style: meridian.text.codeSm),
                                ],
                              ),
                              onActivate: () => set('Show all changes'),
                              onContextMenu: (_) => set('Commit menu'),
                            ),
                            folder('lib'),
                            folder('app'),
                            folder('workspace'),
                            MeridianBreadcrumb(
                              label: 'commit_files.dart',
                              mono: true,
                              emphasis: true,
                              onContextMenu: (_) => set('File menu'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: MeridianSpace.space4),
                      Text(
                        value,
                        style: meridian.text.caption.copyWith(
                          color: meridian.colors.inkMuted,
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Pagination',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final pages = context.knobs.int.slider(
              label: 'Pages',
              initialValue: 12,
              min: 1,
              max: 200,
            );
            final jump = context.knobs.boolean(
              label: 'Jump to page',
              initialValue: true,
            );
            final enabled = context.enabledKnob();
            return preview(
              Center(
                child: Stateful<int>(
                  key: ValueKey(pages),
                  initial: pages < 3 ? 1 : 3,
                  builder: (context, value, set) => MeridianPagination(
                    page: value,
                    pageCount: pages,
                    enabled: enabled,
                    previousLabel: 'Previous page',
                    nextLabel: 'Next page',
                    pageLabel: (p) => 'Page $p',
                    jumpLabel: jump ? 'Page' : null,
                    pageCountLabel: (n) => 'of $n',
                    onPageSelected: set,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Steps',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final count = context.knobs.int.slider(
              label: 'Steps',
              initialValue: 4,
              min: 1,
              max: 6,
            );
            final current = context.knobs.int.slider(
              label: 'Current (steps = all done)',
              initialValue: 1,
              min: 0,
              max: 6,
            );
            final width = context.knobs.double.slider(
              label: 'Width',
              initialValue: 560,
              min: 80,
              max: 600,
            );
            const labels = [
              'Pick',
              'Review',
              'Resolve',
              'Continue',
              'Verify',
              'Publish',
            ];
            return preview(
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width),
                child: MeridianSteps(
                  semanticLabel: 'Resolve conflicts',
                  current: current.clamp(0, count),
                  steps: [
                    for (final label in labels.take(count))
                      MeridianStep(label: label),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Selection bar',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final selected = context.knobs.int.slider(
              label: 'Selected',
              initialValue: 3,
              min: 1,
              max: 40,
            );
            final visible = context.knobs.boolean(
              label: 'Visible',
              initialValue: true,
            );
            final width = context.knobs.double.slider(
              label: 'Available width',
              description: 'Actions that do not fit move into the overflow.',
              initialValue: 520,
              min: 200,
              max: 640,
              precision: 0,
            );
            MeridianSelectionAction action(
              String label,
              String icon, {
              bool danger = false,
            }) => MeridianSelectionAction(
              child: MeridianIconButton(
                label: label,
                icon: icon,
                size: MeridianControlSize.small,
                onPressed: noop,
              ),
              overflow: MeridianMenuItem(
                label: label,
                icon: icon,
                danger: danger,
                onSelected: noop,
              ),
            );
            return onGround(
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  width: width,
                  child: MeridianIsland(
                    child: MeridianSelectionBar(
                      label: '$selected selected',
                      visible: visible,
                      clearLabel: 'Clear',
                      overflowLabel: 'More actions',
                      onClear: noop,
                      actions: [
                        action('Archive', MeridianIcons.archive),
                        action('Move to folder', MeridianIcons.folderInput),
                        action('Label', MeridianIcons.tag),
                        action('Mark as read', MeridianIcons.mailOpen),
                        action('Delete', MeridianIcons.trash2, danger: true),
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

Widget _listRowPlayground(BuildContext context) {
  final title = context.knobs.string(
    label: 'Title',
    initialValue: 'Quarterly report draft',
  );
  final subtitle = context.optionalText('Subtitle', 'Anna Berg');
  final meta = context.optionalText('Meta', '09:41');
  final match = context.optionalText('Match', 'report', on: false);
  final avatar = context.knobs.boolean(label: 'Avatar', initialValue: true);
  final count = context.knobs.boolean(label: 'Count after the title');
  final hoverActions = context.knobs.boolean(
    label: 'Hover actions',
    description: 'Shown on hover and on keyboard focus.',
    initialValue: true,
  );
  final twoLine = context.knobs.boolean(label: 'Two lines');
  final selected = context.knobs.boolean(label: 'Selected');
  final emphasized = context.knobs.boolean(
    label: 'Emphasized',
    description: 'Unread or new.',
  );
  final dimmed = context.knobs.boolean(label: 'Dimmed');
  final checked = context.knobs.objectOrNull.dropdown<bool>(
    label: 'Checked',
    description: 'A checklist row; null draws no checkbox. Tap toggles.',
    options: const [false, true],
    initialOption: false,
    defaultToNull: true,
    labelBuilder: (value) => value ? 'checked' : 'unchecked',
  );
  final enabled = context.enabledKnob();
  return onGround(
    MeridianIsland(
      child: Stateful<bool?>(
        initial: checked,
        builder: (context, value, set) => MeridianList(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MeridianListRow(
              title: title,
              subtitle: subtitle,
              meta: meta,
              match: match,
              leading: avatar ? MeridianAvatar(name: subtitle ?? title) : null,
              titleTrailing: count ? const MeridianCount(label: '2') : null,
              hoverActions: [
                if (hoverActions) ...const [
                  MeridianIconButton(
                    label: 'Archive',
                    icon: MeridianIcons.archive,
                    size: MeridianControlSize.small,
                    onPressed: noop,
                  ),
                  MeridianIconButton(
                    label: 'Delete',
                    icon: MeridianIcons.trash2,
                    size: MeridianControlSize.small,
                    onPressed: noop,
                  ),
                ],
              ],
              twoLine: twoLine,
              selected: selected,
              emphasized: emphasized,
              dimmed: dimmed,
              enabled: enabled,
              checked: value,
              onTap: value == null ? noop : () => set(!value),
            ),
          ],
        ),
      ),
    ),
  );
}
