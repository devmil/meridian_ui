# SelectableText

Text people can select and copy: a hash, a path, an error, a value in a property list. Flutter: `MeridianSelectableText` (and `.rich`), or `MeridianSelectionArea` around any text, on the widgets layer's `SelectableRegion`.

- The consumer provides the text (or a span), `style`, `textAlign`, `maxLines`, `overflow`, `semanticsLabel`, `focusNode` and `contextMenuBuilder`.
- Selection is `accent-soft`; drag, double click (word), Shift with the arrows and select all work as on the platform, and touch shows `accent` handles.
- A secondary click or long press opens the text menu: Meridian's menu (`meridianTextMenu`: Copy, Select all) or the app's `MeridianMenuPresenter.textContextMenuBuilder` (native menus). It does not take focus from the selection.
- Use it only for values people copy, never for labels or headings; a whole list of selectable rows is a `MeridianSelectionArea` around the list.
