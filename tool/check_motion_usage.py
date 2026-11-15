#!/usr/bin/env python3
"""Motion usage guard (design/project/guides/40-motion.md).

Scans lib/src/**/*.dart (generated *.g.dart files excepted) and fails on
literal curves, durations and springs, raw size animation outside the two
helpers that may animate size, and direct reads of the reduce-motion flag.

  python3 tool/check_motion_usage.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "lib" / "src"

HELPERS = "lib/src/foundation/meridian_motion_helpers.dart"
MOTION = {"lib/src/foundation/meridian_theme.dart", "lib/src/foundation/meridian_motion.dart"}
# Android's predictive back preview, ported from material_ui: its curves are
# the Android spec's, not Meridian's.
PORTED = {"lib/src/foundation/predictive_back.dart"}

# (rule, pattern, allowed files, hint)
RULES = [
    ("curve-literal", re.compile(r"\bCurves\.(?!linear\b)"), PORTED,
     "Use MeridianCurves or a MeridianDurations …Curve."),
    ("duration-literal", re.compile(r"Duration\(\s*(milliseconds|seconds|microseconds):"), set(),
     "Use MeridianDurations."),
    ("spring-literal", re.compile(r"SpringDescription\("), set(),
     "Use MeridianSprings."),
    ("raw-animated-size", re.compile(r"\b(AnimatedSize|SizeTransition)\b"), {HELPERS},
     "Only MeridianReveal and MeridianGlide animate size."),
    ("raw-disable-animations", re.compile(r"disableAnimationsOf"), MOTION,
     "Use MeridianMotion.of / .fade / .reduced."),
]

# Named durations that are not tokens; the count must match exactly. menu.dart:
# two timers. meridian_layout.dart: the stroke draw timings the motion guide
# names in MM-04 and MM-11 (160 ms, 140 ms, 40 ms delay). scrollbar.dart: the
# platform's thumb fade and the delay before it fades (300 ms, 600 ms).
DURATION_EXEMPT = {
    "lib/src/components/menu.dart": 2,
    "lib/src/components/scrollbar.dart": 2,
    "lib/src/foundation/meridian_layout.dart": 3,
}


def main() -> int:
    hits: list[str] = []
    exempt_counts: dict[str, int] = {}
    for path in sorted(SRC.rglob("*.dart")):
        if path.name.endswith(".g.dart"):
            continue
        rel = path.relative_to(ROOT).as_posix()
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            code = line.split("//", 1)[0]
            for rule, pattern, allowed, hint in RULES:
                if rel in allowed or not pattern.search(code):
                    continue
                if rule == "duration-literal" and rel in DURATION_EXEMPT:
                    exempt_counts[rel] = exempt_counts.get(rel, 0) + 1
                    continue
                hits.append(f"{rel}:{number}: [{rule}] {hint}")
    for rel, expected in DURATION_EXEMPT.items():
        found = exempt_counts.get(rel, 0)
        if found != expected:
            hits.append(f"{rel}: [duration-literal] expected {expected} exempt timer constants, found {found}.")
    for hit in hits:
        print(hit)
    if hits:
        print(f"Motion usage failed: {len(hits)} violations.")
        return 1
    print("Motion usage passed: 0 violations.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
