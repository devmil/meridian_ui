#!/usr/bin/env python3
"""PNG copies of the Meridian mark (webfront/favicon.svg).

The SVG is the master. This writes webfront/icons/meridian-<size>.png for
each size in SIZES and copies the SVG to example/web/favicon.svg, which
Widgetbook serves. Needs rsvg-convert (librsvg).

  python3 tool/build_site_icons.py            # regenerate
  python3 tool/build_site_icons.py --check    # CI guard, no raster tools
"""

from __future__ import annotations

import shutil
import struct
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MASTER = ROOT / "webfront" / "favicon.svg"
COPIES = [ROOT / "example" / "web" / "favicon.svg"]
OUT = ROOT / "webfront" / "icons"

# 32: browser tab. 180: Apple touch icon. 192 and 512: web manifest.
# 1024: store listings, documents and other places outside the site.
SIZES = [32, 180, 192, 512, 1024]

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def target(size: int) -> Path:
    return OUT / f"meridian-{size}.png"


def png_size(path: Path) -> tuple[int, int]:
    header = path.read_bytes()[:24]
    if header[:8] != PNG_SIGNATURE or header[12:16] != b"IHDR":
        raise ValueError(f"{path.relative_to(ROOT)} is not a PNG")
    return struct.unpack(">II", header[16:24])


def check() -> int:
    problems: list[str] = []
    for copy in COPIES:
        if not copy.exists() or copy.read_bytes() != MASTER.read_bytes():
            problems.append(f"{copy.relative_to(ROOT)} differs from the master")
    for size in SIZES:
        path = target(size)
        if not path.exists():
            problems.append(f"{path.relative_to(ROOT)} is missing")
            continue
        try:
            actual = png_size(path)
        except ValueError as error:
            problems.append(str(error))
            continue
        if actual != (size, size):
            problems.append(
                f"{path.relative_to(ROOT)} is {actual[0]}x{actual[1]}, "
                f"expected {size}x{size}"
            )
    expected = {target(size).name for size in SIZES}
    for path in sorted(OUT.glob("*.png")) if OUT.exists() else []:
        if path.name not in expected:
            problems.append(f"{path.relative_to(ROOT)} is not a generated size")
    for problem in problems:
        print(problem, file=sys.stderr)
    if problems:
        print("Run python3 tool/build_site_icons.py", file=sys.stderr)
        return 1
    print(f"Site icons match the master ({len(SIZES)} sizes).")
    return 0


def build() -> int:
    converter = shutil.which("rsvg-convert")
    if converter is None:
        print("rsvg-convert not found; install librsvg", file=sys.stderr)
        return 1
    OUT.mkdir(parents=True, exist_ok=True)
    for size in SIZES:
        subprocess.run(
            [converter, "-w", str(size), "-h", str(size), "-o", str(target(size)), str(MASTER)],
            check=True,
        )
        print(f"wrote {target(size).relative_to(ROOT)}")
    for copy in COPIES:
        shutil.copyfile(MASTER, copy)
    return check()


if __name__ == "__main__":
    sys.exit(check() if "--check" in sys.argv[1:] else build())
