import QtQuick
import QtTest
import Meridian
import "../gallery"

// The gallery is a layout test across widths, densities, themes and brands:
// it has found layout bugs that primitive tests missed in the Flutter
// library. Scroll the page's own Flickable to its end and check the last
// section was built and nothing overflows horizontally.
Item {
    id: host
    width: 1280
    height: 900

    Component { id: galleryComponent; Gallery {} }

    TestCase {
        name: "Gallery"
        when: windowShown

        function init() {
            Theme.brand = "crossproton"
            Theme.mode = Theme.Light
            Theme.density = -1
            Theme.reducedMotion = true
        }

        function overflowing(item, limit) {
            const found = []
            const walk = node => {
                if (!node.visible || node.width <= 0)
                    return
                const p = node.mapToItem(host, 0, 0)
                if (p.x + node.width > limit + 0.5 && !(node instanceof Flickable))
                    found.push((node.objectName || node.toString()) + " ends at " + (p.x + node.width))
                for (let i = 0; i < node.children.length; ++i)
                    walk(node.children[i])
            }
            walk(item)
            return found
        }

        function scrollToEnd(gallery) {
            const flick = gallery.flickable
            let previous = -1
            for (let i = 0; i < 50 && flick.contentY !== previous; ++i) {
                previous = flick.contentY
                flick.contentY = Math.max(0, flick.contentHeight - flick.height)
                wait(0)
            }
            return flick
        }

        function check(width, density, mode, brand) {
            Theme.density = density
            Theme.mode = mode
            Theme.brand = brand
            const gallery = createTemporaryObject(galleryComponent, host, { width: width, height: 900 })
            waitForRendering(gallery)
            const flick = scrollToEnd(gallery)
            verify(flick.contentY >= flick.contentHeight - flick.height - 1)
            const type = findChild(gallery, "galleryType")
            verify(type !== null && type.height > 0)
            const issues = overflowing(gallery, width)
            compare(issues.length, 0, width + "px " + brand + ": " + issues.slice(0, 5).join("; "))
        }

        function test_layout_matrix_data() {
            return [
                { tag: "390 regular", width: 390, density: Theme.Regular, mode: Theme.Light, brand: "crossproton" },
                { tag: "390 touch dark", width: 390, density: Theme.Touch, mode: Theme.Dark, brand: "crossproton" },
                { tag: "1280 regular", width: 1280, density: Theme.Regular, mode: Theme.Light, brand: "crossproton" },
                { tag: "1280 compact dark gitlama", width: 1280, density: Theme.Compact, mode: Theme.Dark, brand: "gitlama" },
                { tag: "1280 touch", width: 1280, density: Theme.Touch, mode: Theme.Light, brand: "mimameidr" }
            ]
        }

        function test_layout_matrix(data) {
            check(data.width, data.density, data.mode, data.brand)
        }
    }
}
