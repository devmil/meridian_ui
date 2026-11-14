import 'package:flutter/widgets.dart';
import 'package:meridian_ui/meridian_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'support.dart';

/// The motion helpers. Switch on Reduce motion in the Meridian addon to see
/// each fallback.
WidgetbookFolder motionFolder() => WidgetbookFolder(
  name: 'Motion',
  children: [
    WidgetbookComponent(
      name: 'Swap',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final style = context.enumKnob(
              'Style',
              MeridianSwapStyle.values,
              initial: MeridianSwapStyle.rise,
            );
            final text = context.knobs.object.segmented<String>(
              label: 'Content',
              description: 'Change it to swap.',
              options: const ['Fetch', 'Fetching…', 'Up to date'],
            );
            final down = context.knobs.boolean(
              label: 'Roll down',
              description: 'Only for the roll style.',
            );
            return preview(
              Center(
                child: MeridianSwap(
                  swapKey: text,
                  style: style,
                  direction: down ? -1 : 1,
                  alignment: Alignment.center,
                  child: Text(text, style: context.meridian.text.heading),
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Rolling number',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final value = context.knobs.int.slider(
              label: 'Value',
              initialValue: 1204,
              max: 5000,
            );
            final pop = context.knobs.boolean(
              label: 'Pop on increase',
              initialValue: true,
            );
            final unit = context.knobs.boolean(label: 'With a unit');
            return preview(
              Center(
                child: MeridianRollingNumber(
                  value: value,
                  popOnIncrease: pop,
                  format: unit ? (v) => '$v messages' : null,
                  style: MeridianTextStyles.numeric(
                    context.meridian.text.title,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Reveal',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final visible = context.knobs.boolean(
              label: 'Visible',
              initialValue: true,
            );
            final axis = context.enumKnob(
              'Axis',
              Axis.values,
              initial: Axis.vertical,
            );
            final fadeOnly = context.knobs.boolean(
              label: 'Fade only',
              description: 'Keeps its size and only fades.',
            );
            return preview(
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MeridianListRow(title: 'Inbox'),
                  MeridianReveal(
                    visible: visible,
                    axis: axis,
                    fadeOnly: fadeOnly,
                    child: const MeridianListRow(
                      title: 'Drafts',
                      subtitle: 'Appears and leaves with the knob',
                    ),
                  ),
                  const MeridianListRow(title: 'Archive'),
                ],
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Shake',
      useCases: [
        WidgetbookUseCase(
          name: 'Rejected input',
          builder: (context) {
            final strength = context.enumKnob(
              'Strength',
              MeridianShakeStrength.values,
            );
            return preview(
              Stateful<int>(
                initial: 0,
                builder: (context, value, set) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: MeridianSpace.space5,
                  children: [
                    MeridianShake(
                      trigger: value,
                      strength: strength,
                      child: MeridianTextField(
                        label: 'Server',
                        placeholder: 'cloud.example.org',
                        error: value == 0
                            ? null
                            : 'Enter a host name without https://',
                      ),
                    ),
                    MeridianButton(
                      label: 'Connect',
                      variant: MeridianButtonVariant.primary,
                      onPressed: () => set(value + 1),
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
    WidgetbookComponent(
      name: 'Pulse',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) {
            final active = context.knobs.boolean(
              label: 'Active',
              initialValue: true,
            );
            final size = context.knobs.double.slider(
              label: 'Size',
              initialValue: 12,
              min: 6,
              max: 40,
              precision: 0,
            );
            final meridian = context.meridian;
            return preview(
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(MeridianSpace.space10),
                  child: MeridianPulse(
                    active: active,
                    color: meridian.colors.success,
                    size: size,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: meridian.colors.success,
                        shape: BoxShape.circle,
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
      name: 'Entrance',
      useCases: [
        WidgetbookUseCase(
          name: 'Staggered list',
          builder: (context) {
            final rows = context.knobs.int.slider(
              label: 'Rows',
              initialValue: 5,
              min: 1,
              max: 10,
            );
            return preview(
              Stateful<int>(
                initial: 0,
                builder: (context, run, set) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MeridianButton(
                      label: 'Load again',
                      size: MeridianControlSize.small,
                      onPressed: () => set(run + 1),
                    ),
                    const SizedBox(height: MeridianSpace.space4),
                    // A scope per run forgets which rows have entered.
                    MeridianMotionScope(
                      key: ValueKey(run),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < rows; i++)
                            MeridianEntrance(
                              entranceKey: 'row-$i',
                              index: i,
                              child: MeridianListRow(
                                title: 'Notebook ${i + 1}',
                                meta: '${(i + 1) * 7} pages',
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
  ],
);
