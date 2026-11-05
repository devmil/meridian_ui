#!/usr/bin/env python3
"""Writes design/project/guides/10-brands.md from tokens/brands/*.json."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
ORDER = ["gitlama", "crossproton", "mimameidr", "nibluma"]
files = {p.stem: p for p in (ROOT / "tokens" / "brands").glob("*.json")}
brands = [json.loads(files[b].read_text()) for b in ORDER if b in files] + [
    json.loads(files[b].read_text()) for b in sorted(set(files) - set(ORDER))]


def fam(b, k):
    v = b["fonts"].get(k) or {}
    return v.get("flutter") or "platform"


rows = []
for b in brands:
    L, D = b["colors"]["light"], b["colors"]["dark"]
    r = b.get("radius")
    radius = " / ".join(str(r[f"radius-{k}"]) for k in ["xs", "sm", "md", "lg", "xl"]) if r else "3 / 5 / 7 / 10 / 14 (default)"
    reading = fam(b, "reading") if fam(b, "reading") != "platform" else "sans"
    rows.append(f"| **{b['name']}** | `{L['accent']}` / `{D['accent']}` | {fam(b, 'sans')} | {fam(b, 'mono')} | {reading} | {radius} | {b['density']} |")
lines = ["# Brands", "", "Each app is Meridian plus a brand: an accent family for light and dark, fonts, a radius scale and a default density, and optionally its own neutrals (surfaces, canvas, ink and lines) when the shared cool neutrals do not suit the app. Status, categorical colours, spacing, motion and the primitives are always shared. Brand files live in `meridian_ui/tokens/brands/`; the generator checks every brand against the contrast floors in both themes.", "", "| App | Accent (light / dark) | UI face | Mono | Reading | Radii xs / sm / md / lg / xl | Density |", "|---|---|---|---|---|---|---|"] + rows + [""]
for b in brands:
    L, D = b["colors"]["light"], b["colors"]["dark"]
    lines += [f"## {b['name']}", "", b["description"], "", "| Token | Light | Dark |", "|---|---|---|"]
    for k in ["accent", "on-accent", "on-accent-muted", "accent-soft", "accent-ink", "focus", "brand"]:
        lines.append(f"| `{k}` | `{L[k]}` | `{D[k]}` |")
    n = b.get("neutrals")
    if n:
        lines += ["", "Own neutrals (these replace the shared core in this brand):", "", "| Token | Light | Dark |", "|---|---|---|"]
        for k in n["light"]:
            lines.append(f"| `{k}` | `{n['light'][k]}` | `{n['dark'].get(k, n['light'][k])}` |")
    lines += ["", "- Fonts: " + "; ".join(f"{k} {v.get('flutter') or 'platform'} ({v['note']})" for k, v in b["fonts"].items() if v) + ".", f"- Signature, kept in the app: {b['signature']}", ""]
lines += ["## Adding a brand", "", "A new app gets `tokens/brands/<app>.json` with all seven accent tokens for light and dark (`accent`, `on-accent`, `on-accent-muted`, `accent-soft`, `accent-ink`, `focus`, `brand`), its fonts, an optional radius scale, its default density and, only if it needs them, `neutrals` for light and dark (any of the keys in `NEUTRAL_KEYS` in `tool/generate.py`; the generator refuses others and checks every floor against them). Pick the accent so that `on-accent` clears 4.5:1 on it and the accent itself clears 3:1 on `pane`; a light accent in dark themes wants dark `on-accent` text. Run `python3 tool/generate.py`, then republish this system so the new brand appears in the theme switcher (both light and dark for every registered brand)."]
(ROOT / "design" / "project" / "guides" / "10-brands.md").write_text("\n".join(lines) + "\n")
print("10-brands.md")
