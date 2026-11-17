import QtQuick
import qs.theme
import qs.services
import qs.components

// Who is logged in, shown at the right end of the tab strip.
Row {
    id: root

    spacing: 8

    onVisibleChanged: if (visible) SysInfo.refresh()

    Cover {
        anchors.verticalCenter: parent.verticalCenter
        width: 24; height: 24
        source: SysInfo.avatar
        fallback: SysInfo.user.charAt(0).toUpperCase()
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: SysInfo.user
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
    }
}
