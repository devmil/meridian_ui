#!/usr/bin/env python3
"""Build design/project/components/bundle.js from design/src/bundle.src.js and the
Lucide SVGs in assets/icons/ (inlined as an ICONS map for the previews)."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "design" / "src" / "bundle.src.js"
OUT = ROOT / "design" / "project" / "components" / "bundle.js"
COMPONENTS = ["Button", "SplitButton", "ShortcutField", "IconButton", "ToolbarButton", "TextField", "Checkbox", "Radio", "RadioGroup", "Switch",
              "Segmented", "Slider", "RangeSlider", "Select", "Menu", "Suggestions", "Tabs", "TabStrip", "NavSection", "NavRow", "ListRow", "AppBar", "Kbd",
              "Count", "Avatar", "Chip", "StatusDot", "MiddleEllipsis", "Spinner", "ProgressBar", "Meter", "Waveform", "Banner", "Toast",
              "EmptyState", "Skeleton", "Island", "Disclosure", "Dialog", "Sheet", "Panel", "SettingsDialog", "LicenseDialog", "Tooltip", "SelectableText", "Scaffold", "SettingsGroup",
              "SettingsRow", "PropertyList", "ColumnHeader", "ResizeHandle", "StatusBar", "ColorSwatch", "ColorPicker", "ColorWell", "FloatingButton", "Drawer", "Scrollbar",
              "Popover", "Breadcrumbs", "Pagination", "Steps", "SelectionBar", "DropZone", "Calendar", "BusyOverlay", "Canvas", "Paper", "ToolDock", "ToolDockDivider", "Icon"]

icons = {}
for svg in sorted((ROOT / "assets" / "icons").glob("*.svg")):
    text = svg.read_text()
    m = re.search(r"<svg[^>]*>(.*)</svg>", text, re.S)
    inner = re.sub(r"\s+", " ", m.group(1)).strip()
    icons[svg.stem] = inner

header = "/* @ds-bundle: " + json.dumps({"format": 4, "namespace": "Meridian", "components": [{"name": c} for c in COMPONENTS]}) + " */\n"
body = SRC.read_text().replace("__ICONS__", json.dumps(icons, separators=(",", ":")))
out = header + body
assert "</script" not in out.lower() and "<!--" not in out
OUT.write_text(out)
print(f"bundle.js: {len(out)} bytes, {len(icons)} icons")
