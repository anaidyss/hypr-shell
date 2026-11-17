import QtQuick
import Quickshell.Networking
import qs.theme

SettingsListRow {
    id: root

    required property var network
    property bool askPassword: false
    property string error: ""

    readonly property bool secured: network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe
    readonly property bool connecting: network.state === ConnectionState.Connecting

    title: network.name
    active: network.connected
    subtitle: {
        if (error !== "") return error
        if (connecting) return "Connecting…"
        const parts = []
        if (network.connected) parts.push("Connected")
        else if (network.known) parts.push("Saved")
        parts.push(secured ? "Secured" : "Open")
        parts.push(Math.round(network.signalStrength * 100) + " %")
        return parts.join("  ·  ")
    }

    Connections {
        target: root.network
        function onConnectionFailed(reason) {
            root.error = reason === ConnectionFailReason.NoSecrets ? "Wrong password" : "Could not connect"
            root.askPassword = root.secured
        }
        function onConnectedChanged() { if (root.network.connected) { root.error = ""; root.askPassword = false } }
    }

    SettingsButton {
        visible: !root.network.connected && !root.connecting
        text: "Connect"
        primary: true
        onClicked: {
            root.error = ""
            if (!root.network.known && root.secured) root.askPassword = !root.askPassword
            else root.network.connect()
        }
    }
    SettingsButton {
        visible: root.network.connected || root.connecting
        text: "Disconnect"
        onClicked: root.network.disconnect()
    }
    SettingsButton {
        visible: root.network.known
        text: "Forget"
        danger: true
        onClicked: root.network.forget()
    }

    extra: [
        Item {
            width: root.width
            height: root.askPassword ? 46 : 0
            visible: height > 0
            clip: true
            Behavior on height { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }

            Rectangle {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                height: 34
                radius: Theme.radiusSm
                color: Theme.tile
                border.width: 1
                border.color: pass.activeFocus ? Qt.alpha(Theme.accent, 0.6) : Theme.border

                TextInput {
                    id: pass
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.text
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentText
                    font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                    onVisibleChanged: if (visible && root.askPassword) forceActiveFocus()
                    onAccepted: {
                        if (text === "") return
                        root.error = ""
                        root.network.connectWithPsk(text)
                        text = ""
                        root.askPassword = false
                    }
                }

                Text {
                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    visible: pass.text === ""
                    text: "Password, then Enter"
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                }
            }
        }
    ]
}
