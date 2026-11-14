# App

The root of a Meridian application. Flutter: `MeridianApp`, a `WidgetsApp` with no Material.

- The consumer provides `theme` (`MeridianTheme.resolve(brand:, brightness:)`), `darkTheme` and `themeMode` (`MeridianThemeMode.system`, `light`, `dark`), the usual `home`/`routes`/`onGenerateRoute`, `builder`, `localizationsDelegates` and `supportedLocales`, and optionally `scrollBehavior` and `pageTransition`.
- A theme change blends over `motion-overlay` (`AnimatedMeridianTheme`; instant with reduce motion). `MeridianLocalizations.delegate` is always added.
- Pages are `MeridianPageRoute`s. `pageTransition` picks how they move: `MeridianPageTransition.platform` (predictive back on Android, fade upwards on iOS, a fade on desktop), `fade`, `fadeUpwards`, `predictiveBack` or `instant`. Reduce motion makes every built-in transition instant.
- `MeridianScrollBehavior` clamps scrolling on desktop, shows no glow or stretch there, and draws Meridian's scrollbar thumb while a view scrolls; phones keep the platform's feel.
- Inside another app shell (a plugin window, a test host) put a `MeridianThemeScope` above Meridian widgets instead. Never mix in `MaterialApp`, `Theme` or Material widgets.
