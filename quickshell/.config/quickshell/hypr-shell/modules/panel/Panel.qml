import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services
import qs.components
import qs.modules.picker
import "PanelGeometry.js" as Geo

// Screen frame (default): a thin frame around the whole screen with a strip on the left that holds the controls.
// Without the frame: two floating panels (left rail and bottom bar) or a single L-shaped one.
// Branches grow out of the panel as one shape in every mode.
PanelWindow {
    id: win

    required property var modelData
    readonly property string screenName: modelData.name

    // Metrics
    readonly property real m: Theme.gapsOut
    readonly property real thick: 48
    // In frame mode the cutout corners follow the physical screen corner radius.
    readonly property real rad: Theme.radiusBranch
    readonly property real pw: Theme.roundingPower
    readonly property bool flush: Theme.cfg.panel.railFlush
    readonly property real fw: Theme.frameWidth
    readonly property real railW: Theme.railWidth
    readonly property real railX0: flush ? 0 : m
    readonly property real railX1: railX0 + railW
    readonly property real railLen: flush ? height : 340
    readonly property real barLen: flush ? 0 : 680

    // Merge: 0 is two panels, 1 is the L-shaped form (not available with the frame)
    property real t: Theme.cfg.panel.joined && !flush ? 1 : 0
    Behavior on t { NumberAnimation { duration: Theme.durSlow * 2; easing.type: Easing.InOutCubic } }

    // Floating panel positions
    readonly property real bt: height - m - thick
    readonly property real railHi: Math.max(m, bt - m - railLen)
    readonly property real railYSplit: m + (Theme.cfg.panel.offsetY + 1) / 2 * (railHi - m)
    readonly property real railY: flush ? 0 : railYSplit + (bt - railLen - railYSplit) * t
    readonly property real railBottom: railY + railLen
    readonly property real barHi: Math.max(m, width - m - barLen)
    readonly property real barXSplit: m + (Theme.cfg.panel.offsetX + 1) / 2 * (barHi - m)
    readonly property real barL: barXSplit + (m - barXSplit) * t
    readonly property real barW: barLen + thick * t
    readonly property real barR: barL + barW

    // Branches: one slot per edge (BranchSlot), so several menus can be open at once while PanelState.multi is on.
    // Toasts hang from the top band in frame mode and from the bottom bar otherwise.
    readonly property string toastEdge: flush ? "top" : "bar"
    readonly property var railBr: railSlot.geom
    readonly property var barBr: barSlot.geom
    readonly property var topBr: topSlot.geom
    readonly property var botBr: bottomSlot.geom
    readonly property var rightBr: rightSlot.geom
    readonly property bool anyHover: railSlot.hovered || topSlot.hovered || rightSlot.hovered || bottomSlot.hovered || barSlot.hovered

    // Mini terminal: the branch frames a hole, the real terminal window shows through it.
    readonly property bool termOpen: railSlot.termOpen
    readonly property var holeRect: railSlot.holeRect
    // The cutout is rounded concentrically with the outer corner of the branch: its radius is the outer radius minus the gap
    // between them (for superellipse corners the offset rule of look.lua, so the gap stays even on the diagonal).
    readonly property real holeRadius: Math.max(4, rad - (Math.SQRT2 - 1) / (Math.SQRT2 * (1 - Math.pow(2, -1 / pw))) * railSlot.holeGap)
    readonly property var holePts: holeRect ? Geo.roundRect(holeRect.x, holeRect.y, holeRect.w, holeRect.h, holeRadius, pw) : []

    // Outlines
    readonly property var railPts: Geo.rail({ x0: railX0, x1: railX1, y0: railY, y1: railBottom, R: rad, rr: rad * (1 - t), branch: railBr }, pw)
    readonly property var barPts: Geo.bar({ x0: barL, x1: barR, y0: bt, y1: bt + thick, R: rad, rtl: rad * (1 - t), branch: barBr }, pw)
    readonly property var joinedPts: Geo.joined({ x0: m, rx1: m + thick, ry0: railY, by0: bt, y1: bt + thick, x1: barR, R: rad, railBranch: railBr, barBranch: barBr }, pw)
    readonly property var patchPts: Geo.patch(m + thick, bt, rad * t, pw)
    readonly property var patchEdge: Geo.patchEdge(m + thick, bt, rad * t, pw)
    readonly property var frameHolePts: flush
        ? Geo.frameHole({ W: width, H: height, left: railX1, top: fw, right: fw, bottom: fw, R: rad, railBranch: railBr, rightBranch: rightBr, topBranch: topBr, bottomBranch: botBr }, pw)
        : []

    // Fills are drawn from rings: the first is the solid, the others are cut out of it.
    readonly property var barRings: holeRect ? [barPts, holePts] : [barPts]
    readonly property var joinedRings: holeRect ? [joinedPts, holePts] : [joinedPts]
    readonly property var frameRings: holeRect ? [Geo.screenRect(width, height), frameHolePts, holePts] : [Geo.screenRect(width, height), frameHolePts]

    property bool termShown: false
    onHoleRectChanged: termSync.restart()
    Timer {
        id: termSync
        interval: 60
        onTriggered: {
            if (win.holeRect) {
                win.termShown = true
                // The window is a little bigger than the hole: the panel covers its edges and corners.
                const pad = 3
                MiniTerm.show(win.modelData.x + win.holeRect.x - pad, win.modelData.y + win.holeRect.y - pad, win.holeRect.w + 2 * pad, win.holeRect.h + 2 * pad)
            } else if (win.termShown) {
                win.termShown = false
                MiniTerm.hide()
            }
        }
    }

    Connections {
        target: PanelState
        function onSnapshotRequested(path) {
            scene.grabToImage(result => result.saveToFile(path))
        }
    }

    screen: modelData
    anchors { left: true; right: true; top: true; bottom: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "hs-panel"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: PanelState.typing && PanelState.screenName === screenName ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region {
        item: railHit
        regions: [
            Region { item: barHit },
            Region { item: hotZone },
            Region { item: hotZoneRight },
            Region { item: hotZoneBottom },
            Region { item: hotZoneCorner },
            Region { item: catcher },
            Region { item: railSlot.box; regions: [Region { item: holeItem; intersection: Intersection.Subtract }] },
            Region { item: topSlot.box },
            Region { item: rightSlot.box },
            Region { item: bottomSlot.box },
            Region { item: barSlot.box }
        ]
    }

    Binding {
        target: PanelState
        property: "hovered"
        value: hRail.hovered || hBar.hovered || win.anyHover || hHot.hovered || hHotRight.hovered || hHotBottom.hovered || PanelState.typing || ColorPicker.painting || (win.termOpen && MiniTerm.focused)
        when: PanelState.screenName === win.screenName
    }
    Binding { target: Toasts; property: "paused"; value: hRail.hovered || hBar.hovered || win.anyHover || Screenshot.busy }

    // Everything that is drawn lives in one item so that it can be grabbed for snapshots.
    Item {
        id: scene
        anchors.fill: parent

        // While the utility branch holds the keyboard, a click anywhere outside it closes it (and is not passed on),
        // otherwise keys would keep going to the field after the user clicked another window.
        Item {
            id: catcher
            readonly property bool on: bottomSlot.shownKind === "utility" && PanelState.typing && PanelState.screenName === win.screenName
            width: on ? win.width : 0
            height: on ? win.height : 0

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onPressed: PanelState.dismiss("utility")
            }
        }

        // Drop shadow: a wide soft black stroke along the cutout edge, lowered a little as if lit from above.
        // The frame is drawn over it, so only the part on the desktop side stays visible.
        Shape {
            anchors.fill: parent
            visible: win.flush && Theme.shadowStrength > 0.01
            opacity: Theme.shadowStrength
            y: 2
            layer.enabled: true
            layer.samples: 4
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: 24
                blur: Theme.shadowSize
                colorization: 1
                colorizationColor: "black"
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: "white"
                strokeWidth: 8
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: win.frameHolePts }
            }
        }

        // Frame glow: a thick blurred stroke along the cutout edge, tinted to the glow color. The frame
        // (drawn below it) covers the half under the panel, leaving a soft bloom into the desktop.
        Shape {
            anchors.fill: parent
            visible: win.flush && Theme.glowStrength > 0.01
            opacity: Theme.glowStrength * OledCare.glowFactor
            layer.enabled: true
            layer.samples: 4
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: 20
                blur: 1
                colorization: 1
                colorizationColor: Theme.glowColor
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: "white"
                strokeWidth: 6
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: win.frameHolePts }
            }
        }

        // Screen frame
        Shape {
            anchors.fill: parent
            visible: win.flush
            layer.enabled: true
            layer.samples: 4

            // Soft depth: a dark ring on the desktop side of the cutout edge (the fill covers its outer half).
            ShapePath {
                fillColor: "transparent"
                strokeColor: Theme.frameRing
                strokeWidth: 6
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: win.frameHolePts }
            }
            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: 0; y1: 0; x2: 0; y2: win.height
                    GradientStop { position: 0; color: Theme.panelFillHigh }
                    GradientStop { position: 0.35; color: Theme.panelFill }
                    GradientStop { position: 1; color: Theme.panelFill }
                }
                PathMultiline { paths: win.frameRings }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: Theme.border
                strokeWidth: 1
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: win.frameHolePts }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: win.holeRect ? Theme.border : "transparent"
                strokeWidth: 1
                PathPolyline { path: win.holePts }
            }
        }

        // Floating panels
        Shape {
            anchors.fill: parent
            visible: !win.flush && win.t < 1
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                fillColor: Theme.panelBase
                strokeColor: "transparent"
                PathPolyline { path: win.railPts }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: Theme.border
                strokeWidth: 1
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: win.railPts }
            }
            ShapePath {
                fillColor: Theme.panelBase
                strokeColor: "transparent"
                PathMultiline { paths: win.barRings }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: Theme.border
                strokeWidth: 1
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: win.barPts }
            }
            ShapePath {
                fillColor: win.t > 0.02 ? Theme.panelBase : "transparent"
                strokeColor: "transparent"
                PathPolyline { path: win.patchPts }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: win.t > 0.02 ? Theme.border : "transparent"
                strokeWidth: 1
                PathPolyline { path: win.patchEdge }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: win.holeRect ? Theme.border : "transparent"
                strokeWidth: 1
                PathPolyline { path: win.holePts }
            }
        }

        Shape {
            anchors.fill: parent
            visible: !win.flush && win.t >= 1
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                fillColor: Theme.panelBase
                strokeColor: "transparent"
                PathMultiline { paths: win.joinedRings }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: Theme.border
                strokeWidth: 1
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: win.joinedPts }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: win.holeRect ? Theme.border : "transparent"
                strokeWidth: 1
                PathPolyline { path: win.holePts }
            }
        }

        Item {
            id: railHit
            x: win.railX0
            y: win.railY
            width: win.railW
            height: win.railLen

            HoverHandler { id: hRail }
            PanelRailItems { anchors.fill: parent; flush: win.flush; screenName: win.screenName }
        }

        Item {
            id: barHit
            visible: !win.flush
            x: win.barL
            y: win.bt
            width: win.flush ? 0 : win.barW
            height: win.flush ? 0 : win.thick

            HoverHandler { id: hBar }
            Loader {
                active: !win.flush
                x: win.t * win.thick
                width: win.barLen
                height: win.thick
                sourceComponent: PanelBarItems { screenName: win.screenName }
            }
        }

        // Top-edge hot zone that opens the dashboard.
        Item {
            id: hotZone
            readonly property bool on: win.flush && Theme.cfg.dashboard.hotZone
            x: (win.width - width) / 2
            y: 0
            width: on ? 260 : 0
            height: on ? Math.max(win.fw, 4) : 0

            HoverHandler {
                id: hHot
                enabled: hotZone.on
                onHoveredChanged: {
                    if (hovered) PanelState.hoverOpen("dashboard", -1, win.screenName, 250)
                    else PanelState.hoverCancel("dashboard")
                }
            }
        }

        // Right-edge hot zone that opens the control center.
        Item {
            id: hotZoneRight
            readonly property bool on: win.flush && Theme.cfg.dashboard.controlHotZone
            readonly property real w: on ? Math.max(win.fw, 4) : 0
            x: win.width - w
            y: (win.height - height) / 2
            width: w
            height: on ? 260 : 0

            HoverHandler {
                id: hHotRight
                enabled: hotZoneRight.on
                onHoveredChanged: {
                    if (hovered) PanelState.hoverOpen("control", -1, win.screenName, 250)
                    else PanelState.hoverCancel("control")
                }
            }
        }

        // Top-right corner hot zone that opens the notification center. It stays inside the rounded frame corner,
        // so it does not take clicks away from windows.
        Item {
            id: hotZoneCorner
            readonly property bool on: win.flush && Theme.cfg.dashboard.notifHotZone
            readonly property real size: on ? Math.max(win.fw, 4) + 16 : 0
            x: win.width - size
            y: 0
            width: size
            height: size

            HoverHandler {
                enabled: hotZoneCorner.on
                onHoveredChanged: {
                    if (hovered) PanelState.hoverOpen("notifs", 0, win.screenName, 200)
                    else PanelState.hoverCancel("notifs")
                }
            }
        }

        // Bottom-edge hot zone that opens the utility branch (search and calculator).
        Item {
            id: hotZoneBottom
            readonly property bool on: win.flush && Theme.cfg.dashboard.utilityHotZone
            readonly property real h: on ? Math.max(win.fw, 4) : 0
            x: (win.width - width) / 2
            y: win.height - h
            width: on ? 260 : 0
            height: h

            HoverHandler {
                id: hHotBottom
                enabled: hotZoneBottom.on
                onHoveredChanged: {
                    if (hovered) PanelState.hoverOpen("utility", -1, win.screenName, 250)
                    else PanelState.hoverCancel("utility")
                }
            }
        }

        Item {
            id: holeItem
            x: win.holeRect ? win.holeRect.x : 0
            y: win.holeRect ? win.holeRect.y : 0
            width: win.holeRect ? win.holeRect.w : 0
            height: win.holeRect ? win.holeRect.h : 0
        }

        BranchSlot { id: railSlot; host: win; edge: "rail" }
        BranchSlot { id: topSlot; host: win; edge: "top" }
        BranchSlot { id: rightSlot; host: win; edge: "right" }
        BranchSlot { id: bottomSlot; host: win; edge: "bottom" }
        BranchSlot { id: barSlot; host: win; edge: "bar" }

        // Paint mode of the color picker (the topmost layer of the scene).
        PaintLayer { anchors.fill: parent; scene: scene; rail: railHit }
    }
}
