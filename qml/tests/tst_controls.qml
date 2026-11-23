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
        id: radiosComponent
        Column {
            property alias first: first
            property alias second: second
            MeridianRadio { id: first; text: "All changes"; checked: true }
            MeridianRadio { id: second; text: "Selected files"; description: "Choose files below" }
        }
    }
    Component {
        id: shortcutComponent
        MeridianShortcutField {
            id: shortcutField
            width: 260
            showLabel: false
            label: "Open palette"; emptyLabel: "Not set"; recordingLabel: "Press keys"
            preparingLabel: "Preparing"; clearLabel: "Clear"
            onRecordRequested: recording = true
            onCancelRecording: recording = false
            onRecorded: (key, modifiers) => { recording = false; keys = ["Ctrl", "K"] }
        }
    }
    Component {
        id: stepsComponent
        MeridianSteps { steps: ["Pick", "Review", "Resolve", "Continue"]; current: 1 }
    }
    Component {
        id: kbdComponent
        MeridianKbd { keys: ["⌘", "K"] }
    }
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
    Component {
        id: pickerComponent
        MeridianColorPicker { width: 440; color: "#18304f"; original: "#ff0000" }
    }
    Component {
        id: choiceComponent
        MeridianColorChoiceRow { width: 400; allowNone: true; value: ({ series: 2 }) }
    }
    Component {
        id: findComponent
        MeridianFindBar { width: 400; closable: true; caseSensitiveShown: true }
    }
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

    function test_color_picker_edits_by_hex_slider_wheel_and_restore() {
        const picker = createTemporaryObject(pickerComponent, host)
        const edits = spy(picker, "edited")
        const ends = spy(picker, "editFinished")
        compare(picker.hexOf(picker.shown), "#18304F")
        const hex = findChild(picker, "meridian-color-hex")
        compare(hex.text, "#18304F")
        hex.forceActiveFocus()
        hex.selectAll()
        keyClick(Qt.Key_Delete)
        for (const key of "00ff00")
            keyClick(key)
        verify(edits.count > 0)
        compare(picker.hexOf(picker.shown), "#00FF00")
        compare(Math.round(picker.hue), 120)
        keyClick(Qt.Key_Return)
        compare(ends.count, 1)
        // An invalid value says so and keeps the colour.
        hex.selectAll()
        keyClick(Qt.Key_Delete)
        keyClick("1")
        keyClick(Qt.Key_Return)
        verify(picker.hexError.length > 0)
        compare(picker.hexOf(picker.shown), "#00FF00")
        // The wheel steps the hue and saturation from the keyboard.
        picker.stepWheel(10, -0.5)
        compare(Math.round(picker.hue), 130)
        compare(Math.round(picker.saturation * 100), 50)
        // A grey keeps the hue the wheel was turned to.
        picker.choose("#808080")
        compare(Math.round(picker.hue), 130)
        // The original restores.
        picker.choose(picker.original)
        compare(picker.hexOf(picker.shown), "#FF0000")
        picker.model = "rgb"
        verify(findChild(picker, "meridian-color-r") !== null)
    }

    function test_color_choice_row_offers_none_series_and_a_custom_well() {
        const row = createTemporaryObject(choiceComponent, host)
        const chosen = spy(row, "chosen")
        verify(findChild(row, "meridian-color-series-2").selected)
        mouseClick(findChild(row, "meridian-color-series-0"))
        compare(chosen.signalArguments[0][0].series, 0)
        mouseClick(findChild(row, "meridian-color-none"))
        compare(chosen.signalArguments[1][0], null)
        const well = findChild(row, "meridian-color-custom")
        verify(!well.hasColor)
        well.edited("#123456")
        compare(chosen.signalArguments[2][0].custom, "#123456")
        compare(row.custom, "#123456")
        // A palette colour keeps the custom colour in the well.
        row.value = { series: 1 }
        verify(well.hasColor)
        verify(!well.selected)
    }

    function test_find_bar_counts_steps_and_closes_on_escape() {
        const bar = createTemporaryObject(findComponent, host)
        const next = spy(bar, "next")
        const previous = spy(bar, "previous")
        const closes = spy(bar, "closeRequested")
        const edits = spy(bar, "edited")
        bar.searchField.forceActiveFocus()
        keyClick(Qt.Key_A)
        compare(edits.count, 1)
        compare(bar.counter, "No matches")
        // Enter searches before there are matches; the buttons wait for some.
        keyClick(Qt.Key_Return)
        compare(next.count, 1)
        keyClick(Qt.Key_Return, Qt.ShiftModifier)
        compare(previous.count, 1)
        verify(!findChild(bar, "meridian-find-next").enabled)
        bar.matchCount = 12
        compare(bar.counter, "12 matches")
        bar.currentMatch = 2
        compare(bar.counter, "3 of 12")
        verify(findChild(bar, "meridian-find-next").enabled)
        verify(findChild(bar, "meridian-find-case").visible)
        // Escape clears first, then asks to close.
        keyClick(Qt.Key_Escape)
        compare(bar.text, "")
        compare(edits.signalArguments[edits.count - 1][0], "")
        compare(closes.count, 0)
        keyClick(Qt.Key_Escape)
        compare(closes.count, 1)
    }

    function test_find_bar_stacks_when_narrow() {
        const bar = createTemporaryObject(findComponent, host)
        verify(!bar.stacked)
        bar.width = 150
        verify(bar.stacked)
        compare(bar.searchField.width, 150)
    }

    function test_radios_in_one_parent_are_exclusive() {
        const group = createTemporaryObject(radiosComponent, host)
        verify(group.first.checked)
        mouseClick(group.second, 4, group.second.height / 2)
        verify(group.second.checked)
        verify(!group.first.checked)
        compare(group.second.Accessible.role, Accessible.RadioButton)
    }

    function test_shortcut_field_records_one_stroke_and_cancels_on_escape() {
        const field = createTemporaryObject(shortcutComponent, host)
        const recorded = spy(field, "recorded")
        const cancelled = spy(field, "cancelRecording")
        compare(field.valueText, "Not set")
        mouseClick(field)
        verify(field.recording)
        compare(field.valueText, "Press keys")
        keyPress(Qt.Key_Control)
        compare(recorded.count, 0) // modifiers alone record nothing
        keyClick(Qt.Key_K, Qt.ControlModifier)
        compare(recorded.count, 1)
        compare(recorded.signalArguments[0][0], Qt.Key_K)
        verify(recorded.signalArguments[0][1] & Qt.ControlModifier)
        verify(!field.recording)
        compare(field.keys.length, 2)
        mouseClick(field, 10, field.height / 2)
        verify(field.recording)
        keyClick(Qt.Key_Escape)
        compare(cancelled.count, 1)
        verify(!field.recording)
        compare(recorded.count, 1)
    }

    function test_steps_show_every_label_or_only_the_current_one() {
        const steps = createTemporaryObject(stepsComponent, host)
        steps.width = steps.implicitWidth
        verify(steps.allLabels)
        steps.width = steps.fixedWidth + 40
        verify(!steps.allLabels)
        compare(steps.stateOf(0), 0)
        compare(steps.stateOf(1), 1)
        compare(steps.stateOf(3), 2)
        steps.current = 4
        compare(steps.stateOf(3), 0) // every step done
    }

    function test_kbd_draws_one_cap_per_key() {
        const kbd = createTemporaryObject(kbdComponent, testCase)
        compare(kbd.children.length - 1, 2) // the repeater and two caps
        verify(kbd.implicitWidth >= 2 * Metrics.kbdMinWidth + Metrics.kbdGap)
        verify(kbd.implicitHeight >= Metrics.kbdHeight)
        kbd.keys = ["esc"]
        tryCompare(kbd, "implicitWidth", kbd.children[0].implicitWidth)
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

    Component {
        id: textMenuFieldComponent
        MeridianTextField { width: 260; text: "feature/login" }
    }
    Component {
        id: textMenuSelectableComponent
        MeridianSelectableText { width: 260; text: "8660cbd549" }
    }

    function textMenuOf(item) {
        for (let i = 0; i < item.children.length; ++i)
            if (item.children[i].actions !== undefined && item.children[i].openAtCursor !== undefined)
                return item.children[i]
        return null
    }

    function test_text_menu_offers_only_what_applies() {
        const field = createTemporaryObject(textMenuFieldComponent, testCase)
        const menu = textMenuOf(field)
        verify(menu !== null)
        field.forceActiveFocus()
        field.deselect()
        verify(menu.actions().indexOf("cut") < 0, "nothing selected: no cut")
        verify(menu.actions().indexOf("copy") < 0, "nothing selected: no copy")
        compare(menu.actions()[menu.actions().length - 1], "selectAll")
        field.select(0, 7)
        compare(menu.actions().slice(0, 2), ["cut", "copy"])
        field.selectAll()
        verify(menu.actions().indexOf("selectAll") < 0, "all selected: no select all")
        field.echoMode = TextInput.Password
        verify(menu.actions().indexOf("copy") < 0, "a password never copies")
        verify(menu.actions().indexOf("cut") < 0, "a password never cuts")
    }

    function test_text_menu_runs_the_editing_action() {
        const field = createTemporaryObject(textMenuFieldComponent, testCase)
        const menu = textMenuOf(field)
        field.forceActiveFocus()
        field.deselect()
        menu.run("selectAll")
        compare(field.selectedText, "feature/login")
        menu.run("cut")
        compare(field.text, "")
        verify(field.canPaste, "the cut text is on the clipboard")
        menu.run("paste")
        compare(field.text, "feature/login")
    }

    function test_selectable_text_menu_is_read_only() {
        const label = createTemporaryObject(textMenuSelectableComponent, testCase)
        const menu = textMenuOf(label)
        verify(menu.readOnly)
        label.selectAll()
        compare(menu.actions(), ["copy"])
        label.deselect()
        compare(menu.actions(), ["selectAll"])
    }

    function test_key_filter_sees_keys_first() {
        const field = createTemporaryObject(textMenuFieldComponent, testCase)
        const seen = []
        field.keyFilter = event => { seen.push(event.key); return event.key === Qt.Key_Down }
        field.forceActiveFocus()
        field.cursorPosition = 3
        keyClick(Qt.Key_Down)
        compare(field.cursorPosition, 3, "a consumed key does nothing else")
        keyClick(Qt.Key_End)
        compare(field.cursorPosition, field.length, "other keys still edit")
        compare(seen, [Qt.Key_Down, Qt.Key_End])
    }

    function test_text_menu_labels_are_localizable() {
        compare(Theme.textMenuLabels.selectAll, "Select All")
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
