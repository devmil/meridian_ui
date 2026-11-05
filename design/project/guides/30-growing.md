# Growing Meridian

Meridian grows when an app needs something it does not have. The rule for what goes where:

- **Shared** (in `meridian_ui` and on this page): anything two apps need, or anything clearly generic (a date picker, a table header, a tree view). It is built from tokens and `MeridianInteraction`, has a live preview and a guideline here, a gallery entry and a test.
- **App-only**: domain components (a commit graph, a mail composer, a process tree, a pen canvas) and domain tokens. They live in the app, built from Meridian primitives and tokens, and move here when a second app needs them.

## Adding a primitive

1. Check the inventory on this page. If an existing component can do it with one more property, extend it instead.
2. Write the guideline first (`design/project/components/<Name>/README.md`, generated from `design/src/components.py`): what it is for, what the consumer provides, which tokens it uses, its states and its don'ts.
3. Build `Meridian<Name>` in `lib/src/components/`, using only tokens, `MeridianInteraction` for hover/press/focus, `MeridianMotion` for durations, and semantics for role, state and name. It works at every density and in every brand.
4. Add it to the gallery (`example/`) and a widget test (tap, keyboard, disabled, touch target).
5. Add its web rendition to `design/src/bundle.src.js` and `bundle.css`, and a preview. Run `python3 tool/build_bundle.py` and `python3 design/src/components.py`, then republish this system.

## Adding a token

Edit `tokens/meridian.tokens.json`, name it for its role rather than its look (`attention`, not `orange`), give it a usage note that names the grounds it reads on, and run `python3 tool/generate.py`. A token that would fail a contrast floor in any brand or theme does not ship.

## Versions

`meridian_ui` follows semantic versioning. A removed or renamed token or widget property is a major version; apps pin the version they were migrated to and move up deliberately. Every change is listed in `CHANGELOG.md`.
