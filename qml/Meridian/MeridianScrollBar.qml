import QtQuick
import QtQuick.Templates as T

// Meridian's scrollbar (Flutter: MeridianScrollbarThumb, MeridianScrollbar):
// a pill thumb in `line-strong` that thickens and darkens to `control-edge`
// while the pointer is over it or drags it. It fades in while the view
// scrolls and fades out `fadeDelay` ms after it stops.
//
// Attach it like any scroll bar:
//     ListView { ScrollBar.vertical: MeridianScrollBar { } }
//
// `visibility` picks when the thumb shows: only while the view scrolls (the
// default, as MeridianScrollBehavior on desktop), also while the pointer is
// over the view (bind `viewHovered`), or always. The bar takes pointer
// input only while its thumb shows, so controls at the edge of the view
// keep their clicks.
T.ScrollBar {
    id: root

    enum Visibility { Always, Hover, Scrolling }
    property int visibility: MeridianScrollBar.Scrolling
    /// For `Hover`: whether the pointer is over the scrolled view.
    property bool viewHovered: false

    // Named platform timings, not tokens (scrollbar.dart): the thumb fade and
    // the wait before it fades after scrolling stops.
    readonly property int fadeDuration: Motion.fade(300)
    readonly property int fadeDelay: 600

    /// The view has more than it shows.
    readonly property bool needed: size < 1
    readonly property bool emphasised: pressed || (hovered && thumbOpacity > 0)
    /// The view scrolled within the last moment. `active` only follows
    /// flicks and drags; this also catches wheel and keyboard scrolling that
    /// animates the view's content position.
    readonly property bool scrolling: settleTimer.running
    readonly property bool shown: needed
        && (active || scrolling || emphasised
            || visibility === MeridianScrollBar.Always
            || (visibility === MeridianScrollBar.Hover && viewHovered))
    /// 0 hidden, 1 fully shown.
    property real thumbOpacity: 0
    readonly property real thickness: emphasised ? Metrics.scrollbarThicknessHover
                                                 : Metrics.scrollbarThickness

    implicitWidth: horizontal ? 0 : Metrics.scrollbarThicknessHover + 2 * Metrics.scrollbarMargin
    implicitHeight: horizontal ? Metrics.scrollbarThicknessHover + 2 * Metrics.scrollbarMargin : 0
    padding: Metrics.scrollbarMargin
    minimumSize: horizontal ? Metrics.scrollbarMinLength / Math.max(1, width)
                            : Metrics.scrollbarMinLength / Math.max(1, height)
    interactive: thumbOpacity > 0
    hoverEnabled: true

    // A position change at an unchanged size is a scroll; a size change is
    // content that grew or shrank, which does not reveal the thumb.
    property real _lastSize: size
    onPositionChanged: {
        if (size === _lastSize)
            settleTimer.restart()
        _lastSize = size
    }
    onSizeChanged: _lastSize = size
    Timer {
        id: settleTimer
        // Long enough for the fade-in to finish after a single step.
        interval: Math.max(Motion.overlay, root.fadeDuration)
    }

    states: State {
        name: "shown"
        when: root.shown
        PropertyChanges { root.thumbOpacity: 1 }
    }
    transitions: [
        Transition {
            to: "shown"
            NumberAnimation { property: "thumbOpacity"; duration: root.fadeDuration }
        },
        Transition {
            from: "shown"
            SequentialAnimation {
                PauseAnimation { duration: root.fadeDelay }
                NumberAnimation { property: "thumbOpacity"; duration: root.fadeDuration }
            }
        }
    ]

    contentItem: Item {
        implicitWidth: root.horizontal ? Metrics.scrollbarMinLength : Metrics.scrollbarThicknessHover
        implicitHeight: root.horizontal ? Metrics.scrollbarThicknessHover : Metrics.scrollbarMinLength
        opacity: root.thumbOpacity
        visible: root.needed && opacity > 0

        Rectangle {
            objectName: "scrollBarThumb"
            // The thumb keeps to the view's edge and thickens inward.
            x: root.horizontal ? 0 : parent.width - width
            y: root.horizontal ? parent.height - height : 0
            width: root.horizontal ? parent.width : thickness
            height: root.horizontal ? thickness : parent.height
            radius: Theme.radius.pill
            color: root.emphasised ? Theme.colors.controlEdge : Theme.colors.lineStrong
            property real thickness: root.thickness
            Behavior on thickness { NumberAnimation { duration: Motion.overlay } }
            Behavior on color { ColorAnimation { duration: Motion.overlay } }
        }
    }
}
