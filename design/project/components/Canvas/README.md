# Canvas

The desk behind documents: page feeds, scan and image viewers, print previews. Flutter: `MeridianCanvas`.

- Paints `canvas`, which sits one step away from `ground` so that pages read as objects resting on a surface, not as islands. A brand may set its own `canvas` in its neutrals (Nibluma lifts it in dark so white paper glares less).
- Pages on it are Paper. Tools float over it in a ToolDock; nothing else floats there except menus, popovers and toasts.
- Text straight on the canvas is chrome only (a page number, a zoom level) in `ink` or `ink-muted`. Anything longer goes in a raised surface.
