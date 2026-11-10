// ============================================================================
// File: components/island.component.qml
// Purpose: Base three-state expandable container (idle pill -> hover pill -> open panel) with drag-to-detach support.
// Public API:
//   - Properties: ctl, vertical, stripH, panelId, title, clickPanel, fill, fg, dim, accent, dropRadius, dropFlare ...
//   - Functions:  clamp01(v)
// Dependencies: QtQuick, "../styles"
// ============================================================================
import QtQuick
import "../styles"

// Base of the "island": the pill in the middle of a bar. One shape that flows between states:
//   idle  -> the pill (children of the wrapper show their idle content)
//   hover -> a bigger pill (children can show more)
//   open  -> big panel (what a click opens, or a circle's panel; for a circle the shape starts
//            as the bubble that flew in from the circle)
// Used by MiddleBar.qml (clock, top bar) and WorkspaceIsland.qml (workspaces, left bar).
Item {
    id: root

    // ── input from the parent ──
    required property var ctl
    property bool vertical: false         // false: hangs from the top edge · true: from the left edge
    property real stripH: 6               // thickness of the strip it hangs from

    // ── what a click opens ──
    property string panelId: ""
    property string title: ""
    property Component clickPanel: null

    // ── style ──
    property color fill: IslandStyle.fill
    property color fg: IslandStyle.textPrimary
    property color dim: IslandStyle.textDim
    property color accent: IslandStyle.accent
    property real dropRadius: IslandStyle.radius          // convex corners
    property real dropFlare: IslandStyle.flare           // concave corners into the strip
    property real spring: IslandStyle.hoverSpring             // fast, responsive fluid spring
    property real damping: IslandStyle.hoverDamping
    property int releaseDelay: IslandStyle.hoverReleaseMs
    property int openDuration: IslandStyle.openDurationMs        // fast, fluid expansion
    property int closeDuration: IslandStyle.closeDurationMs       // fast collapse

    // len = along the bar, depth = away from the edge
    property real idleLen: IslandStyle.idleLen
    property real idleDepth: IslandStyle.idleDepth           // idleDepth = strip + circle gap + circle diameter lines the bottoms up
    property real idleSlant: IslandStyle.idleSlant
    property real hoverLen: IslandStyle.hoverLen
    property real hoverDepth: IslandStyle.hoverDepth
    property real hoverSlant: IslandStyle.hoverSlant
    property real openLen: IslandStyle.openLen
    property real openDepth: IslandStyle.openDepth
    property real openSlant: IslandStyle.openSlant
    property real integratedStripSpan: 0
    property real nearWingVisibility: 1.0
    property real farWingVisibility: 1.0
    property real hoverScale: IslandStyle.hoverScale
    property real pressedScale: IslandStyle.pressedScale
    property int scaleAnimDurationMs: IslandStyle.scaleAnimDurationMs
    readonly property bool isPressed: mouse.pressed

    default property alias content: drop.content
    readonly property alias maskItem: maskBounds
    readonly property alias contentArea: drop.contentArea

    Item {
        id: maskBounds
        x: root.vertical ? drop.x : drop.x - (drop.width * (drop.scale - 1)) / 2
        y: root.vertical ? drop.y - (drop.height * (drop.scale - 1)) / 2 : drop.y
        width: Math.ceil(drop.width * drop.scale)
        height: Math.ceil(drop.height * drop.scale)
    }

    function clamp01(v) { return Math.max(0, Math.min(1, v)) }

    // ───── hover (idle <-> hover) ─────
    property bool raw: mouse.containsMouse
    property bool hot: false
    onRawChanged: { if (raw) { off.stop(); hot = true } else off.restart() }
    Timer { id: off; interval: root.releaseDelay; onTriggered: root.hot = false }

    // while something is open the hover state is frozen, so the shape doesn't change under the animation
    property string frozen: "idle"
    readonly property string baseMode: ctl.busy ? frozen : (hot ? "hover" : "idle")
    Connections {
        target: root.ctl
        function onBusyChanged() { if (root.ctl.busy) root.frozen = root.hot ? "hover" : "idle" }
    }

    property real baseLen: baseMode === "hover" ? hoverLen : idleLen
    property real baseDepth: baseMode === "hover" ? hoverDepth : idleDepth
    property real baseTop: stripH
    property real baseSlant: baseMode === "hover" ? hoverSlant : idleSlant
    Behavior on baseLen { SpringAnimation { spring: root.spring; damping: root.damping; epsilon: IslandStyle.hoverEpsilon } }
    Behavior on baseDepth { SpringAnimation { spring: root.spring; damping: root.damping; epsilon: IslandStyle.hoverEpsilon } }
    Behavior on baseTop { SpringAnimation { spring: root.spring; damping: root.damping; epsilon: IslandStyle.hoverEpsilon } }
    Behavior on baseSlant { SpringAnimation { spring: root.spring; damping: root.damping; epsilon: IslandStyle.hoverEpsilon } }

    property real hoverFade: baseMode === "hover" ? 1 : 0
    Behavior on hoverFade { NumberAnimation { duration: IslandStyle.hoverFadeDurationMs; easing.type: Easing.OutCubic } }

    // ───── open / close choreography ─────
    readonly property bool hosted: ctl.busy && ctl.host === "island"
    // a circle's panel starts as the bubble that flew in; a click on the island starts from the pill
    readonly property bool useBubble: hosted && ctl.ownerTravels && ctl.phase !== "travelling"
    readonly property bool isOwnPanelFloating: root.floatManager ? root.floatManager.isFloating(root.panelId) : false
    property real floatRetractProgress: isOwnPanelFloating ? 1.0 : 0.0
    Behavior on floatRetractProgress { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    // visible when idle, or while it draws the panel; invisible while anything else animates
    readonly property bool stageVisible: (!ctl.busy && !(root.vertical && root.isOwnPanelFloating && root.floatRetractProgress >= 0.999))
                                     || (hosted && (!ctl.ownerTravels || (ctl.phase !== "travelling" && ctl.phase !== "returning")))
    property real fade: stageVisible ? 1 : 0
    Behavior on fade {
        enabled: !root.useBubble && root.ctl.host === "island"
        NumberAnimation { duration: IslandStyle.fadeDurationMs; easing.type: Easing.OutCubic }
    }

    property real e: 0                    // 0 = pill / bubble, 1 = open panel
    property bool _stoppingExpand: false

    NumberAnimation {
        id: expandAnim
        target: root
        property: "e"
        onFinished: {
            if (root._stoppingExpand) return
            if (root.ctl.phase === "expanding") root.ctl.expandDone()
            else if (root.ctl.phase === "collapsing") root.ctl.collapseDone()
        }
    }
    Connections {
        target: root.ctl
        function onPhaseChanged() {
            if (root.ctl.host !== "island") return
            var ph = root.ctl.phase
            if (ph === "expanding") {
                root._stoppingExpand = true
                expandAnim.stop()
                root._stoppingExpand = false
                if (root.e >= 0.999) {
                    root.e = 1
                    Qt.callLater(function() {
                        if (root.ctl.phase === "expanding") root.ctl.expandDone()
                    })
                } else {
                    expandAnim.from = root.e
                    expandAnim.to = 1
                    expandAnim.duration = Math.max(40, Math.round(root.openDuration * (1 - root.e)))
                    expandAnim.easing.type = Easing.OutCubic
                    expandAnim.restart()
                }
            } else if (ph === "collapsing") {
                // smooth cubic collapse
                root._stoppingExpand = true
                expandAnim.stop()
                root._stoppingExpand = false
                if (root.e <= 0.001) {
                    root.e = 0
                    Qt.callLater(function() {
                        if (root.ctl.phase === "collapsing") root.ctl.collapseDone()
                    })
                } else {
                    expandAnim.from = root.e
                    expandAnim.to = 0
                    expandAnim.duration = Math.max(40, Math.round(root.closeDuration * root.e))
                    expandAnim.easing.type = Easing.InOutCubic
                    expandAnim.restart()
                }
            } else if (ph === "closed") {
                root._stoppingExpand = true
                expandAnim.stop()
                root._stoppingExpand = false
                if (!root.vertical && root.floatManager && root.floatManager.isFloating(root.panelId) && root.detachedFromOpen) {
                    // Keep e = 1 for horizontal MiddleBar while calendar is floating from open
                } else {
                    root.e = 0
                }
            }
        }
    }

    // for wrappers: how visible / how far along the idle and hover content should be
    readonly property real idleOpacity: useBubble ? 0 : Math.max(0, 1 - e * 2.5)
    readonly property real hoverOpacity: useBubble ? 0 : Math.max(0, (hoverFade - 0.2) / 0.8) * Math.max(0, 1 - e * 2.5)
    readonly property real hoverProgress: clamp01((baseDepth - idleDepth) / Math.max(1, hoverDepth - idleDepth))

    // where the shape starts (A) and where it ends (the open panel)
    readonly property real aLen: useBubble ? ctl.bubbleLen : baseLen
    readonly property real aDepth: useBubble ? ctl.bubbleDepth : baseDepth
    readonly property real aTop: useBubble ? 0 : baseTop
    readonly property real aSlant: useBubble ? 0 : baseSlant
    readonly property real aRad: useBubble ? ctl.bubbleDepth / 2 : dropRadius
    readonly property real aFlare: useBubble ? 0 : dropFlare

    readonly property real curLen: Math.max(1, aLen + (openLen - aLen) * e)
    readonly property real curDepth: Math.max(1, aDepth + (openDepth - aDepth) * e)
    readonly property real outerSpan: drop.la + 2 * drop.t

    property var floatManager: null
    property real pressSceneX: 0
    property real pressSceneY: 0
    property bool isDetachingIdle: false
    property bool isDetachingOpen: false
    readonly property bool isActivelyDetaching: isDetachingIdle || isDetachingOpen
    property bool detachedFromOpen: false
    property var savedOpenState: null

    Connections {
        target: root.floatManager
        function onWindowDocked(id) {
            if (id === root.panelId && root.detachedFromOpen && root.savedOpenState) {
                root._stoppingExpand = true
                expandAnim.stop()
                root._stoppingExpand = false
                root.e = 1
                root.ctl.restoreOpen(root.savedOpenState)
                root.detachedFromOpen = false
                root.savedOpenState = null
            } else if (root.savedOpenState && root.savedOpenState.id === id) {
                root.detachedFromOpen = false
                root.savedOpenState = null
            }
        }
        function onWindowClosed(id) {
            if (id === root.panelId || (root.savedOpenState && root.savedOpenState.id === id)) {
                root.detachedFromOpen = false
                root.savedOpenState = null
                root._stoppingExpand = true
                expandAnim.stop()
                root._stoppingExpand = false
                root.e = 0
                root.hot = false
                root.frozen = "idle"
                if (root.ctl.owner === id || root.ctl.owner === root.panelId) {
                    root.ctl.finish()
                }
            }
        }
    }

    // below the shape so buttons inside the panel keep working
    MouseArea {
        id: mouse
        x: drop.x
        y: drop.y
        width: drop.width
        height: drop.height
        scale: drop.scale
        transformOrigin: drop.transformOrigin
        hoverEnabled: true
        cursorShape: root.ctl.busy ? Qt.ArrowCursor : Qt.PointingHandCursor
        enabled: (!root.floatManager || !root.floatManager.isFloating(root.panelId)) || root.isDetachingIdle

        onPressed: function(mouse) {
            var pt = mapToItem(null, mouse.x, mouse.y)
            root.pressSceneX = pt.x
            root.pressSceneY = pt.y
            root.isDetachingIdle = false
        }

        onPositionChanged: function(mouse) {
            if (!pressed || root.ctl.busy) return
            var pt = mapToItem(null, mouse.x, mouse.y)
            var dx = pt.x - root.pressSceneX
            var dy = pt.y - root.pressSceneY
            var thresholdExceeded = root.vertical
                ? (dx > IslandStyle.detachThresholdAxis || Math.hypot(dx, dy) > IslandStyle.detachThresholdHypot)
                : (dy > IslandStyle.detachThresholdAxis || Math.hypot(dx, dy) > IslandStyle.detachThresholdHypot)

            if (!root.isDetachingIdle && root.floatManager && thresholdExceeded) {
                root.isDetachingIdle = true
                var pId = root.panelId
                var pTitle = root.title
                var pComp = root.clickPanel
                root.detachedFromOpen = false
                root.savedOpenState = null
                off.stop()
                root.hot = false
                var targetW = root.vertical ? IslandStyle.verticalFloatWidth : IslandStyle.horizontalFloatWidth
                var targetH = root.vertical ? IslandStyle.verticalFloatHeight : IslandStyle.horizontalFloatHeight
                root.floatManager.startDrag({
                    id: pId,
                    title: pTitle,
                    icon: root.vertical ? "󰍹" : "󰃭",
                    originSide: root.vertical ? "left" : "top",
                    originX: root.x,
                    originY: root.y,
                    width: targetW,
                    height: targetH,
                    panel: pComp,
                    ctl: root.ctl
                }, pt.x, pt.y)
            } else if (root.isDetachingIdle && root.floatManager) {
                root.floatManager.updateDrag(pt.x, pt.y)
            }
        }

        function finishIdleDetach() {
            if (root.isDetachingIdle) {
                root.isDetachingIdle = false
                if (root.floatManager) root.floatManager.endDrag()
            }
        }

        onReleased: {
            if (root.isDetachingIdle) {
                finishIdleDetach()
            } else {
                if (root.ctl.busy || root.clickPanel === null) return
                root.ctl.open({ id: root.panelId, host: "island", kind: "click", travels: false,
                                title: root.title, panel: root.clickPanel })
            }
        }

        onCanceled: finishIdleDetach()
    }

    Drop {
        id: drop
        vertical: root.vertical
        width: root.vertical ? root.curDepth : root.curLen
        height: root.vertical ? root.curLen : root.curDepth
        x: root.vertical ? 0 : (root.width - width) / 2
        y: root.vertical ? (root.height - height) / 2 : 0
        fill: root.fill
        tp: root.aTop * (1 - root.e)
        slant: root.aSlant + (root.openSlant - root.aSlant) * root.e
        rad: root.aRad + (root.dropRadius - root.aRad) * root.e
        flare: root.aFlare + (root.dropFlare - root.aFlare) * root.clamp01(root.e * 3)
        wingLen: root.integratedStripSpan > root.curLen ? (root.integratedStripSpan - root.curLen) / 2 : 0
        nearWingLen: wingLen * root.nearWingVisibility
        farWingLen: wingLen * root.farWingVisibility
        nearTpFactor: root.nearWingVisibility
        farTpFactor: root.farWingVisibility

        opacity: root.fade
        visible: opacity > 0.01 || root.isActivelyDetaching

        scale: (root.ctl.busy || root.isActivelyDetaching) ? 1.0 : (root.isPressed ? root.pressedScale : (root.raw ? root.hoverScale : 1.0))
        transformOrigin: root.vertical ? Item.Left : Item.Top
        Behavior on scale { NumberAnimation { duration: root.scaleAnimDurationMs } }

        transform: Translate {
            x: (root.vertical && !root.useBubble) ? -(root.curDepth + 10) * root.floatRetractProgress : 0
            y: (!root.vertical && !root.isActivelyDetaching) ? -(root.idleDepth + 10) * root.floatRetractProgress : 0
        }

        // ── open: title + the panel that was requested ──
        Item {
            id: openContent
            readonly property real alongDim: root.openLen - 2 * (root.openSlant + 12) - 36
            readonly property real depthDim: root.openDepth - 6 - 36
            width: root.vertical ? depthDim : alongDim
            height: root.vertical ? alongDim : depthDim
            x: root.vertical ? 18 : (parent.width - width) / 2
            y: root.vertical ? (parent.height - height) / 2 : 18
            opacity: root.clamp01((root.e - 0.35) / 0.65)
            visible: opacity > 0.01 || root.isDetachingOpen

            Item {
                id: titleRow
                width: parent.width
                height: IslandStyle.titlebarDragHeight

                property real pressTitleX: 0
                property real pressTitleY: 0
                property bool isDetachingOpen: false

                // Drag handle for detaching an open island panel
                MouseArea {
                    anchors.fill: parent
                    anchors.rightMargin: 32 // leave room for close button
                    cursorShape: Qt.SizeAllCursor
                    enabled: (root.ctl.phase === "open" && (!root.floatManager || !root.floatManager.isFloating(root.ctl.owner || root.panelId))) || root.isDetachingOpen

                    onPressed: function(mouse) {
                        var pt = mapToItem(null, mouse.x, mouse.y)
                        titleRow.pressTitleX = pt.x
                        titleRow.pressTitleY = pt.y
                        titleRow.isDetachingOpen = false
                        root.isDetachingOpen = false
                    }

                    onPositionChanged: function(mouse) {
                        if (!pressed) return
                        var pt = mapToItem(null, mouse.x, mouse.y)
                        var dx = pt.x - titleRow.pressTitleX
                        var dy = pt.y - titleRow.pressTitleY
                        var thresholdExceeded = root.vertical
                            ? (dx > IslandStyle.detachThresholdAxis || Math.hypot(dx, dy) > IslandStyle.detachThresholdHypot)
                            : (dy > IslandStyle.detachThresholdAxis || Math.hypot(dx, dy) > IslandStyle.detachThresholdHypot)

                        if (!titleRow.isDetachingOpen && root.floatManager && thresholdExceeded) {
                            titleRow.isDetachingOpen = true
                            root.isDetachingOpen = true
                            var pId = root.ctl.owner || root.panelId
                            var pTitle = root.ctl.shownTitle || root.title
                            var pComp = root.ctl.shownPanel || root.clickPanel
                            var targetW = root.vertical ? IslandStyle.verticalFloatWidth : IslandStyle.horizontalFloatWidth
                            var targetH = root.vertical ? IslandStyle.verticalFloatHeight : IslandStyle.horizontalFloatHeight

                            root.detachedFromOpen = true
                            root.savedOpenState = {
                                id: pId,
                                host: root.ctl.host || "island",
                                kind: root.ctl.ownerKind || "click",
                                travels: root.ctl.ownerTravels,
                                bubbleLen: root.ctl.bubbleLen,
                                bubbleDepth: root.ctl.bubbleDepth,
                                title: pTitle,
                                panel: pComp
                            }
                            root._stoppingExpand = true
                            expandAnim.stop()
                            root._stoppingExpand = false
                            root.e = (pId === root.panelId && !root.vertical) ? 1 : 0
                            root.hot = false
                            root.frozen = "idle"

                            root.floatManager.startDrag({
                                id: pId,
                                title: pTitle,
                                icon: root.vertical ? "󰍹" : "󰃭",
                                originSide: root.vertical ? "left" : "top",
                                originX: root.x,
                                originY: root.y,
                                width: targetW,
                                height: targetH,
                                panel: pComp,
                                ctl: root.ctl
                            }, pt.x, pt.y)
                        } else if (titleRow.isDetachingOpen && root.floatManager) {
                            root.floatManager.updateDrag(pt.x, pt.y)
                        }
                    }

                    function finishOpenDetach() {
                        if (titleRow.isDetachingOpen) {
                            titleRow.isDetachingOpen = false
                            root.isDetachingOpen = false
                            if (root.vertical || (root.ctl.owner && root.ctl.owner !== root.panelId)) {
                                root._stoppingExpand = true
                                expandAnim.stop()
                                root._stoppingExpand = false
                                root.e = 0
                            }
                            root.ctl.finish()
                            if (root.floatManager) root.floatManager.endDrag()
                        }
                    }

                    onReleased: finishOpenDetach()
                    onCanceled: finishOpenDetach()
                }

                Text {
                    text: root.ctl.shownTitle
                    color: root.accent
                    font.pixelSize: IslandStyle.titleFontPx
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.5
                    font.capitalization: Font.AllUppercase
                }
                Text {
                    id: closeBtn
                    anchors.right: parent.right
                    text: "✕"
                    color: closeBtnMouse.containsMouse ? root.accent : root.dim
                    scale: closeBtnMouse.pressed ? IslandStyle.closePressedScale : (closeBtnMouse.containsMouse ? IslandStyle.closeHoverScale : 1.0)
                    font.pixelSize: IslandStyle.closeIconFontPx
                    Behavior on color { ColorAnimation { duration: IslandStyle.closeAnimDurationMs } }
                    Behavior on scale { NumberAnimation { duration: IslandStyle.closeAnimDurationMs; easing.type: Easing.OutCubic } }
                    MouseArea {
                        id: closeBtnMouse
                        anchors.fill: parent
                        anchors.margins: -10
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.ctl.close()
                    }
                }
            }

            Loader {
                anchors.top: titleRow.bottom
                anchors.topMargin: 12
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                sourceComponent: root.ctl.shownPanel
            }
        }
    }
}
