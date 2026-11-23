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
        id: entranceComponent
        MeridianEntrance {
            Rectangle { implicitWidth: 40; implicitHeight: 10 }
        }
    }

    function test_motion_memory_remembers_each_key_once() {
        MeridianMotionMemory.clear()
        verify(MeridianMotionMemory.markSeen("open|1"))
        verify(!MeridianMotionMemory.markSeen("open|1"))
        verify(MeridianMotionMemory.seen("open|1"))
        verify(!MeridianMotionMemory.seen("open|2"))
    }

    function test_entrance_plays_once_per_key() {
        MeridianMotionMemory.clear()
        Theme.reducedMotion = false
        const first = createTemporaryObject(entranceComponent, motionCase, { entranceKey: "row|a" })
        compare(first.implicitWidth, 40)
        verify(first._t < 1)
        tryCompare(first, "_t", 1)
        // A recycled row with a key already seen shows its content at rest.
        const again = createTemporaryObject(entranceComponent, motionCase, { entranceKey: "row|a" })
        compare(again._t, 1)
        // No key: at rest.
        const unkeyed = createTemporaryObject(entranceComponent, motionCase)
        compare(unkeyed._t, 1)
    }

    function test_entrance_is_off_under_reduced_motion() {
        MeridianMotionMemory.clear()
        Theme.reducedMotion = true
        const entrance = createTemporaryObject(entranceComponent, motionCase, { entranceKey: "row|b" })
        compare(entrance._t, 1)
    }

    Component {
        id: attentionComponent
        MeridianAttention {
            width: 40; height: 10
            Rectangle { anchors.fill: parent; color: "transparent" }
        }
    }

    function test_attention_tints_and_fades_back_once_per_trigger() {
        MeridianMotionMemory.clear()
        Theme.reducedMotion = false
        const attention = createTemporaryObject(attentionComponent, motionCase, { memoryKey: "row" })
        compare(attention.progress, 0)
        attention.trigger = 1
        tryVerify(() => attention.progress > 0)
        tryCompare(attention, "progress", 0, 3000)
        // A recycled row with the same key and trigger does not replay.
        const again = createTemporaryObject(attentionComponent, motionCase, { memoryKey: "row", trigger: 1 })
        compare(again.progress, 0)
        wait(50)
        compare(again.progress, 0)
    }

    Component {
        id: shakeComponent
        MeridianShake { width: 40; height: 10 }
    }

    function test_shake_moves_and_rests() {
        Theme.reducedMotion = false
        const shake = createTemporaryObject(shakeComponent, motionCase)
        compare(shake.offsetAt(0, 3), 0)
        compare(shake.offsetAt(1 / 6, 3), -3)
        compare(shake.offsetAt(1, 3), 0)
        shake.trigger = 1
        tryCompare(shake, "_t", 1)
    }

    Component {
        id: rollingComponent
        MeridianRollingNumber { value: 9 }
    }

    property int rollingSource: 0

    function test_rolling_number_follows_a_binding() {
        Theme.reducedMotion = false
        motionCase.rollingSource = 0
        const number = createTemporaryObject(rollingComponent, motionCase)
        number.value = Qt.binding(() => motionCase.rollingSource)
        motionCase.rollingSource = 2
        tryCompare(number, "_from", "")
        compare(number._to, "2")
        motionCase.rollingSource = 12
        tryCompare(number, "_from", "")
        compare(number._to, "12")
    }

    function test_rolling_number_rolls_to_the_new_value() {
        Theme.reducedMotion = false
        const number = createTemporaryObject(rollingComponent, motionCase)
        compare(number.text, "9")
        number.value = 10
        compare(number.text, "10")
        verify(number._from === "9")
        tryCompare(number, "_from", "")
        Theme.reducedMotion = true
        number.value = 11
        compare(number._from, "")
    }

    Component {
        id: resizeComponent
        MeridianResize {
            property alias inner: box
            Rectangle { id: box; implicitWidth: 40; implicitHeight: 10 }
        }
    }

    function test_resize_follows_its_content() {
        Theme.reducedMotion = false
        const resize = createTemporaryObject(resizeComponent, motionCase)
        compare(resize.implicitWidth, 40)
        wait(20)
        resize.inner.implicitWidth = 80
        verify(resize.implicitWidth < 80)
        tryCompare(resize, "implicitWidth", 80)
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


    Component {
        id: pulseComponent
        MeridianPulse {
            width: 80
            height: 28
            spread: 12
            once: true
            Rectangle { width: 80; height: 28 }
        }
    }

    function test_pulse_plays_once_and_rests() {
        const pulse = createTemporaryObject(pulseComponent, motionCase)
        compare(pulse.progress, 0)
        compare(pulse.implicitWidth, 80)
        pulse.active = true
        tryVerify(() => pulse.progress > 0 && pulse.progress < 1)
        tryVerify(() => pulse.progress === 1, 3000)
    }

    function test_reduced_pulse_shows_a_static_disc_only_when_looping() {
        Theme.reducedMotion = true
        const pulse = createTemporaryObject(pulseComponent, motionCase, { spread: -1, once: false })
        pulse.active = true
        compare(pulse.progress, 0)
        verify(pulse.staticHalo)
        compare(pulse.children[0].opacity, Metrics.opacityStaticHalo)
        pulse.once = true
        verify(!pulse.staticHalo)
    }

    Component {
        id: removingComponent
        MeridianRemovingRow {
            property int removedCount: 0
            onRemoved: removedCount += 1
            Rectangle { implicitWidth: 40; implicitHeight: 10 }
        }
    }

    function test_removing_row_fades_collapses_and_reports() {
        Theme.reducedMotion = false
        const row = createTemporaryObject(removingComponent, motionCase)
        compare(row.implicitHeight, 10)
        tryVerify(() => row.removing)
        tryCompare(row, "removedCount", 1, 2000)
        compare(row.implicitHeight, 0)
        // Started by its owner, after a delay.
        const later = createTemporaryObject(removingComponent, motionCase, { autoStart: false, delay: 40 })
        verify(!later.removing)
        wait(60)
        compare(later.implicitHeight, 10)
        later.start()
        later.start()
        tryCompare(later, "removedCount", 1, 2000)
        wait(50)
        compare(later.removedCount, 1)
    }

    function test_removing_row_is_instant_under_reduced_motion() {
        Theme.reducedMotion = true
        const row = createTemporaryObject(removingComponent, motionCase, { delay: 5000 })
        tryCompare(row, "removedCount", 1, 500)
    }

    Component {
        id: liftComponent
        MeridianLift {
            Rectangle { implicitWidth: 40; implicitHeight: 10 }
        }
    }

    function test_lift_scales_and_settles() {
        Theme.reducedMotion = false
        const lift = createTemporaryObject(liftComponent, motionCase, { lifted: true })
        compare(lift.implicitWidth, 40)
        tryCompare(lift, "progress", 1)
        compare(lift.scale, Tokens.scales.lift)
        lift.lifted = false
        tryCompare(lift, "progress", 0)
        compare(lift.scale, 1)
        // Reduce motion keeps the shadow, not the scale.
        Theme.reducedMotion = true
        lift.lifted = true
        tryCompare(lift, "progress", 1)
        compare(lift.scale, 1)
    }

    Component {
        id: strokeIconComponent
        MeridianStrokeIcon { name: "check" }
    }

    function test_stroke_icon_draws_and_erases() {
        Theme.reducedMotion = false
        const icon = createTemporaryObject(strokeIconComponent, motionCase)
        compare(icon.progress, 1)
        icon.drawn = false
        tryCompare(icon, "progress", 0)
        icon.drawn = true
        verify(icon.progress < 1)
        tryCompare(icon, "progress", 1)
        const appearing = createTemporaryObject(strokeIconComponent, motionCase, { appear: true, duration: 200 })
        verify(appearing.progress < 1)
        tryCompare(appearing, "progress", 1)
        Theme.reducedMotion = true
        const reduced = createTemporaryObject(strokeIconComponent, motionCase, { appear: true })
        compare(reduced.progress, 1)
    }

    Component {
        id: glideComponent
        ListView {
            id: glideView
            property alias glide: bar
            width: 100
            height: 100
            model: 40
            delegate: Item { width: 100; height: 10 }
            MeridianSelectionGlide { id: bar; view: glideView; itemExtent: 10 }
        }
    }

    function test_selection_glide_springs_near_and_jumps_far() {
        Theme.reducedMotion = false
        const view = createTemporaryObject(glideComponent, motionCase)
        const glide = view.glide
        glide.selectedIndex = 2
        compare(glide.y, 20)
        // Near and on screen: springs.
        glide.selectedIndex = 4
        verify(glide.y < 40)
        tryCompare(glide, "y", 40)
        compare(glide.opacity, 1)
        // Far: placed at once and faded in.
        glide.selectedIndex = 30
        compare(glide.y, 300)
        verify(glide.opacity < 1)
        tryCompare(glide, "opacity", 1)
        Theme.reducedMotion = true
        glide.selectedIndex = 31
        compare(glide.y, 310)
    }
}
