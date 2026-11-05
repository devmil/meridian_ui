Meridian is the design system for every Flutter app in this family: GitLama (Git client, desktop), CrossProton (Proton Mail client, desktop), Mimameidr (process explorer, desktop) and Nibluma (notebooks, phones and tablets), and the apps that come after them. It is dense and keyboard-first on desktop, generous and thumb-first on touch, and calm on both. The work sits on rounded **islands** on a tinted **ground**. One **accent**, set by each app's brand, is spent only on intent.

The shared core (surfaces, ink, status and categorical colours, type scales, spacing, shape, depth, motion, states and the primitives) is the same in every app. Each app's **brand** changes its accent family, its fonts, its corner radius scale and its default density, and may bring its own **neutrals** (surfaces, canvas, ink and lines) when the shared cool neutrals do not suit it; Nibluma's warm paper is the example. The theme switcher shows each brand in light and dark; `Light` and `Dark` are the GitLama reference.

The shipped implementation is the Flutter package `meridian_ui` (`MeridianButton`, `MeridianIsland`, …). The previews here are its web rendition.

## Principles

1. **Islands on a ground.** The window or screen is `ground`. Work sits on it in islands (`pane`, `radius-lg`, `shadow-pane`) 6px (`space-3`) apart and 6px from the edge. Never draw hairlines between regions: the gap is the divider. Chrome (sidebar, toolbar, tab strip, touch app bar) sits straight on `ground` with no island, so the islands read as the content.
2. **One accent, spent on intent.** `accent` marks the focused selection, the primary action, checked controls, focus and progress, and nothing else. Status colours (`success`, `warning`, `danger`, `attention`) only describe state. `series-1` … `series-8` only tell categories apart. Brand colour (`brand`) is for the mark, welcome and About screens, never the working UI.
3. **Hierarchy through weight, not size.** The desktop UI runs at 13px (`body`), touch at 15px (`body-touch`). Differences come from `body` → `body-strong`, `ink` → `ink-muted`, sans → mono. Mono is for what a person could paste: identifiers, paths, commands, numbers in columns.
4. **Focus is a place.** One island owns keyboard focus at a time. Its selection is solid `accent` with `on-accent` text; other islands show `accent-soft`. Glance at the window and you know where your arrow keys go.
5. **Work is visible, never modal.** Long operations show progress in place (a progress rule, a spinner in the button that started them). Only destructive or conflicting steps ask a question.
6. **Documents rest on a canvas.** An app that shows pages (notebooks, scans, previews) puts them on `canvas` as paper, not in islands. The paper is content and never follows the theme; the tools float over it in one ToolDock.
7. **The same system on every surface.** Desktop and touch share tokens, components and rules; density changes sizes, never meaning.

## Content

- Sentence case everywhere: "Move to archive", not "Move To Archive". Capitals only in `overline` section headers.
- Buttons say the verb and its object: "Send", "Export 3 notebooks", "Delete Linear algebra". Never "OK", never "Yes".
- Say the real names: "Rebase design-system onto origin/main", "Move Quarterly report to archive", never "the current item".
- Errors say what happened, then what to do: "Could not send “Quarterly report”. The attachment is larger than 25 MB. Remove it or share a link instead."
- Dates are relative in lists ("7 min", "2 h", "Yesterday") and absolute in detail and tooltips ("Thu 24 Sep 2026, 23:00").
- Every string ships in English and German. Leave room for German: labels run up to 40% longer, so never fix a button's width.
- No emoji, no exclamation marks, no "Oops", no filler ("Please", "Simply").

## Colour

