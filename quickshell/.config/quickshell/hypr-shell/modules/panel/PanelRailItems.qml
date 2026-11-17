import QtQuick
import qs.theme
import qs.services
import qs.components

// Contents of the left panel. Framed: grouped controls on a thin strip. Floating: a short card.
Item {
    id: root

    property string screenName: ""
    property bool flush: false

    readonly property real btn: flush ? 32 : 40
    readonly property real ico: flush ? 18 : 20
    readonly property real railInset: Theme.railEndInset + Theme.cfg.panel.cornerInset

    // Floating card
    Column {
        visible: !root.flush
        anchors { top: parent.top; topMargin: 12; horizontalCenter: parent.horizontalCenter }
        spacing: 4

        PanelButton { icon: "note"; kind: "notes"; screenName: root.screenName }
        PanelButton {
            icon: Toasts.dnd ? "bellOff" : "bell"
            clickOpens: false
            highlight: Toasts.dnd
            onClicked: Toasts.dnd = !Toasts.dnd
        }
        PanelButton { icon: "image"; clickOpens: false; onClicked: SettingsState.show("wallpaper") }
    }

    Column {
        visible: !root.flush
        anchors { bottom: parent.bottom; bottomMargin: 12; horizontalCenter: parent.horizontalCenter }
        spacing: 4

        PanelButton { icon: "gear"; clickOpens: false; onClicked: SettingsState.show("panel") }
        PanelButton { icon: "power"; kind: "session"; screenName: root.screenName }
    }

    // Screen frame strip: three zones built from RailLayout (top, centered middle, bottom), edited in BranchRailedit.
    // OledCare dims the whole strip when idle and drifts the zones by a pixel or two.
    opacity: OledCare.stripOpacity

    Column {
        visible: root.flush
        anchors { top: parent.top; topMargin: railInset; horizontalCenter: parent.horizontalCenter }
        spacing: 8
        transform: Translate { x: OledCare.shiftX; y: OledCare.shiftY }

        Repeater {
            model: RailLayout.visibleIds("top")
            RailItem { required property string modelData; itemId: modelData; screenName: root.screenName }
        }
    }

    Column {
        visible: root.flush
        anchors.centerIn: parent
        spacing: 8
        transform: Translate { x: OledCare.shiftX; y: OledCare.shiftY }

        Repeater {
            model: RailLayout.visibleIds("middle")
            RailItem { required property string modelData; itemId: modelData; screenName: root.screenName }
        }
    }

    Column {
        visible: root.flush
        anchors { bottom: parent.bottom; bottomMargin: railInset; horizontalCenter: parent.horizontalCenter }
        spacing: 8
        transform: Translate { x: OledCare.shiftX; y: OledCare.shiftY }

        Repeater {
            model: RailLayout.visibleIds("bottom")
            RailItem { required property string modelData; itemId: modelData; screenName: root.screenName }
        }
    }
}
