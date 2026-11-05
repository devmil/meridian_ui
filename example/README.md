# Meridian gallery

Every primitive in `meridian_ui`, with switches for brand, theme and density.

```sh
cd example
flutter create --platforms=macos,linux,windows,ios,android .   # first run only
flutter run -d macos
```

## Widgetbook

The isolated component browser has its own entry point. Run it with
`flutter run -d chrome -t lib/widgetbook.dart`. The Pages workflow
builds this entry point for the public site.

`lib/widgetbook/` has one file per component group. A `Playground` use case
exposes a component's properties as knobs; the other use cases show fixed
comparisons such as every tone. The Addons panel sets brand, theme, density,
reduced motion, speed, viewport and text scale. `Brand default` density keeps
the density the chosen brand ships with.

Settings live in the address, so a state can be shared as a link. Add
`&preview=true` to show the component alone:

```text
#/?path=actions/button/playground&brand={name:Nibluma}&theme={name:dark}
```

`test/widgetbook_test.dart` opens every use case at 390 px and 1280 px in
regular and touch density. `test/website_test.dart` checks the landing page's
Widgetbook links and token facts against the library.
