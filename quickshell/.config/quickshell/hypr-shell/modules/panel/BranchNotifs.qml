import QtQuick
import qs.theme
import qs.services
import qs.components

// Notification center: hangs from the right frame band at the top corner. Everything that arrived and is still
// around, newest first; a click opens the sender, the cross removes one, "Clear" removes all.
Item {
    id: root

    readonly property real pad: Theme.branchPad
    readonly property real headH: 36
    readonly property real listH: 440

    implicitWidth: 380
    implicitHeight: pad + headH + Theme.gapTile + listH + pad

    // Refreshes the "5 min ago" labels while the center is open.
    property real now: Date.now()
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.now = Date.now() }
    Component.onCompleted: now = Date.now()

    function ago(t) {
        const s = Math.max(0, Math.round((root.now - t) / 1000))
        if (s < 60) return "now"
        if (s < 3600) return Math.floor(s / 60) + " min ago"
        if (s < 86400) return Math.floor(s / 3600) + " h ago"
        return Qt.formatDateTime(new Date(t), "d MMM")
    }

    // Header: title with the count, do-not-disturb and clear.
    Item {
        id: head
        x: root.pad + 4
        y: root.pad
        width: root.width - 2 * root.pad - 4
        height: root.headH

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Notifications"
                color: Theme.text
                font { family: Theme.fontUi; pixelSize: 16; weight: Theme.wHeavy }
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: Toasts.count > 0
                width: Math.max(height, countText.implicitWidth + 12)
                height: 20
                radius: height / 2
                color: Theme.accentContainer
                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: Toasts.count
                    color: Theme.text
                    font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wStrong }
                }
            }
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 4

            HeadButton {
                icon: Toasts.dnd ? "bellOff" : "bell"
                active: Toasts.dnd
                onClicked: Toasts.dnd = !Toasts.dnd
            }
            HeadButton {
                visible: Toasts.count > 0
                label: "Clear"
                onClicked: Toasts.clearAll()
            }
        }
    }

    ListView {
        id: list
        x: root.pad
        y: root.pad + root.headH + Theme.gapTile
        width: root.width - 2 * root.pad
        height: root.listH
        clip: true
        spacing: Theme.gapTile
        boundsBehavior: Flickable.StopAtBounds
        model: Toasts.history

        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durNormal; easing.type: Theme.easingCalm }
            NumberAnimation { property: "x"; from: 24; duration: Theme.durOpen; easing.type: Theme.easing; easing.overshoot: Theme.overshoot }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot }
        }

        delegate: Surface {
            id: card
            required property var modelData
            readonly property bool critical: modelData.critical

            width: list.width
            height: 84
            radius: Theme.radiusLg
            borderWidth: 0
            color: hCard.hovered ? Theme.panelHigh : (critical ? Qt.alpha(Theme.danger, 0.16) : Theme.panelRaised)
            Behavior on color { ColorAnimation { duration: Theme.durFast } }

            HoverHandler { id: hCard; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Toasts.activate(card.modelData.id) }

            Rectangle {
                id: badge
                x: 14
                y: 14
                width: 36
                height: 36
                radius: Theme.radiusSm
                color: Qt.alpha(card.critical ? Theme.danger : Theme.accent, 0.18)
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: card.modelData.image !== "" ? 0 : 6
                    source: card.modelData.image !== "" ? card.modelData.image : card.modelData.icon
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 72
                    sourceSize.height: 72
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: card.modelData.image === "" && card.modelData.icon === ""
                    text: (card.modelData.app || "?").charAt(0).toUpperCase()
                    color: card.critical ? Theme.danger : Theme.accent
                    font { family: Theme.fontUi; pixelSize: 16; weight: Theme.wStrong }
                }
            }

            Column {
                anchors { left: badge.right; leftMargin: 12; right: parent.right; rightMargin: 16; top: parent.top; topMargin: 12 }
                spacing: 2

                Item {
                    width: parent.width
                    height: 16
                    Text {
                        anchors { left: parent.left; right: when.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        text: card.modelData.app
                        color: Theme.textDim
                        elide: Text.ElideRight
                        font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
                    }
                    Text {
                        id: when
                        anchors { right: parent.right; rightMargin: hCard.hovered ? 24 : 0; verticalCenter: parent.verticalCenter }
                        text: root.ago(card.modelData.time)
                        color: Theme.textDim
                        font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
                    }
                }
                Text {
                    width: parent.width
                    text: card.modelData.summary
                    color: Theme.text
                    elide: Text.ElideRight
                    font { family: Theme.fontUi; pixelSize: 13; weight: Theme.wStrong }
                }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: card.modelData.body.replace(/\n/g, " ")
                    color: Theme.textDim
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                }
            }

            // Remove: appears on hover in the top right corner.
            Rectangle {
                x: parent.width - width - 10
                y: 10
                width: 24
                height: 24
                radius: 12
                color: hClose.hovered ? Theme.panelPill : "transparent"
                opacity: hCard.hovered ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
                PanelIcon { anchors.centerIn: parent; name: "close"; size: 14; color: hClose.hovered ? Theme.text : Theme.textDim }
                HoverHandler { id: hClose }
                TapHandler { onTapped: Toasts.remove(card.modelData.id) }
            }
        }
    }

    // Empty state.
    Column {
        anchors.centerIn: list
        visible: Toasts.count === 0
        spacing: 6

        PanelIcon { anchors.horizontalCenter: parent.horizontalCenter; name: Toasts.dnd ? "bellOff" : "bell"; size: 30; color: Theme.textOff }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No notifications"
            color: Theme.text
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Toasts.dnd ? "Do not disturb is on" : "You're all caught up"
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
    }

    // A capsule button of the header: an icon or a short label.
    component HeadButton: Rectangle {
        id: btn
        property string icon: ""
        property string label: ""
        property bool active: false
        signal clicked()

        width: label !== "" ? labelText.implicitWidth + 24 : 32
        height: 32
        radius: height / 2
        color: active ? Theme.accentContainer : (hBtn.hovered ? Theme.panelHigh : Theme.panelPill)
        Behavior on color { ColorAnimation { duration: Theme.durFast } }

        PanelIcon { anchors.centerIn: parent; visible: btn.icon !== ""; name: btn.icon; size: 16; color: btn.active ? Theme.text : Theme.textDim }
        Text {
            id: labelText
            anchors.centerIn: parent
            visible: btn.label !== ""
            text: btn.label
            color: Theme.text
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
        HoverHandler { id: hBtn; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: btn.clicked() }
    }
}
