import QtQuick
import QtTest
import Meridian

Item {
    id: scene
    width: 300
    height: 200

    property bool moved: false

    Rectangle {
        id: source
        width: 100
        height: 20
        MeridianTravel {
            id: from
            visible: !scene.moved
            width: 100
            travelKey: "file|a"
            Rectangle { width: 100; implicitHeight: 20; color: "red" }
        }
    }
    MeridianTravel {
        id: to
        x: 150
        y: 120
        width: 100
        visible: scene.moved
        travelKey: scene.moved ? "file|a" : ""
        Rectangle { width: 100; implicitHeight: 20; color: "red" }
    }

    TestCase {
        name: "Travel"
        when: windowShown

        function cleanup() {
            Theme.reducedMotion = false
            scene.moved = false
        }

        function test_flies_from_the_capture_to_the_destination() {
            from.capture()
            wait(50)
            scene.moved = true
            tryVerify(() => to.flying, 1000)
            verify(to.anyFlying())
            tryVerify(() => !to.flying, 2000)
            verify(!to.anyFlying())
        }

        function test_no_flight_under_reduced_motion() {
            Theme.reducedMotion = true
            from.capture()
            wait(50)
            scene.moved = true
            wait(50)
            verify(!to.flying)
        }
    }
}
