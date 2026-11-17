import QtQuick
import qs.theme
import qs.services
import qs.components

// Rename an image: pick its distribution from the list (sets the logo and the default name), optionally a name
// of your own and the version. Empty fields fall back to what was read from the image; "Auto" forgets the edits.
Item {
    id: root

    required property var item
    signal done()

    property string pick: item.distro
    property string query: ""
    readonly property var picked: IsoLibrary.distro(pick)
    readonly property var shown: {
        const q = query.toLowerCase().trim()
        return q === "" ? IsoLibrary.distros : IsoLibrary.distros.filter(d => d.name.toLowerCase().indexOf(q) >= 0 || d.id.indexOf(q) >= 0)
    }

    Component.onCompleted: {
        nameField.text = item.edited && item.name !== item.distroName ? item.name : ""
        versionField.text = item.version !== item.autoVersion ? item.version : ""
    }

    function save() {
        nameField.release(); versionField.release(); search.release()
        const name = nameField.text.trim()
        IsoLibrary.setOverride(item.file, pick === item.autoDistro ? "" : pick,
            picked && name === picked.name ? "" : name, versionField.text.trim())
        done()
    }
    function cancel() {
        nameField.release(); versionField.release(); search.release()
        done()
    }

    FieldInput {
        id: search
        width: parent.width
        radius: Theme.radiusMd
        placeholder: "Search " + IsoLibrary.distros.length + " distributions"
        onTextChanged: root.query = text
        onAccepted: if (root.shown.length > 0) root.pick = root.shown[0].id
        onEscaped: root.cancel()
    }

    GridView {
        id: grid
        anchors { top: search.bottom; topMargin: Theme.gapTile; left: parent.left; right: parent.right
            bottom: fields.top; bottomMargin: Theme.gapTile }
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        cellWidth: Math.floor(width / 4)
        cellHeight: 56
        model: root.shown
        Component.onCompleted: {
            const i = root.shown.findIndex(d => d.id === root.pick)
            if (i >= 0) positionViewAtIndex(i, GridView.Center)
        }

        delegate: Item {
            id: cell
            required property var modelData
            readonly property bool on: modelData.id === root.pick
            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors { fill: parent; margins: 4 }
                radius: Theme.radiusMd
                color: cell.on ? Theme.accentContainer : cellArea.containsMouse ? Theme.panelHigh : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
            }
            DistroLogo {
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 8 }
                path: cell.modelData.path
                name: cell.modelData.name
                size: 20
                color: cell.on ? Theme.text : Theme.textDim
            }
            Text {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 8; margins: 4 }
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: cell.modelData.name
                color: cell.on ? Theme.text : Theme.textDim
                font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
            }
            MouseArea {
                id: cellArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.pick = cell.modelData.id
                onDoubleClicked: { root.pick = cell.modelData.id; root.save() }
            }
        }
    }

    Row {
        id: fields
        anchors { left: parent.left; right: parent.right; bottom: buttons.top; bottomMargin: Theme.gapTile }
        spacing: Theme.gapTile
        FieldInput {
            id: nameField
            width: parent.width - Theme.gapTile - 120
            radius: Theme.radiusMd
            placeholder: root.picked ? root.picked.name : "Name"
            onAccepted: root.save()
            onEscaped: root.cancel()
        }
        FieldInput {
            id: versionField
            width: 120
            radius: Theme.radiusMd
            placeholder: root.item.autoVersion !== "" ? root.item.autoVersion : "Version"
            maximumLength: 24
            onAccepted: root.save()
            onEscaped: root.cancel()
        }
    }

    Item {
        id: buttons
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 32

        Text {
            anchors { left: parent.left; right: btnRow.left; rightMargin: Theme.gapTile; verticalCenter: parent.verticalCenter }
            elide: Text.ElideRight
            text: (root.item.dated ? "Built " : "File from ") + IsoLibrary.niceDate(root.item.created)
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
        Row {
            id: btnRow
            anchors.right: parent.right
            spacing: Theme.gapTile
            ActionButton {
                visible: root.item.edited
                text: "Auto"
                icon: "restart"
                onClicked: { IsoLibrary.resetOverride(root.item.file); root.done() }
            }
            ActionButton { text: "Cancel"; onClicked: root.cancel() }
            ActionButton { text: "Save"; primary: true; onClicked: root.save() }
        }
    }
}
