import QtQuick
import QtTest
import Meridian

TestCase {
    name: "Theme"

    function init() {
        Theme.brand = "crossproton"
        Theme.mode = Theme.Light
        Theme.density = -1
        Theme.reducedMotion = false
    }

    function test_brand_accent_follows_theme() {
        compare(Theme.colors.accent.toString(), "#6d4aff")
        Theme.mode = Theme.Dark
        verify(Theme.dark)
        compare(Theme.colors.accent.toString(), "#9b83ff")
        compare(Theme.colors.ground.toString(), Tokens.palettes.crossproton.dark.ground)
    }

    function test_system_mode_follows_platform_scheme() {
        Theme.mode = Theme.System
        Theme.systemDark = true
        verify(Theme.dark)
        Theme.systemDark = false
        verify(!Theme.dark)
    }

    function test_every_brand_resolves_every_role() {
        const roles = ["ground", "pane", "paneAlt", "raised", "ink", "inkMuted", "inkFaint", "line",
                       "lineStrong", "controlEdge", "accent", "onAccent", "accentSoft", "accentInk",
                       "focus", "danger", "dangerBg", "success", "warning", "attention"]
        for (const id of Tokens.brandIds) {
            for (const mode of [Theme.Light, Theme.Dark]) {
                Theme.brand = id
                Theme.mode = mode
                for (const role of roles)
                    verify(Theme.colors[role].a > 0, id + "/" + mode + "/" + role)
            }
        }
    }

    function test_brand_radius_overrides_core_steps() {
        compare(Theme.radius.md, 10)
        compare(Theme.radius.pill, 999)
        Theme.brand = "gitlama"
        compare(Theme.radius.md, Tokens.radius.md)
    }

    function test_density_sets_extents_and_type() {
        Theme.density = Theme.Compact
        compare(Theme.size.row, 24)
        Theme.density = Theme.Regular
        compare(Theme.size.row, 28)
        compare(Theme.size.control, 28)
        compare(Theme.type.body.pixelSize, 13)
        Theme.density = Theme.Comfortable
        compare(Theme.size.row, 32)
        Theme.density = Theme.Touch
        compare(Theme.size.row, 48)
        compare(Theme.size.control, 44)
        compare(Theme.size.minTarget, 48)
        compare(Theme.type.body.pixelSize, 15)
        compare(Theme.type.bodyLineHeight, 22)
    }

    function test_type_roles_use_brand_families() {
        compare(Theme.type.body.family, "Inter")
        compare(Theme.type.code.family, "JetBrains Mono")
        compare(Theme.type.reading.family, "Georgia")
        compare(Theme.type.overline.capitalization, Font.AllUppercase)
        compare(Theme.type.bodyStrong.weight, 600)
    }

    function test_layout_metrics_are_generated() {
        compare(Metrics.focusRingWidth, 2)
        compare(Metrics.focusRingOffset, 1)
        compare(Metrics.dialogConfirmWidth, Metrics.dialogWidth)
        compare(Metrics.opacityPressedOverlay, 0.04)
    }

    function test_blend_helpers() {
        const pressed = Theme.pressed(Theme.colors.pane)
        verify(!Qt.colorEqual(pressed, Theme.colors.pane))
        compare(Theme.clear(Theme.colors.accent).a, 0)
        verify(Qt.colorEqual(Theme.hoverFillOn(Theme.colors.pane, false), Theme.colors.paneHover))
        verify(Qt.colorEqual(Theme.hoverFillOn("transparent", true), Theme.colors.groundHover))
    }
}
