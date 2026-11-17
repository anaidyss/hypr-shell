import QtQuick
import qs.theme
import qs.services
import qs.components

// One branch of the panel on one edge: it follows what PanelState wants on that edge, grows and retracts, and loads
// the Branch<Kind>.qml of the kind it shows. The panel window has one slot per edge, so with several menus held open
// (PanelState.multi) each edge keeps its own. `geom` is the branch outline the frame shape is built from.
Item {
    id: slot

    // The panel window, which owns the frame metrics, and the edge this slot grows from: rail, top, right, bottom or bar.
    required property var host
    required property string edge

    readonly property bool onRail: edge === "rail"
    readonly property bool onTop: edge === "top"
    readonly property bool onRight: edge === "right"
    readonly property bool onBottom: edge === "bottom"
    readonly property bool onBar: edge === "bar"

    readonly property bool askedHere: PanelState.screenName === host.screenName
    readonly property string asked: askedHere ? PanelState.kindFor(edge) : ""
    readonly property string wantKind: asked !== "" ? asked
        : (edge === host.toastEdge && !(askedHere && PanelState.any) && Toasts.active ? "toast" : "")

    property string shownKind: ""
    // 0 is retracted, 1 is fully grown. One animation drives it, and its easing and duration are set at the moment
    // it starts: a Behavior reads them from bindings that may not have been re-evaluated yet, which made a branch
    // sometimes open with the closing curve.
    property real p: 0
    // Content of a branch that was swapped in place: 0 right after the swap, back to 1 as it fades in.
    property real swap: 1

    // Runs from onWantKindChanged, where derived bindings may still hold old values, so it reads wantKind only.
    function drive() {
        // Another branch is wanted while this one is shown: it retracts first (briskly) and the new one grows afterwards.
        let swapping = wantKind !== "" && shownKind !== wantKind
        // Two branches of the left strip (a category flyout and one of its options) morph into each other: the
        // outline keeps its place and glides to the new size while the new content fades in.
        if (swapping && shownKind !== "" && p > 0.5 && PanelState.isRail(shownKind) && PanelState.isRail(wantKind)) {
            swap = 0
            shownKind = wantKind
            swapAnim.restart()
            swapping = false
        }
        if (swapping && p <= 0.001) {
            shownKind = wantKind
            swapping = false
        }
        const to = wantKind !== "" && shownKind === wantKind ? 1 : 0
        if (pAnim.running && pAnim.to === to) return
        pAnim.stop()
        if (p === to) return
        pAnim.from = p
        pAnim.to = to
        // Opening ends softly (ease-out). Closing accelerates into the panel: ease-out on the way back would leave a thin slab lingering for the last frames.
        pAnim.easing.type = to === 1 ? Theme.easingOpen : Easing.InCubic
        pAnim.easing.overshoot = Theme.overshoot
        // A reversal from the middle only has the rest of the distance to cover.
        pAnim.duration = Math.round((to === 1 ? Theme.durOpen : (swapping ? Theme.durFast : Theme.durNormal)) * Math.max(0.4, Math.abs(to - p)))
        pAnim.start()
    }

    NumberAnimation { id: swapAnim; target: slot; property: "swap"; from: 0; to: 1; duration: Theme.durNormal; easing.type: Theme.easingCalm }

    NumberAnimation {
        id: pAnim
        target: slot
        property: "p"
        onFinished: {
            // Fully retracted: forget the dashboard tab, and let a waiting branch grow.
            if (slot.p <= 0.001 && slot.shownKind === "dashboard") PanelState.dashTab = 0
            slot.drive()
        }
    }

    onWantKindChanged: drive()

    readonly property real bw: loader.item ? loader.item.implicitWidth : 0
    readonly property real bh: loader.item ? loader.item.implicitHeight : 0
    readonly property bool branchOn: p > 0.005 && bw > 0

    property real bwA: bw
    property real bhA: bh
    Behavior on bwA { enabled: slot.p > 0.5; NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
    Behavior on bhA { enabled: slot.p > 0.5; NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }

    readonly property real anchorV: PanelState.anchorFor(edge)
    readonly property real aBar: wantKind === "toast" || anchorV < 0 ? host.barL + host.barW / 2 : anchorV
    readonly property real aRail: anchorV < 0 ? host.railY + host.railLen / 2 : anchorV
    // A bar branch that would sit in the corner zone of the bar becomes flush with that end of the bar.
    readonly property real wantLeft: aBar - bw / 2
    readonly property bool flushL: onBar && host.t < 0.001 && wantLeft <= host.barL + 2 * host.rad
    readonly property bool flushR: onBar && !flushL && wantLeft + bw >= host.barR - 2 * host.rad
    readonly property real bxT: onRight
        ? host.width - host.fw - bw
        : (onTop || onBottom
            ? Math.max(host.railX1 + 2 * host.rad, Math.min(host.width - host.fw - 2 * host.rad - bw, host.width / 2 - bw / 2))
            : (flushL ? host.barL : (flushR ? host.barR - bw
                : Math.max(host.barL + 2 * host.rad + host.t * host.thick, Math.min(host.barR - 2 * host.rad - bw, wantLeft)))))
    // A right branch is centered unless it asks for a point along the edge; the notification center always hangs at the top.
    readonly property real anchorRight: shownKind === "notifs" ? 0 : anchorV
    readonly property real byT: onRight
        ? Math.max(host.fw + 2 * host.rad, Math.min(host.height - host.fw - 2 * host.rad - bh, anchorRight < 0 ? (host.height - bh) / 2 : anchorRight - bh / 2))
        : Math.max(host.railY + 2 * host.rad, Math.min(host.railBottom - 2 * host.rad - bh, aRail - bh / 2))

    property real bxA: bxT
    property real byA: byT
    Behavior on bxA { enabled: slot.p > 0.5; NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
    Behavior on byA { enabled: slot.p > 0.5; NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }

    // Across the panel edge the tip radius and the concave fillets fold to zero as the branch retracts (fillets first); along it they stay full.
    readonly property real ext: onRail ? bwA * p : bhA * p
    readonly property real rad: host.rad
    readonly property real re: Math.min(rad, ext)
    readonly property real rf: Math.max(0, Math.min(rad, ext - rad))

    // Along the panel edge the branch also shrinks to just its corner radii in the last stretch, so no thin full-length slab is left.
    readonly property real kAlong: Math.min(1, ext / rad)
    function shrunk(len) { return 2 * rad + Math.max(0, len - 2 * rad) * kAlong }
    readonly property real railLenS: shrunk(bhA)
    readonly property real barLenS: shrunk(bwA)
    readonly property real barX0: bxA + (bwA - barLenS) * (flushL ? 0 : (flushR ? 1 : 0.5))

    // The outline of the branch for the frame shape; null while retracted.
    readonly property var geom: {
        if (!branchOn) return null
        if (onRail) return { y: byA + (bhA - railLenS) / 2, y2: byA + (bhA + railLenS) / 2, x2: host.railX1 + bwA * p, ra: rad, re: re, rf: rf }
        if (onRight) return { y: byA + (bhA - railLenS) / 2, y2: byA + (bhA + railLenS) / 2, x2: host.width - host.fw - bwA * p, ra: rad, re: re, rf: rf }
        if (onTop) return { x: bxA + (bwA - barLenS) / 2, x2: bxA + (bwA + barLenS) / 2, y2: host.fw + bhA * p, ra: rad, re: re, rf: rf }
        if (onBottom) return { x: bxA + (bwA - barLenS) / 2, x2: bxA + (bwA + barLenS) / 2, y: host.height - host.fw - bhA * p, ra: rad, re: re, rf: rf }
        return { x: barX0, x2: barX0 + barLenS, y: host.bt - bhA * p, ra: rad, re: re, rf: rf, flushL: flushL, flushR: flushR }
    }

    // Origin of the branch content in window coordinates (content is anchored to the panel side).
    readonly property point origin: onRail ? Qt.point(host.railX1, byA)
        : (onRight ? Qt.point(host.width - host.fw - bwA, byA)
        : (onTop ? Qt.point(bxA, host.fw)
        : (onBottom ? Qt.point(bxA, host.height - host.fw - bhA) : Qt.point(bxA, host.bt - bhA))))

    // Mini terminal: the branch frames a hole, the real terminal window shows through it.
    readonly property bool termOpen: shownKind === "term" && wantKind === "term" && p > 0.97 && loader.item !== null
    readonly property var holeRect: termOpen ? {
        x: origin.x + loader.item.hole.x, y: origin.y + loader.item.hole.y, w: loader.item.hole.width, h: loader.item.hole.height
    } : null

    readonly property real holeGap: loader.item && loader.item.holeGap !== undefined ? loader.item.holeGap : 12

    // The box that clips the branch and takes the pointer.
    readonly property alias box: box
    readonly property bool hovered: hBox.hovered

    anchors.fill: parent

    Item {
        id: box
        visible: slot.branchOn
        clip: true
        x: slot.onRail ? host.railX1 : (slot.onRight ? host.width - host.fw - slot.bwA * slot.p : slot.bxA)
        y: slot.onRail ? slot.byA : (slot.onTop ? host.fw : (slot.onRight ? slot.byA : (slot.onBottom ? host.height - host.fw - slot.bhA * slot.p : host.bt - slot.bhA * slot.p)))
        width: (slot.onRail || slot.onRight) ? slot.bwA * slot.p : slot.bwA
        height: slot.onRail ? slot.bhA : (slot.onRight ? slot.bhA : slot.bhA * slot.p)

        HoverHandler { id: hBox }

        Loader {
            id: loader
            y: slot.onRail || slot.onTop || slot.onRight ? 0 : parent.height - height
            width: slot.bwA
            height: slot.bhA
            opacity: Math.max(0, (slot.p - 0.35) / 0.65) * slot.swap
            transform: Translate { y: (1 - slot.swap) * 12 }
            source: slot.shownKind === "" ? "" : "Branch" + slot.shownKind.charAt(0).toUpperCase() + slot.shownKind.slice(1) + ".qml"
        }

        // While several menus are held open, each one has its own close button in its corner.
        Surface {
            visible: PanelState.multi && slot.p > 0.9 && slot.shownKind !== "toast"
            opacity: hBox.hovered ? 1 : 0.5
            x: loader.x + loader.width - width - 8
            y: slot.onTop ? loader.y + loader.height - height - 8 : loader.y + 8
            width: 28; height: 28
            radius: 14
            borderWidth: 0
            color: closeTap.pressed ? Theme.panelHigh : (closeHover.hovered ? Theme.panelPill : Theme.panelRaised)
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
            Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }

            PanelIcon { anchors.centerIn: parent; name: "close"; size: 14; color: closeHover.hovered ? Theme.text : Theme.textDim }
            HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { id: closeTap; onTapped: PanelState.dismiss(slot.shownKind) }
        }
    }
}
