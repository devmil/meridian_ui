import 'package:flutter/material.dart';
import 'package:meridian_ui/meridian_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'support.dart';

WidgetbookFolder feedbackFolder() => WidgetbookFolder(
  name: 'Feedback',
  children: [
    WidgetbookComponent(
      name: 'Banner',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final tone = context.enumKnob(
              'Tone',
              MeridianBannerTone.values,
              initial: MeridianBannerTone.attention,
            );
            final title = context.optionalText('Title', 'Sync paused.');
            final message = context.knobs.string(
              label: 'Message',
              initialValue:
                  'The server asked for a new password. Sign in again to '
                  'continue.',
              maxLines: 3,
            );
            final icon = context.knobs.boolean(
              label: 'Custom icon',
              description: 'Replaces the icon the tone brings.',
            );
            final actions = context.knobs.int.slider(
              label: 'Actions',
              initialValue: 1,
              max: 2,
            );
            final dismissible = context.knobs.boolean(
              label: 'Dismissible',
              initialValue: true,
            );
            final visible = context.knobs.boolean(
              label: 'Visible',
              initialValue: true,
            );
            final scrolling = context.knobs.boolean(
              label: 'Scrolling feedback area',
            );
            final banner = MeridianBanner(
              tone: tone,
              title: title,
              message: message,
              icon: icon ? MeridianIcons.cloudOff : null,
              visible: visible,
              dismissLabel: 'Dismiss',
              onDismiss: dismissible ? noop : null,
              actions: [
                if (actions > 0)
                  const MeridianButton(
                    label: 'Sign in',
                    size: MeridianControlSize.small,
                    onPressed: noop,
                  ),
                if (actions > 1)
                  const MeridianButton(
                    label: 'Work offline',
                    size: MeridianControlSize.small,
                    variant: MeridianButtonVariant.quiet,
                    onPressed: noop,
                  ),
              ],
            );
            return onGround(
              scrolling
                  ? SizedBox(
                      height: 160,
                      child: SingleChildScrollView(child: banner),
                    )
                  : banner,
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Tones',
          builder: (_) => onGround(
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: MeridianSpace.space3,
              children: [
                for (final (tone, title, message) in const [
                  (
                    MeridianBannerTone.info,
                    'Kept on the server.',
                    'Messages older than 30 days are not stored here.',
                  ),
                  (
                    MeridianBannerTone.success,
                    'Changes saved.',
                    'The project is ready to share.',
                  ),
                  (
                    MeridianBannerTone.warning,
                    'Storage is 90% full.',
                    'Remove scans you no longer need.',
                  ),
                  (
                    MeridianBannerTone.attention,
                    'Sync paused.',
                    'Sign in again to continue.',
                  ),
                  (
                    MeridianBannerTone.error,
                    'Could not send the report.',
                    'The attachment is larger than 25 MB.',
                  ),
                ])
                  MeridianBanner(tone: tone, title: title, message: message),
              ],
            ),
          ),
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Toast',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final tone = context.enumKnob('Tone', MeridianToastTone.values);
            final message = context.knobs.string(
              label: 'Message',
              initialValue: 'Saved to /exports/Project review.png',
            );
            final action = context.optionalText('Action', 'Show in Folder');
            final dismissible = context.knobs.boolean(label: 'Dismissible');
            return onGround(
              Column(
                mainAxisSize: MainAxisSize.min,
                spacing: MeridianSpace.space6,
                children: [
                  MeridianToast(
                    tone: tone,
                    message: message,
                    actionLabel: action,
                    onAction: action == null ? null : noop,
                    onDismiss: dismissible ? noop : null,
                    liveRegion: false,
                  ),
                  MeridianButton(
                    label: 'Show it as a toast',
                    onPressed: () => showMeridianToast(
                      context,
                      tone: tone,
                      message: message,
                      actionLabel: action,
                      onAction: action == null ? null : noop,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Progress bar',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final value = context.knobs.doubleOrNull.slider(
              label: 'Value',
              description: 'Null runs the indeterminate bar.',
              initialValue: 0.62,
              max: 1,
              precision: 2,
            );
            final track = context.knobs.boolean(
              label: 'Track',
              initialValue: true,
            );
            final height = context.knobs.double.slider(
              label: 'Height',
              initialValue: MeridianLayout.progressHeight,
              min: 1,
              max: 12,
              precision: 0,
            );
            return preview(
              MeridianProgressBar(
                value: value,
                track: track,
                height: height,
                // Stays visible at 100% so the knob can reach the end.
                persistent: true,
                semanticLabel: value == null
                    ? 'Loading'
                    : '${(value * 100).round()} percent complete',
              ),
              maxWidth: 420,
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Meter',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final value = context.knobs.double.slider(
              label: 'Value',
              initialValue: 0.78,
              max: 1,
              precision: 2,
            );
            final warningAt = context.knobs.doubleOrNull.slider(
              label: 'Warning at',
              initialValue: 0.5,
              max: 1,
              precision: 2,
            );
            final dangerAt = context.knobs.doubleOrNull.slider(
              label: 'Danger at',
              initialValue: 0.9,
              max: 1,
              precision: 2,
            );
            final meridian = context.meridian;
            return preview(
              Row(
                children: [
                  Expanded(
                    child: MeridianMeter(
                      value: value,
                      warningAt: warningAt,
                      dangerAt: dangerAt,
                    ),
                  ),
                  const SizedBox(width: MeridianSpace.space4),
                  Text(
                    '${(value * 100).round()}%',
                    style: MeridianTextStyles.numeric(meridian.text.caption),
                  ),
                ],
              ),
              maxWidth: 320,
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Spinner',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final size = context.knobs.double.slider(
              label: 'Size',
              initialValue: MeridianLayout.spinnerSize,
              min: 8,
              max: 64,
              precision: 0,
            );
            final accent = context.knobs.boolean(label: 'Accent colour');
            return preview(
              Center(
                child: MeridianSpinner(
                  size: size,
                  color: accent ? context.meridian.colors.accent : null,
                  semanticLabel: 'Loading',
                  delayed: false,
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Skeleton',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final rows = context.knobs.int.slider(
              label: 'Rows',
              initialValue: 3,
              min: 1,
              max: 8,
            );
            final height = context.knobs.double.slider(
              label: 'Height',
              initialValue: MeridianLayout.skeletonHeight,
              min: 4,
              max: 40,
              precision: 0,
            );
            const widths = [220.0, 300.0, 180.0, 260.0];
            return preview(
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: MeridianSpace.space4,
                children: [
                  for (var i = 0; i < rows; i++)
                    MeridianSkeleton(
                      width: widths[i % widths.length],
                      height: height,
                    ),
                ],
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Empty state',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final title = context.knobs.string(
              label: 'Title',
              initialValue: 'No messages match “invoice 2025”',
            );
            final message = context.optionalText(
              'Message',
              'Try fewer words or search all folders.',
            );
            final icon = context.knobs.boolean(
              label: 'Icon',
              initialValue: true,
            );
            final headline = context.knobs.boolean(
              label: 'Headline',
              description: 'The first-run size, in the display style.',
            );
            final action = context.knobs.boolean(label: 'Action');
            final progress = context.knobs.boolean(
              label: 'Progress',
              description: 'Something is loading: a spinner replaces the icon.',
            );
            final value = context.knobs.doubleOrNull.slider(
              label: 'Progress value',
              initialValue: 0.4,
              max: 1,
            );
            final compact = context.knobs.boolean(
              label: 'Compact',
              description: 'The in-pane size for small islands.',
            );
            return preview(
              MeridianEmptyState(
                title: title,
                message: message,
                icon: icon ? MeridianIcons.textSearch : null,
                headline: headline,
                progress: progress,
                progressValue: value,
                compact: compact,
                action: action
                    ? const MeridianButton(
                        label: 'Search all folders',
                        variant: MeridianButtonVariant.primary,
                        onPressed: noop,
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Busy overlay',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final busy = context.knobs.boolean(
              label: 'Busy',
              initialValue: true,
            );
            final message = context.optionalText('Message', 'Verifying…');
            final cancel = context.knobs.boolean(
              label: 'Cancel action',
              initialValue: false,
            );
            return onGround(
              maxWidth: 360,
              SizedBox(
                height: 180,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: MeridianIsland(
                        title: 'Security key',
                        padding: EdgeInsets.all(MeridianSpace.space5),
                        child: MeridianTextField(
                          label: 'Code',
                          placeholder: '6 digits',
                        ),
                      ),
                    ),
                    if (busy)
                      Positioned.fill(
                        child: MeridianBusyOverlay(
                          message: message,
                          action: cancel
                              ? const MeridianButton(
                                  label: 'Cancel',
                                  variant: MeridianButtonVariant.quiet,
                                  onPressed: noop,
                                )
                              : null,
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
  ],
);
