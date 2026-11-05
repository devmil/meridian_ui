# Pagination

Numbered pages of a collection that loads one page at a time: search results, a server-paged list. Flutter: `MeridianPagination`.

- The consumer provides `page` (from 1), `pageCount`, `onPageSelected`, the localized `previousLabel` and `nextLabel`, a `pageLabel` for page buttons ("Page 3"), and optionally `jumpLabel` with `jumpSemanticLabel` and `pageCountLabel` for a field that jumps to a page ("Page [3] of 12"). Set `enabled: false` while a page loads.
- Up to seven pages show in full; beyond that the first, the last and the current page's neighbours, with `…` for the gaps. The current page is `accent-soft` with `accent-ink`; the others are quiet and hover like icon buttons. Numbers use tabular figures.
- Small controls. The jump field accepts digits only, selects its text on focus, clamps to the range and runs on Enter. Nothing shows for a single page.
- Prefer continuous scrolling for lists that can load more on their own; pagination is for sources that are paged.
- Motion: The current page's pill glides (MM-29).
