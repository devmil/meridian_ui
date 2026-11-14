# LicenseDialog

The licenses of an app and everything it bundles: the packages listed at the start, the selected package's licenses beside them. Flutter: `MeridianLicenseDialog` with `showMeridianLicenses` (or `showMeridianDialog`). It replaces Flutter's Material `showLicensePage`.

- Open it from the About dialog ("Licenses") and, where an app has one, from a Settings page. It is the only place an app shows license text.
- It reads `LicenseRegistry`: the Flutter engine's notices plus every license the app registers with `LicenseRegistry.addLicense` (its own license, generated dependency inventories, font and icon notices). Register the app's documents once at startup; the dialog does not read files itself. `licenses` replaces the source in tests and previews.
- The consumer provides `title` (defaults to "Licenses"), `applicationName`, `applicationVersion`, `applicationIcon` (about 40px) and `applicationLegalese`, shown at the top of the list, plus `onClose` (pops the route by default) and `width`.
- A title bar with ✕ over a hairline; the list on `ground` (`licenseDialogPackageListWidth`, 260px): the app header, a search TextField that filters packages, then a NavRow per package with its license count. A vertical hairline, then the package on `raised`: its name in `title`, the count in `caption` `ink-muted`, and each license in `caption` `ink`, separated by hairlines, lines at most 720px (`licenseTextMaxWidth`). Indented paragraphs step 16px per level; centred ones stay centred. 960px wide (`licenseDialogWidth`), up to 720px tall (at most 85% of the window).
- Packages sort by name without regard to case; the first is selected when the dialog opens. Tab reaches the list, Up and Down move between packages. License text is selectable and scrolls on its own, starting at the top for each package.
- Below 640px of dialog width (`licenseDialogPagedBreakpoint`) and at touch density the list fills the dialog; picking a package shows its licenses with a back button in the title bar.
- While the registry loads, a compact EmptyState with a spinner; a filter that matches nothing shows "No packages match".
- Don't add an app's licenses as one long text, link to a website instead of shipping the text, or restyle Material's license page.
