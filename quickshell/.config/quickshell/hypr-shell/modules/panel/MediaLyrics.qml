import QtQuick
import QtQuick.Effects
import qs.theme
import qs.services
import qs.components

// Lyrics view of the Media tab. Synced lyrics follow the song on a spring with the sung line in the middle; a tap on a
// line seeks there, scrolling by hand pauses the follow for a moment. Plain lyrics scroll along with the song.
// The text fades out towards the top and bottom edges.
Item {
    id: root

    clip: true

    // Smooth playback clock: the service samples the player a few times a second, frames fill in between.
    property real anchorPos: 0
    property real anchorAt: 0
    property real clock: 0
    readonly property int cur: Lyrics.indexAt(clock)
    readonly property real progress: Lyrics.progressAt(cur, clock)

    readonly property bool active: visible && Lyrics.synced && Players.has
    readonly property bool free: list.moving || freeTimer.running

    function resync() {
        anchorPos = Lyrics.position
        anchorAt = Date.now()
        clock = anchorPos
    }
    Connections {
        target: Lyrics
        function onPositionChanged() { root.resync() }
        function onLinesChanged() { root.settled = false; root.snap() }
    }
    Connections {
        target: Players
        function onPlayingChanged() { root.resync(); root.settled = false }
    }
    onCurChanged: settled = false
    onVisibleChanged: if (visible) { resync(); snap() }

    // Spring that keeps the sung line in the middle (a little bounce with the Bounce setting).
    property real vel: 0
    property bool settled: false
    readonly property real omega: 11
    readonly property real zeta: 1 - 0.35 * Theme.spring

    function targetY() {
        const it = list.itemAtIndex(Math.max(0, cur))
        return it ? it.y + it.height / 2 - list.height / 2 : list.contentY
    }
    function snap() {
        Qt.callLater(() => { list.contentY = targetY(); vel = 0 })
    }

    FrameAnimation {
        running: root.active && (Players.playing || !root.settled)
        onTriggered: {
            root.clock = root.anchorPos + (Players.playing ? (Date.now() - root.anchorAt) / 1000 : 0)
            if (root.free) { root.vel = 0; return }
            const dt = Math.min(0.05, frameTime)
            const x = list.contentY, target = root.targetY()
            const a = root.omega * root.omega * (target - x) - 2 * root.zeta * root.omega * root.vel
            root.vel += a * dt
            list.contentY = x + root.vel * dt
            root.settled = Math.abs(target - list.contentY) < 0.5 && Math.abs(root.vel) < 2
        }
    }

    Timer { id: freeTimer; interval: 3000 }

    // States
    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: 12
        visible: Lyrics.status === "loading" && Players.has

        Repeater {
            model: [0.62, 0.86, 0.48]

            Rectangle {
                id: bone
                required property real modelData
                required property int index
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * modelData
                height: 14
                radius: 7
                color: Theme.panelPill

                SequentialAnimation on opacity {
                    running: bone.visible
                    loops: Animation.Infinite
                    PauseAnimation { duration: bone.index * Theme.durFast }
                    NumberAnimation { from: 1; to: 0.38; duration: Theme.durOpen * 2; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.38; to: 1; duration: Theme.durOpen * 2; easing.type: Easing.InOutSine }
                }
            }
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Loading lyrics…"
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
        }
    }

    Text {
        readonly property string message: {
            if (!Players.has) return "Nothing playing"
            switch (Lyrics.status) {
            case "none": return "No lyrics found"
            case "error": return Lyrics.error
            case "idle": return "No track information"
            }
            return ""
        }
        anchors.centerIn: parent
        width: parent.width
        visible: message !== ""
        horizontalAlignment: Text.AlignHCenter
        text: message
        color: Lyrics.status === "error" ? Theme.danger : Theme.textDim
        elide: Text.ElideRight
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }

        HoverHandler { cursorShape: Lyrics.status === "error" ? Qt.PointingHandCursor : Qt.ArrowCursor }
        TapHandler { enabled: Lyrics.status === "error"; onTapped: Lyrics.retry() }
    }

    // The text, faded at the edges
    Item {
        id: viewport
        anchors.fill: parent
        visible: Players.has && (Lyrics.synced || Lyrics.status === "plain")
        layer.enabled: visible
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: fade
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }

        ListView {
            id: list
            anchors.fill: parent
            visible: Lyrics.synced
            model: Lyrics.synced ? Lyrics.lines : []
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 4000
            highlightRangeMode: ListView.NoHighlightRange
            onMovementEnded: freeTimer.restart()

            header: Item { width: 1; height: list.height / 2 - 18 }
            footer: Item { width: 1; height: list.height / 2 - 18 }

            delegate: LyricLine {
                width: list.width
                current: root.cur
                progress: root.progress
                free: root.free
                playing: Players.playing
                onPicked: i => {
                    freeTimer.stop()
                    Lyrics.seekToLine(i)
                    root.resync()
                }
            }
        }

        Flickable {
            id: plain
            anchors.fill: parent
            visible: Lyrics.status === "plain"
            contentHeight: plainText.implicitHeight + height
            boundsBehavior: Flickable.StopAtBounds
            onMovementEnded: plainFree.restart()

            Timer { id: plainFree; interval: 3000 }

            // Scrolls along with the song unless moved by hand
            Binding {
                target: plain
                property: "contentY"
                value: Math.max(0, plainText.implicitHeight * Players.ratio - plain.height * 0.3)
                when: !plain.moving && !plainFree.running && Players.has
                restoreMode: Binding.RestoreNone
            }
            Behavior on contentY { enabled: !plain.moving; NumberAnimation { duration: Theme.durOpen; easing.type: Theme.easingCalm } }

            Text {
                id: plainText
                y: plain.height * 0.3
                width: parent.width
                wrapMode: Text.WordWrap
                text: Lyrics.plain
                color: Theme.textDim
                lineHeight: 1.25
                font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
            }
        }
    }

    Item {
        id: fade
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.2; color: Theme.text }
                GradientStop { position: 0.8; color: Theme.text }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }

    // Sync shift for lyrics that run early or late; shows on hover.
    HoverHandler { id: areaHover }
    Row {
        anchors { right: parent.right; bottom: parent.bottom }
        spacing: 4
        visible: Lyrics.synced && Players.has
        opacity: areaHover.hovered || Lyrics.offset !== 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }

        PanelButton {
            icon: "minus"; vertical: false; clickOpens: false; iconSize: 16
            width: 28; height: 28
            onClicked: Lyrics.nudge(-0.5)
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            horizontalAlignment: Text.AlignHCenter
            text: (Lyrics.offset > 0 ? "+" : Lyrics.offset < 0 ? "−" : "") + Math.abs(Lyrics.offset).toFixed(1) + " s"
            color: Theme.textDim
            font { family: Theme.fontMono; pixelSize: 11; weight: Theme.wBold }
        }
        PanelButton {
            icon: "plus"; vertical: false; clickOpens: false; iconSize: 16
            width: 28; height: 28
            onClicked: Lyrics.nudge(0.5)
        }
    }
}
