import QtQuick
import QtTest
import Meridian

Item {
    id: host
    width: 640
    height: 480

TestCase {
    id: testCase
    name: "Icon"
    width: 100
    height: 100
    when: windowShown

    Component { id: iconComponent; MeridianIcon {} }

    function test_every_listed_icon_has_an_outline() {
        verify(IconData.names.length > 200)
        for (const name of IconData.names)
            verify(IconData.paths[name].startsWith("M") || IconData.paths[name].startsWith("m"), name)
    }

    function test_icon_sizes_follow_density() {
        const icon = createTemporaryObject(iconComponent, host, { name: "mail" })
        verify(icon.known)
        compare(icon.width, 16)
        icon.iconSize = MeridianIcon.Small
        compare(icon.width, 14)
        icon.extent = 24
        compare(icon.width, 24)
        Theme.density = Theme.Touch
        icon.extent = 0
        compare(icon.width, 18)
        Theme.density = -1
    }

    function test_unknown_icon_draws_nothing() {
        const icon = createTemporaryObject(iconComponent, host, { name: "no-such-icon" })
        verify(!icon.known)
    }

    function test_an_alias_resolves_to_its_lucide_icon() {
        Theme.iconAliases = { "fetch": "arrow-down-to-line" }
        const icon = createTemporaryObject(iconComponent, host, { name: "fetch" })
        verify(icon.known)
        compare(icon.resolvedName, "arrow-down-to-line")
        Theme.iconAliases = ({})
        verify(!icon.known)
    }
}
}
