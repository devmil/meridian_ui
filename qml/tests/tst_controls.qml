import QtQuick
import QtTest
import Meridian

Item {
    id: host
    width: 640
    height: 480

TestCase {
    id: testCase
    name: "Controls"
    width: 640
    height: 480
    when: windowShown

    Component {
        id: textAreaComponent
        MeridianTextArea { width: 300; placeholderText: "Description"; minimumLines: 2; maximumLines: 4 }
    }
    Component {
        id: buttonComponent
        MeridianButton { text: "Move 3 messages to archive" }
    }
    Component {
        id: iconButtonComponent
        MeridianIconButton { iconName: "search"; text: "Search" }
    }
    Component {
        id: switchComponent
        MeridianSwitch { text: "Check mail automatically" }
    }
    Component {
        id: segmentedComponent
        MeridianSegmented {
            label: "Show"
            segments: [
                { value: "all", label: "All" },
                { value: "unread", label: "Unread" },
                { value: "never", label: "Never", enabled: false },
                { value: "read", label: "Read" }
            ]
            value: "all"
            onActivated: v => value = v
        }
    }
    Component {
        id: fieldComponent
        MeridianTextField { clearLabel: "Clear search"; variant: MeridianTextField.Search; width: 240 }
    }
    Component {
        id: chipComponent
        MeridianChip { text: "Anna"; removable: true; removeLabel: "Remove Anna" }
    }
    Component {
        id: progressComponent
        MeridianProgressBar { width: 200 }
    }
    Component {
        id: emptyComponent
        MeridianEmptyState { width: 400; height: 300; title: "No messages"; message: "New mail appears here."; iconName: "inbox" }
    }
    Component {
        id: bannerComponent
        MeridianBanner { width: 400; message: "Sync paused."; tone: MeridianBanner.Attention; dismissible: true; dismissLabel: "Dismiss" }
    }
    Component { id: spyComponent; SignalSpy {} }
    Component { id: spinnerComponent; MeridianSpinner {} }

    function init() {
        Theme.brand = "crossproton"
        Theme.mode = Theme.Light
        Theme.density = -1
        Theme.reducedMotion = true
    }

    function spy(target, signal) {
        return createTemporaryObject(spyComponent, testCase, { target: target, signalName: signal })
    }

    function test_text_area_grows_between_its_line_limits() {
        const area = createTemporaryObject(textAreaComponent, testCase)
        const two = area.height
        compare(two, area.chrome + 2 * area.lineHeight)
        area.text = "one\ntwo\nthree"
        tryCompare(area, "height", area.chrome + 3 * area.lineHeight)
        area.text = "1\n2\n3\n4\n5\n6\n7"
        tryCompare(area, "height", area.chrome + 4 * area.lineHeight)
        area.forceActiveFocus()
        verify(area.textArea.activeFocus)
    }

    function test_button_pointer_and_keyboard_activation() {
        const button = createTemporaryObject(buttonComponent, host)
        const activated = spy(button, "activated")
        mouseClick(button)
        compare(activated.count, 1)
        // A pointer press never paints the keyboard ring.
        verify(!button.visualFocus)
        host.forceActiveFocus()
        button.forceActiveFocus(Qt.TabFocusReason)
        verify(button.visualFocus)
        keyClick(Qt.Key_Space)
        compare(activated.count, 2)
        keyClick(Qt.Key_Return)
        compare(activated.count, 3)
    }

    function test_button_loading_keeps_focus_and_runs_nothing() {
        const button = createTemporaryObject(buttonComponent, host, { loading: true })
        const activated = spy(button, "activated")
        button.forceActiveFocus(Qt.TabFocusReason)
        mouseClick(button)
        keyClick(Qt.Key_Space)
        compare(activated.count, 0)
        verify(button.activeFocus)
    }

    function test_button_disabled_ignores_input() {
        const button = createTemporaryObject(buttonComponent, host, { enabled: false, disabledReason: "Nothing selected" })
        const clicked = spy(button, "clicked")
        mouseClick(button)
        compare(clicked.count, 0)
        compare(button.Accessible.description, "Nothing selected")
    }

    function test_button_width_follows_label_and_minimum_height() {
        const button = createTemporaryObject(buttonComponent, host)
        const shortButton = createTemporaryObject(buttonComponent, host, { text: "OK" })
        verify(button.width > shortButton.width)
        compare(button.height, Theme.size.control)
        button.controlSize = MeridianButton.Small
        compare(button.height, Math.max(Theme.size.controlSmall, Theme.type.labelLineHeight + 2 * Theme.space.s2))
        button.iconOnly = true
        button.iconName = "archive"
        compare(button.width, Theme.size.controlSmall)
    }

    function test_button_press_scale_settles_at_rest() {
        Theme.reducedMotion = false
        const button = createTemporaryObject(buttonComponent, host)
        mousePress(button)
        mouseRelease(button)
        tryCompare(button, "scale", 1)
    }

    function test_button_success_hold_reports_once() {
        const button = createTemporaryObject(buttonComponent, host, { iconName: "send" })
        const finished = spy(button, "successFinished")
        button.success = true
        finished.wait(Motion.hold + 1000)
        compare(finished.count, 1)
    }

    function test_icon_button_names_itself_and_toggles_look() {
        const button = createTemporaryObject(iconButtonComponent, host)
        compare(button.Accessible.name, "Search")
        verify(Qt.colorEqual(button.iconColor, Theme.colors.inkMuted))
        button.active = true
        verify(Qt.colorEqual(button.iconColor, Theme.colors.accentInk))
        button.surfaceColor = Theme.colors.accent
        verify(Qt.colorEqual(button.iconColor, Theme.colors.inkOnAccentMuted))
    }

    function test_switch_toggles_and_thumb_reaches_terminal_state() {
        const toggle = createTemporaryObject(switchComponent, host)
        mouseClick(toggle)
        verify(toggle.checked)
        const thumb = findChild(toggle, "switchThumb")
        compare(thumb.x, toggle.indicator.width - Metrics.switchThumbInset - thumb.width)
        toggle.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Space)
        verify(!toggle.checked)
        compare(thumb.x, Metrics.switchThumbInset)
    }

    function test_segmented_arrows_skip_disabled_and_home_end() {
        const control = createTemporaryObject(segmentedComponent, host)
        control.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Right)
        compare(control.value, "unread")
        keyClick(Qt.Key_Right)
        compare(control.value, "read")
        keyClick(Qt.Key_Right)
        compare(control.value, "read")
        keyClick(Qt.Key_Home)
        compare(control.value, "all")
        keyClick(Qt.Key_End)
        compare(control.value, "read")
    }

    function test_segmented_manual_activation() {
        const control = createTemporaryObject(segmentedComponent, host, { manualActivation: true })
        control.forceActiveFocus(Qt.TabFocusReason)
        keyClick(Qt.Key_Right)
        compare(control.value, "all")
        compare(control.focusIndex, 1)
        keyClick(Qt.Key_Space)
        compare(control.value, "unread")
    }

    function test_segmented_shares_width_when_narrow() {
        const control = createTemporaryObject(segmentedComponent, host)
        tryVerify(() => control.implicitWidth > 100)
        const natural = control.implicitWidth
        control.width = 120
        // Narrow: the segments share the width instead of overflowing.
        const last = findChild(control, "segment3")
        tryVerify(() => last.x + last.width <= 120 - 2 * control.inset + 0.5,
                  1000, "last segment ends at " + (last.x + last.width))
        control.width = natural
        tryVerify(() => Math.abs(last.width - last.implicitWidth) < 1)
    }

    function test_text_field_clear_button() {
        const field = createTemporaryObject(fieldComponent, host)
        field.forceActiveFocus()
        keyClick(Qt.Key_A)
        keyClick(Qt.Key_B)
        compare(field.text, "ab")
        const clear = findChild(field, "textFieldClearButton")
        verify(clear.visible)
        // The trailing row lays out on the next polish.
        tryVerify(() => clear.mapToItem(field, 0, 0).x + clear.width <= field.width)
        mouseClick(clear)
        compare(field.text, "")
        verify(field.activeFocus)
    }

    function test_chip_remove_is_its_own_button() {
        const chip = createTemporaryObject(chipComponent, host)
        const removed = spy(chip, "removeRequested")
        const remove = findChild(chip, "chipRemoveButton")
        compare(remove.Accessible.name, "Remove Anna")
        mouseClick(remove)
        compare(removed.count, 1)
    }

    function test_spinner_waits_then_shows_and_resets() {
        const spinner = createTemporaryObject(spinnerComponent, host)
        verify(!spinner.shown)
        tryVerify(() => spinner.shown, Motion.spinnerDelay + 1000)
        tryCompare(findChild(spinner, "spinnerArc"), "opacity", 1)
        spinner.running = false
        verify(!spinner.shown)
        spinner.running = true
        verify(!spinner.shown)
        tryVerify(() => spinner.shown, Motion.spinnerDelay + 1000)
    }

    function test_progress_bar_determinate_and_completion_fade() {
        const bar = createTemporaryObject(progressComponent, host, { value: 0.5 })
        const fill = findChild(bar, "progressFill")
        compare(fill.width, 100)
        bar.value = 1
        tryCompare(fill, "opacity", 0, Motion.progressHold + 1000)
        bar.value = -1
        verify(bar.indeterminate)
    }

    function test_empty_state_reaches_terminal_opacity_with_reduced_motion() {
        const state = createTemporaryObject(emptyComponent, host)
        const column = state.children[0]
        for (let i = 0; i < column.children.length; ++i) {
            const part = column.children[i]
            if (part.visible)
                tryCompare(part, "opacity", 1, 1000)
        }
    }

    function test_empty_state_reaches_terminal_opacity_with_motion() {
        Theme.reducedMotion = false
        const state = createTemporaryObject(emptyComponent, host)
        const column = state.children[0]
        tryCompare(column.children[1], "opacity", 1, 2000)
        tryCompare(column.children[3], "opacity", 1, 2000)
    }

    function test_banner_dismiss_and_collapse() {
        const banner = createTemporaryObject(bannerComponent, host)
        const dismissed = spy(banner, "dismissed")
        verify(banner.height > 0)
        banner.shown = false
        tryCompare(banner, "height", 0)
        banner.shown = true
        tryVerify(() => banner.height > 0)
        compare(dismissed.count, 0)
    }

    Component { id: badgeButton; MeridianIconButton { text: "Operations"; iconName: "history" } }

    function test_icon_button_badge_pops_in_and_leaves() {
        const button = createTemporaryObject(badgeButton, host)
        let dot = null
        for (let i = 0; i < button.children.length; ++i)
            if (button.children[i].hasOwnProperty("tone") && button.children[i].hasOwnProperty("count"))
                dot = button.children[i]
        verify(dot !== null, "the button has a badge")
        verify(!dot.visible)
        button.badge = 3
        tryVerify(() => dot.visible && dot.opacity === 1)
        button.badge = 0
        tryVerify(() => !dot.visible)
    }

    function test_spinning_finishes_its_turn() {
        const button = createTemporaryObject(badgeButton, host)
        Theme.reducedMotion = false
        button.spinning = true
        tryVerify(() => button._spin > 0.1, 3000, "spin " + button._spin + " reduced " + Motion.reduced)
        button.spinning = false
        tryVerify(() => Math.abs(button._spin - Math.round(button._spin)) < 0.001, 3000, "end " + button._spin)
    }

}
}
