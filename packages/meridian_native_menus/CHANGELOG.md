# Changelog

## 1.0.1 - 2026-10-12

- Fix the Windows host plugin not compiling: it called the non-const
  `FlutterView::GetNativeWindow` through a const pointer (MSVC C2662).

## 1.0.0 - 2026-10-11

- First release, with Meridian 1.6.0: a `MeridianMenuPresenter` that shows
  `MeridianMenuEntry` menus as native menus (macOS and Windows through this
  package's host plugin, Linux through `super_native_extensions`), a native
  context-menu region with keyboard invocation and focus restoration, a
  native text-editing menu, and the pure menu model and host protocol.
  Generalised from GitLama's `native_menu.dart` and its runner hosts.
