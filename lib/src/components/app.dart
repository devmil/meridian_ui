import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../foundation/meridian_localizations.dart';
import '../foundation/meridian_theme.dart';
import '../foundation/meridian_theme_scope.dart';
import '../foundation/meridian_tokens.g.dart';
import '../foundation/predictive_back.dart';
import 'scrollbar.dart';

/// Which of an app's themes shows.
enum MeridianThemeMode {
  /// The light or dark theme, following the platform.
  system,

  /// Always the light theme.
  light,

  /// Always the dark theme.
  dark,
}

/// A Meridian application: [WidgetsApp] with a Meridian theme, Meridian
/// page routes and scrolling, and Meridian's strings, with no Material.
///
/// [theme] shows in light mode and [darkTheme] (when given) in dark mode,
/// chosen by [themeMode]. A change animates over [themeAnimationDuration].
/// [builder] wraps the navigator inside the theme, so it can read
/// `context.meridian`. [MeridianLocalizations.delegate] is added to
/// [localizationsDelegates].
class MeridianApp extends StatefulWidget {
  const MeridianApp({
    required this.theme,
    super.key,
    this.darkTheme,
    this.themeMode = MeridianThemeMode.system,
    this.themeAnimationDuration = MeridianDurations.overlay,
    this.themeAnimationCurve = Curves.linear,
    this.navigatorKey,
    this.home,
    this.routes = const {},
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.navigatorObservers = const [],
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const [Locale('en', 'US')],
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.scrollBehavior,
    this.pageTransition,
  });

  final MeridianTheme theme;
  final MeridianTheme? darkTheme;
  final MeridianThemeMode themeMode;
  final Duration themeAnimationDuration;
  final Curve themeAnimationCurve;
  final GlobalKey<NavigatorState>? navigatorKey;
  final Widget? home;
  final Map<String, WidgetBuilder> routes;
  final String? initialRoute;
  final RouteFactory? onGenerateRoute;
  final RouteFactory? onUnknownRoute;
  final List<NavigatorObserver> navigatorObservers;
  final TransitionBuilder? builder;
  final String title;
  final GenerateAppTitle? onGenerateTitle;
  final Locale? locale;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final LocaleListResolutionCallback? localeListResolutionCallback;
  final LocaleResolutionCallback? localeResolutionCallback;
  final Iterable<Locale> supportedLocales;
  final bool debugShowCheckedModeBanner;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;
  final String? restorationScopeId;

  /// How scroll views scroll and show scrollbars;
  /// [MeridianScrollBehavior] by default.
  final ScrollBehavior? scrollBehavior;

  /// The transition of every [MeridianPageRoute] that sets none;
  /// [MeridianPageTransition.platform] by default.
  final MeridianPageTransition? pageTransition;

  @override
  State<MeridianApp> createState() => _MeridianAppState();
}

class _MeridianAppState extends State<MeridianApp> {
  final _heroes = HeroController();

  @override
  void dispose() {
    _heroes.dispose();
    super.dispose();
  }

