import QtQuick
import Meridian

Window {
    width: 1280
    height: 900
    minimumWidth: 360
    minimumHeight: 480
    visible: true
    title: "Meridian QML gallery"
    color: Theme.colors.ground

    Gallery {
        anchors.fill: parent
    }
}
