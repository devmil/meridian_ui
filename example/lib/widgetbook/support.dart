import 'package:flutter/widgets.dart';
import 'package:meridian_ui/meridian_ui.dart';
import 'package:widgetbook/widgetbook.dart';

void noop() {}

/// One island on the ground, the surface most components live on.
Widget preview(Widget child, {double maxWidth = 640}) => MeridianGround(
  child: Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(MeridianSpace.space5),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: MeridianIsland(
          padding: const EdgeInsets.all(MeridianSpace.space5),
          child: child,
        ),
      ),
    ),
  ),
);

/// Directly on the ground, for components that bring their own surface.
Widget onGround(Widget child, {double maxWidth = 640}) => MeridianGround(
  child: Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(MeridianSpace.space5),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    ),
  ),
);

/// A wrapping row of examples.
Widget wrap(List<Widget> children, {double spacing = MeridianSpace.space4}) =>
    Wrap(
      spacing: spacing,
      runSpacing: spacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );

/// A caption over an example, for use cases that compare variants.
class Labeled extends StatelessWidget {
  const Labeled(this.label, this.child, {super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final meridian = context.meridian;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: meridian.text.caption.copyWith(
            color: meridian.colors.inkMuted,
          ),
        ),
        const SizedBox(height: MeridianSpace.space3),
        child,
      ],
    );
  }
}

/// Holds the value a control edits, so it responds inside a use case while
/// knobs drive everything else. A new [initial] from a knob replaces it.
class Stateful<T> extends StatefulWidget {
  const Stateful({required this.initial, required this.builder, super.key});

  final T initial;
  final Widget Function(BuildContext context, T value, ValueChanged<T> set)
  builder;

  @override
  State<Stateful<T>> createState() => _StatefulState<T>();
}

class _StatefulState<T> extends State<Stateful<T>> {
  late T _value = widget.initial;

  @override
  void didUpdateWidget(Stateful<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial) _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    _value,
    (value) => setState(() => _value = value),
  );
}

/// Icons offered by the icon knobs: a short list keeps the dropdown usable.
const knobIcons = [
  MeridianIcons.download,
  MeridianIcons.copy,
  MeridianIcons.search,
  MeridianIcons.plus,
  MeridianIcons.archive,
  MeridianIcons.trash2,
  MeridianIcons.send,
  MeridianIcons.refreshCw,
  MeridianIcons.settings,
  MeridianIcons.folder,
  MeridianIcons.gitBranch,
  MeridianIcons.lock,
  MeridianIcons.star,
  MeridianIcons.pin,
  MeridianIcons.listFilter,
  MeridianIcons.layoutGrid,
];

extension MeridianKnobs on BuildContext {
  /// An enum as a dropdown labelled with the value names.
  T enumKnob<T extends Enum>(String label, List<T> values, {T? initial}) =>
      knobs.object.dropdown<T>(
        label: label,
        options: values,
        initialOption: initial ?? values.first,
        labelBuilder: (value) => value.name,
      );

  /// An icon from [knobIcons], or none.
  String? iconKnob(String label, {String? initial}) =>
      knobs.objectOrNull.dropdown<String>(
        label: label,
        options: knobIcons,
        initialOption: initial ?? knobIcons.first,
        defaultToNull: initial == null,
      );

  /// A required icon from [knobIcons].
  String requiredIconKnob(String label, {String? initial}) =>
      knobs.object.dropdown<String>(
        label: label,
        options: knobIcons,
        initialOption: initial ?? knobIcons.first,
      );

  /// Whether the control responds; off shows the disabled state.
  bool enabledKnob() => knobs.boolean(label: 'Enabled', initialValue: true);

  /// Text that is left out when the knob is switched to null.
  String? optionalText(String label, String initial, {bool on = true}) => knobs
      .stringOrNull(label: label, initialValue: initial, defaultToNull: !on);
}
