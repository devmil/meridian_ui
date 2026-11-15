import 'package:flutter/widgets.dart';
import 'package:meridian_ui/meridian_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'support.dart';

WidgetbookFolder displayFolder() => WidgetbookFolder(
  name: 'Display',
  children: [
    WidgetbookComponent(
      name: 'Tooltip',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final message = context.knobs.string(
              label: 'Message',
              initialValue: 'Fetch from origin',
            );
            final below = context.knobs.boolean(
              label: 'Prefer below',
              initialValue: true,
            );
            final excluded = context.knobs.boolean(
              label: 'Exclude from semantics',
              description: 'When the control already announces the text.',
            );
            return preview(
              Center(
                child: MeridianTooltip(
                  message: message,
                  preferBelow: below,
                  excludeFromSemantics: excluded,
                  child: MeridianIconButton(
                    label: message,
                    icon: MeridianIcons.refreshCw,
                    onPressed: noop,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Selectable text',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final text = context.knobs.string(
              label: 'Text',
              initialValue: '3f2a9c1e7b4d',
            );
            final mono = context.knobs.boolean(
              label: 'Monospace',
              initialValue: true,
            );
            final maxLines = context.knobs.int.slider(
              label: 'Max lines',
              initialValue: 2,
              min: 1,
              max: 4,
            );
            return preview(
              Builder(
                builder: (context) => Center(
                  child: MeridianSelectableText(
                    text,
                    maxLines: maxLines,
                    style: mono
                        ? context.meridian.text.code
                        : context.meridian.text.body,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Avatar',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final name = context.knobs.string(
              label: 'Name',
              description: 'Sets the initials and the colour.',
              initialValue: 'Michael Lamers',
            );
            final monogram = context.optionalText('Monogram', 'ML', on: false);
            final size = context.enumKnob(
              'Size',
              MeridianAvatarSize.values,
              initial: MeridianAvatarSize.large,
            );
            final pressable = context.knobs.boolean(
              label: 'Pressable',
              description: 'A button with a tooltip and focus ring.',
            );
            final tooltip = context.optionalText('Tooltip', 'Show profile');
            return preview(
              Center(
                child: MeridianAvatar(
                  name: name,
                  monogram: monogram,
                  size: size,
                  tooltip: tooltip,
                  onPressed: pressable ? noop : null,
                ),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Sizes',
          builder: (_) => preview(
            wrap([
              for (final size in MeridianAvatarSize.values)
                MeridianAvatar(name: 'Ada Lovelace', size: size),
            ]),
          ),
        ),
        WidgetbookUseCase(
          name: 'People',
          builder: (_) => preview(
            wrap([
              for (final name in const [
                'Michael Lamers',
                'Ada Lovelace',
                'Anna Berg',
                'Jonas Weber',
                'Grace Hopper',
                'Alan Turing',
              ])
                MeridianAvatar(name: name, size: MeridianAvatarSize.medium),
            ]),
          ),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Count',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final value = context.knobs.int.slider(
              label: 'Value',
              initialValue: 12,
              max: 150,
            );
            final tone = context.enumKnob(
              'Tone',
              MeridianCountTone.values,
              initial: MeridianCountTone.accent,
            );
            final emphasize = context.knobs.boolean(
              label: 'Emphasize increase',
              description: 'Raise the value to see the count pop.',
              initialValue: true,
            );
            return preview(
              Center(
                child: MeridianCount(
                  label: value > 99 ? '99+' : '$value',
                  tone: tone,
                  emphasizeIncrease: emphasize,
                ),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Tones',
          builder: (_) => preview(
            wrap([
              for (final tone in MeridianCountTone.values)
                Labeled(tone.name, MeridianCount(label: '12', tone: tone)),
            ], spacing: MeridianSpace.space6),
          ),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Chip',
      useCases: [
        WidgetbookUseCase(
          name: 'Enlarged labels',
          builder: (context) => preview(
            MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: wrap([
                const MeridianChip(
                  label: 'Danach bearbeiten',
                  icon: MeridianIcons.pencil,
                  selected: true,
                  maxWidth: 360,
                  onPressed: noop,
                ),
                const MeridianChip(
                  label: 'Anhang entfernen',
                  onRemove: noop,
                  removeLabel: 'Anhang entfernen',
                  maxWidth: 240,
                ),
              ]),
            ),
          ),
        ),
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final label = context.knobs.string(
              label: 'Label',
              initialValue: 'Needs review',
            );
            final tone = context.enumKnob('Tone', MeridianChipTone.values);
            final icon = context.iconKnob('Icon');
            final dot = context.knobs.boolean(
              label: 'Colour dot',
              description: 'A label colour from the categorical series.',
            );
            final kind = context.knobs.object.segmented<String>(
              label: 'Kind',
              description: 'A static tag, a filter that toggles, or an entry.',
              options: const ['Tag', 'Filter', 'Removable'],
            );
            final maxWidth = context.knobs.double.slider(
              label: 'Maximum width',
              initialValue: MeridianLayout.chipMaxWidth,
              min: 60,
              max: 320,
              precision: 0,
            );
            final enabled = context.enabledKnob();
            return preview(
              Center(
                child: Stateful<bool>(
                  initial: true,
                  builder: (context, selected, set) => MeridianChip(
                    label: label,
                    tone: tone,
                    icon: icon,
                    dotColor: dot ? context.meridian.colors.series[1] : null,
                    selected: kind == 'Filter' ? selected : null,
                    onPressed: kind == 'Filter' ? () => set(!selected) : null,
                    onRemove: kind == 'Removable' ? noop : null,
                    removeLabel: 'Remove $label',
                    maxWidth: maxWidth,
                    enabled: enabled,
                  ),
                ),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Tones',
          builder: (_) => preview(
            wrap([
              for (final tone in MeridianChipTone.values)
                MeridianChip(label: tone.name, tone: tone),
            ]),
          ),
        ),
        WidgetbookUseCase(
          name: 'Filters',
          builder: (_) => preview(
            Stateful<Set<String>>(
              initial: const {'Unread'},
              builder: (context, value, set) => wrap([
                for (final filter in const [
                  'Unread',
                  'Starred',
                  'With attachments',
                  'From people I know',
                ])
                  MeridianChip(
                    label: filter,
                    selected: value.contains(filter),
                    onPressed: () => set(
                      value.contains(filter)
                          ? ({...value}..remove(filter))
                          : {...value, filter},
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Status dot',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final tone = context.enumKnob(
              'Tone',
              MeridianStatusTone.values,
              initial: MeridianStatusTone.success,
            );
            final label = context.optionalText('Label', 'Running');
            final halo = context.knobs.boolean(
              label: 'Halo',
              initialValue: true,
            );
            final live = context.knobs.boolean(
              label: 'Live',
              description: 'Breathes while the value is being updated.',
            );
            return preview(
              Center(
                child: MeridianStatusDot(
                  tone: tone,
                  label: label,
                  semanticLabel: label ?? tone.name,
                  halo: halo,
                  live: live,
                ),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Tones',
          builder: (_) => preview(
            wrap([
              for (final tone in MeridianStatusTone.values)
                MeridianStatusDot(tone: tone, label: tone.name),
            ], spacing: MeridianSpace.space6),
          ),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Keycap',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final keys = context.knobs.string(
              label: 'Keys',
              description: 'Separate the keys with spaces.',
              initialValue: '⌘ ⇧ P',
            );
            final reveal = context.enumKnob('Reveal', MeridianKbdReveal.values);
            final pressed = context.knobs.booleanOrNull(
              label: 'Pressed',
              defaultToNull: true,
            );
            final onAccent = context.knobs.boolean(
              label: 'On accent',
              description: 'For a keycap inside a primary button.',
            );
            final meridian = context.meridian;
            return preview(
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: onAccent ? meridian.colors.accent : null,
                    borderRadius: BorderRadius.circular(meridian.radius.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(MeridianSpace.space4),
                    child: MeridianKbd(
                      keys: keys.trim().split(RegExp(r'\s+')),
                      reveal: reveal,
                      pressed: pressed,
                      onAccent: onAccent,
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
      name: 'Middle ellipsis',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final text = context.knobs.string(
              label: 'Text',
              initialValue: 'origin/feature/update-route-dialog-when-offline',
            );
            final width = context.knobs.double.slider(
              label: 'Available width',
              initialValue: 220,
              min: 40,
              max: 560,
              precision: 0,
            );
            final meridian = context.meridian;
            return preview(
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: meridian.colors.lineStrong),
                      borderRadius: BorderRadius.circular(meridian.radius.sm),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MeridianSpace.space3,
                        vertical: MeridianSpace.space1,
                      ),
                      child: MeridianMiddleEllipsis(
                        text,
                        style: meridian.text.caption,
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
  ],
);
