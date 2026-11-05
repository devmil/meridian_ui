# Brands

Each app is Meridian plus a brand: an accent family for light and dark, fonts, a radius scale and a default density, and optionally its own neutrals (surfaces, canvas, ink and lines) when the shared cool neutrals do not suit the app. Status, categorical colours, spacing, motion and the primitives are always shared. Brand files live in `meridian_ui/tokens/brands/`; the generator checks every brand against the contrast floors in both themes.

| App | Accent (light / dark) | UI face | Mono | Reading | Radii xs / sm / md / lg / xl | Density |
|---|---|---|---|---|---|---|
| **GitLama** | `#056CB3` / `#5BB1FE` | platform | JetBrains Mono | sans | 3 / 5 / 7 / 10 / 14 (default) | regular |
| **CrossProton** | `#6D4AFF` / `#9B83FF` | Inter | JetBrains Mono | Georgia | 4 / 6 / 10 / 14 / 22 | regular |
| **Mimameidr** | `#0E7C59` / `#24C27D` | Geist | Geist Mono | Geist | 3 / 6 / 8 / 10 / 13 | compact |
| **Nibluma** | `#0B6477` / `#5CC0CF` | platform | JetBrains Mono | Literata | 6 / 10 / 12 / 18 / 24 | touch |
| **ShotLama** | `#B8338F` / `#E977BB` | platform | JetBrains Mono | sans | 4 / 6 / 9 / 12 / 18 | regular |
| **VaultLama** | `#463878` / `#D6C3FA` | platform | JetBrains Mono | sans | 4 / 7 / 10 / 14 / 20 | regular |

## GitLama

Desktop Git client. The reference brand: a cerulean accent, clear of the danger red that marks conflicts and failed operations.

| Token | Light | Dark |
|---|---|---|
| `accent` | `#056CB3` | `#5BB1FE` |
| `on-accent` | `#FFFFFF` | `#06111D` |
| `on-accent-muted` | `#E2EFFB` | `#123452` |
| `accent-soft` | `#DBEBFC` | `#16334D` |
| `accent-ink` | `#0160A0` | `#87C4FE` |
| `focus` | `#056CB3` | `#87C4FE` |
| `brand` | `#14242B` | `#1F3A48` |

- Fonts: sans platform (Platform face (SF Pro, Segoe UI Variable, Cantarell or Noto Sans).); mono JetBrains Mono (Bundled with meridian_ui.); reading platform (Same as sans.).
- Signature, kept in the app: Islands on a tinted ground, the Compass in the title bar, the spline history graph.

## CrossProton

Private-first desktop client for Proton Mail. Violet on neutral, Inter chrome, serif reading surfaces.

| Token | Light | Dark |
|---|---|---|
| `accent` | `#6D4AFF` | `#9B83FF` |
| `on-accent` | `#FFFFFF` | `#120B2B` |
| `on-accent-muted` | `#F4F1FF` | `#2A1F57` |
| `accent-soft` | `#EEEAFF` | `#312657` |
| `accent-ink` | `#5636DC` | `#B7A6FF` |
| `focus` | `#6D4AFF` | `#B7A6FF` |
| `brand` | `#6D4AFF` | `#6D4AFF` |

