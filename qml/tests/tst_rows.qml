import QtQuick
import QtTest
import Meridian

Item {
    id: host
    width: 900
    height: 700

    Component { id: spyComponent; SignalSpy {} }
    Component {
        id: navComponent
        MeridianNavRow { width: 240; text: "Projects"; iconName: "folder"; count: 4; expandable: true }
    }
    Component {
        id: listComponent
        MeridianListRow {
            id: row
            width: 400
            text: "Quarterly report"
            subtitle: "Anna Berger"
            meta: "09:41"
            MeridianIconButton { objectName: "archiveAction"; iconName: "archive"; text: "Archive"; controlSize: MeridianButton.Small; surfaceColor: row.fillColor }
        }
    }
    Component {
        id: paginationComponent
        MeridianPagination { previousLabel: "Previous page"; nextLabel: "Next page"; pageLabel: "Page %1" }
    }
    Component {
        id: resizeComponent
        MeridianResizeHandle { width: 12; height: 400; accessibleName: "Resize sidebar" }
    }
    Component {
        id: selectionComponent
        MeridianSelectionBar { width: 400; label: "3 selected"; clearLabel: "Clear selection" }
    }
    Component {
        id: dropComponent
        MeridianDropZone { width: 300; text: "Drop files to attach"; message: "Up to 25 MB" }
    }
    Component {
        id: dateComponent
        MeridianDatePicker { previousMonthLabel: "Previous month"; nextMonthLabel: "Next month" }
    }
    Component {
        id: settingsComponent
        MeridianSettingsRow {
            width: 600
            label: "Check mail"
            help: "New mail arrives as it comes."
            MeridianSwitch { text: "Check mail"; showLabel: false }
        }
    }

    TestCase {
        id: testCase
        name: "Rows"
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

        function test_nav_row_states_and_keys() {
            const row = createTemporaryObject(navComponent, host)
            const toggled = spy(row, "toggleExpanded")
            compare(row.height, Theme.size.row)
            row.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Right)
            compare(toggled.count, 1)
            row.expanded = true
            keyClick(Qt.Key_Left)
            compare(toggled.count, 2)
            row.current = true
            verify(Qt.colorEqual(row.fillColor, Theme.colors.accentSoft))
            row.sidebarFocused = true
            verify(Qt.colorEqual(row.fillColor, Theme.colors.accent))
            row.dropState = MeridianNavRow.Reject
            verify(Qt.colorEqual(row.inkColor, Theme.colors.inkFaint))
        }

        function test_list_row_hover_actions_replace_meta() {
            const row = createTemporaryObject(listComponent, host)
            verify(!row.actionsShown)
            mouseMove(row, row.width / 2, row.height / 2)
            tryVerify(() => row.actionsShown)
            const action = findChild(row, "archiveAction")
            tryVerify(() => action.visible)
            row.selected = true
            row.islandFocused = true
            verify(Qt.colorEqual(row.inkColor, Theme.colors.inkOnAccent))
            verify(Qt.colorEqual(action.iconColor, Theme.colors.inkOnAccentMuted) || Qt.colorEqual(action.iconColor, Theme.colors.inkOnAccent))
        }

        function test_list_row_heights_follow_density() {
            const row = createTemporaryObject(listComponent, host)
            Theme.density = Theme.Compact
            compare(row.height, 24)
            Theme.density = Theme.Touch
            compare(row.height, 48)
            row.twoLine = true
            compare(row.height, 68)
            Theme.density = -1
        }

        function test_pagination_entries() {
            const pages = createTemporaryObject(paginationComponent, host, { pageCount: 5, page: 2 })
            compare(pages.entries, [1, 2, 3, 4, 5])
            pages.pageCount = 20
            pages.page = 10
            compare(pages.entries, [1, 0, 9, 10, 11, 0, 20])
            pages.page = 1
            compare(pages.entries, [1, 2, 3, 4, 5, 0, 20])
            pages.page = 20
            compare(pages.entries, [1, 0, 16, 17, 18, 19, 20])
            pages.pageCount = 1
            verify(!pages.visible)
        }

        function test_pagination_selects_pages() {
            const pages = createTemporaryObject(paginationComponent, host, { pageCount: 12, page: 5 })
            const selected = spy(pages, "pageSelected")
            mouseClick(findChild(pages, "paginationNext"))
            compare(selected.signalArguments[0][0], 6)
            mouseClick(findChild(pages, "paginationPage12"))
            compare(selected.signalArguments[1][0], 12)
            mouseClick(findChild(pages, "paginationPage5"))
            compare(selected.count, 2)
            pages.page = 1
            verify(!findChild(pages, "paginationPrevious").enabled)
        }

        function test_pagination_jump_field_clamps_and_restores() {
            const pages = createTemporaryObject(paginationComponent, host,
                                                { pageCount: 12, page: 5, jumpLabel: "Page",
                                                  pageCountLabel: "of %1",
                                                  jumpAccessibleName: "Page number, 1 to %1" })
            const selected = spy(pages, "pageSelected")
            const field = findChild(pages, "paginationJump")
            verify(field.visible)
            compare(field.text, "5")
            compare(field.Accessible.name, "Page number, 1 to 12")
            pages.submitJump("9")
            compare(selected.signalArguments[0][0], 9)
            pages.submitJump("400")
            compare(selected.signalArguments[1][0], 12)
            compare(field.text, "12")
            pages.page = 3
            compare(field.text, "3")
            pages.submitJump("")
            compare(field.text, "3")
            pages.submitJump("3")
            compare(selected.count, 2)
            pages.jumpLabel = ""
            verify(!field.visible)
        }

        function test_resize_handle_grows_on_hover_and_reports_drags() {
            const handle = createTemporaryObject(resizeComponent, host)
            const rule = findChild(handle, "resizeRule")
            const moved = spy(handle, "dragged")
            const reset = spy(handle, "resetRequested")
            compare(handle.implicitWidth, Theme.space.s3)
            verify(!rule.visible)
            mouseMove(handle, 6, 200)
            // The rule waits out the hover delay, then grows from the centre.
            compare(handle.grow, 0)
            tryCompare(handle, "grow", 1, 1000)
            compare(rule.height, 400 - 2 * Theme.space.s5)
            compare(rule.width, Metrics.resizeRule)
            verify(Qt.colorEqual(rule.color, Theme.colors.accent))
            mousePress(handle, 6, 200)
            mouseMove(handle, 26, 200)
            mouseRelease(handle, 26, 200)
            verify(moved.count >= 1)
            let total = 0
            for (let i = 0; i < moved.count; ++i)
                total += moved.signalArguments[i][0]
            compare(total, 20)
            mouseDoubleClickSequence(handle, 6, 200)
            verify(reset.count >= 1)
            mouseMove(host, 300, 10)
            tryCompare(handle, "grow", 0, 1000)
            handle.forceActiveFocus(Qt.TabFocusReason)
            const before = moved.count
            keyClick(Qt.Key_Left)
            compare(moved.count, before + 1)
            compare(moved.signalArguments[before][0], -Metrics.resizeKeyboardStep)
            compare(rule.height, 400 - 2 * Theme.space.s5)
        }

        function test_selection_bar_clear() {
            const bar = createTemporaryObject(selectionComponent, host)
            const cleared = spy(bar, "clearRequested")
            mouseClick(findChild(bar, "selectionBarClear"))
            compare(cleared.count, 1)
            bar.shown = false
            tryVerify(() => !bar.visible)
        }

        function test_drop_zone_browse_and_states() {
            const zone = createTemporaryObject(dropComponent, host)
            const browse = spy(zone, "browseRequested")
            verify(zone.height >= 104)
            mouseClick(zone)
            compare(browse.count, 1)
            zone.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Space)
            compare(browse.count, 2)
            zone.dropState = MeridianDropZone.Active
            verify(Qt.colorEqual(zone.edgeColor, Theme.colors.accent))
            zone.dropState = MeridianDropZone.Invalid
            verify(Qt.colorEqual(zone.inkColor, Theme.colors.danger))
        }

        function test_date_picker_keyboard_and_range() {
            const picker = createTemporaryObject(dateComponent, host, {
                locale: Qt.locale("de_DE"),
                focusDate: new Date(2026, 10, 18),
                firstDate: new Date(2026, 10, 2),
                lastDate: new Date(2026, 11, 31)
            })
            const chosen = spy(picker, "dateChosen")
            // German weeks start on Monday.
            compare(picker.firstWeekday, 1)
            compare(picker.gridStart.getDay(), 1)
            picker.forceActiveFocus(Qt.TabFocusReason)
            keyClick(Qt.Key_Right)
            compare(picker.focusDate.getDate(), 19)
            keyClick(Qt.Key_Down)
            compare(picker.focusDate.getDate(), 26)
            keyClick(Qt.Key_Home)
            compare(picker.focusDate.getDay(), 1)
            keyClick(Qt.Key_End)
            compare(picker.focusDate.getDay(), 0)
            keyClick(Qt.Key_PageDown)
            compare(picker.month, 11)
            keyClick(Qt.Key_PageDown)
            compare(picker.month, 11)
            keyClick(Qt.Key_Return)
            compare(chosen.count, 1)
            compare(picker.selectedDate.getMonth(), 11)
            // Days before firstDate cannot be chosen.
            picker.focusDate = new Date(2026, 10, 3)
            keyClick(Qt.Key_Left)
            keyClick(Qt.Key_Left)
            compare(picker.focusDate.getDate(), 2)
            const early = findChild(picker, "day-2026-11-1")
            verify(early !== null && !early.enabled)
        }

        function test_settings_row_stacks_when_narrow() {
            const row = createTemporaryObject(settingsComponent, host)
            verify(!row.stacked)
            row.width = 400
            verify(row.stacked)
            Theme.density = Theme.Touch
            row.width = 700
            verify(row.stacked)
            Theme.density = -1
        }
    }
}
