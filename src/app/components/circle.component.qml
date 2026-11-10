// ============================================================================
// File: components/circle.component.qml
// Purpose: Circular launcher button executing a two-phase orthogonal flight trajectory with liquid squash-and-stretch physics.
// Public API:
//   - Properties: ctl, stripH, vertical, side, slot, panelId, title, glyph, panel, diameter, spacing, innerOffset ...
//   - Functions:  clamp01(v), easeInOut(t)
// Dependencies: QtQuick, "../styles"
// ============================================================================
import QtQuick
import "../styles"

// Base of the six circles (they live on the left bar). See circles/*.qml for the individual
// ones; any property below can be overridden in a single circle's file
// (e.g. `diameter: 36` in CircleUpInner.qml).
//
// Click: the circle flies out and along the bar to the middle as a bubble, opens into the
// panel, and flies back home when the panel closes.
Item {
    id: root

    // ── input from the parent ──
    required property var ctl
    property real stripH: 6           // thickness of the strip it sits next to

    // ── what it is ──
    property bool vertical: false     // true = on a vertical (left) bar
    property string side: "up"        // "left" | "right" (horizontal bar) · "up" | "down" (vertical bar)
    property int slot: 0              // 0 = outermost … 2 = closest to the island
    property string panelId: ""
    property string title: ""
    property string glyph: ""
    property bool alwaysShowGlyph: false
    property Component panel: null    // what opens when clicked

    // ── style ──
    property real diameter: CircleStyle.diameter
    property real spacing: CircleStyle.spacing         // distance between circle centres
    property real innerOffset: CircleStyle.innerOffset    // bar centre -> centre of the innermost circle
    property real topGap: CircleStyle.topGap           // gap between the strip and the circle
    property color fill: CircleStyle.fill
    property color borderColor: CircleStyle.borderColor
    property color glyphColor: CircleStyle.glyphColor
    property real glyphSize: CircleStyle.glyphFontPx
    property real hoverScale: CircleStyle.hoverScale
    property real spring: CircleStyle.hoverSpring
    property real damping: CircleStyle.hoverDamping
    property int travelDuration: CircleStyle.flightDurationMs  // flight to the middle / back

    readonly property bool hovered: ma.containsMouse
    readonly property bool mine: ctl.owner === panelId
    readonly property bool flying: (mine && (ctl.phase === "travelling" || ctl.phase === "returning")) || travelAnim.running
    property real effectiveStep: 2 - slot
    Behavior on effectiveStep { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    readonly property real offset: innerOffset + effectiveStep * spacing

    // 0 = home, 1 = at the middle of the bar
    property real travel: 0
    property bool _stoppingTravel: false

    function clamp01(v) { return Math.max(0, Math.min(1, v)) }
    function easeInOut(t) { return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2 }

    // Phase 1: Travels vertically along the bar to center height (travel 0.0 -> 0.60)
    readonly property real pA: clamp01(travel / CircleStyle.phase1End)
    readonly property real travelA: easeInOut(pA)

    // Phase 2: Travels horizontally into the middle (travel 0.50 -> 1.00)
    readonly property real pD: clamp01((travel - CircleStyle.phase2Start) / (1.0 - CircleStyle.phase2Start))
    readonly property real travelD: easeInOut(pD)

    // Liquid squash-and-stretch:
    // Stretches along A while moving vertically (pulseA), relaxes, then stretches slightly on D while moving horizontally (pulseD)
    readonly property real pulseA: flying ? Math.sin(pA * Math.PI) : 0
    readonly property real pulseD: flying ? Math.sin(pD * Math.PI) : 0
    readonly property real curLenA: diameter * (1.0 + 0.38 * pulseA - 0.12 * pD)
    readonly property real curLenD: diameter * (1.0 - 0.20 * pulseA + 0.15 * pulseD - 0.25 * pD)

    // "A" = along the bar (vertical Y), "D" = depth (horizontal X away from edge)
    readonly property real centerA: vertical ? parent.height / 2 : parent.width / 2
    readonly property real dirSign: (side === "left" || side === "up") ? -1 : 1
    readonly property real baseHomeA: centerA + dirSign * offset
    readonly property real curCenterA: baseHomeA + (centerA - baseHomeA) * travelA
    readonly property real curA: curCenterA - curLenA / 2

    // homeD: flush at the edge; midD: docking position at the center
    readonly property real homeD: stripH + topGap
    readonly property real midD: 0
    readonly property real curD: homeD + (midD - homeD) * travelD

    width: vertical ? curLenD : curLenA
    height: vertical ? curLenA : curLenD
    x: vertical ? curD : curA
    y: vertical ? curA : curD
    z: (mine || travelAnim.running || travel > 0.001) ? 10 : 0

    // invisible while anything else is open / animating or while floating; fades back in when returned
    opacity: root.isFloatingNow ? 0 : (ctl.busy ? (flying ? 1 : 0) : 1)
    visible: opacity > 0.01 || root.isDetaching
    Behavior on opacity { NumberAnimation { duration: CircleStyle.fadeDurationMs } }

    NumberAnimation {
        id: travelAnim
        target: root
        property: "travel"
        easing.type: Easing.InOutCubic
        onFinished: {
            if (root._stoppingTravel) return
            if (root.ctl.phase === "travelling") root.ctl.travelDone()
            else if (root.ctl.phase === "returning") root.ctl.returnDone()
        }
    }

    function returnHomeIfNeeded() {
        if (travelAnim.running && travelAnim.to === 0 && !root.mine) return
        root._stoppingTravel = true
        travelAnim.stop()
        root._stoppingTravel = false
        if (root.travel <= 0.001 || root.isFloatingNow) {
            root.travel = 0
            if (root.mine && root.ctl.phase === "returning") {
                Qt.callLater(function() {
                    if (root.mine && root.ctl.phase === "returning") root.ctl.returnDone()
                })
            }
        } else {
            travelAnim.from = root.travel
            travelAnim.to = 0
            travelAnim.duration = Math.max(60, Math.round(root.travelDuration * root.travel))
            travelAnim.restart()
        }
    }

    Connections {
        target: root.ctl
        function onPhaseChanged() {
            if (!root.mine) {
                if (root.travel > 0.001) root.returnHomeIfNeeded()
                return
            }
            if (root.ctl.phase === "travelling") {
                root._stoppingTravel = true
                travelAnim.stop()
                root._stoppingTravel = false
                if (root.travel >= 0.999) {
                    root.travel = 1
                    Qt.callLater(function() {
                        if (root.mine && root.ctl.phase === "travelling") root.ctl.travelDone()
                    })
                } else {
                    travelAnim.from = root.travel
                    travelAnim.to = 1
                    travelAnim.duration = Math.max(60, Math.round(root.travelDuration * (1 - root.travel)))
                    travelAnim.restart()
                }
            } else if (root.ctl.phase === "returning") {
                root.returnHomeIfNeeded()
            } else if (root.ctl.phase === "closed") {
                root.returnHomeIfNeeded()
            } else if (root.ctl.phase === "open" || root.ctl.phase === "expanding") {
                root._stoppingTravel = true
                travelAnim.stop()
                root._stoppingTravel = false
                root.travel = 1
            }
        }
        function onOwnerChanged() {
            if (root.mine && (root.ctl.phase === "open" || root.ctl.phase === "expanding")) {
                root._stoppingTravel = true
                travelAnim.stop()
                root._stoppingTravel = false
                root.travel = 1
            } else if (!root.mine && root.travel > 0.001) {
                root.returnHomeIfNeeded()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Math.min(width, height) / 2
        color: root.fill
        border.width: root.flying ? 0 : 1.2
        border.color: root.borderColor
        Behavior on border.width { NumberAnimation { duration: 120 } }

        scale: root.hovered && !root.ctl.busy ? root.hoverScale : 1.0
        Behavior on scale { SpringAnimation { spring: root.spring; damping: root.damping; epsilon: 0.002 } }

        // Liquid glass multi-stop spherical refraction sheen
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: CircleStyle.transparent
            gradient: Gradient {
                GradientStop { position: 0.0; color: CircleStyle.glassSheenTop }
                GradientStop { position: 0.35; color: CircleStyle.glassSheenMid }
                GradientStop { position: 0.70; color: CircleStyle.glassSheenCore }
                GradientStop { position: 1.0; color: CircleStyle.glassSheenBottom }
            }
        }

        // 3D inner refractive bevel ring
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: CircleStyle.transparent
            border.width: root.flying ? 0 : 1.5
            border.color: CircleStyle.glassInnerBevel
        }

        Text {
            anchors.centerIn: parent
            text: root.glyph
            color: root.glyphColor
            font.family: "Symbols Nerd Font"
            font.pixelSize: root.glyphSize
            opacity: !root.flying && !root.ctl.busy ? (root.hovered ? 1.0 : (root.alwaysShowGlyph ? CircleStyle.glyphHoverOpacity : 0.0)) : 0.0
            Behavior on opacity { NumberAnimation { duration: CircleStyle.glyphFadeDurationMs } }
        }
    }

    property var floatManager: null
    property real pressGlobalX: 0
    property real pressGlobalY: 0
    property bool isDetaching: false

    readonly property bool isFloatingNow: floatManager ? floatManager.isFloating(root.panelId) : false

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.isFloatingNow || root.isDetaching
        cursorShape: root.isFloatingNow ? Qt.ArrowCursor : Qt.PointingHandCursor

        onPressed: function(mouse) {
            var pt = mapToItem(null, mouse.x, mouse.y)
            root.pressGlobalX = pt.x
            root.pressGlobalY = pt.y
            root.isDetaching = false
        }

        onPositionChanged: function(mouse) {
            if (!pressed || root.ctl.busy || (root.isFloatingNow && !root.isDetaching)) return
            var pt = mapToItem(null, mouse.x, mouse.y)
            var dx = pt.x - root.pressGlobalX
            var dy = pt.y - root.pressGlobalY

            if (!root.isDetaching && root.floatManager && (dx > CircleStyle.detachThresholdX || Math.hypot(dx, dy) > CircleStyle.detachThresholdHypot)) {
                root.isDetaching = true
                root.floatManager.startDrag({
                    id: root.panelId,
                    title: root.title,
                    icon: "󰄯",
                    originSide: "left",
                    originX: 0,
                    originY: root.y,
                    width: CircleStyle.floatWidth,
                    height: CircleStyle.floatHeight,
                    panel: root.panel,
                    ctl: root.ctl
                }, pt.x, pt.y)
            } else if (root.isDetaching && root.floatManager) {
                root.floatManager.updateDrag(pt.x, pt.y)
            }
        }

        function finishCircleDetach() {
            if (root.isDetaching) {
                root.isDetaching = false
                if (root.floatManager) root.floatManager.endDrag()
            }
        }

        onReleased: {
            if (root.isDetaching) {
                finishCircleDetach()
            } else {
                if (root.ctl.busy) return
                if (root.isFloatingNow && root.floatManager) {
                    root.floatManager.closeWindow(root.panelId)
                    return
                }
                root.ctl.open({
                    id: root.panelId, host: "island", kind: "click", travels: true,
                    title: root.title, panel: root.panel,
                    bubbleLen: root.diameter * 0.88, bubbleDepth: root.diameter * 0.75
                })
            }
        }

        onCanceled: finishCircleDetach()
    }
}
