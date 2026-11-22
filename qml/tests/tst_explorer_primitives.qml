import QtQuick
import QtTest
import Meridian

// Regressions found while porting ProcessLama onto the QML library.
Item {
    id: host
    width: 1000
    height: 700

    TestCase {
        name: "ExplorerPrimitives"
        when: windowShown

        Component {
            id: dialogComponent
            MeridianDialog {
                title: "About"
                Text { text: "Body" }
                actions: [
                    MeridianButton { objectName: "cancel"; text: "Cancel" },
                    MeridianButton { objectName: "verb"; text: "Save" }
                ]
            }
        }
        Component {
            id: textComponent
            MeridianText { text: "systemd"; role: MeridianText.Caption }
        }
        Component {
            id: fieldComponent
            MeridianTextField { width: 300; placeholderText: "Search processes" }
        }
        Component {
            id: navComponent
            MeridianNavRow { width: 200; text: "Live" }
        }

        function cleanup() {
            Theme.textScale = 1
        }

        Component {
            id: swapComponent
            MeridianSwapText { text: "1 process" }
        }
        Component {
            id: iconButtonComponent
            MeridianIconButton { iconName: "pin"; text: "Pin"; iconColorOverride: "#ff0000" }
        }

        function test_swap_text_without_animation_swaps_at_once() {
            const swap = createTemporaryObject(swapComponent, host, { animated: false })
            const leaving = swap.children[0]
            const current = swap.children[1]
            swap.text = "2 processes"
            compare(current.text, "2 processes")
            compare(leaving.opacity, 0)
            compare(current.opacity, 1)
        }

        function test_swap_text_animates_by_default() {
            const swap = createTemporaryObject(swapComponent, host)
            const leaving = swap.children[0]
            swap.text = "2 processes"
            verify(leaving.opacity > 0)
            tryCompare(leaving, "opacity", 0)
        }

        function test_hidden_swap_text_swaps_at_once() {
            const swap = createTemporaryObject(swapComponent, host, { visible: false })
            swap.text = "2 processes"
            compare(swap.children[0].opacity, 0)
        }

        function test_icon_override_follows_data_at_once() {
            const button = createTemporaryObject(iconButtonComponent, host)
            const glyph = button.contentItem.children[0]
            button.iconColorOverride = "#0000ff"
            verify(Qt.colorEqual(glyph.color, "#0000ff"))
        }

        function test_dialog_has_an_implicit_size() {
            const dialog = createTemporaryObject(dialogComponent, host)
            dialog.open()
            tryCompare(dialog, "opened", true)
            verify(dialog.height > 0, "a dialog sizes itself to its content")
            verify(dialog.width > 0)
        }

        function test_dialog_actions_keep_their_order() {
            const dialog = createTemporaryObject(dialogComponent, host)
            dialog.open()
            tryCompare(dialog, "opened", true)
            const cancel = findChild(dialog.footer, "cancel")
            const verb = findChild(dialog.footer, "verb")
            verify(cancel.mapToItem(null, 0, 0).x < verb.mapToItem(null, 0, 0).x, "the verb ends the row")
        }

        function test_font_overrides_keep_the_role_family() {
            const text = createTemporaryObject(textComponent, host)
            const family = text.font.family
            const size = text.font.pixelSize
            text.fontWeight = Font.DemiBold
            text.strikeout = true
            compare(text.font.family, family)
            compare(text.font.pixelSize, size)
            compare(text.font.weight, Font.DemiBold)
            verify(text.font.strikeout)
        }

        function test_text_scale_scales_type() {
            const before = Theme.type.body.pixelSize
            Theme.textScale = 0.5
            // Qt font pixel sizes are integers: the scaled size rounds.
            compare(Theme.type.body.pixelSize, Math.round(before * 0.5))
        }

        function test_text_field_shows_its_placeholder() {
            const field = createTemporaryObject(fieldComponent, host)
            let found = false
            for (let i = 0; i < field.background.children.length; ++i) {
                const child = field.background.children[i]
                if (child.text === "Search processes") {
                    found = child.visible
                }
            }
            verify(found, "the placeholder shows while the field is empty")
        }

        function test_nav_row_selected_keeps_the_regular_label() {
            const row = createTemporaryObject(navComponent, host, { selected: true })
            verify(row.marked)
            verify(!row.current)
        }
    }
}
