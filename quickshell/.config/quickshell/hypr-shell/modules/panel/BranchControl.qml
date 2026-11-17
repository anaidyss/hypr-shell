import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import qs.theme
import qs.services
import qs.components

// Control center hanging from the right frame band. A tab strip (Wi-Fi, Bluetooth, sound, battery, VPN)
// over one page at a time; every page is the same: a big block with live details and a row of
// figures on the left, the switch and the list of options on the right.
Item {
    id: root

    readonly property real pad: 12
    readonly property real tabsH: 40
    readonly property real pageH: 340
    readonly property real leftW: 300
    readonly property var tabIds: ["wifi", "bluetooth", "sound", "battery", "vpn"]
    readonly property int tab: Math.max(0, tabIds.indexOf(PanelState.controlFocus))

    implicitWidth: 740
    implicitHeight: pad / 2 + tabsH + 8 + pageH + pad

    readonly property var wifiDevice: {
        for (const d of Networking.devices.values) if (d.type === DeviceType.Wifi) return d
        return null
    }
    readonly property var wifiNetwork: {
        if (!wifiDevice) return null
        for (const n of wifiDevice.networks.values) if (n.connected) return n
        return null
    }
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter !== null && adapter.enabled
    readonly property var btDevice: {
        if (!adapter) return null
        for (const d of adapter.devices.values) if (d.connected) return d
        return null
    }
    readonly property int btPaired: {
        if (!adapter) return 0
        let n = 0
        for (const d of adapter.devices.values) if (d.paired) n++
        return n
    }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property int appStreams: {
        let n = 0
        for (const d of Pipewire.nodes.values) if (d.isStream && !d.isSink && d.audio) n++
        return n
    }
    readonly property var battery: UPower.displayDevice
    readonly property real level: battery.percentage > 1 ? battery.percentage / 100 : battery.percentage
    readonly property bool charging: battery.state === UPowerDeviceState.Charging

    PwObjectTracker { objects: [root.sink, root.source] }
    Binding { target: root.wifiDevice; property: "scannerEnabled"; value: root.wifiDevice !== null && Networking.wifiEnabled }
    Binding { target: ControlInfo; property: "wifiDev"; value: root.wifiDevice ? root.wifiDevice.name : "" }
    Binding { target: ControlInfo; property: "wifiWatch"; value: root.visible && root.tab === 0 }
    Binding { target: ControlInfo; property: "soundWatch"; value: root.visible && root.tab === 2 }
    Binding { target: ControlInfo; property: "batteryWatch"; value: root.visible && root.tab === 3 }
    Binding { target: Vpn; property: "watch"; value: root.visible && root.tab === 4 }

    function fmt(seconds) {
        const h = Math.floor(seconds / 3600)
        const m = Math.floor((seconds % 3600) / 60)
        return h > 0 ? h + " h " + m + " min" : m + " min"
    }

    function pct(v) { return Math.round(v * 100) + "%" }
    function mbit(v) { return v > 0 ? Math.round(v) + " Mb/s" : "—" }
    function ghz(mhz) { return mhz > 0 ? (mhz / 1000).toFixed(mhz % 100 === 0 ? 1 : 3).replace(/0+$/, "").replace(/\.$/, "") + " GHz" : "—" }
    function btType(icon) {
        if (!icon) return "Device"
        const t = icon.replace(/^audio-/, "").replace(/^input-/, "").replace(/-/g, " ")
        return t.charAt(0).toUpperCase() + t.slice(1)
    }

    DashTabs {
        x: root.pad
        y: root.pad / 2
        width: parent.width - 2 * root.pad
        height: root.tabsH
        current: root.tab
        model: [
            { label: "Wi-Fi", icon: "wifi" },
            { label: "Bluetooth", icon: "bluetooth" },
            { label: "Sound", icon: "volume" },
            { label: "Battery", icon: "battery" },
            { label: "VPN", icon: "shield" }
        ]
        onPicked: i => PanelState.controlFocus = root.tabIds[i]
    }

    Item {
        id: pages
        x: root.pad
        y: root.pad / 2 + root.tabsH + 8
        width: parent.width - 2 * root.pad
        height: root.pageH

        // ---------------------------------------------------------------- Wi-Fi
        Page {
            index: 0

            RowLayout {
                anchors.fill: parent
                spacing: 8

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
                            name: "wifi"
                            size: 28
                            color: root.wifiNetwork ? Theme.accent : Theme.textDim
                        }
                        HeroButton {
                            anchors.right: parent.right
                            visible: root.wifiNetwork !== null
                            text: "Disconnect"
                            onClicked: if (root.wifiNetwork) root.wifiNetwork.disconnect()
                        }
                        Text {
                            y: 40
                            width: parent.width
                            text: !Networking.wifiEnabled ? "Wi-Fi is off" : (!root.wifiDevice ? "No Wi-Fi adapter" : (root.wifiNetwork ? root.wifiNetwork.name : "Not connected"))
                            color: root.wifiNetwork ? Theme.text : Theme.textDim
                            elide: Text.ElideRight
                            font { family: Theme.fontUi; pixelSize: 22; weight: Theme.wStrong }
                        }
                        Text {
                            y: 72
                            width: parent.width
                            visible: root.wifiNetwork !== null
                            text: {
                                if (!root.wifiNetwork) return ""
                                const parts = [root.pct(root.wifiNetwork.signalStrength)]
                                if (ControlInfo.wifiDbm < 0) parts.push(Math.round(ControlInfo.wifiDbm) + " dBm")
                                parts.push(root.wifiNetwork.security === WifiSecurityType.Open ? "Open" : "Secured")
                                return parts.join("  ·  ")
                            }
                            color: Theme.textDim
                            elide: Text.ElideRight
                            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                        }
                        Text {
                            y: 92
                            width: parent.width
                            visible: root.wifiNetwork !== null && ControlInfo.wifiIp !== ""
                            text: ControlInfo.wifiIp
                            color: Theme.textDim
                            font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold }
                        }
                        Item {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 24
                            visible: root.wifiDevice !== null

                            Text {
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                text: "Connect automatically"
                                color: Theme.textDim
                                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                            }
                            Switch {
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                checked: root.wifiDevice ? root.wifiDevice.autoconnect : false
                                onToggled: v => { if (root.wifiDevice) root.wifiDevice.autoconnect = v }
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 8

                        Stat { label: "Link speed"; value: root.wifiNetwork ? root.mbit(ControlInfo.wifiLink) : "—" }
                        Stat { label: root.wifiNetwork && ControlInfo.wifiChan !== "" ? "Frequency · ch " + ControlInfo.wifiChan : "Frequency"; value: root.wifiNetwork ? root.ghz(ControlInfo.wifiFreq) : "—" }
                        Stat { radiusBL: Theme.radiusLg; label: "Download"; value: root.wifiNetwork ? Perf.rate(Perf.netDown) : "—" }
                        Stat { label: "Upload"; value: root.wifiNetwork ? Perf.rate(Perf.netUp) : "—" }
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
                                anchors { left: parent.left; right: wifiSwitch.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                text: !Networking.wifiEnabled ? "Off" : (!root.wifiDevice ? "No adapter" : "Networks")
                                color: Theme.textDim
                                elide: Text.ElideRight
                                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                            }
                            Switch {
                                id: wifiSwitch
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                checked: Networking.wifiEnabled
                                onToggled: v => Networking.wifiEnabled = v
                            }
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentWidth: width
                            contentHeight: netList.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: contentHeight > height

                            Column {
                                id: netList
                                width: parent.width
                                spacing: 2

                                Repeater {
                                    model: root.wifiDevice && Networking.wifiEnabled ? root.wifiDevice.networks : null
                                    delegate: WifiRow {
                                        required property var modelData
                                        network: modelData
                                        visible: modelData.known && !modelData.connected
                                    }
                                }
                                Repeater {
                                    model: root.wifiDevice && Networking.wifiEnabled ? root.wifiDevice.networks : null
                                    delegate: WifiRow {
                                        required property var modelData
                                        network: modelData
                                        visible: !modelData.known
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ------------------------------------------------------------ Bluetooth
        Page {
            index: 1

            RowLayout {
                anchors.fill: parent
                spacing: 8

                ColumnLayout {
                    Layout.preferredWidth: root.leftW
                    Layout.maximumWidth: root.leftW
                    Layout.fillHeight: true
                    spacing: 8

                    Block {
                        tone: Theme.secondaryContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        PanelIcon {
                            name: "bluetooth"
                            size: 28
                            color: root.btDevice ? Theme.accent : Theme.textDim
                        }
                        HeroButton {
                            anchors.right: parent.right
                            visible: root.btDevice !== null
                            text: "Disconnect"
                            onClicked: if (root.btDevice) root.btDevice.disconnect()
                        }
                        Text {
                            y: 40
                            width: parent.width
                            text: !root.adapter ? "No adapter" : (!root.btOn ? "Bluetooth is off" : (root.btDevice ? (root.btDevice.name || root.btDevice.address) : "Nothing connected"))
                            color: root.btDevice ? Theme.text : Theme.textDim
                            elide: Text.ElideRight
                            font { family: Theme.fontUi; pixelSize: 22; weight: Theme.wStrong }
                        }
                        Text {
                            y: 72
                            width: parent.width
                            visible: root.btDevice !== null
                            text: root.btDevice ? root.btType(root.btDevice.icon) : ""
                            color: Theme.textDim
                            elide: Text.ElideRight
                            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                        }
                        Text {
                            y: 72
                            width: parent.width
                            visible: root.btOn && root.btDevice === null
                            text: "Pick a device from the list"
                            color: Theme.textDim
                            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                        }
                        Item {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 24
                            visible: root.btOn

                            Text {
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                text: "Scan for devices"
                                color: Theme.textDim
                                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                            }
                            Switch {
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                checked: root.adapter ? root.adapter.discovering : false
                                onToggled: v => { if (root.adapter) root.adapter.discovering = v }
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 8

                        Stat { label: "Battery"; value: root.btDevice && root.btDevice.batteryAvailable ? Math.round(root.btDevice.battery * (root.btDevice.battery > 1 ? 1 : 100)) + "%" : "—" }
                        Stat { label: "Type"; value: root.btDevice ? root.btType(root.btDevice.icon) : "—" }
                        Stat { radiusBL: Theme.radiusLg; label: "Address"; mono: true; value: root.btDevice ? root.btDevice.address : "—" }
                        Stat { label: "Paired"; value: root.adapter ? root.btPaired + (root.btPaired === 1 ? " device" : " devices") : "—" }
                    }
                }

                Block {
                    tone: Theme.tertiaryContainer
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
                                text: !root.adapter ? "No adapter" : (root.btOn ? "Devices" : "Off")
                                color: Theme.textDim
                                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                            }
                            Switch {
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                visible: root.adapter !== null
                                checked: root.btOn
                                onToggled: v => { if (root.adapter) root.adapter.enabled = v }
                            }
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentWidth: width
                            contentHeight: btList.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: contentHeight > height
                            visible: root.btOn

                            Column {
                                id: btList
                                width: parent.width
                                spacing: 2

                                Repeater {
                                    model: root.adapter ? root.adapter.devices : null
                                    delegate: DeviceRow {
                                        required property var modelData
                                        device: modelData
                                        visible: modelData.paired && !modelData.connected
                                    }
                                }
                                Repeater {
                                    model: root.adapter ? root.adapter.devices : null
                                    delegate: DeviceRow {
                                        required property var modelData
                                        device: modelData
                                        visible: !modelData.paired
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true; visible: !root.btOn }
                    }
                }
            }
        }

        // ---------------------------------------------------------------- Sound
        Page {
            index: 2

            RowLayout {
                anchors.fill: parent
                spacing: 8

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
                            name: "volume"
                            size: 28
                            color: root.sink && root.sink.audio && !root.sink.audio.muted ? Theme.accent : Theme.textDim
                        }
                        Text {
                            anchors { right: parent.right; top: parent.top; topMargin: -4 }
                            text: root.sink && root.sink.audio ? root.pct(root.sink.audio.volume) : "—"
                            color: Theme.text
                            font { family: Theme.fontUi; pixelSize: 32; weight: Theme.wHeavy }
                        }
                        Text {
                            y: 40
                            width: parent.width
                            text: root.sink ? (root.sink.description || root.sink.nickname || root.sink.name) : "No output"
                            color: root.sink ? Theme.text : Theme.textDim
                            elide: Text.ElideRight
                            font { family: Theme.fontUi; pixelSize: 16; weight: Theme.wStrong }
                        }
                        PanelSlider {
                            y: 64
                            width: parent.width
                            value: root.sink && root.sink.audio ? root.sink.audio.volume : 0
                            onMoved: v => { if (root.sink && root.sink.audio) root.sink.audio.volume = v }
                        }

                        // Microphone gain goes up to 300%; the tick marks 100%.
                        PanelSlider {
                            id: micSlider
                            y: 112
                            width: parent.width
                            value: root.source && root.source.audio ? Math.min(1, root.source.audio.volume / 3) : 0
                            opacity: root.source && root.source.audio && root.source.audio.muted ? 0.45 : 1
                            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
                            onMoved: v => {
                                if (!root.source || !root.source.audio) return
                                let x = v * 3
                                if (Math.abs(x - 1) < 0.05) x = 1
                                root.source.audio.volume = x
                            }
                        }
                        Rectangle {
                            x: micSlider.width / 3 - 0.5
                            y: micSlider.y + micSlider.height / 2 - 6
                            width: 1
                            height: 12
                            color: Theme.textDim
                            opacity: 0.7
                        }
                        Item {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 24

                            Text {
                                id: micLabel
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                text: "Microphone"
                                color: Theme.textDim
                                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                            }
                            Text {
                                anchors { left: micLabel.right; leftMargin: 8; verticalCenter: parent.verticalCenter }
                                text: root.source && root.source.audio ? root.pct(root.source.audio.volume) : "—"
                                color: Theme.text
                                font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold }
                            }
                            Switch {
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                checked: root.source && root.source.audio ? !root.source.audio.muted : false
                                onToggled: v => { if (root.source && root.source.audio) root.source.audio.muted = !v }
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 8

                        Stat { label: "Sample rate"; value: ControlInfo.sinkRate > 0 ? (ControlInfo.sinkRate / 1000) + " kHz" : "—" }
                        Stat { label: "Format"; value: ControlInfo.sinkFormat !== "" ? ControlInfo.sinkFormat + " · " + ControlInfo.sinkChannels + " ch" : "—" }
                        Stat { radiusBL: Theme.radiusLg; label: "Microphone"; value: !root.source || !root.source.audio ? "—" : (root.source.audio.muted ? "Muted" : root.pct(root.source.audio.volume)) }
                        Stat { label: "Playing"; value: root.appStreams + (root.appStreams === 1 ? " app" : " apps") }
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
                                text: root.sink && root.sink.audio && root.sink.audio.muted ? "Muted" : "Outputs"
                                color: Theme.textDim
                                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                            }
                            Switch {
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                checked: root.sink && root.sink.audio ? !root.sink.audio.muted : false
                                onToggled: v => { if (root.sink && root.sink.audio) root.sink.audio.muted = !v }
                            }
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentWidth: width
                            contentHeight: sinkList.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: contentHeight > height

                            Column {
                                id: sinkList
                                width: parent.width
                                spacing: 2

                                Repeater {
                                    model: Pipewire.nodes
                                    delegate: SinkRow {
                                        required property var modelData
                                        node: modelData
                                        visible: modelData.isSink && !modelData.isStream
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // -------------------------------------------------------------- Battery
        Page {
            index: 3

            RowLayout {
                anchors.fill: parent
                spacing: 8

                ColumnLayout {
                    Layout.preferredWidth: root.leftW
                    Layout.maximumWidth: root.leftW
                    Layout.fillHeight: true
                    spacing: 8

                    Block {
                        tone: Theme.secondaryContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        PanelIcon {
                            name: root.charging ? "bolt" : "battery"
                            size: 28
                            color: root.level < 0.15 && !root.charging ? Theme.danger : Theme.accent
                        }
                        Text {
                            anchors { right: parent.right; top: parent.top; topMargin: 6 }
                            text: root.charging ? "Charging" : "On battery"
                            color: Theme.textDim
                            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                        }
                        Text {
                            y: 34
                            text: Math.round(root.level * 100) + "%"
                            color: root.level < 0.15 && !root.charging ? Theme.danger : Theme.text
                            font { family: Theme.fontUi; pixelSize: 48; weight: Theme.wHeavy }
                        }
                        Rectangle {
                            y: 98
                            width: parent.width
                            height: 6
                            radius: 3
                            color: Theme.panelTrack

                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, root.level))
                                height: parent.height
                                radius: 3
                                color: root.level < 0.15 && !root.charging ? Theme.danger : Theme.accent
                            }
                        }
                        Text {
                            y: 112
                            width: parent.width
                            text: {
                                if (root.charging && root.battery.timeToFull > 0) return root.fmt(root.battery.timeToFull) + " until full"
                                if (!root.charging && root.battery.timeToEmpty > 0) return root.fmt(root.battery.timeToEmpty) + " remaining"
                                return root.charging ? "Fully charged soon" : ""
                            }
                            color: Theme.textDim
                            elide: Text.ElideRight
                            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                        }
                        Text {
                            anchors { left: parent.left; bottom: parent.bottom }
                            visible: root.battery.energyCapacity > 0
                            text: root.battery.energy.toFixed(1) + " / " + root.battery.energyCapacity.toFixed(1) + " Wh"
                            color: Theme.textDim
                            font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 8

                        Stat { label: root.charging ? "Charging at" : "Drawing"; value: root.battery.changeRate !== undefined ? Math.abs(root.battery.changeRate).toFixed(1) + " W" : "—" }
                        Stat { label: "Voltage"; value: ControlInfo.voltage > 0 ? ControlInfo.voltage.toFixed(2) + " V" : "—" }
                        Stat { radiusBL: Theme.radiusLg; label: "Health"; value: root.battery.healthPercentage > 0 ? Math.round(root.battery.healthPercentage) + "%" : (ControlInfo.capacityHealth > 0 ? Math.round(ControlInfo.capacityHealth) + "%" : "—") }
                        Stat { label: "Cycles"; value: ControlInfo.cycles > 0 ? ControlInfo.cycles : "—" }
                    }
                }

                Block {
                    tone: Theme.tertiaryContainer
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
                                text: "Power profile"
                                color: Theme.textDim
                                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                            }
                        }

                        ProfileRow { icon: "battery"; label: "Power saver"; hint: "Longer battery life"; value: PowerProfile.PowerSaver }
                        ProfileRow { icon: "dashboard"; label: "Balanced"; hint: "Everyday use"; value: PowerProfile.Balanced }
                        ProfileRow { icon: "bolt"; label: "Performance"; hint: "Full speed, more heat"; value: PowerProfile.Performance; visible: PowerProfiles.hasPerformanceProfile }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }

        // ------------------------------------------------------------------ VPN
        Page {
            index: 4

            ControlVpn {
                anchors.fill: parent
                leftW: root.leftW
            }
        }
    }

    // One tab page; it fades in when its tab is picked.
    component Page: Item {
        required property int index

        anchors.fill: parent
        opacity: root.tab === index ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easingCalm } }
    }

    // A power profile: icon, name and a hint; the current one is marked.
    component ProfileRow: Item {
        id: prof

        property string icon
        property string label
        property string hint
        property var value
        readonly property bool current: PowerProfiles.profile === prof.value

        Layout.fillWidth: true
        Layout.preferredHeight: 48

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusSm
            color: prof.current ? Qt.alpha(Theme.accent, 0.14) : (hov.hovered ? Theme.panelHigh : "transparent")
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }
        PanelIcon {
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            name: prof.icon
            size: 18
            color: prof.current ? Theme.accent : Theme.textDim
        }
        Column {
            anchors { left: parent.left; leftMargin: 42; right: check.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: 2

            Text {
                width: parent.width
                text: prof.label
                color: prof.current ? Theme.accent : Theme.text
                elide: Text.ElideRight
                font { family: Theme.fontUi; pixelSize: 13; weight: Theme.wStrong }
            }
            Text {
                width: parent.width
                text: prof.hint
                color: Theme.textDim
                elide: Text.ElideRight
                font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
            }
        }
        PanelIcon {
            id: check
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            name: "check"
            size: 16
            color: Theme.accent
            visible: prof.current
        }
        HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: PowerProfiles.profile = prof.value }
    }

    // A network: the name connects, a red trash icon forgets it; secured unknown networks ask for a password.
    component WifiRow: Item {
        id: row

        required property var network
        property bool askPassword: false
        // 802.1X sign-in in flight (hs-wifi-eap) and its last failure, shown in the password field.
        property bool busy: false
        property string err: ""

        width: parent ? parent.width : 0
        height: askPassword ? (enterprise ? 86 : 58) : 30
        clip: true
        Behavior on height { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }

        readonly property bool secured: network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe

        // 802.1X (campus) networks take a login and a password; Quickshell can only send a key,
        // so these go through hs-wifi-eap (PEAP + MSCHAPv2), which saves the profile in NetworkManager.
        readonly property bool enterprise: [WifiSecurityType.WpaEap, WifiSecurityType.Wpa2Eap, WifiSecurityType.Wpa3SuiteB192, WifiSecurityType.Leap, WifiSecurityType.DynamicWep].includes(network.security)

        function focusPass() { PanelState.typing = true; PanelState.typed(); (enterprise && login.text === "" ? login : pass).forceActiveFocus() }

        function submit() {
            if (busy || pass.text === "") return
            if (!enterprise) {
                row.network.connectWithPsk(pass.text)
                row.askPassword = false
                return
            }
            if (login.text === "") { login.forceActiveFocus(); return }
            err = ""
            busy = true
            eap.running = true
        }

        Process {
            id: eap
            command: ["hs-wifi-eap"]
            stdinEnabled: true
            // Credentials go through stdin, never argv.
            onStarted: { write(row.network.name + "\n" + login.text + "\n" + pass.text + "\n"); stdinEnabled = false }
            onExited: code => {
                row.busy = false
                eap.stdinEnabled = true
                if (code === 0) { row.askPassword = false; return }
                row.err = code === 4 ? "Wrong login or password" : "Could not connect"
                pass.text = ""
                pass.forceActiveFocus()
            }
        }

        onAskPasswordChanged: {
            if (askPassword) {
                // Take the panel keyboard first, then focus once the field is actually visible.
                PanelState.typing = true
                Qt.callLater(row.focusPass)
            } else {
                pass.text = ""
                login.text = ""
                err = ""
                PanelState.typing = false
            }
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 30
            radius: Theme.radiusSm
            color: hover.hovered ? Theme.panelHigh : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }

        PanelIcon {
            id: wifiIcon
            anchors { left: parent.left; leftMargin: 8 }
            y: 7
            name: "wifi"
            size: 16
            color: Theme.textDim
        }
        PanelIcon {
            id: forgetIcon
            anchors { right: parent.right; rightMargin: 8 }
            y: 8
            name: "trash"
            size: 14
            color: Theme.danger
            visible: row.network.known
        }
        Text {
            id: strength
            anchors { right: forgetIcon.visible ? forgetIcon.left : parent.right; rightMargin: 8 }
            y: 8
            text: root.pct(row.network.signalStrength)
            color: Theme.textDim
            font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold }
        }
        PanelIcon {
            id: lockIcon
            anchors { right: strength.left; rightMargin: 8 }
            y: 9
            name: "lock"
            size: 12
            color: Theme.textDim
            visible: row.secured
        }
        Text {
            anchors { left: wifiIcon.right; leftMargin: 8; right: row.secured ? lockIcon.left : strength.left; rightMargin: 8 }
            y: 8
            text: row.network.name
            color: Theme.text
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }

        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }

        MouseArea {
            anchors { left: parent.left; right: parent.right; top: parent.top; rightMargin: forgetIcon.visible ? 32 : 0 }
            height: 30
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (row.askPassword) { row.askPassword = false; return }
                if (row.network.connected) row.network.disconnect()
                else if (row.network.known) row.network.connect()
                else if (row.secured) row.askPassword = true
                else row.network.connect()
            }
        }
        MouseArea {
            anchors { right: parent.right; top: parent.top }
            width: 32
            height: 30
            visible: row.network.known
            cursorShape: Qt.PointingHandCursor
            onClicked: row.network.forget()
        }

        Rectangle {
            y: 32
            anchors { left: parent.left; right: parent.right }
            height: 24
            radius: Theme.radiusSm
            visible: row.askPassword && row.enterprise
            color: Theme.tile
            border.width: 1
            border.color: login.activeFocus ? Qt.alpha(Theme.accent, 0.6) : Theme.border

            TextInput {
                id: login
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                selectionColor: Theme.accent
                selectedTextColor: Theme.accentText
                clip: true
                readOnly: row.busy
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                Keys.onEscapePressed: row.askPassword = false
                Keys.onTabPressed: pass.forceActiveFocus()
                onTextChanged: PanelState.typed()
                onAccepted: pass.forceActiveFocus()
            }
            Text {
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                visible: login.text === ""
                text: "Login"
                color: Theme.textDim
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }
            HoverHandler { cursorShape: Qt.IBeamCursor }
            TapHandler { onTapped: { PanelState.typing = true; PanelState.typed(); login.forceActiveFocus() } }
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 24
            radius: Theme.radiusSm
            visible: row.askPassword
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
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                clip: true
                readOnly: row.busy
                Keys.onEscapePressed: row.askPassword = false
                Keys.onBacktabPressed: if (row.enterprise) login.forceActiveFocus()
                onTextChanged: { PanelState.typed(); if (text !== "") row.err = "" }
                onAccepted: row.submit()
            }
            Text {
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                visible: pass.text === ""
                text: row.busy ? "Connecting…" : (row.err !== "" ? row.err : "Password, then Enter")
                color: row.err !== "" && !row.busy ? Theme.danger : Theme.textDim
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }
            HoverHandler { cursorShape: Qt.IBeamCursor }
            TapHandler { onTapped: { PanelState.typing = true; PanelState.typed(); pass.forceActiveFocus() } }
        }
    }

    // A Bluetooth device: the name pairs/connects, a red trash icon unpairs it.
    component DeviceRow: Item {
        id: row

        required property var device

        width: parent ? parent.width : 0
        height: 30

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusSm
            color: row.device.connected ? Qt.alpha(Theme.accent, 0.14) : (hover.hovered ? Theme.panelHigh : "transparent")
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }

        PanelIcon {
            id: btIcon
            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
            name: "bluetooth"
            size: 16
            color: row.device.connected ? Theme.accent : Theme.textDim
        }
        PanelIcon {
            id: unpairIcon
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            name: "trash"
            size: 14
            color: Theme.danger
            visible: row.device.paired
        }
        Text {
            id: batteryText
            anchors { right: unpairIcon.visible ? unpairIcon.left : parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            text: row.device.batteryAvailable ? Math.round(row.device.battery * (row.device.battery > 1 ? 1 : 100)) + "%" : ""
            color: Theme.textDim
            font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold }
        }
        Text {
            anchors { left: btIcon.right; leftMargin: 8; right: batteryText.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            text: row.device.name || row.device.address
            color: row.device.connected ? Theme.accent : Theme.text
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }

        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }

        MouseArea {
            anchors { fill: parent; rightMargin: unpairIcon.visible ? 32 : 0 }
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (row.device.connected) row.device.disconnect()
                else if (row.device.paired) row.device.connect()
                else row.device.pair()
            }
        }
        MouseArea {
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: 32
            visible: row.device.paired
            cursorShape: Qt.PointingHandCursor
            onClicked: row.device.forget()
        }
    }

    // An output device: the name switches the default sink.
    component SinkRow: Item {
        id: row

        required property var node
        readonly property bool current: row.node === root.sink

        width: parent ? parent.width : 0
        height: 26

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusSm
            color: row.current ? Qt.alpha(Theme.accent, 0.14) : (hover.hovered ? Theme.panelHigh : "transparent")
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }
        PanelIcon {
            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
            name: "volume"
            size: 14
            color: row.current ? Theme.accent : Theme.textDim
        }
        Text {
            anchors { left: parent.left; leftMargin: 28; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            text: row.node.description || row.node.name || row.node.nickname || ""
            color: row.current ? Theme.accent : Theme.text
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: Pipewire.preferredDefaultAudioSink = row.node }
    }
}
