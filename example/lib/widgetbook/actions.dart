import 'package:flutter/material.dart';
import 'package:meridian_ui/meridian_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'support.dart';

WidgetbookFolder actionsFolder() => WidgetbookFolder(
  name: 'Actions',
  children: [
    WidgetbookComponent(
      name: 'Button',
      useCases: [
        WidgetbookUseCase(name: 'Playground', builder: _buttonPlayground),
        WidgetbookUseCase(
          name: 'Label confirmation',
          builder: (_) => preview(const _ButtonConfirmationDemo()),
        ),
        WidgetbookUseCase(
          name: 'Ranks',
          builder: (context) {
            final size = context.enumKnob('Size', MeridianControlSize.values);
            return preview(
              wrap([
                for (final (variant, label) in const [
                  (MeridianButtonVariant.primary, 'Create project'),
                  (MeridianButtonVariant.secondary, 'Export'),
                  (MeridianButtonVariant.quiet, 'Copy ID'),
                  (MeridianButtonVariant.danger, 'Delete project'),
                  (MeridianButtonVariant.dangerQuiet, 'Discard'),
                ])
                  MeridianButton(
                    label: label,
                    variant: variant,
                    size: size,
                    onPressed: noop,
                  ),
              ]),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Loading and disabled',
          builder: (_) => preview(
            wrap(const [
              MeridianButton(label: 'Sync now', loading: true, onPressed: noop),
              MeridianButton(
                label: 'Send',
                variant: MeridianButtonVariant.primary,
                disabledReason: 'Add a recipient first',
                onPressed: null,
              ),
              MeridianButton(label: 'Saved', success: true, onPressed: noop),
            ]),
          ),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Split button',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) => preview(
            MeridianSplitButton(
              label: context.knobs.string(label: 'Label', initialValue: 'Save'),
              optionsLabel: 'Save options',
              icon: MeridianIcons.save,
              compact: context.knobs.boolean(label: 'Compact'),
              loading: context.knobs.boolean(label: 'Loading'),
              success: context.knobs.boolean(label: 'Success'),
              optionsEnabled: context.knobs.boolean(
                label: 'Options enabled',
                initialValue: true,
              ),
              size: context.enumKnob('Size', MeridianControlSize.values),
              variant: context.enumKnob(
                'Rank',
                MeridianButtonVariant.values,
                initial: MeridianButtonVariant.primary,
              ),
              onPressed: context.enabledKnob() ? noop : null,
              disabledReason: 'Choose a destination first',
              entries: [
                const MeridianMenuItem(label: 'Save as…', onSelected: noop),
                const MeridianMenuItem(label: 'Copy as file', onSelected: noop),
              ],
            ),
          ),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Icon button',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final icon = context.requiredIconKnob(
              'Icon',
              initial: MeridianIcons.search,
            );
            final label = context.knobs.string(
              label: 'Label',
              description: 'Read by screen readers and shown as the tooltip.',
              initialValue: 'Search',
            );
            final size = context.enumKnob('Size', MeridianControlSize.values);
            final active = context.knobs.booleanOrNull(
              label: 'Active',
              description: 'Null for an action, true or false for a toggle.',
              defaultToNull: true,
            );
            final badge = context.knobs.intOrNull.slider(
              label: 'Badge',
              initialValue: 3,
              max: 120,
              defaultToNull: true,
            );
            final badgeTone = context.enumKnob(
              'Badge tone',
              MeridianCountTone.values,
              initial: MeridianCountTone.accent,
            );
            final spinning = context.knobs.boolean(label: 'Spinning');
            final nudge = context.enumKnob('Nudge', MeridianNudge.values);
            final enabled = context.enabledKnob();
            return preview(
              Center(
                child: MeridianIconButton(
                  label: label,
                  icon: icon,
                  size: size,
                  active: active,
                  badge: badge,
                  badgeTone: badgeTone,
                  spinning: spinning,
                  nudge: nudge,
                  disabledReason: enabled ? null : 'Nothing to search yet',
                  onPressed: enabled ? noop : null,
                ),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Toggle group',
          builder: (_) => preview(
            Stateful<String>(
              initial: 'grid',
              builder: (context, value, set) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (id, label, icon) in const [
                    ('list', 'Show as list', MeridianIcons.list),
                    ('tree', 'Show as tree', MeridianIcons.listTree),
                    ('grid', 'Show as grid', MeridianIcons.layoutGrid),
                  ])
                    MeridianIconButton(
                      label: label,
                      icon: icon,
                      active: value == id,
                      onPressed: () => set(id),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Toolbar button',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final label = context.knobs.string(
              label: 'Label',
              initialValue: 'Refresh',
            );
            final icon = context.requiredIconKnob(
              'Icon',
              initial: MeridianIcons.refreshCw,
            );
            final showLabel = context.knobs.boolean(
              label: 'Show label',
              initialValue: true,
            );
            final selected = context.knobs.boolean(label: 'Selected');
            final badge = context.knobs.intOrNull.slider(
              label: 'Badge',
              initialValue: 4,
              max: 120,
            );
            final menu = context.knobs.boolean(
              label: 'Menu',
              description: 'Adds the split arrow with more choices.',
            );
            final enabled = context.enabledKnob();
            return onGround(
              Center(
                child: MeridianToolbarButton(
                  label: label,
                  icon: icon,
                  showLabel: showLabel,
                  selected: selected,
                  badge: badge,
                  menuLabel: menu ? 'More options' : null,
                  menu: menu
                      ? [
                          const MeridianMenuItem(
                            label: 'Refresh all',
                            icon: MeridianIcons.refreshCw,
                            onSelected: noop,
                          ),
                          const MeridianMenuItem(
                            label: 'Refresh later…',
                            icon: MeridianIcons.clock,
                            onSelected: noop,
                          ),
                        ]
                      : null,
                  disabledReason: enabled ? null : 'You are offline',
                  onPressed: enabled ? noop : null,
                ),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Toolbar',
          builder: (_) => onGround(
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MeridianToolbarButton(
                    label: 'New',
                    icon: MeridianIcons.squarePlus,
                    onPressed: noop,
                  ),
                  MeridianToolbarButton(
                    label: 'Refresh',
                    icon: MeridianIcons.refreshCw,
                    badge: 4,
                    onPressed: noop,
                  ),
                  MeridianToolbarButton(
                    label: 'Send',
                    icon: MeridianIcons.send,
                    onPressed: noop,
                    menuLabel: 'More send options',
                    menu: [
                      MeridianMenuItem(
                        label: 'Send later…',
                        icon: MeridianIcons.clock,
                        onSelected: noop,
                      ),
                    ],
                  ),
                  MeridianToolbarButton(
                    label: 'Archive',
                    icon: MeridianIcons.archive,
                    disabledReason: 'Select a message first',
                    onPressed: null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Floating button',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final label = context.knobs.string(
              label: 'Label',
              initialValue: 'New notebook',
            );
            final icon = context.requiredIconKnob(
              'Icon',
              initial: MeridianIcons.plus,
            );
            final extended = context.knobs.boolean(
              label: 'Extended',
              description: 'Shows the label beside the icon.',
            );
            final enabled = context.enabledKnob();
            return onGround(
              Center(
                child: MeridianFloatingButton(
                  label: label,
                  icon: icon,
                  extended: extended,
                  onPressed: enabled ? noop : null,
                ),
              ),
            );
          },
        ),
      ],
    ),
  ],
);

Widget _buttonPlayground(BuildContext context) {
  final label = context.knobs.string(
    label: 'Label',
    initialValue: 'Move 3 messages to archive',
  );
  final variant = context.enumKnob(
    'Variant',
    MeridianButtonVariant.values,
    initial: MeridianButtonVariant.primary,
  );
  final size = context.enumKnob('Size', MeridianControlSize.values);
  final icon = context.iconKnob('Icon');
  final iconOnly = context.knobs.boolean(
    label: 'Icon only',
    description:
        'Toggle during loading or confirmation to review compact transitions.',
  );
  final trailingIcon = context.knobs.boolean(
    label: 'Trailing chevron',
    description: 'For a button that opens a menu.',
  );
  final shortcut = context.knobs.boolean(label: 'Shortcut');
  final shortcutReveal = context.enumKnob(
    'Shortcut reveal',
    MeridianKbdReveal.values,
  );
  final loading = context.knobs.boolean(label: 'Loading');
  final success = context.knobs.boolean(label: 'Success');
  final successReplacesLabel = context.knobs.boolean(
    label: 'Success replaces label',
  );
  final animateLabel = context.knobs.boolean(
    label: 'Animate label',
    description: 'Edit the label to see the new one rise into place.',
  );
  final expand = context.knobs.boolean(label: 'Expand');
  final enabled = context.enabledKnob();
  return preview(
    Center(
      child: MeridianButton(
        label: label,
        variant: variant,
        size: size,
        icon: iconOnly ? (icon ?? MeridianIcons.save) : icon,
        iconOnly: iconOnly,
        trailingIcon: trailingIcon ? MeridianIcons.chevronDown : null,
        shortcut: shortcut ? const ['⌘', '↵'] : null,
        shortcutReveal: shortcutReveal,
        loading: loading,
        success: success,
        successReplacesLabel: successReplacesLabel,
        animateLabel: animateLabel,
        expand: expand,
        disabledReason: enabled ? null : 'Select a message first',
        onPressed: enabled ? noop : null,
      ),
    ),
  );
}

class _ButtonConfirmationDemo extends StatefulWidget {
  const _ButtonConfirmationDemo();

  @override
  State<_ButtonConfirmationDemo> createState() =>
      _ButtonConfirmationDemoState();
}

class _ButtonConfirmationDemoState extends State<_ButtonConfirmationDemo> {
  var _success = false;

  @override
  Widget build(BuildContext context) => MeridianButton(
    label: 'Copy ID',
    icon: MeridianIcons.copy,
    success: _success,
    successReplacesLabel: true,
    onSuccessFinished: () => setState(() => _success = false),
    onPressed: _success ? null : () => setState(() => _success = true),
  );
}
