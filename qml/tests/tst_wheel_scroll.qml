import QtQuick
import QtTest
import Meridian

Item {
    id: host
    width: 400
    height: 300

    ListView {
        id: view
        anchors.fill: parent
        model: 500
        delegate: Rectangle { width: 400; height: 20 }
        MeridianWheelScroll { id: scroller; flickable: view }
    }

    ListView {
        id: strip
        y: 250
        width: 200
        height: 40
        orientation: ListView.Horizontal
        model: 50
        delegate: Rectangle { width: 40; height: 40 }
        MeridianWheelScroll { flickable: strip }
    }

    TestCase {
        name: "WheelScroll"
        when: windowShown

        function init() {
            view.contentY = 0
            wait(20)
        }

        function test_a_notch_moves_wheel_scroll_lines() {
            mouseWheel(host, 50, 50, 0, -120)
            compare(view.contentY, Application.styleHints.wheelScrollLines * scroller.lineHeight)
        }

        function test_fast_notches_add_up() {
            for (let i = 0; i < 10; ++i)
                mouseWheel(host, 50, 50, 0, -120)
            compare(view.contentY, 10 * Application.styleHints.wheelScrollLines * scroller.lineHeight)
        }

        function test_a_sideways_view_takes_the_vertical_wheel() {
            strip.contentX = 0
            mouseWheel(host, 50, 270, 0, -120)
            compare(strip.contentX, Application.styleHints.wheelScrollLines * 20)
        }

        function test_stops_at_the_ends() {
            mouseWheel(host, 50, 50, 0, 120)
            compare(view.contentY, 0)
            for (let i = 0; i < 400; ++i)
                mouseWheel(host, 50, 150, 0, -120)
            compare(view.contentY, view.contentHeight - view.height)
        }
    }
}
