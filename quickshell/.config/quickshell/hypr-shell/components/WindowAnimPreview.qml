import QtQuick
import qs.theme

// Window open and close animation: four cards, one per style, each plays a small window opening and closing with the
// current speeds. The chosen card repeats on its own while the page is visible; the others play when the pointer is on
// them. A click picks the style. The motion is an approximation of what Hyprland does with the same style.
Item {
    id: root

    readonly property var styles: [
        { id: "popin", label: "Pop" },
        { id: "slide", label: "Slide" },
        { id: "gnomed", label: "Genie" },
        { id: "fade", label: "Fade" }
    ]
    readonly property string current: Theme.cfg.motion.windowStyle
    readonly property int openMs: Theme.cfg.motion.windowOpen
    readonly property int closeMs: Theme.cfg.motion.windowClose
    readonly property real startScale: Theme.cfg.motion.windowScale / 100
    readonly property int gap: 8
    readonly property real cardW: (width - 3 * gap) / 4

    width: parent ? parent.width : implicitWidth
    implicitHeight: 132

    function playCurrent() {
        for (let i = 0; i < cards.count; i++) {
            const c = cards.itemAt(i)
            if (c && c.styleId === current) c.play()
        }
    }

    // A change of speed or size replays the chosen card once the slider has settled.
    Connections {
        target: Theme.cfg.motion
        function onWindowOpenChanged() { settle.restart() }
        function onWindowCloseChanged() { settle.restart() }
        function onWindowScaleChanged() { settle.restart() }
        function onWindowStyleChanged() { settle.restart() }
    }
    Timer { id: settle; interval: 350; onTriggered: root.playCurrent() }

    // Pause between two plays: the whole motion plus a moment to look at the result.
    Timer {
        interval: root.openMs + 700 + root.closeMs + 1200
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.playCurrent()
    }

    Row {
        spacing: root.gap

        Repeater {
            id: cards
            model: root.styles

            delegate: Item {
                id: card
                required property var modelData
                readonly property string styleId: modelData.id
                readonly property bool chosen: root.current === styleId
                // 0 is hidden, 1 is fully shown
                property real t: 1

                width: root.cardW
                height: root.implicitHeight

                function play() { seq.restart() }

                SequentialAnimation {
                    id: seq
                    NumberAnimation { target: card; property: "t"; from: 0; to: 1; duration: root.openMs; easing.type: Theme.easing; easing.overshoot: Theme.overshoot }
                    PauseAnimation { duration: 700 }
                    NumberAnimation { target: card; property: "t"; to: 0; duration: root.closeMs; easing.type: Theme.easingCalm }
                    NumberAnimation { target: card; property: "t"; to: 1; duration: 0 }
                }

                Rectangle {
                    id: stage
                    width: parent.width
                    height: 92
                    radius: Theme.radiusSm
                    color: hover.hovered ? Theme.panelPill : Theme.panelRaised
                    border.width: 1
                    border.color: card.chosen ? Theme.borderActive : Theme.border
                    clip: true
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }

                    // The mock window
                    Rectangle {
                        id: win
                        width: 56; height: 40
                        x: (stage.width - width) / 2
                        y: (stage.height - height) / 2
                        radius: 8
                        color: Theme.panelHigh
                        opacity: card.styleId === "slide" ? Math.min(1, card.t * 2.5) : card.t
                        transform: [
                            Scale {
                                origin.x: win.width / 2
                                origin.y: card.styleId === "gnomed" ? win.height : win.height / 2
                                xScale: card.styleId === "popin" ? root.startScale + (1 - root.startScale) * card.t
                                    : (card.styleId === "gnomed" ? 0.7 + 0.3 * card.t : 1)
                                yScale: card.styleId === "popin" ? root.startScale + (1 - root.startScale) * card.t
                                    : (card.styleId === "gnomed" ? card.t : 1)
                            },
                            Translate { x: card.styleId === "slide" ? -(1 - card.t) * (stage.width / 2 + win.width / 2) : 0 }
                        ]

                        Rectangle { x: 8; y: 8; width: 14; height: 4; radius: 2; color: Theme.accent }
                        Rectangle { x: 8; y: 18; width: parent.width - 16; height: 3; radius: 1.5; color: Theme.separator }
                        Rectangle { x: 8; y: 25; width: parent.width - 28; height: 3; radius: 1.5; color: Theme.separator }
                    }

                    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor; onHoveredChanged: if (hovered) card.play() }
                    TapHandler { onTapped: Theme.set("motion", "windowStyle", card.styleId) }
                }

                Text {
                    anchors { horizontalCenter: parent.horizontalCenter }
                    y: stage.height + 8
                    text: card.modelData.label
                    color: card.chosen ? Theme.text : Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 14; weight: card.chosen ? Theme.wStrong : Theme.wBold }
                }
            }
        }
    }
}
