import QtQuick
import qs.theme
import qs.services
import qs.components

// One option of a strip category flyout (see BranchMenu): a rich row, the big first tile or a small tile.
// It lifts and fades in by its place in the flyout, so a new category appears as a ripple instead of a cut.
Item {
    id: root

    required property var opt
    // Place in the flyout, which sets the delay of the entrance.
    required property int order
    // "row" | "hero" | "tile"
    property string variant: "row"

    readonly property string state: RailMenus.stateOf(opt.kind)
    readonly property bool on: RailMenus.kindActive(opt.kind)
    readonly property bool live: on || state === "On"

    opacity: 0
    transform: Translate { id: lift; y: 12 }

    ParallelAnimation {
        id: enter
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: Theme.durNormal; easing.type: Theme.easingCalm }
        NumberAnimation { target: lift; property: "y"; to: 0; duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot }
    }
    Timer { id: delay; interval: root.order * 55; onTriggered: enter.start() }
    Component.onCompleted: delay.start()

    Surface {
        anchors.fill: parent
        radius: Theme.radiusLg
        color: tap.pressed ? Theme.panelHigh : (hover.hovered ? Theme.panelPill : Theme.panelRaised)
        borderWidth: 0
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    // The icon sits on a small rounded plate that lights up under the pointer.
    Surface {
        id: plate
        visible: root.variant !== "tile"
        x: Theme.padTile
        anchors.verticalCenter: parent.verticalCenter
        width: root.variant === "hero" ? 48 : 32
        height: width
        radius: Theme.radiusSm
        color: hover.hovered ? Theme.panelHigh : Theme.panelPill
        borderWidth: 0
        Behavior on color { ColorAnimation { duration: Theme.durFast } }

        PanelIcon {
            anchors.centerIn: parent
            name: root.opt.icon
            size: root.variant === "hero" ? 24 : 18
            color: root.live ? Theme.accent : Theme.text
        }
    }

    // Row and hero: name, a line of what it does, and the live value (or a chevron) at the right.
    Item {
        visible: root.variant !== "tile"
        x: plate.x + plate.width + Theme.padTile
        width: parent.width - x - Theme.padTile - (stateText.visible ? stateText.width + 8 : 16 + 8)
        height: parent.height

        Text {
            id: name
            y: parent.height / 2 - (name.height + hint.height + 2) / 2
            width: parent.width
            text: root.opt.label
            color: Theme.text
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: root.variant === "hero" ? 18 : 14; weight: Theme.wBold }
        }
        Text {
            id: hint
            y: name.y + name.height + 2
            width: parent.width
            text: root.opt.hint
            color: Theme.textDim
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
    }

    Text {
        id: stateText
        visible: root.variant !== "tile" && root.state !== ""
        anchors { right: parent.right; rightMargin: Theme.padTile; verticalCenter: parent.verticalCenter }
        text: root.state
        color: root.live ? Theme.accent : Theme.textDim
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
    }
    PanelIcon {
        visible: root.variant !== "tile" && root.state === ""
        anchors { right: parent.right; rightMargin: Theme.padTile; verticalCenter: parent.verticalCenter }
        name: "chevronRight"
        size: 16
        color: hover.hovered ? Theme.text : Theme.textDim
    }

    // Tile: icon over a short name, a live dot in the corner.
    PanelIcon {
        visible: root.variant === "tile"
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 12 }
        name: root.opt.icon
        size: 24
        color: root.live ? Theme.accent : (hover.hovered ? Theme.text : Theme.textDim)
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }
    Text {
        visible: root.variant === "tile"
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 12 }
        width: parent.width - 2 * Theme.padTile
        horizontalAlignment: Text.AlignHCenter
        text: root.opt.short || root.opt.label
        color: hover.hovered ? Theme.text : Theme.textDim
        elide: Text.ElideRight
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
    }
    Rectangle {
        visible: root.variant === "tile" && root.live
        x: parent.width - width - 8
        y: 8
        width: 8; height: 8; radius: 4
        color: Theme.accent
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; onTapped: PanelState.openOption(root.opt.kind) }
}
