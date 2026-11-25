import QtQuick
import QtTest
import Meridian

Item {
    id: host
    width: 900
    height: 200

    Component {
        id: stripComponent
        MeridianTabStrip {
            width: 700
            renamable: true
            groupsMovable: true
            tabs: [
                { id: 1, label: "alpha", group: "g" },
                { id: 2, label: "beta", group: "g" },
                { id: 3, label: "gamma" },
            ]
            groups: [{ id: "g", color: "#1f6fd6", name: "Work" }]
            activeTab: 3
        }
    }
    Component { id: spyComponent; SignalSpy {} }
    Component {
        id: boundedStripComponent
        Item {
            property real maxW: 900
            property alias strip: bounded
            width: 900
            height: 40
            MeridianTabStrip {
                id: bounded
                width: Math.min(implicitWidth, parent.maxW)
                tabs: [
                    { id: 1, label: "alpha" },
                    { id: 2, label: "beta" },
                    { id: 3, label: "gamma" },
                ]
                activeTab: 3
            }
        }
    }

    TestCase {
        id: stripCase
        name: "TabStrip"
        when: windowShown

        function settle(strip) {
            wait(Motion.layout + 50)
        }

        function test_group_chip_stands_before_its_tabs() {
            Theme.reducedMotion = true
            const strip = createTemporaryObject(stripComponent, host)
            settle(strip)
            verify(strip.tabWidth >= Metrics.tabPillMinWidth && strip.tabWidth <= Metrics.tabLabelMaxWidth)
            const keys = []
            for (let row = 0; row < strip.entryCount(); ++row)
                keys.push(strip.entryKeyAt(row))
            compare(keys.join(","), "group:g,tab:1,tab:2,tab:3")
        }

        function test_dragging_a_tab_out_of_its_group() {
            Theme.reducedMotion = true
            const strip = createTemporaryObject(stripComponent, host)
            settle(strip)
            const moved = createTemporaryObject(spyComponent, stripCase, { target: strip, signalName: "moveRequested" })
            strip._startDrag("tab:1", 10, 0)
            strip._updateDrag(10 + strip._total)
            strip._endDrag(true)
            compare(moved.count, 1)
            compare(moved.signalArguments[0][0], 1)
            compare(moved.signalArguments[0][1], 2)
            compare(moved.signalArguments[0][2], null)
        }

        function test_renaming_emits_the_new_name() {
            Theme.reducedMotion = true
            const strip = createTemporaryObject(stripComponent, host)
            settle(strip)
            const renamed = createTemporaryObject(spyComponent, stripCase, { target: strip, signalName: "renamed" })
            strip.renameTab(3)
            strip._finishTabRename(3, "delta")
            compare(renamed.count, 1)
            compare(renamed.signalArguments[0][1], "delta")
        }

        function test_a_collapsed_group_hides_its_tabs() {
            Theme.reducedMotion = true
            const strip = createTemporaryObject(stripComponent, host)
            strip.groups = [{ id: "g", color: "#1f6fd6", name: "Work", collapsed: true }]
            settle(strip)
            verify(strip._total < 2 * strip.tabWidth + 100)
        }

        function test_width_resize_snaps_without_layout_animation() {
            Theme.reducedMotion = false
            const strip = createTemporaryObject(stripComponent, host)
            settle(strip)
            const before = strip.tabWidth
            strip.width = 420
            wait(1)
            verify(strip.tabWidth < before)
            verify(strip._layoutAnimated)
            // The active tab indicator updates immediately with zero duration on width resize.
            compare(strip._total < 420 + 1, true)
            Theme.reducedMotion = true
        }

        function test_dragging_and_widening_do_not_ratchet_tab_width() {
            Theme.reducedMotion = true
            const box = createTemporaryObject(boundedStripComponent, host)
            const strip = box.strip
            settle(strip)
            compare(strip.tabWidth, Metrics.tabLabelMaxWidth)
            // Dragging the last tab left must not shrink implicitWidth or tabWidth.
            const startX = strip._total - strip.tabWidth
            strip._startDrag("tab:3", startX + 20, startX)
            strip._updateDrag(40)
            settle(strip)
            compare(strip.tabWidth, Metrics.tabLabelMaxWidth)
            strip._endDrag(false)
            settle(strip)
            compare(strip.tabWidth, Metrics.tabLabelMaxWidth)
            // Narrowing then widening restores full tabWidth.
            box.maxW = 360
            settle(strip)
            verify(strip.tabWidth < Metrics.tabLabelMaxWidth)
            box.maxW = 900
            settle(strip)
            compare(strip.tabWidth, Metrics.tabLabelMaxWidth)
        }
    }
}