- Build light and dark from the same token names. A brand's accent family changes; a brand's neutrals may replace the surfaces, canvas, ink and lines as one family (never one token at a time, and every floor is rechecked); status and categorical colours never change.
- Text: `ink` and `ink-muted` on `ground`, `pane`, `pane-alt`, `raised` and `accent-soft` (at least 4.5:1 in every brand and theme). `accent-ink` for accent-coloured text and links on the same grounds. `on-accent` and `on-accent-muted` only on `accent`; `on-danger` on `danger`; `on-attention` on `attention`. `ink-faint` only for disabled labels and placeholders.
- Surfaces: `canvas` behind documents (pages rest on it as paper), `pane` for islands, `pane-alt` for inset areas (table headers, docked editors, search wells), `raised` for everything that floats, `scrim` only behind modal dialogs and sheets. Hover: `pane-hover` inside islands, `ground-hover` on chrome.
- Lines: `line` for hairlines inside islands, `line-strong` for outlines of labelled controls, `control-edge` (3:1) for fields, checkboxes, radios and switches.
- Status: `success`, `warning`, `danger`, `attention` as text and icons on `pane` and on their own `-bg` tint. `attention` (orange) is work to do, not a failure; `danger` (red) is a failure or a destructive action.
- Categories: give `series-1` … `series-8` in order; an avatar picks its colour from a stable hash of the name. A category colour always goes with its name.
- Content colours (a notebook's paper and ink, a mail's HTML, a chart's data) belong to the content and never invert with the theme.

## Type

- The UI uses the brand's `sans` family: the platform face by default (SF Pro, Segoe UI Variable, Roboto, Cantarell or Noto Sans), Inter in CrossProton, Geist in Mimameidr, the platform face in Nibluma. Code and identifiers use the brand's `mono`: JetBrains Mono by default (bundled with `meridian_ui`), Geist Mono in Mimameidr. `reading` is for long-form content and may be a serif (Georgia in CrossProton, Literata in Nibluma); Nibluma also sets `display` in Literata 500 (`displayWeight`) and keeps `title` in the sans (`displayForTitle: false`): the serif is for the library headline and book titles, not for dialogs.
- Desktop styles: `display` welcome and empty-state headline only (one per window), `title` dialogs and settings pages, `heading` the headline of the selected item, `body` rows, fields and menus, `body-strong` the current item and island titles, `label` buttons, tabs and field labels, `caption` metadata and help, `overline` section headers in capitals, `code` and `code-sm` identifiers, `reading` long text.
- Touch density uses the `-touch` styles, two steps larger. Never go below 11px on desktop or 12px on touch.
- Numbers that change or line up (counts, metrics, times) use tabular figures.

## Spacing and density

- A 2px grid with `space-4` (8px) as the working unit. Islands are `space-3` apart; control padding `space-4`; island header padding `space-5`; popovers `space-6`; dialogs `space-7`.
- Density changes row and control heights and nothing else on desktop: compact rows 24, regular 28 (default), comfortable 32. Touch density (phones and tablets) sets rows to 48, controls to 44 with a 48px hit target, icons to 20px, and switches to the touch type scale.
- Each app starts at its brand's density (Mimameidr compact, GitLama and CrossProton regular, Nibluma touch); people may change it.

## Shape and depth

- Rows and chips `radius-sm`, controls `radius-md`, islands and banners `radius-lg`, floating surfaces `radius-xl`, counts, switches, avatars and progress `radius-pill`. The selected row is an inset rounded bar `space-3` in from the island edge, never full width.
- Brands may replace the five radius steps with their own scale: CrossProton 4 / 6 / 10 / 14 / 22, Mimameidr 3 / 6 / 8 / 10 / 13, Nibluma 6 / 10 / 12 / 18 / 24. The previews show the default scale.
- Two levels of depth only: `shadow-pane` for islands (it is their edge) and `shadow-float` for anything that floats. Controls get at most a 1px lip (`shadow-control`). No inner shadows, no gradients, no Material elevation.

## Motion

Quick and physical, and only on state change: motion shows where something came from and where it went, confirms that an action landed, and is gone before anyone waits for it. It never blocks input, every animation retargets, and springs drive what the pointer touches. Hover fades in over 80ms and out over 160ms, selections glide, overlays grow from their anchor over 140ms and leave in 100ms, dialogs grow over 200ms. Honour reduce motion: movement becomes an instant change or a fade of at most 100ms, and loops stop or slow. Tokens, curves, springs, the helpers and the full catalogue (MM-01 to MM-78) are in [guides/40-motion.md](guides/40-motion.md).

## States

Every control has rest, hover (`pane-hover` or `ground-hover`), pressed (hover plus 4% `ink`), keyboard focus (a 2px `focus` ring 1px outside, following the control's radius), disabled (`ink-faint` label, no hover, the reason in the tooltip) and, where it applies, loading (label kept, spinner replaces the icon) and error (`danger` edge plus a message below). Keyboard focus is always visible; a pointer press never shows the ring. There is no ripple and no splash anywhere.

## Accessibility

- Every text pair clears 4.5:1 and every control edge, focus ring and icon 3:1, in every brand and both themes; `tool/generate.py` in `meridian_ui` fails the build when a pair drops below.
- Status is never colour alone: icons, letters, labels and arrows go with every colour.
- Every action has a keyboard route; every drag and every hover action has a menu item. Touch targets are at least 48px.
- Test at 130% text scale and with a screen reader: controls expose their role, state (selected, checked, expanded, busy, disabled) and name.

## Iconography

Use the Lucide icons in the Icons group (lucide-static 1.37.0, ISC): 24×24 viewBox, 2px stroke, round caps and joins, single-ink. Draw them at 16px (`size-icon`), 14px in chips and small controls, 18px with a 1.75 stroke in the toolbar, 20px at touch density. Tint them `ink` at rest, `ink-muted` when idle, `on-accent` on an accent fill. An app adds its own icons (GitLama's Git verbs, CrossProton's folded-envelope mark) through `MeridianIconSet`; they must be Lucide 1.37.0 or drawn to the same grid. No icon fonts, no Unicode action glyphs, no emoji, no second icon family.

## App marks

The Logos group holds each app's mark. Use a mark only on welcome and About screens, splash screens and platform icons, never inside the working UI, and never recolour it. There are no wordmarks: set the app's name in `display` next to the mark.