  MeridianTheme _themeFor(BuildContext context) {
    final dark = widget.darkTheme;
    final useDark = switch (widget.themeMode) {
      MeridianThemeMode.light => false,
      MeridianThemeMode.dark => true,
      MeridianThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    return useDark && dark != null ? dark : widget.theme;
  }

  Widget _build(BuildContext context, Widget? child) {
    final builder = widget.builder;
    return AnimatedMeridianTheme(
      theme: _themeFor(context),
      duration: widget.themeAnimationDuration,
      curve: widget.themeAnimationCurve,
      child: ScrollConfiguration(
        behavior: widget.scrollBehavior ?? const MeridianScrollBehavior(),
        child: _PageTransitionScope(
          transition: widget.pageTransition ?? MeridianPageTransition.platform,
          child: builder == null
              ? child ?? const SizedBox.shrink()
              : Builder(builder: (context) => builder(context, child)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => HeroControllerScope(
    controller: _heroes,
    child: WidgetsApp(
      navigatorKey: widget.navigatorKey,
      home: widget.home,
      routes: widget.routes,
      initialRoute: widget.initialRoute,
      onGenerateRoute: widget.onGenerateRoute,
      onUnknownRoute: widget.onUnknownRoute,
      navigatorObservers: widget.navigatorObservers,
      pageRouteBuilder: <T>(settings, builder) =>
          MeridianPageRoute<T>(settings: settings, builder: builder),
      builder: _build,
      title: widget.title,
      onGenerateTitle: widget.onGenerateTitle,
      color: widget.theme.colors.accent,
      locale: widget.locale,
      localizationsDelegates: [
        ...?widget.localizationsDelegates,
        MeridianLocalizations.delegate,
      ],
      localeListResolutionCallback: widget.localeListResolutionCallback,
      localeResolutionCallback: widget.localeResolutionCallback,
      supportedLocales: widget.supportedLocales,
      debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
      shortcuts: widget.shortcuts,
      actions: widget.actions,
      restorationScopeId: widget.restorationScopeId,
    ),
  );
}

/// How Meridian views scroll: on desktop they clamp at their edges, show
/// no overscroll glow or stretch, and draw Meridian's scrollbar thumb while
/// they scroll (always, with [alwaysShowThumb]); on phones and tablets they
/// keep the platform's feel.
class MeridianScrollBehavior extends ScrollBehavior {
  const MeridianScrollBehavior({this.alwaysShowThumb = false});

  /// Shows the desktop thumb whenever a view has more than it shows, not
  /// only while it scrolls.
  final bool alwaysShowThumb;

  static bool _desktop(TargetPlatform platform) => switch (platform) {
    TargetPlatform.macOS ||
    TargetPlatform.linux ||
    TargetPlatform.windows => true,
    _ => false,
  };

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.unknown,
  };

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => _desktop(getPlatform(context))
      ? child
      : super.buildOverscrollIndicator(context, child, details);

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      _desktop(getPlatform(context))
      ? const ClampingScrollPhysics()
      : super.getScrollPhysics(context);

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (!_desktop(getPlatform(context))) return child;
    return switch (axisDirectionToAxis(details.direction)) {
      Axis.vertical || Axis.horizontal => MeridianScrollbarThumb(
        controller: details.controller,
        thumbVisibility: alwaysShowThumb ? true : null,
        child: child,
      ),
    };
  }
}

/// How a [MeridianPageRoute] enters and leaves. Reduce motion makes every
/// built-in transition instant.
abstract class MeridianPageTransition {
  const MeridianPageTransition();

  /// No motion: the page is there.
  static const MeridianPageTransition instant = _InstantTransition();

  /// A cross-fade.
  static const MeridianPageTransition fade = _FadeTransition();

  /// The new page rises a quarter of its height while it fades in.
  static const MeridianPageTransition fadeUpwards = _FadeUpwardsTransition();

  /// Android's predictive back: the page follows the back gesture; other
  /// transitions [fadeUpwards].
  static const MeridianPageTransition predictiveBack =
      _PredictiveBackTransition();

  /// [predictiveBack] on Android, [fadeUpwards] on iOS, [fade] on desktop.
  static const MeridianPageTransition platform = _PlatformTransition();

  /// How long the route takes to enter (and leave).
  Duration get duration => MeridianDurations.sheet;

  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  );
}

class _InstantTransition extends MeridianPageTransition {
  const _InstantTransition();

  @override
  Duration get duration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

class _FadeTransition extends MeridianPageTransition {
  const _FadeTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MeridianMotion.reduced(context)
      ? child
      : FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: MeridianCurves.enter,
          ),
          child: child,
        );
}

class _FadeUpwardsTransition extends MeridianPageTransition {
  const _FadeUpwardsTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MeridianMotion.reduced(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: MeridianCurves.enter,
      reverseCurve: Curves.easeIn,
    );
    return SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.25),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(opacity: curved, child: child),
    );
  }
}

class _PredictiveBackTransition extends MeridianPageTransition {
  const _PredictiveBackTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MeridianMotion.reduced(context)
      ? child
      : meridianPredictiveBackTransition(
          route: route,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
          fallback: () => MeridianPageTransition.fadeUpwards.buildTransitions(
            route,
            context,
            animation,
            secondaryAnimation,
            child,
          ),
        );
}

class _PlatformTransition extends MeridianPageTransition {
  const _PlatformTransition();

  static MeridianPageTransition _resolve(TargetPlatform platform) =>
      switch (platform) {
        TargetPlatform.android => MeridianPageTransition.predictiveBack,
        TargetPlatform.iOS ||
        TargetPlatform.fuchsia => MeridianPageTransition.fadeUpwards,
        _ => MeridianPageTransition.fade,
      };

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _resolve(defaultTargetPlatform)
      .buildTransitions(route, context, animation, secondaryAnimation, child);
}

class _PageTransitionScope extends InheritedWidget {
  const _PageTransitionScope({required this.transition, required super.child});

  final MeridianPageTransition transition;

  static MeridianPageTransition? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_PageTransitionScope>()
      ?.transition;

  @override
  bool updateShouldNotify(_PageTransitionScope oldWidget) =>
      transition != oldWidget.transition;
}

/// A full-screen page: the route `MeridianApp` uses for its routes and
/// the one to push for a new screen. It enters with [transition], else
/// the app's `pageTransition`, else [MeridianPageTransition.platform].
class MeridianPageRoute<T> extends PageRoute<T> {
  MeridianPageRoute({
    required this.builder,
    super.settings,
    this.transition,
    this.maintainState = true,
    super.fullscreenDialog,
    super.allowSnapshotting,
  });

  final WidgetBuilder builder;
  final MeridianPageTransition? transition;

  @override
  final bool maintainState;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration =>
      (transition ?? MeridianPageTransition.platform).duration;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is MeridianPageRoute && !nextRoute.fullscreenDialog;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: builder(context),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      (transition ??
              _PageTransitionScope.maybeOf(context) ??
              MeridianPageTransition.platform)
          .buildTransitions(
            this,
            context,
            animation,
            secondaryAnimation,
            child,
          );

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}
