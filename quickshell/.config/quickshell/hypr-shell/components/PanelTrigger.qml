import QtQuick
import qs.services

// Invisible hit area that opens a panel branch on hover or click.
Item {
    id: root

    property string kind: ""
    property bool clickOpens: false
    property bool vertical: false
    property string screenName: ""
    // A control-center module id; when set, the trigger opens the control center focused on it.
    property string focusId: ""
    // For kind "menu": which category of the strip's tool menus to show.
    property string menuId: ""
    readonly property bool hovered: hover.hovered
    signal clicked()

    function anchor() {
        const p = root.mapToItem(null, width / 2, height / 2)
        return vertical ? p.y : p.x
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: {
            if (root.kind === "" || root.clickOpens) return
            if (hovered) {
                if (root.focusId !== "") PanelState.hoverOpenControl(root.focusId, root.anchor(), root.screenName)
                else PanelState.hoverOpen(root.kind, root.anchor(), root.screenName, root.kind === "menu" ? 1 : 0, root.menuId)
            } else {
                PanelState.hoverCancel(root.kind)
            }
        }
    }

    TapHandler {
        onTapped: {
            if (root.kind !== "" && root.clickOpens) {
                if (root.focusId !== "") PanelState.toggleControl(root.focusId, root.anchor(), root.screenName)
                else {
                    if (root.menuId !== "") PanelState.menuId = root.menuId
                    PanelState.toggle(root.kind, root.anchor(), root.screenName)
                }
            }
            root.clicked()
        }
    }
}
