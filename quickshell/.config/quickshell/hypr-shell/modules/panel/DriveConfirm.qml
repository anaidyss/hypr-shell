import QtQuick
import qs.theme
import qs.services
import qs.components

// The confirmation before anything that rewrites a drive (rule 7.6): what it is about, what is lost, one danger
// button. Writing an image can also switch the read-back check here.
Item {
    id: root

    property string logo: ""
    property string logoName: ""
    property string icon: "usb"
    property string heading
    property string detail
    property string actionText: "Erase"
    property string actionIcon: "eraser"
    property bool showVerify: false
    signal accepted()
    signal cancelled()

    Rectangle {
        id: badge
        anchors.horizontalCenter: parent.horizontalCenter
        y: 4
        width: 64
        height: 64
        radius: Theme.radiusMd
        color: Theme.panelPill
        DistroLogo {
            anchors.centerIn: parent
            visible: root.logo !== ""
            path: root.logo
            name: root.logoName
            size: 30
            color: Theme.text
        }
        PanelIcon {
            anchors.centerIn: parent
            visible: root.logo === ""
            name: root.icon
            size: 30
            color: Theme.text
        }
    }

    Text {
        id: head
        anchors { top: badge.bottom; topMargin: Theme.padTile; horizontalCenter: parent.horizontalCenter }
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.heading
        color: Theme.danger
        font { family: Theme.fontUi; pixelSize: 18; weight: Theme.wHeavy }
    }

    Text {
        anchors { top: head.bottom; topMargin: 4; horizontalCenter: parent.horizontalCenter }
        width: parent.width - 2 * Theme.padTile
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        maximumLineCount: 5
        elide: Text.ElideRight
        text: root.detail
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
    }

    Row {
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
        spacing: Theme.gapTile

        Item {
            visible: root.showVerify
            width: verifyRow.implicitWidth
            height: 32
            Row {
                id: verifyRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Switch {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: Theme.cfg.drives.verify
                    onToggled: v => Theme.set("drives", "verify", v)
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    rightPadding: 8
                    text: "Verify"
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                }
            }
        }
        ActionButton { text: "Cancel"; onClicked: root.cancelled() }
        ActionButton {
            text: root.actionText
            icon: root.actionIcon
            danger: true
            onClicked: root.accepted()
        }
    }
}
