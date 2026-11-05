# Scrollbar

The scrollbar of one scroll view that decides when its thumb shows. Flutter: `MeridianScrollbar`.

- Use it for a sidebar or a list beside the content, where a thumb that is always there competes with the rows. The main content keeps the scrollbar of the platform.
- The consumer provides the `controller` of the scroll view, the `child` that holds this view, and `visibility`: **hover** (the default) shows the thumb while the pointer is over the view and while it scrolls, **scrolling** only while it scrolls, **always** as long as the view has more than it shows.
- The thumb fades in and out and takes no room: rows keep their width. 6px wide, 8px under the pointer, `radius-pill`, `line-strong`, `control-edge` while hovered or dragged.
- On touch there is no pointer to hover: the thumb shows while a finger scrolls.
- Wrap one scroll view, not a screen: the scroll views below lose the scrollbar the platform adds. Never hide the only sign that a view scrolls where its content gives none, such as a list that ends exactly at a row edge; use **always** there.
