import 'package:flutter/widgets.dart';

import 'meridian_theme.dart';
import 'meridian_tokens.g.dart';

/// Puts [theme] above [child]: every Meridian widget below reads it with
/// `MeridianTheme.of(context)`.
///
/// It also sets what the widgets layer takes from the ambient theme: the
/// default text style (`body` in `ink`), the icon colour and size, and the
/// caret and selection colours. `MeridianApp` installs one; use it directly
/// to show Meridian inside another app shell or to give a subtree another
/// brand.
class MeridianThemeScope extends StatelessWidget {
  const MeridianThemeScope({
    required this.theme,
    required this.child,
    super.key,
  });

  final MeridianTheme theme;
  final Widget child;

  /// The nearest theme, or `null` when there is none.
  static MeridianTheme? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_InheritedMeridianTheme>()
      ?.theme;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return _InheritedMeridianTheme(
      theme: theme,
      child: DefaultTextStyle(
        style: theme.text.body.copyWith(color: colors.ink),
        child: IconTheme(
          data: IconThemeData(color: colors.ink, size: theme.density.iconSize),
          child: DefaultSelectionStyle(
            cursorColor: colors.accent,
            selectionColor: colors.accentSoft,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _InheritedMeridianTheme extends InheritedTheme {
  const _InheritedMeridianTheme({required this.theme, required super.child});

  final MeridianTheme theme;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      MeridianThemeScope(theme: theme, child: child);

  @override
  bool updateShouldNotify(_InheritedMeridianTheme oldWidget) =>
      theme != oldWidget.theme;
}

/// A [MeridianThemeScope] that animates to a new [theme] (light to dark, a
/// brand or density change) over [duration], blending with
/// [MeridianTheme.lerp]. Reduce motion makes the change instant.
class AnimatedMeridianTheme extends ImplicitlyAnimatedWidget {
  const AnimatedMeridianTheme({
    required this.theme,
    required this.child,
    super.key,
    super.curve = Curves.linear,
    super.duration = MeridianDurations.overlay,
    super.onEnd,
  });

  final MeridianTheme theme;
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedMeridianTheme> createState() =>
      _AnimatedMeridianThemeState();
}

class _MeridianThemeTween extends Tween<MeridianTheme> {
  _MeridianThemeTween({super.begin});

  @override
  MeridianTheme lerp(double t) => begin!.lerp(end, t);
}

class _AnimatedMeridianThemeState
    extends AnimatedWidgetBaseState<AnimatedMeridianTheme> {
  _MeridianThemeTween? _theme;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _theme = visitor(
      _theme,
      widget.theme,
      (value) => _MeridianThemeTween(begin: value as MeridianTheme),
    ) as _MeridianThemeTween?;
  }

  @override
  Widget build(BuildContext context) => MeridianThemeScope(
    theme: MeridianMotion.reduced(context)
        ? widget.theme
        : _theme!.evaluate(animation),
    child: widget.child,
  );
}
