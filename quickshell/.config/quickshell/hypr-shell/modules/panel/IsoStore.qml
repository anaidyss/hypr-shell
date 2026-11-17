import QtQuick
import qs.theme
import qs.services
import qs.components

// Images on the mirror: distributions with their newest version, then the images of one distribution (newest first)
// with a download button. Downloads queue in IsoMirror and land in the ISO folder; the library header shows them.
Item {
    id: root

    signal done()
    property string pick: ""
    property string query: ""

    readonly property var picked: pick !== "" ? IsoLibrary.distro(pick) : null
    readonly property var groups: {
        const q = query.toLowerCase().trim()
        return q === "" ? IsoMirror.groups : IsoMirror.groups.filter(g => g.name.toLowerCase().indexOf(q) >= 0)
    }
    readonly property var images: pick !== "" ? IsoMirror.variants(pick) : []

    // The name the file gets in the library (same rule as hs-flash download: a version is added when missing).
    function target(e) {
        if (e.version === "" || e.file.indexOf(e.version) >= 0) return e.file
        const m = /\.(iso|img)(\.\w+)?$/i.exec(e.file)
        return e.file.slice(0, m.index) + "-" + e.version.replace(/ /g, "-") + e.file.slice(m.index)
    }
    function have(e) { const t = target(e); return IsoLibrary.items.some(it => it.file === t) }

    function back() {
        search.release()
        if (pick !== "") pick = ""
        else done()
    }

    Item {
        id: head
        width: parent.width
        height: 32

        IconButton { id: backBtn; anchors.verticalCenter: parent.verticalCenter; icon: "chevronLeft"; onClicked: root.back() }
        FieldInput {
            id: search
            visible: root.pick === ""
            anchors { left: backBtn.right; leftMargin: Theme.gapTile; right: refresh.left; rightMargin: Theme.gapTile }
            radius: Theme.radiusMd
            placeholder: "Search " + IsoMirror.groups.length + " distributions on the mirror"
            onTextChanged: root.query = text
            onAccepted: if (root.groups.length > 0) root.pick = root.groups[0].id
            onEscaped: root.back()
        }
        Row {
            visible: root.pick !== ""
            anchors { left: backBtn.right; leftMargin: Theme.gapTile; verticalCenter: parent.verticalCenter }
            spacing: 8
            DistroLogo {
                anchors.verticalCenter: parent.verticalCenter
                path: root.picked ? root.picked.path : ""
                name: root.picked ? root.picked.name : ""
                size: 18
                color: Theme.text
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.picked ? root.picked.name : ""
                color: Theme.text
                font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
            }
        }
        IconButton {
            id: refresh
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            icon: "restart"
            onClicked: IsoMirror.load(true)
        }
    }

    ListView {
        id: list
        anchors { top: head.bottom; topMargin: Theme.gapTile; left: parent.left; right: parent.right; bottom: parent.bottom }
        clip: true
        spacing: 4
        boundsBehavior: Flickable.StopAtBounds
        model: root.pick === "" ? root.groups : root.images

        delegate: Item {
            id: row
            required property var modelData
            readonly property bool isGroup: root.pick === ""
            readonly property bool inLib: !isGroup && root.have(modelData)
            readonly property bool waiting: !isGroup && IsoMirror.queued(modelData)
            readonly property bool now: waiting && IsoMirror.current !== null && IsoMirror.current.path === modelData.path

            width: list.width
            height: 44

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusMd
                color: rowArea.containsMouse ? Theme.panelHigh : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
            }
            MouseArea {
                id: rowArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: row.isGroup ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (row.isGroup) { search.release(); root.pick = row.modelData.id }
            }

            DistroLogo {
                visible: row.isGroup
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                path: row.isGroup ? row.modelData.logo : ""
                name: row.isGroup ? row.modelData.name : ""
                size: 20
                color: Theme.text
            }
            Column {
                anchors { left: parent.left; leftMargin: row.isGroup ? 40 : 8; right: tail.left; rightMargin: Theme.gapTile
                    verticalCenter: parent.verticalCenter }
                spacing: 2
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: row.isGroup ? row.modelData.name : IsoMirror.variantName(row.modelData)
                    color: Theme.text
                    font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: row.isGroup ? (row.modelData.latest !== "" ? row.modelData.latest : "Rolling")
                        : (row.modelData.version || "Rolling") + (row.modelData.pre ? " · pre-release" : "") + " · " + row.modelData.file
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                }
            }
            Item {
                id: tail
                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                width: row.isGroup || row.inLib || row.waiting ? state.implicitWidth : 30
                height: 30
                Text {
                    id: state
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    visible: row.isGroup || row.inLib || row.waiting
                    text: row.isGroup ? row.modelData.count + (row.modelData.count === 1 ? " image" : " images")
                        : row.inLib ? "In library"
                        : row.now ? (IsoMirror.dlTotal > 0 ? Math.floor(IsoMirror.dlRatio * 100) + "%" : "Starting")
                        : "Queued"
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                }
                IconButton {
                    visible: !row.isGroup && !row.inLib && !row.waiting
                    anchors.right: parent.right
                    icon: "download"
                    onClicked: IsoMirror.download(row.modelData)
                }
            }
        }
    }

    Text {
        anchors.centerIn: list
        width: list.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        visible: text !== ""
        color: IsoMirror.error !== "" ? Theme.danger : Theme.textDim
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
        text: !IsoMirror.loaded ? "Loading the mirror list…"
            : IsoMirror.error !== "" ? IsoMirror.error
            : list.count === 0 ? "Nothing found" : ""
    }
}
