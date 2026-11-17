import QtQuick
import qs.theme
import qs.services

Item {
    id: root

    implicitWidth: 400
    implicitHeight: 76

    Rectangle {
        id: icon
        anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
        width: 38; height: 38
        radius: Theme.radiusMd
        color: Qt.alpha(Toasts.critical ? Theme.danger : Theme.accent, 0.18)
        clip: true

        Image {
            anchors.fill: parent
            anchors.margins: Toasts.image !== "" ? 0 : 7
            source: Toasts.image !== "" ? Toasts.image : Toasts.icon
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 76
            sourceSize.height: 76
            visible: status === Image.Ready
        }
        Text {
            anchors.centerIn: parent
            visible: Toasts.image === "" && Toasts.icon === ""
            text: Toasts.app.charAt(0).toUpperCase()
            color: Toasts.critical ? Theme.danger : Theme.accent
            font { family: Theme.fontUi; pixelSize: 18; weight: Theme.wStrong }
        }
    }

    Column {
        anchors { left: icon.right; leftMargin: 12; right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
        spacing: 2

        Text {
            width: parent.width
            text: Toasts.app
            color: Theme.textDim
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy; letterSpacing: 1.3; capitalization: Font.AllUppercase }
        }
        Text {
            width: parent.width
            text: Toasts.summary
            color: Theme.text
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
        }
        Text {
            width: parent.width
            visible: Toasts.body !== ""
            text: Toasts.body.replace(/\n/g, " ")
            textFormat: Text.StyledText
            color: Theme.textDim
            elide: Text.ElideRight
            maximumLineCount: 1
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => mouse.button === Qt.RightButton ? Toasts.dismiss() : Toasts.invokeDefault()
    }
}
