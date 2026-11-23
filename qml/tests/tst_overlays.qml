import QtQuick
import QtTest
import Meridian

Item {
    id: host
    width: 900
    height: 700

    Component { id: spyComponent; SignalSpy {} }
    Component {
        id: panelComponent
        MeridianPanel {
            title: "Logbook"
            width: 300
            Rectangle { objectName: "panelBody"; width: 280; height: 120 }
        }
    }
    Component {
        id: busyComponent
        Item {
            anchors.fill: parent
            property int clicks: 0
            property alias overlay: overlay
            property alias cancel: cancel
            MouseArea { anchors.fill: parent; onClicked: parent.clicks++ }
            MeridianBusyOverlay {
                id: overlay
                anchors.fill: parent
                message: "Merging…"
                MeridianButton { id: cancel; text: "Cancel"; variant: MeridianButton.Quiet }
            }
        }
    }
    Component {
        id: settingsComponent
        MeridianSettingsDialog {
            title: "Settings"
            pages: [{ label: "One" }, { label: "Two" }]
            property alias failureText: failure
            footerShown: failure.text.length > 0
            footerContent: [Text { id: failure }]
            Item { objectName: "short"; height: 40 }
            Item { objectName: "tall"; height: 900 }
        }
    }
    Component {
        id: licenseComponent
        MeridianLicenseDialog {
            packages: [{ name: "Beta", licenses: ["B1", "B2"] }, { name: "alpha", licenses: ["A"] }]
            applicationName: "App"
        }
    }
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
        id: surfaceComponent
        MeridianDialogSurface {
            label: "Review"
            Item { objectName: "surfaceBody"; anchors.fill: parent }
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

        function test_panel_enters_closes_on_escape_and_reports_its_exit() {
            const panel = createTemporaryObject(panelComponent, host)
            tryCompare(panel, "opacity", 1)
            compare(panel.height, panel.headerHeight + 120 + panel.bottomPadding)
            const closes = spy(panel, "closeRequested")
            panel.forceActiveFocus()
            keyClick(Qt.Key_Escape)
            compare(closes.count, 1)
            const hidden = spy(panel, "hidden")
            panel.shown = false
            tryCompare(hidden, "count", 1)
            compare(panel.opacity, 0)
        }

        function test_busy_overlay_blocks_at_once_and_shows_after_the_delay() {
            const page = createTemporaryObject(busyComponent, host)
            const content = findChild(page.overlay, "busyOverlayContent")
            compare(content.opacity, 0)
            mouseClick(page, 5, 5)
            compare(page.clicks, 0) // input stops before anything shows
            tryCompare(content, "opacity", 1, Motion.spinnerDelay + Motion.quick + 500)
            const clicked = spy(page.cancel, "clicked")
            mouseClick(page.cancel)
            compare(clicked.count, 1) // the action still works
            compare(page.overlay.Accessible.name, "Merging…")
            verify(page.overlay.hasAction)
            page.cancel.visible = false
            verify(!page.overlay.hasAction)
        }

        function test_settings_dialog_sizes_the_shown_page_and_hides_an_empty_footer() {
            const dialog = createTemporaryObject(settingsComponent, host)
            dialog.open()
            tryVerify(() => dialog.opened)
            const body = findChild(dialog.contentItem, "settingsBody")
            compare(body.contentHeight, 40 + body.pageTop + 2 * dialog.inset)
            dialog.currentPage = 1
            tryCompare(body, "contentHeight", 900 + body.pageTop + 2 * dialog.inset)
            const footer = findChild(dialog.contentItem, "settingsFooter")
            verify(!footer.visible)
            dialog.failureText.text = "Could not save"
            tryVerify(() => footer.visible)
        }

        function test_license_dialog_filters_and_counts_licenses() {
            const dialog = createTemporaryObject(licenseComponent, host)
            compare(dialog.selected, "Beta")
            compare(dialog.countText(1), "1 license")
            compare(dialog.countText(2), "2 licenses")
            dialog.query = "ALP"
            compare(dialog.visiblePackages.length, 1)
            compare(dialog.visiblePackages[0].name, "alpha")
            dialog.countText = count => count + " Lizenzen"
            compare(dialog.countText(3), "3 Lizenzen")
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

        function test_dialog_surface_fills_the_window_and_closes_on_escape() {
            const surface = createTemporaryObject(surfaceComponent, host)
            surface.fillWindow = true
            surface.open()
            tryVerify(() => surface.opened)
            compare(surface.width, surface.parent.width - 2 * surface.margin)
            compare(surface.height, surface.parent.height - 2 * surface.margin)
            compare(surface.padding, 0)
            compare(surface.header, null)
            surface.contentItem.forceActiveFocus()
            keyClick(Qt.Key_Escape)
            tryVerify(() => !surface.visible)
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
