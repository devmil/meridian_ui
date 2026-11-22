pragma ComponentBehavior: Bound
import QtQuick
import Meridian

// The Meridian QML gallery: every primitive in its states, under a toolbar
// that switches brand, theme, density and reduce motion. Run it with
//   qml -I qml qml/gallery/main.qml
MeridianGround {
    id: gallery

    readonly property bool narrow: width < 640
    property alias flickable: scroller

    implicitWidth: 1280
    implicitHeight: 900

    component Section: Column {
        id: section
        property string title
        default property alias content: body.data
        width: parent ? parent.width : 0
        spacing: Theme.space.s4
        MeridianText {
            role: MeridianText.Overline
            text: section.title
            color: Theme.colors.inkMuted
        }
        Flow {
            id: body
            width: parent.width
            spacing: Theme.space.s4
        }
    }

    // Toolbar on ground: the chrome.
    Flow {
        id: toolbar
        x: Theme.space.s5
        y: Theme.space.s4
        width: parent.width - 2 * Theme.space.s5
        spacing: Theme.space.s4

        MeridianText {
            role: MeridianText.Title
            text: "Meridian " + Tokens.version + " · QML"
            height: Theme.size.control
        }
        MeridianSegmented {
            objectName: "galleryBrand"
            width: Math.min(implicitWidth, toolbar.width)
            label: "Brand"
            controlSize: MeridianButton.Small
            segments: Tokens.brandIds.map(id => ({ value: id, label: Tokens.brands[id].name }))
            value: Theme.brand
            onActivated: v => Theme.brand = v
        }
        MeridianSegmented {
            label: "Theme"
            controlSize: MeridianButton.Small
            segments: [
                { value: Theme.System, label: "System", icon: "monitor" },
                { value: Theme.Light, label: "Light", icon: "sun" },
                { value: Theme.Dark, label: "Dark", icon: "moon" }
            ]
            value: Theme.mode
            onActivated: v => Theme.mode = v
        }
        MeridianSegmented {
            label: "Density"
            width: Math.min(implicitWidth, toolbar.width)
            controlSize: MeridianButton.Small
            segments: [
                { value: Theme.Compact, label: "Compact" },
                { value: Theme.Regular, label: "Regular" },
                { value: Theme.Comfortable, label: "Comfortable" },
                { value: Theme.Touch, label: "Touch" }
            ]
            value: Theme.resolvedDensity
            onActivated: v => Theme.density = v
        }
        MeridianSwitch {
            text: "Reduce motion"
            checked: Theme.reducedMotion
            onToggled: Theme.reducedMotion = checked
        }
    }

    MeridianIsland {
        id: island
        x: Theme.space.s3
        y: toolbar.y + toolbar.height + Theme.space.s4
        width: parent.width - 2 * Theme.space.s3
        height: parent.height - y - Theme.space.s3

        Flickable {
            id: scroller
            objectName: "galleryScroller"
            anchors.fill: parent
            contentHeight: sections.height + 2 * Theme.space.s7
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: sections
                x: Theme.space.s7
                y: Theme.space.s7
                width: scroller.width - 2 * Theme.space.s7
                spacing: Theme.space.s8

                Section {
                    title: "Buttons"
                    MeridianButton { text: "Send"; variant: MeridianButton.Primary; iconName: "send" }
                    MeridianButton { text: "Move 3 messages to archive"; iconName: "archive" }
                    MeridianButton { text: "Reply"; variant: MeridianButton.Quiet; iconName: "reply" }
                    MeridianButton { text: "Delete forever"; variant: MeridianButton.Danger }
                    MeridianButton { text: "Discard draft"; variant: MeridianButton.DangerQuiet; iconName: "trash-2" }
                    MeridianButton { text: "Sending"; variant: MeridianButton.Primary; loading: true; iconName: "send" }
                    MeridianButton { text: "Export"; enabled: false; disabledReason: "Nothing selected" }
                    MeridianButton {
                        id: saveButton
                        text: "Save copy"
                        iconName: "download"
                        onActivated: { success = false; success = true }
                    }
                    MeridianButton { text: "Filters"; controlSize: MeridianButton.Small; trailingIconName: "chevron-down" }
                    MeridianButton { text: "Archive"; iconOnly: true; iconName: "archive" }
                }

                Section {
                    title: "Icon buttons"
                    MeridianIconButton { iconName: "search"; text: "Search" }
                    MeridianIconButton { iconName: "pin"; text: "Pin"; active: true }
                    MeridianIconButton { iconName: "ellipsis"; text: "More"; controlSize: MeridianButton.Small }
                    MeridianIconButton { iconName: "refresh-cw"; text: "Refresh"; enabled: false }
                    MeridianIconButton {
                        id: disclosure
                        property bool open: false
                        iconName: "chevron-right"
                        text: open ? "Collapse" : "Expand"
                        turns: open ? 0.25 : 0
                        onClicked: open = !open
                    }
                }

                Section {
                    title: "Fields"
                    MeridianTextField { width: 260; placeholderText: "Host name"; Accessible.name: "Host name" }
                    MeridianTextField {
                        width: 260
                        variant: MeridianTextField.Search
                        placeholderText: "Search mail"
                        clearLabel: "Clear search"
                        Accessible.name: "Search mail"
                    }
                    MeridianTextField {
                        id: rejecting
                        width: 260
                        text: "https://mail.example"
                        error: true
                        Accessible.name: "Server"
                        onAccepted: rejectCount += 1
                    }
                    MeridianTextField { width: 200; text: "f4b34279b4"; monospace: true; Accessible.name: "Commit" }
                }

                Section {
                    title: "Radios"
                    Column {
                        MeridianRadio { text: "All changes"; checked: true }
                        MeridianRadio { text: "Selected files"; description: "Choose the files to stash" }
                        MeridianRadio { text: "Unavailable"; enabled: false }
                    }
                }
                Section {
                    title: "Keys"
                    Row {
                        spacing: Theme.space.s5
                        MeridianKbd { keys: ["⌘", "K"] }
                        MeridianKbd { keys: ["esc"] }
                        MeridianKbd { keys: ["Ctrl", "Shift", "P"]; pressed: true }
                    }
                }
                Section {
                    title: "Shortcut field"
                    MeridianShortcutField {
                        id: galleryShortcut
                        width: 280
                        showLabel: false
                        label: "Command palette"
                        emptyLabel: "Not set"
                        recordingLabel: "Press a key combination…"
                        preparingLabel: "Preparing…"
                        clearLabel: "Clear shortcut"
                        keys: ["Ctrl", "Shift", "P"]
                        onRecordRequested: recording = true
                        onCancelRecording: recording = false
                        onRecorded: (key, modifiers) => { recording = false }
                        onCleared: keys = []
                    }
                }
                Section {
                    title: "Text area"
                    MeridianTextArea {
                        width: Math.min(420, parent.width)
                        placeholderText: "Description"
                        Accessible.name: "Description"
                    }
                }
                Section {
                    title: "Selection"
                    MeridianSwitch { text: "Check mail automatically"; checked: true }
                    MeridianSwitch {
                        width: 320
                        text: "Load remote content"
                        description: "Images and fonts from senders load when you open a message."
                    }
                    MeridianSwitch { text: "Unavailable"; enabled: false }
                    MeridianSegmented {
                        label: "Show"
                        segments: [
                            { value: "all", label: "All" },
                            { value: "unread", label: "Unread" },
                            { value: "starred", label: "Starred", icon: "star" }
                        ]
                        value: "all"
                        onActivated: v => value = v
                    }
                    MeridianSegmented {
                        label: "Layout"
                        segments: [
                            { value: "list", icon: "list", tooltip: "List" },
                            { value: "grid", icon: "layout-grid", tooltip: "Grid" }
                        ]
                        value: "list"
                        onActivated: v => value = v
                    }
                }

                Section {
                    title: "Chips"
                    MeridianChip { text: "Inbox" }
                    MeridianChip { text: "Work"; dotColor: Theme.colors.series3 }
                    MeridianChip { text: "Unread"; interactive: true; selected: true }
                    MeridianChip { text: "Has attachment"; interactive: true; iconName: "paperclip" }
                    MeridianChip { text: "Anna Berger"; removable: true; removeLabel: "Remove Anna Berger" }
                    MeridianChip { text: "Encrypted"; tone: MeridianChip.Success; iconName: "lock" }
                    MeridianChip { text: "Expires soon"; tone: MeridianChip.Warning }
                    MeridianChip { text: "Failed"; tone: MeridianChip.Danger }
                }

                Section {
                    title: "Progress"
                    Row {
                        spacing: Theme.space.s5
                        MeridianSpinner { immediate: true }
                        MeridianSpinner { immediate: true; size: 24 }
                    }
                    MeridianProgressBar { width: 240; track: true }
                    MeridianProgressBar { width: 240; track: true; value: 0.4; persistent: true }
                }

                Section {
                    title: "Banners"
                    MeridianBanner {
                        width: Math.min(560, sections.width)
                        tone: MeridianBanner.Info
                        message: "Content search indexes your messages on this device."
                    }
                    MeridianBanner {
                        width: Math.min(560, sections.width)
                        tone: MeridianBanner.Attention
                        title: "Sync is paused."
                        message: "Proton cannot be reached. Mail you send waits in the outbox."
                        dismissible: true
                        dismissLabel: "Dismiss"
                        MeridianButton { text: "Retry"; controlSize: MeridianButton.Small }
                    }
                    MeridianBanner {
                        width: Math.min(560, sections.width)
                        tone: MeridianBanner.Error
                        message: "Could not send “Quarterly report”. The attachment is larger than 25 MB."
                    }
                }

                Section {
                    title: "Empty states"
                    MeridianIsland {
                        width: Math.min(420, sections.width)
                        height: 240
                        color: Theme.colors.paneAlt
                        MeridianEmptyState {
                            anchors.fill: parent
                            iconName: "inbox"
                            title: "No messages match “invoice 2025”"
                            message: "Check the spelling or search all folders."
                            MeridianButton { text: "Search all folders" }
                        }
                    }
                    MeridianIsland {
                        width: Math.min(420, sections.width)
                        height: 240
                        color: Theme.colors.paneAlt
                        MeridianEmptyState {
                            anchors.fill: parent
                            compact: true
                            progress: true
                            title: "Loading conversation…"
                        }
                    }
                }

                Section {
                    title: "Overlays"
                    MeridianButton {
                        text: "Show a toast"
                        onActivated: toasts.show("Archived 3 messages", MeridianToast.Success, "Undo")
                    }
                    MeridianButton {
                        text: "Delete 3 messages…"
                        variant: MeridianButton.DangerQuiet
                        onActivated: confirm.open()
                    }
                    MeridianButton {
                        id: menuAnchor
                        text: "Actions"
                        trailingIconName: "chevron-down"
                        onActivated: actionMenu.popup(menuAnchor, 0, menuAnchor.height + Theme.space.s2)
                    }
                    MeridianButton {
                        id: popoverAnchor
                        text: "Snooze until…"
                        iconName: "clock"
                        onActivated: popover.open()
                        MeridianPopover {
                            id: popover
                            width: datePicker.implicitWidth + 2 * padding
                            MeridianDatePicker {
                                id: datePicker
                                previousMonthLabel: "Previous month"
                                nextMonthLabel: "Next month"
                                onDateChosen: popover.close()
                            }
                        }
                    }
                }

                Section {
                    title: "Breadcrumbs"
                    MeridianBreadcrumbs {
                        width: Math.min(420, parent.width)
                        crumbs: [
                            { label: "Fix the parser", icon: "git-commit-horizontal", prefix: "1a2b3c4d5e", enabled: true },
                            { label: "src", enabled: true },
                            { label: "parser", enabled: true },
                            { label: "lexer.rs", emphasis: true },
                        ]
                    }
                }
                Section {
                    title: "Rows"
                    Column {
                        width: Math.min(260, sections.width)
                        MeridianNavRow { width: parent.width; text: "Inbox"; iconName: "inbox"; count: 12; countEmphasized: true; current: true }
                        MeridianNavRow { width: parent.width; text: "Projects"; iconName: "folder"; expandable: true; expanded: true }
                        MeridianNavRow { width: parent.width; text: "Quarterly"; iconName: "folder"; depth: 1 }
                        MeridianNavRow { width: parent.width; text: "Work"; iconName: "tag"; iconColor: Theme.colors.series3 }
                        MeridianNavRow { width: parent.width; text: "Archive"; iconName: "archive"; dropState: MeridianNavRow.Accept }
                    }
                    MeridianIsland {
                        width: Math.min(460, sections.width)
                        height: listColumn.height + 2 * Theme.space.s3
                        Column {
                            id: listColumn
                            x: Theme.space.s3
                            y: Theme.space.s3
                            width: parent.width - 2 * Theme.space.s3
                            MeridianListRow {
                                id: firstRow
                                width: parent.width
                                text: "Quarterly report"
                                subtitle: "Anna Berger"
                                meta: "09:41"
                                emphasized: true
                                MeridianIconButton { iconName: "archive"; text: "Archive"; controlSize: MeridianButton.Small; surfaceColor: firstRow.fillColor }
                                MeridianIconButton { iconName: "trash-2"; text: "Delete"; controlSize: MeridianButton.Small; surfaceColor: firstRow.fillColor }
                            }
                            MeridianListRow { width: parent.width; text: "Travel plans"; subtitle: "Ben Okafor"; meta: "Yesterday"; selected: true; islandFocused: true }
                            MeridianListRow { width: parent.width; text: "Invoice 2025-114"; subtitle: "Billing"; meta: "Mon"; selected: true }
                            MeridianListRow { width: parent.width; text: "Filtered out"; subtitle: "Hidden by the filter"; meta: "Sep 3"; dimmed: true }
                            MeridianListRow { width: parent.width; text: "Release notes"; subtitle: "Two lines, the subtitle below"; meta: "Aug 28"; twoLine: true; iconName: "file-text" }
                        }
                    }
                    MeridianSelectionBar { width: Math.min(460, sections.width); label: "3 selected"; clearLabel: "Clear selection"
                        MeridianIconButton { iconName: "archive"; text: "Archive"; controlSize: MeridianButton.Small; surfaceColor: Theme.colors.accentSoft }
                        MeridianIconButton { iconName: "trash-2"; text: "Delete"; controlSize: MeridianButton.Small; surfaceColor: Theme.colors.accentSoft }
                    }
                    MeridianPagination {
                        page: 5; pageCount: 20
                        previousLabel: "Previous page"; nextLabel: "Next page"; pageLabel: "Page %1"
                        onPageSelected: p => page = p
                    }
                }

                Section {
                    title: "Drop zone and settings"
                    MeridianDropZone { width: Math.min(320, sections.width); text: "Drop files to attach"; message: "Up to 25 MB" }
                    MeridianDropZone { width: Math.min(320, sections.width); text: "Release to attach"; dropState: MeridianDropZone.Active }
                    Column {
                        width: Math.min(640, sections.width)
                        spacing: Theme.space.s6
                        MeridianSettingsRow {
                            width: parent.width
                            label: "Check mail"
                            help: "New mail arrives as it comes."
                            MeridianSwitch { text: "Check mail"; showLabel: false; checked: true }
                        }
                        MeridianSettingsRow {
                            width: parent.width
                            label: "Density"
                            MeridianSegmented {
                                label: "Density"
                                segments: [{ value: 0, label: "Comfortable" }, { value: 1, label: "Compact" }]
                                value: 0
                                onActivated: v => value = v
                            }
                        }
                    }
                }

                Section {
                    objectName: "galleryIcons"
                    title: "Icons (Lucide " + IconData.lucideVersion + ")"
                    Repeater {
                        model: IconData.names
                        delegate: MeridianIcon {
                            required property string modelData
                            name: modelData
                            color: Theme.colors.inkMuted
                        }
                    }
                }

                Section {
                    objectName: "galleryType"
                    title: "Type"
                    Column {
                        width: sections.width
                        Repeater {
                            model: [
                                [MeridianText.Display, "Open a mailbox"],
                                [MeridianText.Title, "Delete 3 notebooks"],
                                [MeridianText.Heading, "Quarterly report draft"],
                                [MeridianText.Body, "Recover the connection after an early disconnect"],
                                [MeridianText.BodyStrong, "Unread conversation"],
                                [MeridianText.Label, "Move to archive"],
                                [MeridianText.Caption, "Synced · 2 min ago"],
                                [MeridianText.Overline, "Folders"],
                                [MeridianText.Code, "git fetch --prune origin"],
                                [MeridianText.Reading, "Thanks for the notes. I moved the review to Thursday."]
                            ]
                            delegate: MeridianText {
                                required property var modelData
                                width: sections.width
                                role: modelData[0]
                                text: modelData[1]
                            }
                        }
                    }
                }
            }
        }
    }

    MeridianMenu {
        id: actionMenu
        MeridianMenuItem { text: "Reply"; iconName: "reply"; shortcut: "R" }
        MeridianMenuItem { text: "Forward"; iconName: "forward"; shortcut: "F" }
        MeridianMenu {
            title: "Label as"
            MeridianMenuItem { text: "Work"; dotColor: Theme.colors.series3; checkable: true; checked: true }
            MeridianMenuItem { text: "Travel"; dotColor: Theme.colors.series5; checkable: true }
        }
        MeridianMenuItem { text: "Mark as unread"; iconName: "mail"; hint: "3" }
        MeridianMenuSeparator {}
        MeridianMenuItem { text: "Delete"; iconName: "trash-2"; danger: true }
    }

    MeridianConfirm {
        id: confirm
        title: "Delete 3 messages"
        description: "They are removed from every device. This cannot be undone."
        confirmLabel: "Delete 3 messages"
        cancelLabel: "Cancel"
        destructive: true
    }

    MeridianToastHost {
        id: toasts
        anchors.fill: parent
    }
}
