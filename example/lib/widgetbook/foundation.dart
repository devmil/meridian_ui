import 'package:flutter/material.dart';
import 'package:meridian_ui/meridian_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'support.dart';

WidgetbookFolder foundationFolder() => WidgetbookFolder(
  name: 'Foundation',
  children: [
    WidgetbookComponent(
      name: 'Colours',
      useCases: [
        WidgetbookUseCase(
          name: 'Tokens',
          builder: (context) {
            final colors = context.meridian.colors;
            return onGround(
              maxWidth: 720,
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: MeridianSpace.space3,
                children: [
                  _Swatches('Accent', [
                    ('accent', colors.accent),
                    ('on-accent', colors.onAccent),
                    ('on-accent-muted', colors.onAccentMuted),
                    ('accent-soft', colors.accentSoft),
                    ('accent-ink', colors.accentInk),
                    ('focus', colors.focus),
                    ('brand', colors.brand),
                  ]),
                  _Swatches('Surfaces', [
                    ('ground', colors.ground),
                    ('ground-hover', colors.groundHover),
                    ('pane', colors.pane),
                    ('pane-alt', colors.paneAlt),
                    ('pane-hover', colors.paneHover),
                    ('raised', colors.raised),
                    ('canvas', colors.canvas),
                  ]),
                  _Swatches('Ink and lines', [
                    ('ink', colors.ink),
                    ('ink-muted', colors.inkMuted),
                    ('ink-faint', colors.inkFaint),
                    ('line', colors.line),
                    ('line-strong', colors.lineStrong),
                    ('control-edge', colors.controlEdge),
                  ]),
                  _Swatches('Status', [
                    ('success', colors.success),
                    ('success-bg', colors.successBg),
                    ('warning', colors.warning),
                    ('warning-bg', colors.warningBg),
                    ('danger', colors.danger),
                    ('danger-bg', colors.dangerBg),
                    ('attention', colors.attention),
                    ('attention-bg', colors.attentionBg),
                  ]),
                  _Swatches('Series', [
                    for (final (i, color) in colors.series.indexed)
                      ('series-${i + 1}', color),
                  ]),
                ],
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Typography',
      useCases: [
        WidgetbookUseCase(
          name: 'Mono weights',
          builder: (context) {
            final sample = context.knobs.string(
              label: 'Sample',
              initialValue: 'ÄÖÜ 0123456789',
            );
            final weight = context.knobs.object.dropdown<FontWeight>(
              label: 'Weight',
              options: [FontWeight.w400, FontWeight.w500, FontWeight.w700],
              initialOption: FontWeight.w500,
              labelBuilder: (value) => value.value.toString(),
            );
            return preview(
              Text(
                sample,
                style: context.meridian.text.code.copyWith(fontWeight: weight),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Type scale',
          builder: (context) {
            final sample = context.knobs.string(
              label: 'Sample',
              initialValue: 'Islands on a tinted ground',
            );
            final text = context.meridian.text;
            final muted = context.meridian.colors.inkMuted;
            return preview(
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: MeridianSpace.space5,
                children: [
                  for (final (name, style) in [
                    ('display', text.display),
                    ('title', text.title),
                    ('heading', text.heading),
                    ('body', text.body),
                    ('body-strong', text.bodyStrong),
                    ('label', text.label),
                    ('caption', text.caption),
                    ('overline', text.overline),
                    ('code', text.code),
                    ('code-sm', text.codeSm),
                    ('reading', text.reading),
                  ])
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$name · ${style.fontSize?.round()} / '
                          '${style.fontWeight?.value}',
                          style: text.codeSm.copyWith(color: muted),
                        ),
                        const SizedBox(height: MeridianSpace.space1),
                        Text(sample, style: style),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Shape and space',
      useCases: [
        WidgetbookUseCase(
          name: 'Radius',
          builder: (context) {
            final meridian = context.meridian;
            final radius = meridian.radius;
            return preview(
              wrap(spacing: MeridianSpace.space6, [
                for (final (name, value) in [
                  ('xs', radius.xs),
                  ('sm', radius.sm),
                  ('md', radius.md),
                  ('lg', radius.lg),
                  ('xl', radius.xl),
                ])
                  Labeled(
                    '$name · ${value.round()}',
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: meridian.colors.accentSoft,
                        border: Border.all(color: meridian.colors.accent),
                        borderRadius: BorderRadius.circular(value),
                      ),
                    ),
                  ),
              ]),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Spacing',
          builder: (context) {
            final meridian = context.meridian;
            return preview(
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: MeridianSpace.space4,
                children: [
                  for (final (i, value) in const [
                    MeridianSpace.space1,
                    MeridianSpace.space2,
                    MeridianSpace.space3,
                    MeridianSpace.space4,
                    MeridianSpace.space5,
                    MeridianSpace.space6,
                    MeridianSpace.space7,
                    MeridianSpace.space8,
                    MeridianSpace.space9,
                    MeridianSpace.space10,
                  ].indexed)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            'space-${i + 1} · ${value.round()}',
                            style: meridian.text.codeSm.copyWith(
                              color: meridian.colors.inkMuted,
                            ),
                          ),
                        ),
                        Container(
                          width: value,
                          height: MeridianSpace.space6,
                          color: meridian.colors.accent,
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Elevation',
          builder: (context) {
            final meridian = context.meridian;
            return onGround(
              wrap(spacing: MeridianSpace.space9, [
                for (final (name, shadow, color) in [
                  ('shadow-control', meridian.shadows.shadowControl, null),
                  ('shadow-pane', meridian.shadows.shadowPane, null),
                  (
                    'shadow-float',
                    meridian.shadows.shadowFloat,
                    meridian.colors.raised,
                  ),
                ])
                  Labeled(
                    name,
                    Container(
                      width: 140,
                      height: 88,
                      decoration: BoxDecoration(
                        color: color ?? meridian.colors.pane,
                        borderRadius: BorderRadius.circular(meridian.radius.lg),
                        boxShadow: shadow,
                      ),
                    ),
                  ),
              ]),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Icons',
      useCases: [
        WidgetbookUseCase(
          name: 'Library',
          builder: (context) {
            final filter = context.knobs.string(
              label: 'Filter',
              description: 'Part of an icon name, such as “folder”.',
            );
            final size = context.enumKnob(
              'Size',
              MeridianIconSize.values,
              initial: MeridianIconSize.regular,
            );
            final accent = context.knobs.boolean(label: 'Accent colour');
            final meridian = context.meridian;
            final query = filter.trim().toLowerCase();
            final names = [
              for (final name in MeridianIcons.all)
                if (name.contains(query)) name,
            ];
            return onGround(
              maxWidth: 960,
              MeridianIsland(
                title: 'Lucide',
                subtitle: Text(
                  '${names.length} of ${MeridianIcons.all.length}',
                ),
                padding: const EdgeInsets.all(MeridianSpace.space5),
                child: names.isEmpty
                    ? MeridianEmptyState(
                        icon: MeridianIcons.searchX,
                        title: 'No icon matches “$filter”',
                      )
                    : Wrap(
                        spacing: MeridianSpace.space3,
                        runSpacing: MeridianSpace.space5,
                        children: [
                          for (final name in names)
                            SizedBox(
                              width: 104,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MeridianIcon(
                                    name,
                                    size: size,
                                    color: accent
                                        ? meridian.colors.accent
                                        : null,
                                  ),
                                  const SizedBox(height: MeridianSpace.space3),
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: meridian.text.codeSm.copyWith(
                                      color: meridian.colors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
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
      name: 'Interaction',
      useCases: [
        WidgetbookUseCase(
          name: 'Custom surface',
          builder: (context) {
            final doubleTap = context.knobs.boolean(
              label: 'Double tap',
              initialValue: false,
            );
            final pressScale = context.knobs.boolean(
              label: 'Press scale',
              initialValue: true,
            );
            final enabled = context.enabledKnob();
            return preview(
              Center(
                child: MeridianInteraction(
                  onTap: enabled ? noop : null,
                  onDoubleTap: enabled && doubleTap ? noop : null,
                  pressScale: pressScale,
                  borderRadius: BorderRadius.circular(
                    context.meridian.radius.lg,
                  ),
                  builder: (context, state) {
                    final meridian = context.meridian;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: state.pressed
                            ? meridian.colors.accentSoft
                            : state.hovered
                            ? meridian.colors.paneHover
                            : meridian.colors.paneAlt,
                        border: Border.all(color: meridian.colors.line),
                        borderRadius: BorderRadius.circular(meridian.radius.lg),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(MeridianSpace.space6),
                        child: Text(
                          [
                            if (!state.enabled) 'disabled',
                            if (state.hovered) 'hovered',
                            if (state.pressed) 'pressed',
                            if (state.focused) 'focused',
                            if (state.enabled &&
                                !state.hovered &&
                                !state.pressed &&
                                !state.focused)
                              'at rest',
                          ].join(' · '),
                          style: meridian.text.bodyStrong,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    ),
  ],
);

/// A named row of colour tokens with their hex values.
class _Swatches extends StatelessWidget {
  const _Swatches(this.title, this.colors);

  final String title;
  final List<(String, Color)> colors;

  static String _hex(Color color) {
    final argb = color.toARGB32();
    final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    final alpha = argb >> 24;
    return alpha == 0xFF
        ? '#${rgb.toUpperCase()}'
        : '#${rgb.toUpperCase()} · ${(alpha / 2.55).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    final meridian = context.meridian;
    return MeridianIsland(
      title: title,
      padding: const EdgeInsets.all(MeridianSpace.space5),
      child: Wrap(
        spacing: MeridianSpace.space5,
        runSpacing: MeridianSpace.space5,
        children: [
          for (final (name, color) in colors)
            SizedBox(
              width: 120,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: meridian.colors.line),
                      borderRadius: BorderRadius.circular(meridian.radius.md),
                    ),
                  ),
                  const SizedBox(height: MeridianSpace.space3),
                  Text(name, style: meridian.text.label),
                  Text(
                    _hex(color),
                    style: meridian.text.codeSm.copyWith(
                      color: meridian.colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
