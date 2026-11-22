import QtQuick
import QtTest
import Meridian
import "../gallery"

// Renders the gallery for design review into the working directory:
//   cd /abs/capture/dir && QT_QPA_PLATFORM=offscreen qmltestrunner \
//     -import <repo>/qml -input <repo>/qml/tools/capture_gallery.qml
// Not part of the test suite (tests/ holds the assertions).
Item {
    id: host
    width: 1280
    height: 1400

    Component { id: galleryComponent; Gallery {} }

    TestCase {
        name: "CaptureGallery"
        when: windowShown

        function test_capture_data() {
            return [
                { tag: "crossproton-light-1280", width: 1280, mode: Theme.Light, density: Theme.Regular },
                { tag: "crossproton-dark-1280", width: 1280, mode: Theme.Dark, density: Theme.Regular },
                { tag: "crossproton-light-390-touch", width: 390, mode: Theme.Light, density: Theme.Touch }
            ]
        }

        function test_capture(data) {
            Theme.brand = "crossproton"
            Theme.mode = data.mode
            Theme.density = data.density
            Theme.reducedMotion = true
            const gallery = createTemporaryObject(galleryComponent, host, { width: data.width, height: host.height })
            waitForRendering(gallery)
            wait(400)
            grabImage(gallery).save("gallery-" + data.tag + ".png")
        }
    }
}
