# Meridian public site

`index.html`, `style.css` and `site.js` are the public landing page. The live
Flutter component browser is compiled from `example/lib/widgetbook.dart` into
`webfront/widgetbook/` by the Pages workflow. That build directory is
ignored locally and mirrored only as compiled web assets.

The page's Live section embeds Widgetbook in preview mode once the visitor
asks for it, so the page itself stays light. Without JavaScript the section
links to Widgetbook instead.

Token values, brand facts and Widgetbook links on the page are checked against
the library by `example/test/website_test.dart`. Update the page when a token,
a brand or a use case name changes.

`favicon.svg` is the master of the Meridian mark. After changing it, run
`python3 tool/build_site_icons.py` to regenerate `icons/meridian-<size>.png`
and the copy Widgetbook serves.

To preview the landing page, run `python3 -m http.server 4173 --directory webfront`.
To build Widgetbook locally, run:

```sh
cd example
flutter pub get
flutter build web --release --target lib/widgetbook.dart --base-href /meridian_ui/widgetbook/
```

To preview the landing page together with Widgetbook, build with
`--base-href /widgetbook/` and copy `example/build/web/` to
`webfront/widgetbook/`.

Choose the base path for the public repository before serving the build. The
Pages workflow derives it from the repository name.

## Publishing

`.github/workflows/meridian-pages.yml` runs on every push to `main` that touches
the site, Widgetbook or the library. It builds Widgetbook into
`webfront/widgetbook/` and deploys `webfront/` with GitHub Pages. In the
repository settings, choose **GitHub Actions** as the Pages source. The site is
served at `https://owner.github.io/repository/`, or at `https://owner.github.io/`
when the repository is named `owner.github.io`.
