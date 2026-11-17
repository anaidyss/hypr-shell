import QtQuick
import qs.theme
import qs.services
import qs.components

// One item of the left strip, chosen by id (see RailLayout.catalog). Items that have nothing to show report
// `wanted: false` and take no room.
Item {
    id: root

    required property string itemId
    property string screenName: ""

    readonly property bool wanted: !loader.item || loader.item.wanted === undefined || loader.item.wanted

    width: 36
    height: wanted && loader.item ? loader.item.height : 0
    visible: wanted

    Loader {
        id: loader
        anchors.horizontalCenter: parent.horizontalCenter
        sourceComponent: root.parts[root.itemId] || null
    }

    readonly property var parts: ({
        distro: distro, term: term, running: running, workspaces: workspaces, tabs: tabs, clock: clock,
        controls: controls, vpn: vpn, status: status, power: power
    })

    Component { id: distro; PanelDistroButton {} }
    Component { id: running; PanelRunningApps {} }
    Component { id: tabs; PanelMenuTabs { screenName: root.screenName } }

    Component {
        id: term
        PanelGroup {
            tone: Theme.secondaryContainer
            PanelTermButton { size: 32; iconSize: 18; vertical: true; screenName: root.screenName }
        }
    }

    Component {
        id: workspaces
        PanelGroup {
            tone: Theme.accentContainer
            padding: 9
            PanelWorkspaces { vertical: true }
        }
    }

    Component {
        id: clock
        PanelGroup {
            tone: Theme.secondaryContainer
            padding: 4
            PanelClockStack { screenName: root.screenName }
        }
    }

    Component {
        id: controls
        PanelGroup {
            tone: Theme.tertiaryContainer
            PanelButton { width: 32; height: 32; iconSize: 18; icon: "note"; kind: "notes"; screenName: root.screenName }
            PanelButton {
                width: 32; height: 32; iconSize: 18
                icon: Toasts.dnd ? "bellOff" : "bell"
                clickOpens: false
                highlight: Toasts.dnd
                onClicked: Toasts.dnd = !Toasts.dnd
            }
            PanelButton {
                width: 32; height: 32; iconSize: 18
                icon: "usb"
                kind: "drives"
                screenName: root.screenName
                visible: Drives.hasDrives || Drives.writing
                highlight: Drives.pulse || Drives.writing
            }
            PanelButton { width: 32; height: 32; iconSize: 18; icon: "image"; clickOpens: false; onClicked: SettingsState.show("wallpaper") }
            PanelButton { width: 32; height: 32; iconSize: 18; icon: "gear"; clickOpens: false; onClicked: SettingsState.show("panel") }
        }
    }

    Component {
        id: vpn
        PanelGroup {
            tone: Theme.accentContainer
            padding: 4
            PanelVpn { screenName: root.screenName }
        }
    }

    Component {
        id: status
        PanelGroup {
            tone: Theme.secondaryContainer
            padding: 5
            spacing: 4
            PanelLayout {}
            PanelBattery { screenName: root.screenName }
        }
    }

    Component {
        id: power
        PanelButton {
            width: 32; height: 32; iconSize: 18
            icon: "power"; kind: "session"; screenName: root.screenName
        }
    }
}
