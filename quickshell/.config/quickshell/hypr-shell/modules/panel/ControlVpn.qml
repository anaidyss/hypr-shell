import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components

// VPN page of the control center: the active node and tunnel switch on the left, node list on the right.
RowLayout {
    id: root

    property real leftW: 300

    spacing: 8

    function title(node) {
        return node ? node.who + " " + node.proto.split(" · ")[0] : ""
    }

    function duration(seconds) {
        const h = Math.floor(seconds / 3600)
        const m = Math.floor((seconds % 3600) / 60)
        return h > 0 ? h + " h " + m + " min" : (m > 0 ? m + " min" : "< 1 min")
    }

    function pingOf(tag) {
        const v = Vpn.ping[tag]
        return v ? v : null
    }

    function pingText(tag) {
        const v = pingOf(tag)
        if (!v) return "—"
        return v.ms < 0 ? "Lost" : Math.round(v.ms) + " ms"
    }

    function pingBad(tag) {
        const v = pingOf(tag)
        return v !== null && (v.ms < 0 || v.loss > 10 || v.ms > 150)
    }

    readonly property string heading: {
        if (Vpn.resetting) return "Resetting …"
        if (Vpn.busy) return Vpn.starting ? "Starting …" : "Stopping …"
        if (!Vpn.loaded) return "Loading …"
        if (!Vpn.up) return "Tunnel off"
        if (Vpn.selected === Vpn.auto && !Vpn.activeNode) return "Auto"
        return Vpn.activeNode ? title(Vpn.activeNode) : Vpn.active
    }

    ColumnLayout {
        Layout.preferredWidth: root.leftW
        Layout.maximumWidth: root.leftW
        Layout.fillHeight: true
        spacing: 8

        Block {
            tone: Theme.tertiaryContainer
            Layout.fillWidth: true
            Layout.fillHeight: true

            PanelIcon {
                name: Vpn.up ? "shieldCheck" : "shield"
                size: 30
                color: Vpn.up ? Theme.accent : Theme.textDim
            }
            Switch {
                anchors.right: parent.right
                checked: Vpn.busy ? Vpn.starting : Vpn.up
                opacity: Vpn.busy || Vpn.resetting || !Vpn.loaded ? 0.38 : 1
                onToggled: v => { if (Vpn.loaded) Vpn.setTunnel(v) }
            }
            Text {
                y: 42
                width: parent.width
                text: root.heading
                color: Vpn.up ? Theme.text : Theme.textDim
                elide: Text.ElideRight
                font { family: Theme.fontUi; pixelSize: 18; weight: Theme.wStrong }
            }
            Text {
                y: 68
                width: parent.width
                visible: Vpn.resetting || Vpn.resetResult !== "" || (Vpn.loaded && !Vpn.busy)
                text: Vpn.resetting ? Vpn.resetStep + " …"
                    : (Vpn.resetResult === "ok" ? "Restored"
                    : (Vpn.resetResult === "fail" ? "Still down · try another node"
                    : (Vpn.up ? (Vpn.pinned ? "Pinned node" : "Automatic · lowest latency") : "Traffic goes out directly")))
                color: Theme.textDim
                elide: Text.ElideRight
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }
            Text {
                y: 88
                width: parent.width
                visible: Vpn.up && Vpn.activeNode !== null
                text: Vpn.activeNode ? Vpn.activeNode.ip + ":" + Vpn.activeNode.port : ""
                color: Theme.textDim
                elide: Text.ElideRight
                font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold }
            }
            Text {
                anchors { left: parent.left; right: resetButton.left; rightMargin: 8; verticalCenter: resetButton.verticalCenter }
                visible: Vpn.up
                text: Vpn.connVpn + " tunnelled · " + Vpn.connDirect + " direct"
                color: Theme.textDim
                elide: Text.ElideRight
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }
            // Rebuilds everything the tunnel depends on, like a reboot would.
            HeroButton {
                id: resetButton
                anchors { right: parent.right; bottom: parent.bottom }
                opacity: Vpn.resetting ? 0.38 : 1
                text: Vpn.resetting ? "Resetting …" : "Reset"
                onClicked: Vpn.resetAll()
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            Stat { label: "Latency"; value: Vpn.up && Vpn.active !== "" ? root.pingText(Vpn.active) : "—" }
            Stat { label: "Uptime"; value: Vpn.up && Vpn.uptime > 0 ? root.duration(Vpn.uptime) : "—" }
            Stat { radiusBL: Theme.radiusLg; label: "Download"; value: Vpn.up ? Perf.rate(Vpn.rateDown) : "—" }
            Stat { label: "Upload"; value: Vpn.up ? Perf.rate(Vpn.rateUp) : "—" }
        }
    }

    Block {
        tone: Theme.secondaryContainer
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 24

                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "Nodes"
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                }
                HeroButton {
                    anchors.right: parent.right
                    visible: Vpn.up && Vpn.nodes.length > 0
                    opacity: Vpn.testing ? 0.38 : 1
                    text: Vpn.testing ? "Testing …" : "Test"
                    onClicked: Vpn.testAll()
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: nodeList.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                Column {
                    id: nodeList
                    width: parent.width
                    spacing: 2
                    opacity: Vpn.up ? 1 : 0.38
                    Behavior on opacity { NumberAnimation { duration: Theme.durFast } }

                    NodeRow {
                        visible: Vpn.nodes.length > 0
                        label: "Auto"
                        hint: Vpn.up && Vpn.selected === Vpn.auto && Vpn.activeNode ? "Lowest latency · now " + root.title(Vpn.activeNode) : "Lowest latency"
                        selected: Vpn.up && Vpn.selected === Vpn.auto
                        onPicked: Vpn.select(Vpn.auto)
                    }

                    Repeater {
                        model: Vpn.nodes

                        delegate: NodeRow {
                            required property var modelData

                            label: root.title(modelData)
                            hint: modelData.proto.split(" · ")[1] + " · " + modelData.ip
                            selected: Vpn.up && Vpn.selected === modelData.tag
                            live: Vpn.up && Vpn.selected === Vpn.auto && Vpn.active === modelData.tag
                            ping: root.pingText(modelData.tag)
                            pingBad: root.pingBad(modelData.tag)
                            probe: Vpn.probe[modelData.tag] !== undefined ? (Vpn.probe[modelData.tag] > 0 ? Vpn.probe[modelData.tag] + " ms" : "Failed") : ""
                            onPicked: Vpn.select(modelData.tag)
                        }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: Vpn.loaded && Vpn.nodes.length === 0
            text: "No nodes in the sing-box config"
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
        }
    }

    // A node: the name selects it; a check marks the pinned one, a dot the node Auto currently uses.
    component NodeRow: Item {
        id: row

        property string label
        property string hint
        property bool selected: false
        property bool live: false
        property string ping: ""
        property bool pingBad: false
        property string probe: ""
        signal picked

        width: parent ? parent.width : 0
        height: 44

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusSm
            color: row.selected ? Theme.panelPill : (hover.hovered && Vpn.up ? Theme.panelHigh : "transparent")
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }
        PanelIcon {
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            visible: row.selected
            name: "check"
            size: 16
            color: Theme.accent
        }
        Rectangle {
            anchors { left: parent.left; leftMargin: 17; verticalCenter: parent.verticalCenter }
            visible: row.live
            width: 6
            height: 6
            radius: 3
            color: Theme.accent
        }
        Column {
            anchors { left: parent.left; leftMargin: 40; right: figures.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: 2

            Text {
                width: parent.width
                text: row.label
                color: Theme.text
                elide: Text.ElideRight
                font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
            }
            Text {
                width: parent.width
                text: row.hint
                color: Theme.textDim
                elide: Text.ElideRight
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }
        }
        Column {
            id: figures
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            spacing: 2
            visible: row.ping !== ""

            Text {
                anchors.right: parent.right
                text: row.ping
                color: row.pingBad ? Theme.danger : Theme.text
                font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold }
            }
            Text {
                anchors.right: parent.right
                visible: row.probe !== ""
                text: row.probe
                color: Theme.textDim
                font { family: Theme.fontMono; pixelSize: 11; weight: Theme.wBold }
            }
        }
        HoverHandler { id: hover; cursorShape: Vpn.up ? Qt.PointingHandCursor : Qt.ArrowCursor }
        TapHandler { enabled: Vpn.up; onTapped: row.picked() }
    }
}
