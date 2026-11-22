import QtQuick
import QtQuick.Templates as T
import QtTest
import Meridian

Item {
    id: host
    width: 400
    height: 300

    ListView {
        id: view
        width: 400
        height: 240
        model: 500
        delegate: Rectangle { width: 400; height: 20 }
        MeridianWheelScroll { id: scroller; flickable: view }
        T.ScrollBar.vertical: MeridianScrollBar { id: bar }
    }

    ListView {
        id: strip
        y: 250
        width: 200
        height: 40
        orientation: ListView.Horizontal
        model: 50
        delegate: Rectangle { width: 40; height: 40 }
        property int observed: 0
        // An app's own onWheel observes without replacing the scrolling.
        MeridianWheelScroll { id: stripScroller; flickable: strip; onWheel: strip.observed++ }
    }

    Flickable {
        id: tall
        visible: false
        width: 400
        height: 1000
        contentHeight: 10000
        MeridianWheelScroll { id: tallScroller; flickable: tall }
    }

    TestCase {
        name: "WheelScroll"
        when: windowShown

        readonly property real step: scroller.verticalStepSize

        function init() {
            scroller.stop()
            scroller.smoothScroll = true
            scroller.syntheticMomentum = false
            scroller._nativeMomentum = false
            view.contentY = 0
            strip.contentX = 0
            wait(20)
        }

        function notch(dy, px) {
            return { angleDelta: Qt.point(0, dy), pixelDelta: Qt.point(0, px === undefined ? 0 : px),
                     phase: Qt.NoScrollPhase, modifiers: Qt.NoModifier }
        }
        function finger(phase, dy) {
            return { angleDelta: Qt.point(0, dy * 12), pixelDelta: Qt.point(0, dy),
                     phase: phase, modifiers: Qt.NoModifier }
        }

        function test_step_is_wheel_lines_and_grows_with_the_view() {
            const lines = Application.styleHints.wheelScrollLines
            // 240 px: the line floor wins.
            compare(scroller.verticalStepSize, lines * scroller.lineHeight)
            // 1000 px: GTK's extent^(2/3) = 100 px at 3 lines.
            compare(tallScroller.verticalStepSize,
                    Math.max(lines * 20, Math.pow(1000, 2 / 3) * lines / 3))
        }

        function test_a_notch_animates_one_step() {
            mouseWheel(view, 50, 50, 0, -120)
            verify(scroller.animating)
            tryVerify(() => !scroller.animating, 1000)
            compare(view.contentY, step)
        }

        function test_reduced_motion_jumps() {
            scroller.smoothScroll = false
            mouseWheel(view, 50, 50, 0, -120)
            verify(!scroller.animating)
            compare(view.contentY, step)
        }

        function test_fast_notches_add_up() {
            for (let i = 0; i < 10; ++i)
                mouseWheel(view, 50, 50, 0, -120)
            tryVerify(() => !scroller.animating, 1000)
            compare(view.contentY, 10 * step)
        }

        function test_it_stops_when_the_wheel_stops() {
            for (let i = 0; i < 5; ++i)
                mouseWheel(view, 50, 50, 0, -120)
            // At most one animation length after the last notch, and no glide.
            tryVerify(() => !scroller.animating, scroller.smoothDuration + 100)
            const settled = view.contentY
            wait(300)
            compare(view.contentY, settled)
            verify(!view.moving)
        }

        function test_a_notch_ignores_the_wayland_pixel_delta() {
            scroller.smoothScroll = false
            // Qt Wayland: one notch is angle 120 plus libinput's 15 px.
            verify(scroller.handleWheel(notch(-120, -15)))
            compare(view.contentY, step)
        }

        function test_a_high_resolution_notch_moves_its_share() {
            scroller.smoothScroll = false
            scroller.handleWheel(notch(-30))
            compare(view.contentY, Math.round(step / 4))
        }

        function test_a_touchpad_follows_its_fingers_without_animation() {
            scroller.handleWheel(finger(Qt.ScrollBegin, 0))
            scroller.handleWheel(finger(Qt.ScrollUpdate, -7))
            verify(!scroller.animating)
            compare(view.contentY, 7)
            // Slow motion rounds to a null pixel delta: stand still.
            scroller.handleWheel(finger(Qt.ScrollUpdate, 0))
            compare(view.contentY, 7)
            scroller.handleWheel(finger(Qt.ScrollEnd, 0))
            verify(!scroller.animating)
            compare(view.contentY, 7)
        }

        function test_wayland_continues_a_lifted_gesture() {
            scroller.syntheticMomentum = true
            scroller.handleWheel(finger(Qt.ScrollBegin, 0))
            for (let i = 0; i < 6; ++i) {
                scroller.handleWheel(finger(Qt.ScrollUpdate, -20))
                wait(10)
            }
            const lifted = view.contentY
            scroller.handleWheel(finger(Qt.ScrollEnd, 0))
            verify(scroller.animating)
            tryVerify(() => !scroller.animating, 3000)
            verify(view.contentY > lifted + 100)
        }

        function test_native_momentum_replaces_the_synthetic_one() {
            scroller.syntheticMomentum = true
            scroller.handleWheel(finger(Qt.ScrollBegin, 0))
            for (let i = 0; i < 6; ++i) {
                scroller.handleWheel(finger(Qt.ScrollUpdate, -20))
                wait(10)
            }
            scroller.handleWheel(finger(Qt.ScrollMomentum, -10))
            scroller.handleWheel(finger(Qt.ScrollEnd, 0))
            verify(!scroller.animating)
            compare(view.contentY, 130)
        }

        function test_a_new_gesture_stops_a_glide() {
            scroller.syntheticMomentum = true
            scroller.handleWheel(finger(Qt.ScrollBegin, 0))
            for (let i = 0; i < 6; ++i) {
                scroller.handleWheel(finger(Qt.ScrollUpdate, -20))
                wait(10)
            }
            scroller.handleWheel(finger(Qt.ScrollEnd, 0))
            verify(scroller.animating)
            scroller.handleWheel(finger(Qt.ScrollBegin, 0))
            verify(!scroller.animating)
        }

        function test_the_scrollbar_shows_while_the_wheel_scrolls() {
            tryCompare(bar, "thumbOpacity", 0, 3000)
            mouseWheel(view, 50, 50, 0, -120)
            tryCompare(bar, "thumbOpacity", 1)
            tryCompare(bar, "thumbOpacity", 0, 3000)
        }

        function test_a_sideways_view_takes_the_vertical_wheel() {
            stripScroller.smoothScroll = false
            mouseWheel(strip, 50, 20, 0, -120)
            compare(strip.contentX, stripScroller.horizontalStepSize)
            compare(strip.observed, 1)
        }

        function test_stops_at_the_ends() {
            scroller.smoothScroll = false
            mouseWheel(view, 50, 50, 0, 120)
            compare(view.contentY, 0)
            for (let i = 0; i < 400; ++i)
                mouseWheel(view, 50, 150, 0, -120)
            compare(view.contentY, view.contentHeight - view.height)
        }
    }
}
