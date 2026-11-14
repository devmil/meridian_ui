# Scaffold

A screen's frame: an app bar on top, the body, a bottom bar below and an optional navigation drawer. Flutter: `MeridianScaffold`.

- The consumer provides `appBar` (a `MeridianAppBar`), `body`, `bottomBar` (a status bar, toolbar or navigation bar), `drawer` (a `MeridianDrawer`), `backgroundColor` (`ground` by default), `resizeToAvoidBottomInset` and `drawerEdgeDragWidth`.
- The body fills the space between the bars and moves up out of the on-screen keyboard; padding the bars take care of is removed from the body. The bottom bar hides while the keyboard is up.
- The drawer slides in from the leading edge over `scrim` with `motion-sheet` and `curve-enter` and leaves over `motion-exit`. It opens from the app bar's menu button, `MeridianScaffold.of(context).openDrawer()` or a swipe from the edge at touch density, and closes with `Navigator.pop` (like a route), Escape, the back button, a swipe or the scrim. Focus moves into it while it is open; the body is hidden from focus and assistive technology.
- Desktop windows often need no scaffold: a `MeridianGround` with a toolbar and a status bar is the frame.
