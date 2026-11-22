import QtQuick
import QtTest
import Meridian

TestCase {
    id: motionCase
    name: "Motion"

    function cleanup() {
        Theme.reducedMotion = false
    }

    function test_tokens_at_rest() {
        compare(Motion.hover, 80)
        compare(Motion.select, 120)
        compare(Motion.overlay, 140)
        compare(Motion.standard, Tokens.curves.standard)
        compare(Motion.pressScale, 0.97)
        compare(Motion.staggerDelay(2), 36)
        compare(Motion.staggerDelay(40), (Motion.staggerMax - 1) * 18)
    }

    function test_reduced_motion_substitution() {
        Theme.reducedMotion = true
        for (const name of ["hover", "press", "quick", "select", "exit", "overlay", "dialog", "layout",
                            "sheet", "emphasized", "highlight", "celebrate", "shakeField", "stagger"])
            compare(Motion[name], 0, name)
        compare(Motion.snappy.duration, 0)
        compare(Motion.pop.duration, 0)
        compare(Motion.standard, Motion.linearCurve)
        compare(Motion.fade(240), Motion.reducedFade)
        compare(Motion.fade(60), 60)
        compare(Motion.staggerDelay(3), 0)
        compare(Motion.pressScale, 1)
        compare(Motion.riseContent, 0)
        // Essential indicators keep moving, more slowly; waits are not motion.
        compare(Motion.spinner, Tokens.durations.spinnerReduced)
        compare(Motion.spinnerDelay, Tokens.durations.spinnerDelay)
    }

    function test_spring_splines_end_at_rest() {
        for (const name of ["snappy", "gentle", "pop"]) {
            const spring = Tokens.springs[name]
            verify(spring.duration > 0, name)
            compare(spring.curve.length % 6, 0, name)
            // Long Easing.BezierSpline lists corrupt Qt's heap (seen on Qt
            // 6.12 with 45+ segments); the generator fits 10.
            verify(spring.curve.length <= 60, name + " has " + spring.curve.length / 6 + " segments")
            compare(spring.curve[spring.curve.length - 2], 1, name)
            compare(spring.curve[spring.curve.length - 1], 1, name)
        }
        // The pop spring overshoots; snappy barely does.
        verify(Math.max(...Tokens.springs.pop.curve.filter((_, i) => i % 2 === 1)) > 1.1)
        verify(Math.max(...Tokens.springs.snappy.curve.filter((_, i) => i % 2 === 1)) < 1.01)
    }

    Component {
        id: revealComponent
        MeridianReveal {
            axis: MeridianReveal.Horizontal
            Rectangle { implicitWidth: 40; implicitHeight: 10 }
        }
    }

    function test_reveal_collapses_and_grows_its_axis() {
        Theme.reducedMotion = false
        const reveal = createTemporaryObject(revealComponent, motionCase)
        compare(reveal.implicitWidth, 40)
        reveal.shown = false
        tryCompare(reveal, "implicitWidth", 0)
        verify(!reveal.visible)
        reveal.shown = true
        tryCompare(reveal, "implicitWidth", 40)
        compare(reveal.implicitHeight, 10)
    }


    Component {
        id: swapComponent
        MeridianSwap {
            property string value: "a"
            swapKey: value
            Text { text: parent ? "x" : "" }
        }
    }

    function test_swap_rises_new_content_in() {
        Theme.reducedMotion = false
        const swap = createTemporaryObject(swapComponent, motionCase)
        verify(swap.implicitWidth > 0)
        swap.value = "b"
        const live = swap.children[1]
        tryVerify(() => live.opacity === 1 && live.y === 0)
    }

}
