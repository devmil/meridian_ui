import 'meridian_tokens.g.dart';

/// How tightly an app packs rows and controls.
///
/// The three desktop densities change row height and nothing else. [touch]
/// is for phones and tablets: taller rows and controls, a 48px minimum hit
/// target, larger icons and the touch type scale.
enum MeridianDensity {
  compact,
  regular,
  comfortable,
  touch;

  /// True for [touch].
  bool get isTouch => this == MeridianDensity.touch;

  /// Height of list, navigation and menu rows.
  double get rowExtent => switch (this) {
    MeridianDensity.compact => MeridianSize.rowCompact,
    MeridianDensity.regular => MeridianSize.row,
    MeridianDensity.comfortable => MeridianSize.rowComfortable,
    MeridianDensity.touch => MeridianSize.rowTouch,
  };

  /// Height of buttons, fields, selects and segmented controls.
  double get controlExtent =>
      isTouch ? MeridianSize.controlTouch : MeridianSize.control;

  /// Height of the small control size (island headers, row actions).
  double get controlSmallExtent =>
      isTouch ? MeridianSize.control : MeridianSize.controlSm;

  /// The smallest hit target a control may have.
  double get minTarget => isTouch ? MeridianSize.targetTouch : 0;

  /// The default icon size.
  double get iconSize => isTouch ? 20 : MeridianSize.icon;

  /// The icon size inside chips and small controls.
  double get iconSmallSize => isTouch ? 18 : 14;

  /// The type scale that goes with this density.
  MeridianTypeScale get typeScale =>
      isTouch ? MeridianTypeScale.touch : MeridianTypeScale.desktop;
}
