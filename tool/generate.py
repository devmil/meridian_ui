#!/usr/bin/env python3
"""Meridian token pipeline.

Reads tokens/meridian.tokens.json (the shared core) and tokens/brands/*.json
(one brand per app) and writes:

  lib/src/foundation/meridian_tokens.g.dart   core colours, shadows, space, radius, size, type, motion
  lib/src/foundation/meridian_brands.g.dart   one const MeridianBrand per brand file
  design/project/motion.css                    the motion tokens as CSS custom properties
  design/project/tokens.json                   the Design System artifact's tokens (one light and
                                               one dark theme per brand)

and checks every contrast floor in FLOORS for every brand in both themes.

  python3 tool/generate.py            write everything, fail on a contrast miss
  python3 tool/generate.py --check    write nothing, fail if a generated file is stale or a floor is missed
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CORE = ROOT / "tokens" / "meridian.tokens.json"
BRANDS = ROOT / "tokens" / "brands"
DART_TOKENS = ROOT / "lib" / "src" / "foundation" / "meridian_tokens.g.dart"
DART_BRANDS = ROOT / "lib" / "src" / "foundation" / "meridian_brands.g.dart"
ARTIFACT_TOKENS = ROOT / "design" / "project" / "tokens.json"
MOTION_CSS = ROOT / "design" / "project" / "motion.css"

BRAND_ORDER = ["gitlama", "crossproton", "mimameidr", "nibluma"]
ACCENT_KEYS = ["accent", "on-accent", "on-accent-muted", "accent-soft", "accent-ink", "focus", "brand"]
# Core colours a brand may replace with its own neutral family (`neutrals` in its brand file).
NEUTRAL_KEYS = ["ground", "ground-hover", "pane", "pane-alt", "pane-hover", "raised", "canvas", "scrim",
                "ink", "ink-muted", "ink-faint", "line", "line-strong", "control-edge"]

# (foreground, background, minimum ratio). Checked in every brand x theme.
FLOORS = [
    *[(fg, bg, 4.5) for fg in ("ink", "ink-muted") for bg in ("ground", "pane", "pane-alt", "raised", "accent-soft", "pane-hover", "canvas")],
    *[("accent-ink", bg, 4.5) for bg in ("ground", "pane", "pane-alt", "raised", "accent-soft")],
    ("on-accent", "accent", 4.5),
    ("on-accent-muted", "accent", 4.5),
    ("accent", "pane", 3.0),
    *[("focus", bg, 3.0) for bg in ("ground", "pane", "raised", "canvas")],
    *[("control-edge", bg, 3.0) for bg in ("pane", "raised")],
    *[(s, bg, 4.5) for s in ("success", "warning", "danger", "attention") for bg in ("pane", "raised")],
    ("success", "success-bg", 4.5),
    ("warning", "warning-bg", 4.5),
    ("danger", "danger-bg", 4.5),
    ("attention", "attention-bg", 4.5),
    ("ink", "success-bg", 4.5),
    ("ink", "warning-bg", 4.5),
    ("ink", "danger-bg", 4.5),
    ("ink", "attention-bg", 4.5),
    ("on-danger", "danger", 4.5),
    ("on-attention", "attention", 4.5),
    *[(f"series-{i}", "pane", 3.0) for i in range(1, 9)],
    *[(f"syntax-{k}", bg, 4.5)
      for k in ("comment", "keyword", "string", "number", "type", "function", "variable", "constant",
                "operator", "punctuation", "attribute", "tag")
      for bg in ("pane", "pane-alt", "raised", "pane-hover", "success-bg", "danger-bg")],
]


# ---------------------------------------------------------------- helpers

def camel(name: str) -> str:
    parts = re.split(r"[-.]", name)
    return parts[0] + "".join(p[:1].upper() + p[1:] for p in parts[1:])


def parse_color(value: str) -> tuple[int, int, int, float]:
    value = value.strip()
    if value.startswith("#"):
        h = value[1:]
        if len(h) in (3, 4):
            h = "".join(c * 2 for c in h)
        r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
        a = int(h[6:8], 16) / 255 if len(h) == 8 else 1.0
        return r, g, b, a
    m = re.fullmatch(r"rgba?\(([^)]*)\)", value)
    if m:
        parts = [p.strip() for p in m.group(1).split(",")]
        r, g, b = (int(float(p)) for p in parts[:3])
        a = float(parts[3]) if len(parts) > 3 else 1.0
        return r, g, b, a
    raise ValueError(f"unsupported colour {value!r}")


def dart_color(value: str) -> str:
    r, g, b, a = parse_color(value)
    return f"Color(0x{round(a * 255):02X}{r:02X}{g:02X}{b:02X})"


def luminance(value: str) -> float:
    r, g, b, _ = parse_color(value)

    def chan(c: int) -> float:
        c = c / 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

    return 0.2126 * chan(r) + 0.7152 * chan(g) + 0.0722 * chan(b)


def contrast(a: str, b: str) -> float:
    la, lb = luminance(a), luminance(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


def px(value) -> float:
    if isinstance(value, (int, float)):
        return float(value)
    return float(str(value).replace("px", ""))


def doc(text: str, indent: str = "  ") -> str:
    return f"{indent}/// {text.strip()}\n"


def fmt(x: float) -> str:
    s = f"{x:.4f}".rstrip("0").rstrip(".")
    return s if "." in s else s + ".0"


# ---------------------------------------------------------------- load

def load():
    core = json.loads(CORE.read_text())
    brands = {}
    for path in sorted(BRANDS.glob("*.json")):
        brand = json.loads(path.read_text())
        for theme in ("light", "dark"):
            missing = [k for k in ACCENT_KEYS if k not in brand["colors"][theme]]
            if missing:
                raise SystemExit(f"{path.name}: {theme} is missing {missing}")
            unknown = [k for k in (brand.get("neutrals") or {}).get(theme, {}) if k not in NEUTRAL_KEYS]
            if unknown:
                raise SystemExit(f"{path.name}: neutrals.{theme} names tokens that are not neutrals: {unknown}")
        brands[brand["id"]] = brand
    order = [b for b in BRAND_ORDER if b in brands] + sorted(set(brands) - set(BRAND_ORDER))
    return core, [brands[b] for b in order]


def palette(core, brand, theme):
    out = {t["name"]: (t["value"][theme] if isinstance(t["value"], dict) else t["value"]) for t in core["color"]["tokens"]}
    out.update((t["name"], t["value"][theme]) for t in core["syntax"]["tokens"])
    out.update((brand.get("neutrals") or {}).get(theme, {}))
    out.update(brand["colors"][theme])
    return out


# ---------------------------------------------------------------- contrast

def check_contrast(core, brands) -> list[str]:
    failures = []
    for brand in brands:
        for theme in ("light", "dark"):
            p = palette(core, brand, theme)
            for fg, bg, floor in FLOORS:
                ratio = contrast(p[fg], p[bg])
                if ratio + 1e-9 < floor:
                    failures.append(f"{brand['id']}/{theme}: {fg} on {bg} = {ratio:.2f} (< {floor})")
    return failures


# ---------------------------------------------------------------- dart: tokens

def gen_dart_tokens(core) -> str:
    colors = core["color"]["tokens"]
    accent = core["accent"]["tokens"]
    out = []
    w = out.append
    w("// GENERATED by tool/generate.py from tokens/meridian.tokens.json. Do not edit.\n")
    w("// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars\n\n")
    w("import 'dart:ui' show lerpDouble;\n\n")
    w("import 'package:flutter/widgets.dart';\n\n")

    # accent set
    w("/// The brand-supplied accent family for one theme.\n")
    w("@immutable\nfinal class MeridianAccentColors {\n  const MeridianAccentColors({\n")
    for t in accent:
        w(f"    required this.{camel(t['name'])},\n")
    w("  });\n\n")
    for t in accent:
        w(doc(t["usage"]))
        w(f"  final Color {camel(t['name'])};\n\n")
    w("  static MeridianAccentColors lerp(MeridianAccentColors a, MeridianAccentColors b, double t) =>\n      MeridianAccentColors(\n")
    for t in accent:
        n = camel(t["name"])
        w(f"        {n}: Color.lerp(a.{n}, b.{n}, t)!,\n")
    w("      );\n\n")
    w("  @override\n  bool operator ==(Object other) =>\n      other is MeridianAccentColors")
    for t in accent:
        n = camel(t["name"])
        w(f" &&\n      other.{n} == {n}")
    w(";\n\n  @override\n  int get hashCode => Object.hashAll([")
    w(", ".join(camel(t["name"]) for t in accent))
    w("]);\n}\n\n")

    # neutral overrides
    neutrals = [t for t in colors if t["name"] in NEUTRAL_KEYS]
    w("/// A brand's own neutral family for one theme: any of the surface, canvas,\n")
    w("/// scrim, ink and line colours. A `null` field keeps the shared core value.\n")
    w("@immutable\nfinal class MeridianNeutralColors {\n  const MeridianNeutralColors({\n")
    for t in neutrals:
        w(f"    this.{camel(t['name'])},\n")
    w("  });\n\n")
    for t in neutrals:
        w(doc(t["usage"]))
        w(f"  final Color? {camel(t['name'])};\n\n")
    w("  @override\n  bool operator ==(Object other) =>\n      other is MeridianNeutralColors")
    for t in neutrals:
        n = camel(t["name"])
        w(f" &&\n      other.{n} == {n}")
    w(";\n\n  @override\n  int get hashCode => Object.hashAll([")
    w(", ".join(camel(t["name"]) for t in neutrals))
    w("]);\n}\n\n")

    # colors
    w("/// Every Meridian colour for one theme: the shared core plus the brand's accent family.\n")
    w("@immutable\nfinal class MeridianColors {\n  const MeridianColors({\n")
    for t in colors:
        w(f"    required this.{camel(t['name'])},\n")
    for t in accent:
        w(f"    required this.{camel(t['name'])},\n")
    w("  });\n\n")
    w("  /// Core colours for [brightness] combined with the brand's [accent] family\n")
    w("  /// and, where the brand sets them, its own [neutrals].\n")
    w("  factory MeridianColors.resolve(Brightness brightness, MeridianAccentColors accent, [MeridianNeutralColors? neutrals]) {\n")
    w("    final dark = brightness == Brightness.dark;\n")
    w("    return MeridianColors(\n")
    for t in colors:
        v = t["value"]
        lc, dc = (v["light"], v["dark"]) if isinstance(v, dict) else (v, v)
        if t["name"] in NEUTRAL_KEYS:
            w(f"      {camel(t['name'])}: neutrals?.{camel(t['name'])} ?? (dark ? const {dart_color(dc)} : const {dart_color(lc)}),\n")
        else:
            w(f"      {camel(t['name'])}: dark ? const {dart_color(dc)} : const {dart_color(lc)},\n")
    for t in accent:
        n = camel(t["name"])
        w(f"      {n}: accent.{n},\n")
    w("    );\n  }\n\n")
    for t in colors + accent:
        w(doc(t["usage"]))
        w(f"  final Color {camel(t['name'])};\n\n")
    series = [camel(t["name"]) for t in colors if t["name"].startswith("series-")]
    w("  /// The categorical colours in order (`series-1` … `series-8`).\n")
    w(f"  List<Color> get series => [{', '.join(series)}];\n\n")
    w("  /// The accent family of this colour set.\n")
    w("  MeridianAccentColors get accentColors => MeridianAccentColors(\n")
    for t in accent:
        n = camel(t["name"])
        w(f"    {n}: {n},\n")
    w("  );\n\n")
    w("  /// A copy with the given colours replaced, for an app whose people pick\n")
    w("  /// or edit themes. Keep the contrast floors of the replaced pairs.\n")
    w("  MeridianColors copyWith({\n")
    for t in colors + accent:
        w(f"    Color? {camel(t['name'])},\n")
    w("  }) => MeridianColors(\n")
    for t in colors + accent:
        n = camel(t["name"])
        w(f"    {n}: {n} ?? this.{n},\n")
    w("  );\n\n")
    w("  static MeridianColors lerp(MeridianColors a, MeridianColors b, double t) => MeridianColors(\n")
    for t in colors + accent:
        n = camel(t["name"])
        w(f"    {n}: Color.lerp(a.{n}, b.{n}, t)!,\n")
    w("  );\n\n")
    w("  @override\n  bool operator ==(Object other) =>\n      other is MeridianColors")
    for t in colors + accent:
        n = camel(t["name"])
        w(f" &&\n      other.{n} == {n}")
    w(";\n\n  @override\n  int get hashCode => Object.hashAll([")
    w(", ".join(camel(t["name"]) for t in colors + accent))
    w("]);\n}\n\n")

    # shadows
    def shadow_list(css: str) -> str:
        items = []
        for part in re.split(r",(?![^(]*\))", css):
            m = re.fullmatch(r"\s*(-?\d+)(?:px)?\s+(-?\d+)(?:px)?\s+(-?\d+)(?:px)?\s+(-?\d+)(?:px)?\s+(.+?)\s*", part)
            if not m:
                m2 = re.fullmatch(r"\s*(-?\d+)(?:px)?\s+(-?\d+)(?:px)?\s+(-?\d+)(?:px)?\s+(.+?)\s*", part)
                x, y, blur, color = m2.groups()
                spread = "0"
            else:
                x, y, blur, spread, color = m.groups()
            items.append(
                f"BoxShadow(color: {dart_color(color)}, offset: Offset({fmt(float(x))}, {fmt(float(y))}), "
                f"blurRadius: {fmt(float(blur))}, spreadRadius: {fmt(float(spread))})"
            )
        return "[\n      " + ",\n      ".join(items) + ",\n    ]"

    shadows = core["shadow"]["tokens"]
    w("/// Meridian shadows for one theme.\n@immutable\nfinal class MeridianShadows {\n  const MeridianShadows({\n")
    for t in shadows:
        w(f"    required this.{camel(t['name'])},\n")
    w("  });\n\n")
    for t in shadows:
        w(doc(t["usage"]))
        w(f"  final List<BoxShadow> {camel(t['name'])};\n\n")
    for theme in ("light", "dark"):
        w(f"  static const {theme} = MeridianShadows(\n")
        for t in shadows:
            w(f"    {camel(t['name'])}: <BoxShadow>{shadow_list(t['value'][theme])},\n")
        w("  );\n\n")
    w("  static MeridianShadows lerp(MeridianShadows a, MeridianShadows b, double t) => MeridianShadows(\n")
    for t in shadows:
        n = camel(t["name"])
        w(f"    {n}: BoxShadow.lerpList(a.{n}, b.{n}, t)!,\n")
    w("  );\n}\n\n")

    # space
    w("/// The spacing scale (a 2px grid; `space4` = 8px is the working unit).\nabstract final class MeridianSpace {\n")
    for t in core["spacing"]["tokens"]:
        w(doc(t["usage"]))
        w(f"  static const double {camel(t['name'])} = {fmt(px(t['value']))};\n\n")
    w("}\n\n")

    # radius
    rt = {t["name"]: t for t in core["radius"]["tokens"]}
    w("/// A brand's corner radius scale. [pill] never changes.\n@immutable\nfinal class MeridianRadiusScale {\n")
    w("  const MeridianRadiusScale({required this.xs, required this.sm, required this.md, required this.lg, required this.xl});\n\n")
    for key in ("xs", "sm", "md", "lg", "xl"):
        w(doc(rt[f"radius-{key}"]["usage"]))
        w(f"  final double {key};\n\n")
    w(doc(rt["radius-pill"]["usage"]))
    w(f"  static const double pill = {fmt(px(rt['radius-pill']['value']))};\n\n")
    w("  /// The default Meridian scale.\n  static const standard = MeridianRadiusScale(")
    w(", ".join(f"{k}: {fmt(px(rt[f'radius-{k}']['value']))}" for k in ("xs", "sm", "md", "lg", "xl")))
    w(");\n\n")
    w("  /// Interpolates every step, for a theme change that animates.\n")
    w("  static MeridianRadiusScale lerp(MeridianRadiusScale a, MeridianRadiusScale b, double t) => MeridianRadiusScale(")
    w(", ".join(f"{k}: lerpDouble(a.{k}, b.{k}, t)!" for k in ("xs", "sm", "md", "lg", "xl")))
    w(");\n\n")
    w("  @override\n  bool operator ==(Object other) =>\n      other is MeridianRadiusScale && other.xs == xs && other.sm == sm && other.md == md && other.lg == lg && other.xl == xl;\n\n")
    w("  @override\n  int get hashCode => Object.hash(xs, sm, md, lg, xl);\n}\n\n")

    # size
    w("/// Fixed component sizes.\nabstract final class MeridianSize {\n")
    for t in core["size"]["tokens"]:
        w(doc(t["usage"]))
        w(f"  static const double {camel(t['name'].replace('size-', ''))} = {fmt(px(t['value']))};\n\n")
    w("}\n\n")

    # motion
    motion = core["motion"]
    w("/// Timing curves (design/project/guides/40-motion.md).\nabstract final class MeridianCurves {\n")
    for c in motion["curves"]:
        a, b, cc, d = c["cubic"]
        w(doc(c["usage"]))
        w(f"  static const Cubic {camel(c['name'])} = Cubic({a!r}, {b!r}, {cc!r}, {d!r});\n\n")
    w("}\n\n")
    curves = {
        "linear": "Curves.linear",
        "easeInOut": "Curves.easeInOut",
        "standard": "MeridianCurves.standard",
        "enter": "MeridianCurves.enter",
        "exit": "MeridianCurves.exit",
        "exitSoft": "MeridianCurves.exitSoft",
    }
    w("/// Durations and their curves. Honour reduce motion: see `MeridianMotion`.\nabstract final class MeridianDurations {\n")
    for t in motion["tokens"]:
        n = camel(t["name"].replace("motion-", ""))
        w(doc(t["usage"]))
        w(f"  static const Duration {n} = Duration(milliseconds: {t['value']});\n")
        w(f"  static const Curve {n}Curve = {curves[t['curve']]};\n\n")
    w("}\n\n")
    w("/// Springs, mass 1 (`SpringDescription.withDampingRatio`).\nabstract final class MeridianSprings {\n")
    for sp in motion["springs"]:
        w(doc(sp["usage"]))
        w(f"  static final SpringDescription {camel(sp['name'])} = SpringDescription.withDampingRatio(mass: 1, stiffness: {fmt(sp['stiffness'])}, ratio: {sp['ratio']!r});\n\n")
    w("}\n\n")
    ints = {"shake-cycles", "stagger-max", "glide-max-rows"}
    w("/// Scales, distances and counts used by motion.\nabstract final class MeridianMotionScales {\n")
    for sc in motion["scales"]:
        w(doc(sc["usage"]))
        if sc["name"] in ints:
            w(f"  static const int {camel(sc['name'])} = {int(sc['value'])};\n\n")
        else:
            w(f"  static const double {camel(sc['name'])} = {fmt(float(sc['value']))};\n\n")
    w("}\n\n")

    # type
    w("/// One type scale (desktop or touch). Families and colours are applied by `MeridianTextStyles`.\n")
    styles_by_group = {g["name"]: g["styles"] for g in core["type"]["groups"]}
    desktop = styles_by_group["Desktop"]
    names = [s["name"] for s in desktop]
    w("@immutable\nfinal class MeridianTypeScale {\n  const MeridianTypeScale({\n")
    for n in names:
        w(f"    required this.{camel(n)},\n")
    w("  });\n\n")
    for s in desktop:
        w(doc(s["usage"]))
        w(f"  final TextStyle {camel(s['name'])};\n\n")

    def style(s) -> str:
        fs = px(s["fontSize"])
        lh = px(s["lineHeight"])
        parts = [f"fontSize: {fmt(fs)}", f"height: {lh / fs:.4f}", f"fontWeight: FontWeight.w{int(s['fontWeight'])}"]
        if "letterSpacing" in s:
            ls = s["letterSpacing"]
            val = float(ls.replace("em", "")) * fs if ls.endswith("em") else px(ls)
            parts.append(f"letterSpacing: {fmt(round(val, 3))}")
        parts.append("leadingDistribution: TextLeadingDistribution.even")
        return "TextStyle(" + ", ".join(parts) + ")"

    w("  /// A copy with the given styles replaced. A style that names a\n")
    w("  /// `fontFamily` keeps it; the others take the brand's families.\n")
    w("  MeridianTypeScale copyWith({\n")
    for n in names:
        w(f"    TextStyle? {camel(n)},\n")
    w("  }) => MeridianTypeScale(\n")
    for n in names:
        w(f"    {camel(n)}: {camel(n)} ?? this.{camel(n)},\n")
    w("  );\n\n")
    w("  @override\n  bool operator ==(Object other) =>\n      other is MeridianTypeScale")
    for n in names:
        w(f" &&\n      other.{camel(n)} == {camel(n)}")
    w(";\n\n  @override\n  int get hashCode => Object.hashAll([")
    w(", ".join(camel(n) for n in names))
    w("]);\n\n")
    for group, suffix in (("Desktop", ""), ("Touch", "-touch")):
        w(f"  /// The {group.lower()} scale.\n  static const {group.lower()} = MeridianTypeScale(\n")
        by = {s["name"]: s for s in styles_by_group[group]}
        for n in names:
            w(f"    {camel(n)}: {style(by[n + suffix])},\n")
        w("  );\n\n")
    w("}\n\n")

    # syntax
    syntax = core["syntax"]["tokens"]
    w("/// Foreground colours of code token categories for one theme, shared by\n")
    w("/// every brand. Plain code is `ink`.\n")
    w("@immutable\nfinal class MeridianSyntaxColors {\n  const MeridianSyntaxColors({\n")
    for t in syntax:
        w(f"    required this.{camel(t['name'][len('syntax-'):])},\n")
    w("  });\n\n")
    for theme in ("light", "dark"):
        w(f"  /// The {theme} theme's colours.\n  static const {theme} = MeridianSyntaxColors(\n")
        for t in syntax:
            w(f"    {camel(t['name'][len('syntax-'):])}: {dart_color(t['value'][theme])},\n")
        w("  );\n\n")
    w("  /// The colours for [brightness].\n")
    w("  static MeridianSyntaxColors resolve(Brightness brightness) =>\n")
    w("      brightness == Brightness.dark ? dark : light;\n\n")
    for t in syntax:
        w(doc(t["usage"]))
        w(f"  final Color {camel(t['name'][len('syntax-'):])};\n\n")
    w("  static MeridianSyntaxColors lerp(MeridianSyntaxColors a, MeridianSyntaxColors b, double t) => MeridianSyntaxColors(\n")
    for t in syntax:
        n = camel(t["name"][len("syntax-"):])
        w(f"    {n}: Color.lerp(a.{n}, b.{n}, t)!,\n")
    w("  );\n\n")
    w("  @override\n  bool operator ==(Object other) =>\n      other is MeridianSyntaxColors")
    for t in syntax:
        n = camel(t["name"][len("syntax-"):])
        w(f" &&\n      other.{n} == {n}")
    w(";\n\n  @override\n  int get hashCode => Object.hashAll([")
    w(", ".join(camel(t["name"][len("syntax-"):]) for t in syntax))
    w("]);\n}\n")
    return "".join(out)


# ---------------------------------------------------------------- dart: brands

def gen_dart_brands(brands) -> str:
    out = []
    w = out.append
    w("// GENERATED by tool/generate.py from tokens/brands/*.json. Do not edit.\n")
    w("// ignore_for_file: lines_longer_than_80_chars\n\n")
    w("import 'package:flutter/widgets.dart';\n\n")
    w("import 'meridian_brand.dart';\nimport 'meridian_density.dart';\nimport 'meridian_tokens.g.dart';\n\n")
    w("/// The brands of the apps built on Meridian.\nabstract final class MeridianBrands {\n")
    for b in brands:
        n = camel(b["id"])
        w(f"  /// {b['description']}\n")
        w(f"  static const {n} = MeridianBrand(\n")
        w(f"    id: '{b['id']}',\n    name: '{b['name']}',\n")
        for theme in ("light", "dark"):
            c = b["colors"][theme]
            w(f"    {theme}: MeridianAccentColors(\n")
            for k in ACCENT_KEYS:
                w(f"      {camel(k)}: {dart_color(c[k])},\n")
            w("    ),\n")
        for theme in ("light", "dark"):
            nb = (b.get("neutrals") or {}).get(theme)
            if nb:
                w(f"    {theme}Neutrals: MeridianNeutralColors(\n")
                for k in NEUTRAL_KEYS:
                    if k in nb:
                        w(f"      {camel(k)}: {dart_color(nb[k])},\n")
                w("    ),\n")
        f = b["fonts"]

        def fam(key):
            v = f.get(key) or {}
            return f"'{v['flutter']}'" if v.get("flutter") else "null"

        def fb(key):
            v = f.get(key) or {}
            return "<String>[" + ", ".join(f"'{x}'" for x in v.get("fallback", [])) + "]"

        mono_pkg = (f.get("mono") or {}).get("package")
        w("    fonts: MeridianFonts(\n")
        w(f"      sans: {fam('sans')},\n")
        w(f"      mono: {fam('mono')},\n")
        w(f"      monoPackage: {repr(mono_pkg).replace('None', 'null')},\n")
        w(f"      display: {fam('display')},\n")
        w(f"      reading: {fam('reading')},\n")
        w(f"      readingFallback: {fb('reading')},\n")
        disp = f.get("display") or {}
        if disp.get("titles") is False:
            w("      displayForTitle: false,\n")
        if disp.get("weight"):
            w(f"      displayWeight: FontWeight.w{int(disp['weight'])},\n")
        w("    ),\n")
        if b.get("radius"):
            r = b["radius"]
            w("    radius: MeridianRadiusScale(" + ", ".join(f"{k}: {fmt(float(r[f'radius-{k}']))}" for k in ("xs", "sm", "md", "lg", "xl")) + "),\n")
        w(f"    density: MeridianDensity.{b.get('density', 'regular')},\n")
        w("  );\n\n")
    w("  /// Every brand, in catalogue order.\n  static const all = [" + ", ".join(camel(b["id"]) for b in brands) + "];\n}\n")
    return "".join(out)


# ---------------------------------------------------------------- artifact tokens

def gen_artifact_tokens(core, brands) -> str:
    themes = []
    for b in brands:
        for theme in ("light", "dark"):
            tid = theme if b["id"] == brands[0]["id"] else f"{b['id']}-{theme}"
            label = theme.title() if b["id"] == brands[0]["id"] else f"{b['name']} {theme}"
            themes.append((tid, label, b, theme))

    def per_theme(fn):
        return {tid: fn(b, theme) for tid, _, b, theme in themes}

    color_tokens = []
    for t in core["color"]["tokens"]:
        v = t["value"]
        color_tokens.append({"name": t["name"], "value": per_theme(lambda b, th, v=v, n=t["name"]: (b.get("neutrals") or {}).get(th, {}).get(n) or (v[th] if isinstance(v, dict) else v)), "usage": t["usage"] + (" A brand may set its own." if t["name"] in NEUTRAL_KEYS else "")})
    for t in core["accent"]["tokens"]:
        color_tokens.append({"name": t["name"], "value": per_theme(lambda b, th, n=t["name"]: b["colors"][th][n]), "usage": t["usage"] + " Set by the brand."})
    for t in core["syntax"]["tokens"]:
        color_tokens.append({"name": t["name"], "value": per_theme(lambda b, th, v=t["value"]: v[th]), "usage": t["usage"]})

    shadow_tokens = [{"name": t["name"], "value": per_theme(lambda b, th, v=t["value"]: v[th]), "usage": t["usage"]} for t in core["shadow"]["tokens"]]

    groups = []
    for g in core["type"]["groups"]:
        groups.append({"name": g["name"], "family": g["family"], "styles": [dict(s) for s in g["styles"]]})
    families = dict(core["type"]["families"])

    out = {
        "name": "Meridian",
        "version": core["version"],
        "meta": {
            "source": "meridian_ui/tokens/meridian.tokens.json + tokens/brands/*.json, via tool/generate.py",
            "themes": "Light and Dark are Meridian with the GitLama brand; the other themes are the same core with each app's accent family. Fonts and radii per brand are listed in the Brands section.",
        },
        "color": {"themes": [{"id": tid, "name": label} for tid, label, _, _ in themes], "tokens": color_tokens},
        "type": {"fonts": core["type"]["fonts"], "families": families, "groups": groups},
        "spacing": core["spacing"],
        "radius": {"tokens": core["radius"]["tokens"]},
        "shadow": {"tokens": shadow_tokens},
        "size": core["size"],
        "motion": core["motion"],
    }
    return json.dumps(out, indent=1, ensure_ascii=False) + "\n"


# ---------------------------------------------------------------- css: motion

def spring_samples(stiffness: float, ratio: float, step_ms: int = 8) -> list[float]:
    """Positions of a unit spring (mass 1) from 0 to 1, every [step_ms], until
    it stays within 0.1% of rest."""
    import math
    omega = math.sqrt(stiffness)
    zeta = ratio
    values = []
    t = 0.0
    while t <= 3.0:
        if zeta < 1:
            wd = omega * math.sqrt(1 - zeta * zeta)
            x = 1 - math.exp(-zeta * omega * t) * (math.cos(wd * t) + (zeta * omega / wd) * math.sin(wd * t))
        else:
            x = 1 - math.exp(-omega * t) * (1 + omega * t)
        values.append(x)
        t += step_ms / 1000
    last = max(i for i, v in enumerate(values) if abs(v - 1) > 0.001)
    out = values[: last + 2]
    out[-1] = 1.0
    return out


def gen_motion_css(core) -> str:
    motion = core["motion"]
    out = ["/* GENERATED by tool/generate.py from tokens/meridian.tokens.json. Do not edit.",
           "   Motion tokens for the web rendition (design/project/guides/40-motion.md). */",
           ":root {"]
    for t in motion["tokens"]:
        out.append(f"  --{t['name']}: {t['value']}ms;")
    for c in motion["curves"]:
        a, b, cc, d = c["cubic"]
        out.append(f"  --curve-{c['name']}: cubic-bezier({a}, {b}, {cc}, {d});")
    for sp in motion["springs"]:
        samples = spring_samples(sp["stiffness"], sp["ratio"])
        points = ", ".join(f"{v:.4f}".rstrip("0").rstrip(".") if v not in (0, 1) else str(int(v)) for v in samples)
        out.append(f"  --spring-{sp['name']}: linear({points});")
        out.append(f"  --spring-{sp['name']}-duration: {(len(samples) - 1) * 8}ms;")
    out.append("}")
    return "\n".join(out) + "\n"


# ---------------------------------------------------------------- main

def dart_format(text: str, path: Path) -> str:
    """Format generated Dart the way `dart format` would, so the checked-in
    file passes `dart format --set-exit-if-changed` and `--check` stays exact."""
    return subprocess.run(
        ["dart", "format", f"--stdin-name={path.relative_to(ROOT)}"],
        input=text, capture_output=True, text=True, check=True, cwd=ROOT,
    ).stdout


def main() -> int:
    check_only = "--check" in sys.argv
    core, brands = load()
    outputs = {
        DART_TOKENS: dart_format(gen_dart_tokens(core), DART_TOKENS),
        DART_BRANDS: dart_format(gen_dart_brands(brands), DART_BRANDS),
        ARTIFACT_TOKENS: gen_artifact_tokens(core, brands),
        MOTION_CSS: gen_motion_css(core),
    }
    stale = []
    for path, text in outputs.items():
        if check_only:
            if not path.exists() or path.read_text() != text:
                stale.append(str(path.relative_to(ROOT)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)
    failures = check_contrast(core, brands)
    for f in failures:
        print("contrast:", f)
    for s in stale:
        print("stale:", s)
    if not failures and not stale:
        print(f"ok: {len(brands)} brands x 2 themes, {len(FLOORS)} contrast floors each")
    return 1 if failures or stale else 0


if __name__ == "__main__":
    sys.exit(main())
