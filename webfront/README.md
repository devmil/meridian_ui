# Meridian public site

`index.html` and `style.css` are the public landing page. The live Flutter
component browser is compiled from `example/lib/widgetbook.dart` into
`webfront/widgetbook/` by the Forgejo sync workflow. That build directory is
ignored locally and mirrored only as compiled web assets.

To preview the landing page, run `python3 -m http.server 4173 --directory webfront`.
To build Widgetbook locally, run:

```sh
cd example
flutter pub get
flutter build web --release --target lib/widgetbook.dart --base-href /meridian_ui/widgetbook/
```

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
