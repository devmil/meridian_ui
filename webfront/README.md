# Meridian public site

`index.html`, `style.css` and `site.js` are the public landing page. The live
Flutter component browser is compiled from `example/lib/widgetbook.dart` into
`webfront/widgetbook/` by the Forgejo sync workflow. That build directory is
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
Forgejo workflow derives it from `GH_REPO_URL`.

## Publishing

Forgejo `main` is authoritative. `.forgejo/workflows/sync-website.yml` builds
Widgetbook and runs `scripts/sync-website-mirror.sh`, which mirrors only
`webfront/` and the Pages workflow into a GitHub repository. The destination
must have a `main` branch; an existing `webfront/` must carry the
`.meridian-site-owner` marker. The script does not force-push.

Set Forgejo secrets `GH_REPO_URL` to `owner/repository` and `GH_SYNC_TOKEN` to a
GitHub token that can write contents and workflows in that repository. In the
GitHub repository, choose **GitHub Actions** as the Pages source. Its
`.github/workflows/meridian-pages.yml` deploys the mirrored `webfront/` tree.
The repository's site will be at `https://owner.github.io/repository/`, or at
`https://owner.github.io/` when the repository is named `owner.github.io`.
