// ============================================================================
// File: components/side-bar.component.qml
// Purpose: Hover-triggered edge wing flyout container that spawns a travelling droplet and expands into a full-width top panel.
// Public API:
//   - Properties: ctl, barX, barW, stripH, side, trigger, fill, expandedH, expandedSlant, radius, flare, zoneInset ...
//   - Functions:  clamp01(v), request()
// Dependencies: QtQuick, "../styles"
// ============================================================================
import QtQuick
import "../styles"

// Shared logic of the left / right bar.
// Idle: only the thin strip shows (this item is just an invisible hover/click zone).
// Triggered: a bubble leaves the zone, travels along the bar to the middle, then opens into
// the full bar (on top of the circles). Closing plays the same thing backwards.
// Children go inside the expanded bar (see TopLeftBar.qml / TopRightBar.qml).
Item {
    id: root

    // ── input from the parent ──
    property var ctl: null
    property real barX: 0
    property real barW: 720
    property real stripH: 6
    property string side: "left"
    property bool isFloatingWindow: false
    property var floatingWindow: null
    property var extraData: null

    // ── behaviour ──
    property string trigger: "click"      // "hover" | "click"
                                          //   hover: opens after hoverDelay, closes when the mouse leaves it
                                          //   click:  opens on click, closes with Esc / click outside

    // ── style ──
    property color fill: SideBarStyle.fill
    property real expandedH: SideBarStyle.openHeight          // keep equal to MiddleBar.openH for a matching size
    property real expandedSlant: SideBarStyle.openSlant       // keep equal to MiddleBar.openSlant
    property real radius: SideBarStyle.dropRadius              // convex bottom corners
    property real flare: SideBarStyle.dropFlare               // concave corners into the monitor edge
    property real zoneInset: SideBarStyle.zoneInset          // idle zone stops this far from the screen centre
    property real hitHeight: SideBarStyle.hitHeight           // idle zone height (invisible, easier to hit)
    property real pillW: SideBarStyle.pillStartWidth          // middle pill width when strip has shrunk to center
    property real pillH: SideBarStyle.pillStartHeight         // middle pill height when strip has shrunk to center
    property real pillSlant: SideBarStyle.pillStartSlant      // middle pill slant when strip has shrunk to center
    property int hoverDelay: SideBarStyle.openDelayMs          // ms the mouse must rest before a hover opens it
    property int releaseDelay: SideBarStyle.closeDelayMs        // ms before it closes after the mouse leaves
    property int travelDuration: SideBarStyle.travelDurationMs      // smooth droplet glide to the middle / back
    property int openDuration: SideBarStyle.expandDurationMs        // fluid expansion
    property int closeDuration: SideBarStyle.collapseDurationMs       // smooth collapse

    default property alias content: drop.content
    readonly property alias maskItem: mouse

    readonly property bool isLeft: side === "left"
    readonly property string myId: side + "-bar"
    readonly property bool mine: (!isFloatingWindow && ctl) ? (ctl.owner === myId) : false
    readonly property bool isOwnPanelFloating: (!isFloatingWindow && floatManager) ? floatManager.isFloating("top-" + side) : false
    readonly property real floatWinWidth: Math.max(SideBarStyle.floatWidth, Math.round(barW))
    readonly property real floatWinHeight: Math.max(SideBarStyle.floatHeight, Math.round(expandedH + 60))

    property real travel: 0               // 0 = bubble at its origin, 1 = at the middle
    property real expand: 0               // 0 = bubble, 1 = full bar
    property real originX: 0

    readonly property real stripSegmentLen: Math.max(40, (barW - (ctl && ctl.busy ? 0 : MiddleBarStyle.idleLen)) / 2)
    readonly property real zoneW: stripSegmentLen
    readonly property real zoneX: isLeft ? barX : barX + barW - zoneW
    readonly property real cx: width / 2

    function clamp01(v) { return Math.max(0, Math.min(1, v)) }

    // Strip-shrink-to-middle-and-open geometry:
    // - During `travel` (0 -> 1): both strip wings shrink inward (`maxWingLen -> 0`) while the
    //   middle bar simultaneously animates UP into the top strip (`pillH -> collapsedH`).
    // - During `expand` (0 -> 1): from that tucked-up center state, it animates back DOWN and out
    //   as the open strip bar panel (`collapsedH -> expandedH`, `pillW -> barW`).
    readonly property real maxWingLen: Math.max(0, (barW - pillW) / 2)
    readonly property real curWingLen: expand > 0 ? 0 : maxWingLen * (1.0 - travel)
    readonly property real collapsedH: Math.max(2, stripH + 1)
    readonly property real baseH: pillH - (pillH - collapsedH) * travel
    readonly property real baseSlant: pillSlant * (1.0 - travel)

    readonly property real dw: pillW + (barW - pillW) * expand
    readonly property real dh: baseH + (expandedH - baseH) * expand

    function request() {
        if (isFloatingWindow || !ctl || isOwnPanelFloating) return
        originX = cx
        ctl.open({ id: myId, host: "own", kind: trigger, travels: true,
                   bubbleLen: pillW, bubbleDepth: pillH })
    }

    function getDetachState() {
        return null
    }

    // ───── hover handling ─────
    property bool raw: mouse.containsMouse
    property bool seenInside: false       // only close on leave after the mouse was seen inside the open bar

    onRawChanged: {
        if (isFloatingWindow || !ctl) return
        if (raw) {
            leaveTimer.stop()
            if (mine && ctl.phase === "open") seenInside = true
            if (trigger === "hover" && !ctl.busy && !isOwnPanelFloating) dwell.restart()
        } else {
            dwell.stop()
            if (trigger === "hover" && mine && ctl.phase === "open" && seenInside) leaveTimer.restart()
        }
    }
    Timer { id: dwell; interval: root.hoverDelay; onTriggered: { if (!root.isFloatingWindow && root.ctl && root.raw && !root.ctl.busy && !root.isOwnPanelFloating) root.request() } }
    Timer { id: leaveTimer; interval: root.releaseDelay; onTriggered: { if (!root.isFloatingWindow && root.ctl && root.mine && root.ctl.phase === "open" && !root.raw) root.ctl.close() } }

    // ───── animation driven by the controller ─────
    NumberAnimation {
        id: travelAnim
        target: root
        property: "travel"
        easing.type: Easing.InOutCubic
        onFinished: {
            if (!root.ctl) return
            if (root.ctl.phase === "travelling") root.ctl.travelDone()
            else if (root.ctl.phase === "returning") root.ctl.returnDone()
        }
    }
    NumberAnimation {
        id: expandAnim
        target: root
        property: "expand"
        onFinished: {
            if (!root.ctl) return
            if (root.ctl.phase === "expanding") root.ctl.expandDone()
            else if (root.ctl.phase === "collapsing") root.ctl.collapseDone()
        }
    }
    Connections {
        target: (!root.isFloatingWindow && root.ctl) ? root.ctl : null
        function onPhaseChanged() {
            if (!root.ctl || !root.mine) { root.seenInside = false; return }
            var ph = root.ctl.phase
            if (ph === "travelling") {
                travelAnim.stop(); travelAnim.to = 1; travelAnim.duration = root.travelDuration; travelAnim.restart()
            } else if (ph === "expanding") {
                expandAnim.stop(); expandAnim.to = 1; expandAnim.duration = root.openDuration
                expandAnim.easing.type = Easing.OutCubic; expandAnim.restart()
            } else if (ph === "open") {
                root.seenInside = root.raw
                if (root.trigger === "hover" && !root.raw && root.seenInside) leaveTimer.restart()
            } else if (ph === "collapsing") {
                // no bounce on the way back
                expandAnim.stop(); expandAnim.to = 0; expandAnim.duration = root.closeDuration
                expandAnim.easing.type = Easing.InOutCubic; expandAnim.restart()
            } else if (ph === "returning") {
                travelAnim.stop(); travelAnim.to = 0; travelAnim.duration = root.travelDuration; travelAnim.restart()
            }
        }
    }

    property var floatManager: null
    property real pressSceneX: 0
    property real pressSceneY: 0
    property bool isDetaching: false

    function beginDragCheck(sceneX, sceneY) {
        if (root.isFloatingWindow) return
        root.pressSceneX = sceneX
        root.pressSceneY = sceneY
        root.isDetaching = false
    }

    function moveDragCheck(sceneX, sceneY) {
        if (root.isFloatingWindow) return false
        var dy = sceneY - root.pressSceneY
        var dx = sceneX - root.pressSceneX
        if (!root.isDetaching && root.floatManager && (dy > SideBarStyle.detachThresholdY || Math.hypot(dx, dy) > SideBarStyle.detachThresholdHypot)) {
            root.isDetaching = true
            dwell.stop()
            leaveTimer.stop()
            root.floatManager.startDrag({
                id: "top-" + root.side,
                title: root.side === "left" ? "Active Processes" : "Performance",
                icon: root.side === "left" ? "󰍛" : "󰓅",
                originSide: "top",
                originX: root.cx,
                originY: 0,
                width: root.floatWinWidth,
                height: root.floatWinHeight,
                ctl: root.ctl,
                extraData: root.getDetachState()
            }, sceneX, sceneY)
        } else if (root.isDetaching && root.floatManager) {
            root.floatManager.updateDrag(sceneX, sceneY)
        }
        return root.isDetaching
    }

    function endDragCheck() {
        if (!root.isDetaching) return false
        root.isDetaching = false
        if (root.mine && root.ctl) {
            expandAnim.stop()
            travelAnim.stop()
            root.expand = 0
            root.travel = 0
            root.ctl.finish()
        }
        if (root.floatManager) root.floatManager.endDrag()
        return true
    }

    function cancelDragCheck() {
        if (!root.isDetaching) return
        root.isDetaching = false
        if (root.mine && root.ctl) {
            expandAnim.stop()
            travelAnim.stop()
            root.expand = 0
            root.travel = 0
            root.ctl.finish()
        }
        if (root.floatManager) root.floatManager.endDrag()
    }

    // below the shape so content inside the bar keeps working; it also swallows clicks,
    // so nothing underneath can be pressed through the open bar
    MouseArea {
        id: mouse
        visible: !root.isFloatingWindow
        enabled: !root.isFloatingWindow && ((!root.isOwnPanelFloating && (!root.ctl || !root.ctl.busy || root.mine)) || root.isDetaching)
        x: (root.mine || root.isDetaching) ? drop.x : root.zoneX
        y: 0
        width: (root.mine || root.isDetaching) ? drop.width : root.zoneW
        height: (root.mine || root.isDetaching) ? drop.height : root.hitHeight
        hoverEnabled: true
        cursorShape: (root.ctl && root.ctl.busy && !root.mine) ? Qt.ArrowCursor : Qt.PointingHandCursor

        onPressed: function(mouse) {
            var pt = mapToItem(null, mouse.x, mouse.y)
            root.beginDragCheck(pt.x, pt.y)
        }

        onPositionChanged: function(mouse) {
            if (!pressed) return
            var pt = mapToItem(null, mouse.x, mouse.y)
            root.moveDragCheck(pt.x, pt.y)
        }

        onReleased: {
            if (!root.endDragCheck()) {
                if (root.trigger === "click" && root.ctl && !root.ctl.busy && !root.isOwnPanelFloating) root.request()
            }
        }

        onCanceled: {
            root.cancelDragCheck()
        }
    }

    Drop {
        id: drop
        x: root.isFloatingWindow ? 0 : (root.cx - width / 2)
        y: 0
        width: root.isFloatingWindow ? Math.max(1, root.width) : Math.max(1, root.dw)
        height: root.isFloatingWindow ? Math.max(1, root.height) : Math.max(1, root.dh)
        fill: root.isFloatingWindow ? SideBarStyle.transparent : root.fill
        strokeColor: root.isFloatingWindow ? SideBarStyle.transparent : DropStyle.strokeColor
        tp: root.isFloatingWindow ? 0 : (root.stripH * (1 - root.expand))
        slant: root.isFloatingWindow ? 0 : (root.baseSlant + (root.expandedSlant - root.baseSlant) * root.expand)
        rad: root.isFloatingWindow ? 0 : root.radius
        flare: root.isFloatingWindow ? 0 : root.flare
        wingLen: root.isFloatingWindow ? 0 : root.curWingLen
        nearWingLen: root.isFloatingWindow ? 0 : ((root.floatManager && root.floatManager.isTopLeftFloating) ? 0 : root.curWingLen)
        farWingLen: root.isFloatingWindow ? 0 : ((root.floatManager && root.floatManager.isTopRightFloating) ? 0 : root.curWingLen)
        nearTpFactor: (!root.isFloatingWindow && root.floatManager && root.floatManager.isTopLeftFloating) ? 0 : 1
        farTpFactor: (!root.isFloatingWindow && root.floatManager && root.floatManager.isTopRightFloating) ? 0 : 1
        inset: root.isFloatingWindow ? 0 : Math.round(DropStyle.inset * (1 - root.expand * 0.5))
        bottomInset: root.isFloatingWindow ? 0 : DropStyle.bottomInset
        contentOpacity: root.isFloatingWindow ? 1 : root.clamp01((root.expand - 0.35) / 0.65)

        opacity: root.isFloatingWindow ? 1 : ((root.mine && !root.isDetaching) ? 1 : 0)
        visible: root.isFloatingWindow || opacity > 0.01 || root.isDetaching
    }

    // Moves the middle bar's idle clock text UP as the middle bar shrinks up during `travel`,
    // and brings it back DOWN as the middle bar unshrinks on close.
    Item {
        x: root.cx - root.pillW / 2
        y: root.stripH - (root.pillH - root.collapsedH) * root.travel
        width: root.pillW
        height: Math.max(0, root.pillH - root.stripH - 6)
        opacity: (!root.isFloatingWindow && root.mine && !root.isDetaching && root.expand <= 0.01) ? Math.max(0, 1 - root.travel * 1.35) : 0
        visible: opacity > 0.01 && root.ctl && root.ctl.now !== undefined

        Text {
            anchors.centerIn: parent
            text: (root.ctl && root.ctl.now) ? Qt.formatDateTime(root.ctl.now, "hh:mm:ss · dd/MM/yy") : ""
            color: SideBarStyle.textPrimary
            font.pixelSize: SideBarStyle.panelFontPx
            font.weight: Font.DemiBold
        }
    }
}
