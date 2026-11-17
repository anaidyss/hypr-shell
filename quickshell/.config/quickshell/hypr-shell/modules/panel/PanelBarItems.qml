import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.components

// Contents of the floating bottom bar (used when the screen frame is off).
Item {
    id: root

    property string screenName: ""

    SystemClock { id: clock; precision: SystemClock.Minutes }

    PanelTermButton {
        id: termButton
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        size: 40
        iconSize: 20
        screenName: root.screenName
    }

    PanelDock {
        id: dock
        anchors { left: termButton.right; leftMargin: 8; verticalCenter: parent.verticalCenter }
    }

    PanelWorkspaces {
        id: workspaces
        anchors { left: dock.right; leftMargin: 14; verticalCenter: parent.verticalCenter }
    }

    Item {
        anchors.centerIn: parent
        width: clockText.width
        height: 32

        Text {
            id: clockText
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(clock.date, "HH:mm")
            color: PanelState.isOpen("clock") ? Theme.accent : Theme.text
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
        }

        PanelTrigger {
            anchors { fill: parent; margins: -10 }
            kind: "clock"
            clickOpens: true
            screenName: root.screenName
        }
    }

    Item {
        anchors { right: parent.right; rightMargin: 22; verticalCenter: parent.verticalCenter }
        width: statusIcons.width
        height: 32

        PanelStatusIcons { id: statusIcons; anchors.verticalCenter: parent.verticalCenter; screenName: root.screenName }
    }
}