- Fonts: sans Inter (Inter 4.1 (400/500/600/700), bundled by the app.); mono JetBrains Mono (Bundled with meridian_ui.); reading Georgia (Serif for message bodies only.).
- Signature, kept in the app: The lime privacy spark (#DDE300 light, #F0EF52 dark) under the active menu item, and the folded-envelope mark. Both stay app-level.

## Mimameidr

Cross-platform process explorer. Data is the hero, chrome is quiet, every number in Geist Mono.

| Token | Light | Dark |
|---|---|---|
| `accent` | `#0E7C59` | `#24C27D` |
| `on-accent` | `#FFFFFF` | `#03130C` |
| `on-accent-muted` | `#ECF9F2` | `#043D2A` |
| `accent-soft` | `#DAF2E6` | `#0B3627` |
| `accent-ink` | `#026F4F` | `#80D6B0` |
| `focus` | `#0E7C59` | `#80D6B0` |
| `brand` | `#00402C` | `#1A533E` |

- Fonts: sans Geist (Geist, bundled by the app (OFL).); mono Geist Mono (Geist Mono for every metric, with tabular figures.); reading Geist (Same as sans.).
- Signature, kept in the app: The live dot that breathes while polling, CPU heat tint on rows. The signal-green accent replaced the original blue in October 2026 so the Lama apps are told apart by hue.

## Nibluma

Offline notebooks for handwriting and scanned documents on phones and tablets. Warm paper, blue-black ink and petrol, a serif only where a book speaks.

| Token | Light | Dark |
|---|---|---|
| `accent` | `#0B6477` | `#5CC0CF` |
| `on-accent` | `#FFFFFF` | `#03191E` |
| `on-accent-muted` | `#D3ECF0` | `#0E3F48` |
| `accent-soft` | `#DDEEF0` | `#17363B` |
| `accent-ink` | `#0A5A6B` | `#80D2DE` |
| `focus` | `#0B6477` | `#80D2DE` |
| `brand` | `#18304F` | `#22406A` |

Own neutrals (these replace the shared core in this brand):

| Token | Light | Dark |
|---|---|---|
| `ground` | `#ECEAE6` | `#151412` |
| `ground-hover` | `#E2DFD9` | `#211F1C` |
| `pane` | `#FDFCFA` | `#1D1C1A` |
| `pane-alt` | `#F6F4F0` | `#191816` |
| `pane-hover` | `#EFECE7` | `#282623` |
| `raised` | `#FFFFFF` | `#262421` |
| `canvas` | `#E2DFD9` | `#24221F` |
| `scrim` | `rgba(24,22,19,0.32)` | `rgba(0,0,0,0.55)` |
| `ink` | `#18212D` | `#ECE8E1` |
| `ink-muted` | `#555D67` | `#A9A398` |
| `ink-faint` | `#8C8A86` | `#6F6A63` |
| `line` | `#E1DDD6` | `#2D2A27` |
| `line-strong` | `#CEC9C1` | `#3A3632` |
| `control-edge` | `#86827B` | `#7E786F` |

- Fonts: sans platform (Platform face: SF Pro on iOS and iPadOS, Roboto on Android. Controls feel native on each.); mono JetBrains Mono (Bundled with meridian_ui. Rare in Nibluma: sync diagnostics only.); display Literata (Literata 500 for the display style only: the library headline, book titles, empty states. Dialog and sheet titles stay in the sans.); reading Literata (Serif for long-form text (help, onboarding).).
- Signature, kept in the app: The book as object: covers with a spine and orbital arcs, paper that never inverts, pages resting on the canvas, tools in one floating dock. Petrol marks intent; saved-state green stays status.

## ShotLama

Cross-platform screenshot and screen-recording studio. The capture is the hero; chrome is graphite glass that steps aside, and one magenta accent marks intent.

| Token | Light | Dark |
|---|---|---|
| `accent` | `#B8338F` | `#E977BB` |
| `on-accent` | `#FFFFFF` | `#180A13` |
| `on-accent-muted` | `#FDF1F8` | `#49243C` |
| `accent-soft` | `#FBE4F0` | `#412235` |
| `accent-ink` | `#A72A82` | `#EFA7D2` |
| `focus` | `#B8338F` | `#EFA7D2` |
| `brand` | `#4D253F` | `#623852` |

Own neutrals (these replace the shared core in this brand):

| Token | Light | Dark |
|---|---|---|
| `ground` | `#ECECF1` | `#0F0F14` |
| `ground-hover` | `#E1E1E8` | `#1A1A22` |
| `pane` | `#FFFFFF` | `#17171E` |
| `pane-alt` | `#F7F7FA` | `#131319` |
| `pane-hover` | `#F0F0F5` | `#212129` |
| `raised` | `#FFFFFF` | `#1F1F28` |
| `canvas` | `#E2E2E9` | `#09090D` |
| `scrim` | `rgba(14,14,22,0.32)` | `rgba(0,0,0,0.55)` |
| `ink` | `#14141B` | `#EDEDF3` |
| `ink-muted` | `#575769` | `#A3A3B4` |
| `ink-faint` | `#8F8FA0` | `#666679` |
| `line` | `#DFDFE7` | `#262630` |
| `line-strong` | `#C9C9D4` | `#34343F` |
| `control-edge` | `#84849A` | `#71718A` |

- Fonts: sans platform (Platform face (SF Pro, Segoe UI Variable, Cantarell or Noto Sans): ShotLama should feel like part of the operating system.); mono JetBrains Mono (Bundled with meridian_ui. Dimensions, coordinates, colour values, timers and file sizes, always with tabular figures.); reading platform (Same as sans.).
- Signature, kept in the app: Graphite glass over the capture (the veil), the shutter lift from selection into the Quick Access card, the Drag me grip. Annotation colours are content and never follow the theme.

## VaultLama

Open-source Vaultwarden password manager for phones, tablets, desktops and browsers. Calm midnight chrome, secrets that stay masked until asked, and one midnight-violet accent for intent.

| Token | Light | Dark |
|---|---|---|
| `accent` | `#463878` | `#D6C3FA` |
| `on-accent` | `#FFFFFF` | `#170F2B` |
| `on-accent-muted` | `#DCD5F2` | `#4B3D70` |
| `accent-soft` | `#ECE8F8` | `#2C2446` |
| `accent-ink` | `#4B3C86` | `#DCCDFB` |
| `focus` | `#5A47A8` | `#DCCDFB` |
| `brand` | `#231B3F` | `#31285A` |

Own neutrals (these replace the shared core in this brand):

| Token | Light | Dark |
|---|---|---|
| `ground` | `#ECEBF2` | `#0F0E15` |
| `ground-hover` | `#E1E0EA` | `#1A1823` |
| `pane` | `#FFFFFF` | `#17151F` |
| `pane-alt` | `#F7F6FB` | `#13121A` |
| `pane-hover` | `#F0EFF6` | `#22202C` |
| `raised` | `#FFFFFF` | `#1F1D29` |
| `canvas` | `#E3E1EC` | `#0A090F` |
| `scrim` | `rgba(18,14,32,0.32)` | `rgba(0,0,0,0.55)` |
| `ink` | `#15131D` | `#EDECF4` |
| `ink-muted` | `#58566A` | `#A5A3B6` |
| `ink-faint` | `#8F8DA1` | `#67657B` |
| `line` | `#E0DEE8` | `#27252F` |
| `line-strong` | `#CAC8D6` | `#35333F` |
| `control-edge` | `#85839B` | `#72708B` |

- Fonts: sans platform (Platform face (SF Pro, Segoe UI Variable, Roboto, Cantarell or Noto Sans): a password manager should feel like part of the system it fills into.); mono JetBrains Mono (Bundled with meridian_ui. Revealed passwords, generated passwords, one-time codes and fingerprints, always with tabular figures so similar glyphs stay apart.); reading platform (Same as sans.).
- Signature, kept in the app: Midnight islands on a cool ground; secrets masked until the person asks, revealed in mono and re-masked on their own; one midnight-violet accent for intent. Danger, warning and attention keep their status meaning for weak, reused and exposed credentials.

## Adding a brand

A new app gets `tokens/brands/<app>.json` with all seven accent tokens for light and dark (`accent`, `on-accent`, `on-accent-muted`, `accent-soft`, `accent-ink`, `focus`, `brand`), its fonts, an optional radius scale, its default density and, only if it needs them, `neutrals` for light and dark (any of the keys in `NEUTRAL_KEYS` in `tool/generate.py`; the generator refuses others and checks every floor against them). Pick the accent so that `on-accent` clears 4.5:1 on it and the accent itself clears 3:1 on `pane`; a light accent in dark themes wants dark `on-accent` text. Run `python3 tool/generate.py`, then republish this system so the new brand appears in the theme switcher (both light and dark for every registered brand).
