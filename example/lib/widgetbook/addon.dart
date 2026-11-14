import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:meridian_ui/meridian_ui.dart';
import 'package:widgetbook/widgetbook.dart';

/// Brand, theme, density, reduced motion and speed, each as its own addon so
/// the side panel names every control.
///
/// Keep the order: the first four hand their choice down the tree, and the
/// last one builds the Meridian theme from them.
List<WidgetbookAddon> meridianAddons() => [
  _ChoiceAddon<MeridianBrand>(
    name: 'Brand',
    values: MeridianBrands.all,
    label: (brand) => brand.name,
  ),
  _ChoiceAddon<Brightness>(
    name: 'Theme',
    values: const [Brightness.light, Brightness.dark],
    label: (brightness) => brightness.name,
    segmented: true,
  ),
  // `null` keeps the density the brand ships with, so switching the brand
  // shows each app as it is built.
  _ChoiceAddon<MeridianDensity?>(
    name: 'Density',
    values: const [null, ...MeridianDensity.values],
    label: (density) => density?.name ?? 'Brand default',
  ),
  _ReduceMotionAddon(),
  _SpeedAddon(),
];

/// Hands one addon's choice to the addons nested inside it.
class _Choice<T> extends InheritedWidget {
  const _Choice({required this.value, required super.child});

  final T value;

  static T? of<T>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Choice<T>>()?.value;

  @override
  bool updateShouldNotify(_Choice<T> oldWidget) => value != oldWidget.value;
}

class _ChoiceAddon<T> extends WidgetbookAddon<T> {
  _ChoiceAddon({
    required super.name,
    required this.values,
    required this.label,
    this.segmented = false,
  });

  final List<T> values;
  final String Function(T value) label;
  final bool segmented;

  @override
  List<Field> get fields => [
    segmented
        ? ObjectSegmentedField<T>(
            name: 'name',
            values: values,
            initialValue: values.first,
            labelBuilder: label,
          )
        : ObjectDropdownField<T>(
            name: 'name',
            values: values,
            initialValue: values.first,
            labelBuilder: label,
          ),
  ];

  @override
  T valueFromQueryGroup(Map<String, String> group) {
    final chosen = group['name'];
    return values.firstWhere(
      (value) => label(value) == chosen,
      orElse: () => values.first,
    );
  }

  @override
  Widget buildUseCase(BuildContext context, Widget child, T setting) =>
      _Choice<T>(value: setting, child: child);
}

class _ReduceMotionAddon extends WidgetbookAddon<bool> {
  _ReduceMotionAddon() : super(name: 'Reduce motion');

  @override
  List<Field> get fields => [
    BooleanField(name: 'enabled', initialValue: false),
  ];

  @override
  bool valueFromQueryGroup(Map<String, String> group) =>
      valueOf<bool>('enabled', group) ?? false;

  @override
  Widget buildUseCase(BuildContext context, Widget child, bool setting) =>
      setting
      ? MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child,
        )
      : child;
}

/// Slow motion for review, through Flutter's global `timeDilation`.
class _SpeedAddon extends WidgetbookAddon<double> {
  _SpeedAddon() : super(name: 'Speed');

  static const _slowdowns = {'1×': 1.0, '0.5×': 2.0, '0.2×': 5.0};

  @override
  List<Field> get fields => [
    ObjectSegmentedField<String>(
      name: 'factor',
      values: _slowdowns.keys.toList(),
      initialValue: _slowdowns.keys.first,
    ),
  ];

  @override
  double valueFromQueryGroup(Map<String, String> group) =>
      _slowdowns[group['factor']] ?? 1;

  @override
  Widget buildUseCase(BuildContext context, Widget child, double setting) {
    timeDilation = setting;
    final theme = MeridianTheme.resolve(
      brand: _Choice.of<MeridianBrand>(context) ?? MeridianBrands.all.first,
      brightness: _Choice.of<Brightness>(context) ?? Brightness.light,
      density: _Choice.of<MeridianDensity?>(context),
    );
    return MeridianThemeScope(
      theme: theme,
      child: ColoredBox(color: theme.colors.ground, child: child),
    );
  }
}
