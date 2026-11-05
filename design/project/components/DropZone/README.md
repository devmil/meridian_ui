# DropZone

A dashed area that takes dropped files: attachments, imports. Flutter: `MeridianDropZone`.

- The consumer provides `label` ("Drop files to attach"), an optional `message` ("Up to 25 MB"), `icon` (`upload` by default), `state` and `onBrowse`, which makes the zone a button that opens a file picker (click, Enter or Space): a drop is never the only way in.
- **idle**: a 1px dashed `line-strong` edge, `ink-muted`. **active** (acceptable files are over it): `accent` edge on `accent-soft`, `accent-ink`. **invalid**: `danger` edge and text. Hover darkens the edge to `ink-muted`.
- `radius-lg`, at least 104px tall, `space-6` padding, a 24px icon over a `label` and a `caption`. The app owns the drag transport and sets `state`; over an editor, show the zone as an overlay only while files are dragged over the window.
- Motion: While a drag is over it the dashed edge marches (MM-77).
