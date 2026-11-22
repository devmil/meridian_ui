import QtQuick
import QtTest
import Meridian

Item {
    id: host
    width: 900
    height: 700

    Component { id: spyComponent; SignalSpy {} }
    Component { id: toastHostComponent; MeridianToastHost { anchors.fill: parent } }
    Component {
        id: dialogComponent
        MeridianDialog {
            title: "Rename notebook"
            description: "The new name shows everywhere."
            MeridianTextField { objectName: "nameField"; width: 200; Accessible.name: "Name" }
        }
    }
    Component {
        id: confirmComponent
        MeridianConfirm {
            title: "Delete 3 messages"
            description: "They are removed from every device."
            confirmLabel: "Delete 3 messages"
            cancelLabel: "Cancel"
        }
    }
    Component {
        id: menuComponent
        MeridianMenu {
            MeridianMenuItem { text: "Archive"; iconName: "archive" }
            MeridianMenuItem { text: "Move to…"; iconName: "folder-input" }
            MeridianMenuItem { text: "Mark as unread"; checkable: true }
            MeridianMenuSeparator {}
            MeridianMenuItem { text: "Delete"; danger: true }
        }
    }

    TestCase {
        id: testCase
        name: "Overlays"
        when: windowShown

        function init() {
            Theme.brand = "crossproton"
            Theme.mode = Theme.Light
            Theme.density = -1
            Theme.reducedMotion = true
        }

        function spy(target, signal) {
            return createTemporaryObject(spyComponent, testCase, { target: target, signalName: signal })
        }

        function test_toast_replaces_pauses_and_reports_action() {
            const toastHost = createTemporaryObject(toastHostComponent, host)
            const actions = spy(toastHost, "actionTriggered")
            const first = toastHost.show("Archived 3 messages", MeridianToast.Success, "Undo")
            const second = toastHost.show("Moved to Work", MeridianToast.Neutral, "Undo")
            verify(second > first)
            compare(toastHost.message, "Moved to Work")
            compare(toastHost.duration, Motion.toastAction)
            const toast = findChild(toastHost, "toast")
            tryVerify(() => toast.visible && toast.opacity === 1)
            // Hovering pauses the countdown.
            mouseMove(toast, toast.width / 2, toast.height / 2)
            tryVerify(() => toast.paused)
            const elapsed = toastHost.elapsed
            wait(200)
            compare(toastHost.elapsed, elapsed)
            mouseClick(findChild(toast, "toastAction"))
            compare(actions.count, 1)
            compare(actions.signalArguments[0][0], second)
            verify(!toastHost.showing)
        }

        function test_toast_times_out() {
            const toastHost = createTemporaryObject(toastHostComponent, host)
            const dismissed = spy(toastHost, "dismissed")
            toastHost.show("Saved")
            compare(toastHost.duration, Motion.toast)
            toastHost.elapsed = Motion.toast - 60
            tryCompare(dismissed, "count", 1, 2000)
        }

        function test_dialog_enter_submits_or_shakes() {
            const dialog = createTemporaryObject(dialogComponent, host)
            const submitted = spy(dialog, "submitted")
            dialog.open()
            tryVerify(() => dialog.opened)
            dialog.contentItem.forceActiveFocus()
            keyClick(Qt.Key_Return)
            compare(submitted.count, 1)
            dialog.submitDisabled = true
            keyClick(Qt.Key_Return)
            compare(submitted.count, 1)
            compare(dialog.rejectCount, 1)
            keyClick(Qt.Key_Escape)
            tryVerify(() => !dialog.visible)
        }

        function test_dialog_width_classes() {
            const dialog = createTemporaryObject(dialogComponent, host)
            compare(dialog.width, Metrics.dialogConfirmWidth)
            dialog.widthClass = MeridianDialog.Form
            compare(dialog.width, Metrics.dialogFormWidth)
            dialog.widthClass = MeridianDialog.Workflow
            compare(dialog.width, Metrics.dialogWorkflowWidth)
        }

        function test_destructive_confirm_starts_on_cancel() {
            const confirm = createTemporaryObject(confirmComponent, host, { destructive: true })
            const confirmed = spy(confirm, "confirmed")
            const cancelled = spy(confirm, "cancelled")
            confirm.open()
            tryVerify(() => confirm.opened)
            const cancel = findChild(confirm.footer, "cancelButton")
            tryVerify(() => cancel.activeFocus)
            keyClick(Qt.Key_Space)
            tryCompare(cancelled, "count", 1)
            compare(confirmed.count, 0)
        }

        function test_confirm_runs_the_verb() {
            const confirm = createTemporaryObject(confirmComponent, host)
            const confirmed = spy(confirm, "confirmed")
            confirm.open()
            tryVerify(() => confirm.opened)
            const verb = findChild(confirm.footer, "confirmButton")
            tryVerify(() => verb.activeFocus)
            compare(verb.variant, MeridianButton.Primary)
            keyClick(Qt.Key_Return)
            compare(confirmed.count, 1)
            tryVerify(() => !confirm.visible)
        }

        function test_menu_type_ahead_and_keys() {
            const menu = createTemporaryObject(menuComponent, host)
            menu.open()
            tryVerify(() => menu.opened)
            keyClick("m")
            compare(menu.currentIndex, 1)
            keyClick("a")
            compare(menu.currentIndex, 2)
            const triggered = spy(menu.itemAt(2), "triggered")
            keyClick(Qt.Key_Return)
            compare(triggered.count, 1)
            tryVerify(() => !menu.visible)
        }

        function test_pointer_opened_menu_highlights_nothing() {
            const menu = createTemporaryObject(menuComponent, host)
            menu.popup(host, 40, 40)
            tryVerify(() => menu.opened)
            compare(menu.currentIndex, -1)
            for (let i = 0; i < menu.count; ++i) {
                const item = menu.itemAt(i)
                verify(!item.highlighted && !item.highlightedRow, "item " + i + " starts highlighted")
            }
            // Keyboard navigation still starts at the first command.
            keyClick(Qt.Key_Down)
            compare(menu.currentIndex, 0)
        }

        function test_menu_under_a_resting_pointer_waits_for_movement() {
            const menu = createTemporaryObject(menuComponent, host)
            menu.popup(host, 50, 50)
            tryVerify(() => menu.opened)
            const first = menu.itemAt(0)
            const inside = first.mapToItem(host, first.width / 2, first.height / 2)
            // Hover reaches the scene once per frame: wait for each position.
            mouseMove(host, inside.x, inside.y)
            tryVerify(() => first.hovered)
            wait(50)
            verify(!first.highlightedRow, "highlighted before the pointer moved")
            mouseMove(host, inside.x + 8, inside.y)
            tryVerify(() => menu.pointerArmed)
            verify(first.highlightedRow)
        }

        function test_menu_separator_draws_a_hairline() {
            const menu = createTemporaryObject(menuComponent, host)
            menu.popup(host, 40, 40)
            tryVerify(() => menu.opened)
            const separator = menu.itemAt(3)
            const rule = separator.contentItem.children.length > 0 ? separator.contentItem.children[0] : separator.contentItem
            compare(rule.height, 1)
            verify(separator.height > rule.height)
        }

        function test_menu_items_paint_danger_and_check() {
            const menu = createTemporaryObject(menuComponent, host)
            const danger = menu.itemAt(4)
            verify(Qt.colorEqual(danger.inkColor, Theme.colors.danger))
            const check = menu.itemAt(2)
            check.checked = true
            verify(check.checked)
        }
    }
}
