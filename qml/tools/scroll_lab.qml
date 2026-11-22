pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Templates as T
import Meridian

// Hands-on check of wheel and touchpad scrolling on real hardware:
//     qml -I qml qml/tools/scroll_lab.qml
// Left: Qt Quick's own wheel handling. Right: MeridianWheelScroll. The strip
// at the bottom logs each wheel event as the platform delivered it.
Window {
    id: window
    width: 1000
    height: 760
    visible: true
    title: "Meridian scroll lab (" + Qt.platform.pluginName + ")"
    color: Theme.colors.ground

    property var log: []
    function note(label, e) {
        const phases = ["none", "begin", "update", "end", "momentum"]
        const line = label + "  phase " + phases[e.phase] + "  angle " + e.angleDelta.x + "," + e.angleDelta.y
            + "  pixel " + e.pixelDelta.x + "," + e.pixelDelta.y
            + "  device " + (e.device ? e.device.name + " (type " + e.device.type + ")" : "?")
        log = [line].concat(log).slice(0, 8)
    }

    component ScrollColumn: ListView {
        id: list
        required property string heading
        clip: true
        model: 2000
        delegate: Rectangle {
            id: row
            required property int index
            width: ListView.view.width
            height: 28
            color: index % 2 ? Theme.colors.pane : Theme.colors.ground
            MeridianText { anchors.verticalCenter: parent.verticalCenter; x: 12; text: list.heading + " row " + row.index }
        }
        T.ScrollBar.vertical: MeridianScrollBar { }
    }

    Row {
        x: 16
        y: 16
        spacing: 16
        ScrollColumn {
            width: (window.width - 48) / 2
            height: window.height - 200
            heading: "Qt default"
            // Observe only: the event goes on to Qt's Flickable handling.
            WheelHandler { target: null; onWheel: e => { window.note("Qt      ", e); e.accepted = false } }
        }
        ScrollColumn {
            id: meridian
            width: (window.width - 48) / 2
            height: window.height - 200
            heading: "Meridian"
            MeridianWheelScroll { flickable: meridian; onWheel: e => window.note("Meridian", e) }
        }
    }

    Rectangle {
        x: 16
        y: window.height - 168
        width: window.width - 32
        height: 152
        color: Theme.colors.pane
        radius: Theme.radius.md
        Repeater {
            model: window.log
            MeridianText {
                required property string modelData
                required property int index
                x: 12
                y: 8 + index * 17
                text: modelData
                font.family: "monospace"
            }
        }
    }
}
