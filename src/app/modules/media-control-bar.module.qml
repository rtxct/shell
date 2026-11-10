// ============================================================================
// File: modules/media-control-bar.module.qml
// Purpose: Bottom-right media and volume controller with merging volume/mic circles and live PipeWire audio peak perimeter wave.
// Public API:
//   - Properties: audio, floatManager, fg, dim, accent, fill, danger, btnWidth, btnDepth, circleSize, circleSpacing, mergedMode ...
//   - Functions:  openMerged(mode), closeMerged(), currentAudioIcon(), currentVolume(), currentRatio(), handleWheel(wheel)
// Dependencies: QtQuick, "../components", "../styles", "../theme", QtQuick.Shapes
// ============================================================================
import QtQuick
import "../components"
import "../styles"
import "../../../themes"
import QtQuick.Shapes

// Bottom right media control bar with Volume and Microphone circles on the left side
// and audio controls (previous, play/pause, next) inside the Drop island.
// When the Volume or Mic circles are clicked, they animate and merge with the right bar
// into a single horizontal slider showing the audio icon, track, and percentage.
// When the mouse leaves the merged bar, it smoothly returns to the original 2 buttons + bar.
Item {
    id: root

    required property var audio
    property var floatManager: null

    property color fg: MediaControlBarStyle.textPrimary
    property color dim: MediaControlBarStyle.textDim
    property color accent: MediaControlBarStyle.accent
    property color fill: MediaControlBarStyle.fill
    property color danger: MediaControlBarStyle.danger

    // ── Dimensions ──
    property real btnWidth: MediaControlBarStyle.mediaBaseWidth
    property real btnDepth: MediaControlBarStyle.barHeight
    property real circleSize: MediaControlBarStyle.circleDiameter
    property real circleSpacing: MediaControlBarStyle.circleSpacing

    width: circleSize + circleSpacing + circleSize + MediaControlBarStyle.dropGap + btnWidth
    height: btnDepth

    readonly property alias borderVisualizerRef: borderVisualizer
    readonly property alias dropMediaRef: dropMedia

    // ── Merged Audio Controller State ──
    // Mode: "" (unmerged: 2 buttons + media island)
    //       "output" (merged horizontal volume slider)
    //       "input"  (merged horizontal microphone slider)
    property string mergedMode: ""
    readonly property bool isMerged: mergedMode !== ""

    function openMerged(mode) {
        mergedMode = mode
        unmergeTimer.restart()
    }

    function closeMerged() {
        mergedMode = ""
    }

    HoverHandler {
        id: barHover
        target: root
        enabled: true
        onHoveredChanged: {
            if (hovered) {
                unmergeTimer.stop()
            } else if (root.isMerged && !trackMouse.pressed) {
                unmergeTimer.restart()
            }
        }
    }

    // Timer to smoothly unmerge when mouse leaves the merged bar
    Timer {
        id: unmergeTimer
        interval: MediaControlBarStyle.autoUnmergeMs
        onTriggered: {
            if (!barHover.hovered && !mergedBarHover.hovered && !trackMouse.pressed) {
                root.closeMerged()
            }
        }
    }

    // ── Audio Helpers ──
    readonly property string currentAudioGlyph: {
        if (mergedMode === "output") {
            return circleVolume.iconGlyph
        } else if (mergedMode === "input") {
            return circleMic.iconGlyph
        }
        return "󰕾"
    }

    function currentAudioIcon() {
        return currentAudioGlyph
    }

    readonly property bool isCurrentMuted: {
        if (mergedMode === "output") {
            return root.audio ? root.audio.sinkMuted : false
        } else if (mergedMode === "input") {
            return root.audio ? root.audio.sourceMuted : false
        }
        return false
    }

    function currentVolume() {
        if (mergedMode === "output") {
            return root.audio ? root.audio.sinkVolume : 1.0
        } else if (mergedMode === "input") {
            return root.audio ? root.audio.sourceVolume : 1.0
        }
        return 1.0
    }

    function currentRatio() {
        var v = currentVolume()
        return Math.max(0.0, Math.min(1.0, v))
    }

    function wheelStep() {
        return (root.audio && root.audio.wheelStep > 0) ? root.audio.wheelStep : MediaControlBarStyle.wheelVolumeStep
    }

    function handleWheel(wheel) {
        if (!root.audio) return
        var step = root.wheelStep()
        var delta = wheel.angleDelta.y > 0 ? step : -step
        if (mergedMode === "output") {
            root.audio.setSinkVolume(root.audio.sinkVolume + delta)
        } else if (mergedMode === "input") {
            root.audio.setSourceVolume(root.audio.sourceVolume + delta)
        }
    }

    // ── Mask items for Wayland LayerShell input registration ──
    readonly property Item maskItem: barMask
    readonly property Item volMask: dummyMask
    readonly property Item micMask: dummyMask

    readonly property bool isSoundFloating: root.floatManager ? root.floatManager.isSoundFloating : false
    readonly property bool isVolumeBarFloating: root.floatManager ? root.floatManager.isVolumeBarFloating : false
    readonly property bool isMicBarFloating: root.floatManager ? root.floatManager.isMicBarFloating : false
    readonly property real dropIdleX: root.circleSize * 2 + root.circleSpacing + MediaControlBarStyle.dropGap
    readonly property real floatedCirclesStartX: dropIdleX + (root.btnWidth - (root.circleSize * 2 + root.circleSpacing)) / 2
    readonly property real floatedSingleCircleX: dropIdleX + (root.btnWidth - root.circleSize) / 2

    Item {
        id: barMask
        x: (root.isSoundFloating && !root.isMerged && !dropDragArea.isDetaching) ? circleVolume.x : 0
        y: 0
        width: (root.isSoundFloating && !root.isMerged && !dropDragArea.isDetaching)
               ? (circleMic.x + circleMic.width - circleVolume.x)
               : root.width
        height: root.height
    }

    Item {
        id: dummyMask
        width: 0
        height: 0
    }

    // ────────────────────────────────────────────────────────────────
    // 1. LEFTMOST CIRCLE: Volume Output
    // ────────────────────────────────────────────────────────────────
    Rectangle {
        id: circleVolume
        x: (root.isSoundFloating && !root.isMerged)
           ? (root.isMicBarFloating ? root.floatedSingleCircleX : root.floatedCirclesStartX)
           : 0
        anchors.verticalCenter: parent.verticalCenter
        width: root.circleSize
        height: root.circleSize
        radius: width / 2
        color: volCircleMouse.containsMouse ? MediaControlBarStyle.circleHoverBg : root.fill
        border.width: 1.2
        border.color: volCircleMouse.containsMouse ? root.accent : MediaControlBarStyle.circleIdleBorder

        scale: (root.isMerged || root.isVolumeBarFloating) ? MediaControlBarStyle.circleMergedScale : (volCircleMouse.pressed ? MediaControlBarStyle.circlePressedScale : 1.0)
        opacity: (root.isMerged || root.isVolumeBarFloating) ? 0.0 : 1.0
        visible: opacity > 0.01 || circleVolume.isDetaching
        enabled: (!root.isMerged && !root.isVolumeBarFloating) || circleVolume.isDetaching

        Behavior on x { NumberAnimation { duration: MediaControlBarStyle.circleMoveDurationMs; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: MediaControlBarStyle.colorAnimDurationMs } }
        Behavior on border.color { ColorAnimation { duration: MediaControlBarStyle.colorAnimDurationMs } }
        Behavior on scale { NumberAnimation { duration: MediaControlBarStyle.circleScaleDurationMs; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: MediaControlBarStyle.circleFadeDurationMs; easing.type: Easing.OutCubic } }

        // Liquid glass multi-stop spherical refraction sheen
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: MediaControlBarStyle.dropActiveStrokeColor
            gradient: Gradient {
                GradientStop { position: 0.0; color: MediaControlBarStyle.glassSheenTop }
                GradientStop { position: 0.35; color: MediaControlBarStyle.glassSheenMid }
                GradientStop { position: 0.70; color: MediaControlBarStyle.glassSheenCore }
                GradientStop { position: 1.0; color: MediaControlBarStyle.glassSheenBottom }
            }
        }

        // 3D inner refractive bevel ring
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: MediaControlBarStyle.dropActiveStrokeColor
            border.width: 1.5
            border.color: MediaControlBarStyle.glassInnerBevel
        }

        readonly property string iconGlyph: {
            if (!root.audio) return "󰕾"
            if (root.audio.sinkMuted) return "󰝟"
            var v = root.audio.sinkVolume
            if (v <= 0.01) return "󰕿"
            if (v < 0.5) return "󰖀"
            return "󰕾"
        }

        function volumeIcon() {
            return iconGlyph
        }

        Text {
            anchors.centerIn: parent
            text: circleVolume.iconGlyph
            font.family: "Symbols Nerd Font"
            font.pixelSize: MediaControlBarStyle.circleIconFontPx
            color: (!root.audio || root.audio.sinkMuted) ? root.danger
                   : (volCircleMouse.containsMouse ? root.accent : root.fg)
            Behavior on color { ColorAnimation { duration: MediaControlBarStyle.colorAnimDurationMs } }
        }

        property real pressSceneX: 0
        property real pressSceneY: 0
        property bool isDetaching: false

        MouseArea {
            id: volCircleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onPressed: function(mouse) {
                var pt = mapToItem(null, mouse.x, mouse.y)
                circleVolume.pressSceneX = pt.x
                circleVolume.pressSceneY = pt.y
                circleVolume.isDetaching = false
                if (mouse.button === Qt.RightButton) {
                    if (root.audio) root.audio.toggleSinkMute()
                }
            }

            onPositionChanged: function(mouse) {
                if (!pressed) return
                var pt = mapToItem(null, mouse.x, mouse.y)
                var dy = circleVolume.pressSceneY - pt.y

                if (!circleVolume.isDetaching && root.floatManager && (dy > MediaControlBarStyle.detachThresholdY || Math.hypot(pt.x - circleVolume.pressSceneX, dy) > MediaControlBarStyle.detachThresholdHypot)) {
                    circleVolume.isDetaching = true
                    root.floatManager.startDrag({
                        id: "volume-bar",
                        title: "Volume",
                        icon: "󰕾",
                        originSide: "bottom",
                        originX: root.x,
                        originY: root.y,
                        width: MediaControlBarStyle.floatBarWidth,
                        height: MediaControlBarStyle.floatBarHeight,
                        audio: root.audio,
                        extraData: { mode: "output" }
                    }, pt.x, pt.y)
                } else if (circleVolume.isDetaching && root.floatManager) {
                    root.floatManager.updateDrag(pt.x, pt.y)
                }
            }

            onReleased: function(mouse) {
                if (circleVolume.isDetaching) {
                    circleVolume.isDetaching = false
                    if (root.floatManager) root.floatManager.endDrag()
                } else if (mouse.button === Qt.LeftButton) {
                    root.openMerged("output")
                }
            }

            onWheel: function(wheel) {
                if (root.audio) {
                    var step = root.wheelStep()
                    var delta = wheel.angleDelta.y > 0 ? step : -step
                    root.audio.setSinkVolume(root.audio.sinkVolume + delta)
                }
            }
        }
    }

    // ────────────────────────────────────────────────────────────────
    // 2. MIDDLE CIRCLE: Microphone Input
    // ────────────────────────────────────────────────────────────────
    Rectangle {
        id: circleMic
        x: root.isMerged ? 0
           : (root.isSoundFloating
              ? (root.isVolumeBarFloating ? root.floatedSingleCircleX : (root.floatedCirclesStartX + root.circleSize + root.circleSpacing))
              : (root.circleSize + root.circleSpacing))
        anchors.verticalCenter: parent.verticalCenter
        width: root.circleSize
        height: root.circleSize
        radius: width / 2
        color: micCircleMouse.containsMouse ? MediaControlBarStyle.circleHoverBg : root.fill
        border.width: 1.2
        border.color: micCircleMouse.containsMouse ? root.accent : MediaControlBarStyle.circleIdleBorder

        scale: (root.isMerged || root.isMicBarFloating) ? MediaControlBarStyle.circleMergedScale : (micCircleMouse.pressed ? MediaControlBarStyle.circlePressedScale : 1.0)
        opacity: (root.isMerged || root.isMicBarFloating) ? 0.0 : 1.0
        visible: opacity > 0.01 || circleMic.isDetaching
        enabled: (!root.isMerged && !root.isMicBarFloating) || circleMic.isDetaching

        Behavior on x { NumberAnimation { duration: MediaControlBarStyle.circleMoveDurationMs; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: MediaControlBarStyle.colorAnimDurationMs } }
        Behavior on border.color { ColorAnimation { duration: MediaControlBarStyle.colorAnimDurationMs } }
        Behavior on scale { NumberAnimation { duration: MediaControlBarStyle.circleScaleDurationMs; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: MediaControlBarStyle.circleFadeDurationMs; easing.type: Easing.OutCubic } }

        // Liquid glass multi-stop spherical refraction sheen
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: MediaControlBarStyle.dropActiveStrokeColor
            gradient: Gradient {
                GradientStop { position: 0.0; color: MediaControlBarStyle.glassSheenTop }
                GradientStop { position: 0.35; color: MediaControlBarStyle.glassSheenMid }
                GradientStop { position: 0.70; color: MediaControlBarStyle.glassSheenCore }
                GradientStop { position: 1.0; color: MediaControlBarStyle.glassSheenBottom }
            }
        }

        // 3D inner refractive bevel ring
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: MediaControlBarStyle.dropActiveStrokeColor
            border.width: 1.5
            border.color: MediaControlBarStyle.glassInnerBevel
        }

        readonly property string iconGlyph: {
            if (!root.audio) return "󰍬"
            return root.audio.sourceMuted ? "󰍭" : "󰍬"
        }

        function micIcon() {
            return iconGlyph
        }

        Text {
            anchors.centerIn: parent
            text: circleMic.iconGlyph
            font.family: "Symbols Nerd Font"
            font.pixelSize: MediaControlBarStyle.circleIconFontPx
            color: (!root.audio || root.audio.sourceMuted) ? root.danger
                   : (micCircleMouse.containsMouse ? root.accent : root.fg)
            Behavior on color { ColorAnimation { duration: MediaControlBarStyle.colorAnimDurationMs } }
        }

        property real pressSceneX: 0
        property real pressSceneY: 0
        property bool isDetaching: false

        MouseArea {
            id: micCircleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onPressed: function(mouse) {
                var pt = mapToItem(null, mouse.x, mouse.y)
                circleMic.pressSceneX = pt.x
                circleMic.pressSceneY = pt.y
                circleMic.isDetaching = false
                if (mouse.button === Qt.RightButton) {
                    if (root.audio) root.audio.toggleSourceMute()
                }
            }

            onPositionChanged: function(mouse) {
                if (!pressed) return
                var pt = mapToItem(null, mouse.x, mouse.y)
                var dy = circleMic.pressSceneY - pt.y

                if (!circleMic.isDetaching && root.floatManager && (dy > MediaControlBarStyle.detachThresholdY || Math.hypot(pt.x - circleMic.pressSceneX, dy) > MediaControlBarStyle.detachThresholdHypot)) {
                    circleMic.isDetaching = true
                    root.floatManager.startDrag({
                        id: "mic-bar",
                        title: "Microphone",
                        icon: "󰍬",
                        originSide: "bottom",
                        originX: root.x,
                        originY: root.y,
                        width: MediaControlBarStyle.floatBarWidth,
                        height: MediaControlBarStyle.floatBarHeight,
                        audio: root.audio,
                        extraData: { mode: "input" }
                    }, pt.x, pt.y)
                } else if (circleMic.isDetaching && root.floatManager) {
                    root.floatManager.updateDrag(pt.x, pt.y)
                }
            }

            onReleased: function(mouse) {
                if (circleMic.isDetaching) {
                    circleMic.isDetaching = false
                    if (root.floatManager) root.floatManager.endDrag()
                } else if (mouse.button === Qt.LeftButton) {
                    root.openMerged("input")
                }
            }

            onWheel: function(wheel) {
                if (root.audio) {
                    var step = root.wheelStep()
                    var delta = wheel.angleDelta.y > 0 ? step : -step
                    root.audio.setSourceVolume(root.audio.sourceVolume + delta)
                }
            }
        }
    }

    // ────────────────────────────────────────────────────────────────
    // 3. LIVING LIQUID GLASS AUDIO VISUALIZER (Extended Island Perimeter)
    // ────────────────────────────────────────────────────────────────
    Canvas {
        id: borderVisualizer
        readonly property real padX: MediaControlBarStyle.wavePadX
        readonly property real padY: MediaControlBarStyle.wavePadY
        x: dropMedia.x - padX
        y: dropMedia.y - padY
        width: dropMedia.width + 2 * padX
        height: dropMedia.height + padY + MediaControlBarStyle.waveBottomPad

        property var pts: []
        property var nms: []
        property var hts: []
        property real currentMax: 0.0
        property real animTime: 0.0

        readonly property bool hasAudio: root.audio ? root.audio.hasAudio : false
        readonly property bool visualizerActive: !root.isMerged && !root.isSoundFloating && hasAudio
        readonly property bool shouldRun: visualizerActive || opacity > 0.01
        readonly property bool isVisualizerActive: visualizerActive || opacity > 0.01

        opacity: visualizerActive ? 1.0 : 0.0
        visible: opacity > 0.001
        Behavior on opacity { NumberAnimation { duration: MediaControlBarStyle.waveFadeDurationMs; easing.type: Easing.OutCubic } }

        function toCanvasRgba(c) {
            if (!c) return "rgba(0,0,0,0)"
            var r = Math.round((c.r || 0) * 255)
            var g = Math.round((c.g || 0) * 255)
            var b = Math.round((c.b || 0) * 255)
            var a = (c.a !== undefined) ? c.a : 1.0
            return "rgba(" + r + "," + g + "," + b + "," + a.toFixed(3) + ")"
        }

        function pushQuadSample(p, n, h, x0, y0, cx, cy, x2, y2, u) {
            var om = 1.0 - u
            var x = om * om * x0 + 2.0 * om * u * cx + u * u * x2
            var y = om * om * y0 + 2.0 * om * u * cy + u * u * y2
            var dux = 2.0 * om * (cx - x0) + 2.0 * u * (x2 - cx)
            var duy = 2.0 * om * (cy - y0) + 2.0 * u * (y2 - cy)
            var l = Math.hypot(dux, duy)
            var nx = l > 0.0001 ? (duy / l) : 0.0
            var ny = l > 0.0001 ? (-dux / l) : -1.0
            p.push([x, y])
            n.push([nx, ny])
            h.push(0.0)
        }

        function recomputePoints() {
            var p = []
            var n = []
            var h = []
            var btnW = root.btnWidth
            var btnH = root.btnDepth
            var slant = MediaControlBarStyle.dropSlant
            var rad = MediaControlBarStyle.dropRadius
            var flare = MediaControlBarStyle.dropFlare

            // Match components/drop.component.qml geometry (fillets, slants, and convex corners)
            var sl = Math.max(0, Math.min(slant, btnW / 2.0 - 1.0))
            var hh = Math.max(1.0, btnH)
            var len = Math.sqrt(sl * sl + hh * hh)
            var t = Math.max(0.0, Math.min(flare * (len - sl) / hh, len * 0.6))
            var r = Math.max(0.0, Math.min(rad, hh / 2.0, (len - t) * 0.95, btnW / 2.0 - sl))
            var dx = r * sl / len
            var dy = r * hh / len
            var tx = t * sl / len
            var ty = t * hh / len
            var slNx = -hh / len
            var slNy = -sl / len
            var srNx = hh / len
            var srNy = -sl / len

            // 1. Bottom-left concave fillet (3 points: u = 0, 0.5, 1.0)
            for (var f1 = 0; f1 < 3; f1++) {
                pushQuadSample(p, n, h,
                    padX - t, padY + btnH,
                    padX, padY + btnH,
                    padX + tx, padY + btnH - ty,
                    f1 / 2.0)
            }

            // 2. Left slanted wall (3 interior points)
            for (var s1 = 1; s1 <= 3; s1++) {
                var u1 = s1 / 4.0
                var lx = (padX + tx) * (1.0 - u1) + (padX + sl - dx) * u1
                var ly = (padY + btnH - ty) * (1.0 - u1) + (padY + dy) * u1
                p.push([lx, ly])
                n.push([slNx, slNy])
                h.push(0.0)
            }

            // 3. Top-left convex rounded corner (3 points: u = 0, 0.5, 1.0)
            for (var c1 = 0; c1 < 3; c1++) {
                pushQuadSample(p, n, h,
                    padX + sl - dx, padY + dy,
                    padX + sl, padY,
                    padX + sl + r, padY,
                    c1 / 2.0)
            }

            // 4. Top horizontal flat edge (26 interior points across y = padY)
            for (var j = 1; j <= 26; j++) {
                var tj = j / 27.0
                var txTop = (padX + sl + r) + (btnW - 2.0 * (sl + r)) * tj
                p.push([txTop, padY])
                n.push([0.0, -1.0])
                h.push(0.0)
            }

            // 5. Top-right convex rounded corner (3 points: u = 0, 0.5, 1.0)
            for (var c2 = 0; c2 < 3; c2++) {
                pushQuadSample(p, n, h,
                    padX + btnW - sl - r, padY,
                    padX + btnW - sl, padY,
                    padX + btnW - sl + dx, padY + dy,
                    c2 / 2.0)
            }

            // 6. Right slanted wall (3 interior points)
            for (var s2 = 1; s2 <= 3; s2++) {
                var u2 = s2 / 4.0
                var rx = (padX + btnW - sl + dx) * (1.0 - u2) + (padX + btnW - tx) * u2
                var ry = (padY + dy) * (1.0 - u2) + (padY + btnH - ty) * u2
                p.push([rx, ry])
                n.push([srNx, srNy])
                h.push(0.0)
            }

            // 7. Bottom-right concave fillet (3 points: u = 0, 0.5, 1.0)
            for (var f2 = 0; f2 < 3; f2++) {
                pushQuadSample(p, n, h,
                    padX + btnW - tx, padY + btnH - ty,
                    padX + btnW, padY + btnH,
                    padX + btnW + t, padY + btnH,
                    f2 / 2.0)
            }

            pts = p
            nms = n
            hts = h
        }

        Component.onCompleted: recomputePoints()
        onPadXChanged: recomputePoints()
        onPadYChanged: recomputePoints()

        Connections {
            target: root
            function onBtnWidthChanged() { borderVisualizer.recomputePoints() }
            function onBtnDepthChanged() { borderVisualizer.recomputePoints() }
        }

        Timer {
            id: visualizerTicker
            interval: MediaControlBarStyle.waveTickIntervalMs
            repeat: true
            running: borderVisualizer.shouldRun
            onTriggered: {
                if (borderVisualizer.pts.length === 0) return
                borderVisualizer.animTime += 0.016
                var t = borderVisualizer.animTime

                var spec = (root.audio && root.audio.spectrumAvailable && root.audio.spectrum && root.audio.spectrum.length > 0)
                           ? root.audio.spectrum : null
                var useSpectrum = (spec !== null && spec.length >= 2)

                var peak = 0.0
                var peaks = [0.0, 0.0]
                if (root.audio && !root.audio.sinkMuted) {
                    peak = root.audio.audioPeak || 0.0
                    if (root.audio.audioPeaks && root.audio.audioPeaks.length >= 2) {
                        peaks = [root.audio.audioPeaks[0], root.audio.audioPeaks[1]]
                    } else {
                        peaks = [peak, peak]
                    }
                    if (!useSpectrum && root.audio.isPlaying && peak > 0.001 && peak < 0.08) {
                        peak = 0.28
                        peaks = [0.28, 0.28]
                    }
                }

                var maxH = 0.0
                var total = borderVisualizer.pts.length
                var newHts = []
                var centerIdx = (total - 1) / 2.0

                var rawTargets = []
                for (var i = 0; i < total; i++) {
                    var target = 0.0

                    if (useSpectrum) {
                        // Mirrored frequency layout:
                        // Center of top edge (normDist = 0) is BASS / DRUMS (spectrum[0..])
                        // Towards both bottom ends (normDist = 1) is TREBLE (spectrum[spec.length - 1])
                        var normDist = Math.abs(i - centerIdx) / centerIdx
                        var specIdx = normDist * (spec.length - 1)
                        var idx0 = Math.floor(specIdx)
                        var idx1 = Math.min(spec.length - 1, idx0 + 1)
                        var frac = specIdx - idx0

                        // Smooth Hermite interpolation (smoothstep) across spectrum bins
                        var s = frac * frac * (3.0 - 2.0 * frac)
                        var rawVal = spec[idx0] * (1.0 - s) + spec[idx1] * s

                        // Enhanced dynamic sensitivity: bass boost curve for punchy response
                        var bassBoost = 1.0 + 0.85 * Math.pow(1.0 - normDist, 1.8)
                        var dynamicVal = Math.pow(rawVal, 0.82) * bassBoost
                        var shimmer = 1.0 + 0.08 * Math.sin(t * 12.0 + i * 0.7)

                        target = dynamicVal * shimmer * MediaControlBarStyle.waveAmplitudeScale
                    } else {
                        // Peak-based synthetic wave fallback (when cava is not available)
                        var pos = (i - centerIdx) / centerIdx
                        var ch = peaks[0] * (1.0 - (pos + 1.0) / 2.0) + peaks[1] * ((pos + 1.0) / 2.0)
                        var d = Math.abs(pos)
                        var bass = Math.exp(-4.0 * d * d)
                        var mids = Math.sin(d * Math.PI)
                        var treble = Math.pow(d, 1.8)
                        var w1 = Math.sin(t * 18.0 + i * 0.6) * 0.5 + 0.5
                        var w2 = Math.cos(t * 11.0 - i * 0.9) * 0.5 + 0.5
                        var w3 = Math.sin(t * 26.0 + i * 1.5) * 0.5 + 0.5
                        var dyn = (bass * 1.5 * w1 + mids * 1.1 * w2 + treble * 0.9 * w3) / 1.6
                        target = ch * dyn * MediaControlBarStyle.waveAmplitudeScale
                    }

                    // Smoothly pin the ends at the bottom screen edge
                    if (i === 0 || i === total - 1) target = 0.0
                    else if (i === 1 || i === total - 2) target *= 0.35

                    rawTargets.push(target)
                }

                // Spatial 3-point Gaussian smoothing for continuous rounded dome profile
                for (var j = 0; j < total; j++) {
                    var target = rawTargets[j]
                    if (j > 1 && j < total - 2) {
                        target = rawTargets[j - 1] * 0.20 + rawTargets[j] * 0.60 + rawTargets[j + 1] * 0.20
                    }

                    var current = borderVisualizer.hts[j] || 0.0
                    if (target > current) {
                        current = current * 0.20 + target * 0.80
                    } else {
                        current = current * MediaControlBarStyle.waveDecayFactor
                        if (current < 0.05) current = 0.0
                    }

                    newHts.push(current)
                    if (current > maxH) maxH = current
                }

                borderVisualizer.hts = newHts
                borderVisualizer.currentMax = maxH
                borderVisualizer.requestPaint()
            }
        }

        function traceWavePath(ctx, wPts) {
            if (wPts.length === 0) return
            if (currentMax <= 0.05) {
                var btnW = root.btnWidth
                var btnH = root.btnDepth
                var slant = MediaControlBarStyle.dropSlant
                var rad = MediaControlBarStyle.dropRadius
                var flare = MediaControlBarStyle.dropFlare
                var sl = Math.max(0, Math.min(slant, btnW / 2.0 - 1.0))
                var hh = Math.max(1.0, btnH)
                var len = Math.sqrt(sl * sl + hh * hh)
                var t = Math.max(0.0, Math.min(flare * (len - sl) / hh, len * 0.6))
                var r = Math.max(0.0, Math.min(rad, hh / 2.0, (len - t) * 0.95, btnW / 2.0 - sl))
                var dx = r * sl / len
                var dy = r * hh / len
                var tx = t * sl / len
                var ty = t * hh / len

                ctx.moveTo(padX - t, padY + btnH)
                ctx.quadraticCurveTo(padX, padY + btnH, padX + tx, padY + btnH - ty)
                ctx.lineTo(padX + sl - dx, padY + dy)
                ctx.quadraticCurveTo(padX + sl, padY, padX + sl + r, padY)
                ctx.lineTo(padX + btnW - sl - r, padY)
                ctx.quadraticCurveTo(padX + btnW - sl, padY, padX + btnW - sl + dx, padY + dy)
                ctx.lineTo(padX + btnW - tx, padY + btnH - ty)
                ctx.quadraticCurveTo(padX + btnW, padY + btnH, padX + btnW + t, padY + btnH)
                return
            }
            ctx.moveTo(wPts[0][0], wPts[0][1])
            if (wPts.length === 1) return
            if (wPts.length === 2) {
                ctx.lineTo(wPts[1][0], wPts[1][1])
                return
            }

            // Smooth quadratic Bézier curves through midpoints to eliminate sharp polygonal triangles
            var firstMidX = (wPts[0][0] + wPts[1][0]) * 0.5
            var firstMidY = (wPts[0][1] + wPts[1][1]) * 0.5
            ctx.lineTo(firstMidX, firstMidY)

            for (var i = 1; i < wPts.length - 1; i++) {
                var nextMidX = (wPts[i][0] + wPts[i + 1][0]) * 0.5
                var nextMidY = (wPts[i][1] + wPts[i + 1][1]) * 0.5
                ctx.quadraticCurveTo(wPts[i][0], wPts[i][1], nextMidX, nextMidY)
            }

            ctx.lineTo(wPts[wPts.length - 1][0], wPts[wPts.length - 1][1])
        }

        function traceFullIslandPath(ctx, wPts, pX, pY, bW, bH) {
            ctx.beginPath()
            traceWavePath(ctx, wPts)
            // Connect across bottom screen edge from bottom-right flared corner to bottom-left flared corner
            if (wPts.length > 0) {
                ctx.lineTo(wPts[wPts.length - 1][0], pY + bH)
                ctx.lineTo(wPts[0][0], pY + bH)
            } else {
                ctx.lineTo(pX + bW, pY + bH)
                ctx.lineTo(pX, pY + bH)
            }
            ctx.closePath()
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            if (opacity <= 0.005 || pts.length === 0) return

            // Compute displaced outer wave points
            var wavePts = []
            for (var k = 0; k < pts.length; k++) {
                wavePts.push([
                    pts[k][0] + nms[k][0] * hts[k],
                    pts[k][1] + nms[k][1] * hts[k]
                ])
            }

            var btnW = root.btnWidth
            var btnH = root.btnDepth

            // 1. Translucent glass substrate base fill across the entire island
            traceFullIslandPath(ctx, wavePts, padX, padY, btnW, btnH)
            ctx.fillStyle = toCanvasRgba(root.fill)
            ctx.fill()

            // 2. Liquid Glass multi-stop refractive sheen gradient across the entire morphing island
            // Matches Drop (fromBottom: true) where y=0 is at bottomY and y=ld is at topY
            var topY = Math.max(0, padY - currentMax)
            var bottomY = padY + btnH
            var grad = ctx.createLinearGradient(padX, bottomY, padX + btnW * 0.25, topY)
            grad.addColorStop(0.0, toCanvasRgba(DropStyle.glassSheenTop))
            grad.addColorStop(0.32, toCanvasRgba(DropStyle.glassSheenMid))
            grad.addColorStop(0.68, toCanvasRgba(DropStyle.glassSheenCore))
            grad.addColorStop(1.0, toCanvasRgba(DropStyle.glassSheenBottom))

            traceFullIslandPath(ctx, wavePts, padX, padY, btnW, btnH)
            ctx.fillStyle = grad
            ctx.fill()

            // 3. Inner 3D caustic bevel glow along the exposed wave perimeter
            if (DropStyle.glassInnerBevel.a > 0.01) {
                ctx.beginPath()
                traceWavePath(ctx, wavePts)
                ctx.strokeStyle = toCanvasRgba(DropStyle.glassInnerBevel)
                ctx.lineWidth = DropStyle.bevelStrokeWidth
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                ctx.stroke()
            }

            // 4. Moving specular rim highlight along the exposed wave perimeter
            ctx.beginPath()
            traceWavePath(ctx, wavePts)
            ctx.strokeStyle = toCanvasRgba(DropStyle.strokeColor)
            ctx.lineWidth = MediaControlBarStyle.waveStrokeWidth
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.stroke()
        }
    }

    // ────────────────────────────────────────────────────────────────
    // 4. RIGHT DROP ISLAND: Media Controls & Merged Volume Slider
    // ────────────────────────────────────────────────────────────────
    Drop {
        id: dropMedia
        fromBottom: true
        x: root.isMerged ? 0 : (root.circleSize * 2 + root.circleSpacing + MediaControlBarStyle.dropGap)
        y: (root.isSoundFloating && !root.isMerged) ? (root.btnDepth + 2) : 0
        width: root.isMerged ? root.width : root.btnWidth
        height: root.btnDepth
        fill: borderVisualizer.visualizerActive ? MediaControlBarStyle.dropActiveFillColor : root.fill
        Behavior on fill { ColorAnimation { duration: MediaControlBarStyle.waveFadeDurationMs; easing.type: Easing.OutCubic } }
        strokeColor: borderVisualizer.visualizerActive ? MediaControlBarStyle.dropActiveStrokeColor : DropStyle.strokeColor
        strokeWidth: DropStyle.strokeWidth
        strokeColorDuration: MediaControlBarStyle.waveFadeDurationMs
        slant: MediaControlBarStyle.dropSlant
        rad: MediaControlBarStyle.dropRadius
        flare: MediaControlBarStyle.dropFlare
        tp: 0
        inset: MediaControlBarStyle.dropInset
        bottomInset: MediaControlBarStyle.dropBottomInset

        Behavior on x { NumberAnimation { duration: MediaControlBarStyle.mergeDurationMs; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: MediaControlBarStyle.mergeDurationMs; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: MediaControlBarStyle.mergeDurationMs; easing.type: Easing.OutCubic } }
        visible: y < (root.btnDepth + 1) || dropDragArea.isDetaching
        enabled: !root.isSoundFloating || root.isMerged || dropDragArea.isDetaching

        readonly property bool audioPlaying: (root.audio && (root.audio.isPlaying || root.audio.hasAudio)) ? true : false
        readonly property bool showNowPlaying: !root.isMerged && !root.isSoundFloating && audioPlaying && !mergedBarHover.hovered
        readonly property bool showMediaControls: !root.isMerged && !root.isSoundFloating && (!audioPlaying || mergedBarHover.hovered)

        // HoverHandler to detect hover over the audio bar (switches Now Playing -> Media Controls and manages merged unmerge timer)
        HoverHandler {
            id: mergedBarHover
            target: dropMedia
            enabled: true
            onHoveredChanged: {
                if (hovered) {
                    unmergeTimer.stop()
                } else {
                    if (root.isMerged && !trackMouse.pressed) {
                        unmergeTimer.restart()
                    }
                }
            }
        }

        // WheelHandler to adjust volume/mic anywhere over the merged bar
        WheelHandler {
            enabled: root.isMerged
            onWheel: function(event) {
                root.handleWheel(event)
            }
        }

        // Background MouseArea for dragging the sound island out to float
        MouseArea {
            id: dropDragArea
            anchors.fill: parent
            z: -1
            property real pressSceneX: 0
            property real pressSceneY: 0
            property bool isDetaching: false

            onPressed: function(mouse) {
                var pt = mapToItem(null, mouse.x, mouse.y)
                pressSceneX = pt.x
                pressSceneY = pt.y
                isDetaching = false
            }

            onPositionChanged: function(mouse) {
                if (!pressed) return
                var pt = mapToItem(null, mouse.x, mouse.y)
                var dy = pressSceneY - pt.y

                if (!isDetaching && root.floatManager && (dy > MediaControlBarStyle.detachThresholdY || Math.hypot(pt.x - pressSceneX, dy) > MediaControlBarStyle.detachThresholdHypot)) {
                    isDetaching = true
                    root.closeMerged()
                    root.floatManager.startDrag({
                        id: "sound",
                        title: "Sound Control",
                        icon: "󰕾",
                        originSide: "bottom",
                        originX: root.x,
                        originY: root.y,
                        width: MediaControlBarStyle.floatWidth,
                        height: MediaControlBarStyle.floatHeight,
                        audio: root.audio
                    }, pt.x, pt.y)
                } else if (isDetaching && root.floatManager) {
                    root.floatManager.updateDrag(pt.x, pt.y)
                }
            }

            onReleased: {
                if (isDetaching) {
                    isDetaching = false
                    if (root.floatManager) root.floatManager.endDrag()
                }
            }
        }

        // ── View A0: Now Playing Track & Software Info (shown when audio is playing and not hovered) ──
        Column {
            id: nowPlayingView
            anchors.centerIn: parent
            width: Math.max(0, parent.width - MediaControlBarStyle.nowPlayingHorizontalPadding * 2)
            spacing: MediaControlBarStyle.nowPlayingSpacing
            opacity: dropMedia.showNowPlaying ? 1.0 : 0.0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: MediaControlBarStyle.mediaFadeDurationMs; easing.type: Easing.OutCubic } }

            // Song / Audio Title
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: {
                    if (root.audio && root.audio.trackTitle) return root.audio.trackTitle
                    if (root.audio && root.audio.trackArtist) return root.audio.trackArtist
                    if (root.audio && root.audio.trackApp) return root.audio.trackApp
                    return "Audio Playing"
                }
                color: root.fg
                font.pixelSize: MediaControlBarStyle.nowPlayingTitleFontPx
                font.weight: Font.DemiBold
            }

            // Software / Application Playing It
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: MediaControlBarStyle.nowPlayingIconSpacing

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰎈"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: MediaControlBarStyle.nowPlayingIconFontPx
                    color: root.accent
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, Math.max(0, nowPlayingView.width - 20))
                    elide: Text.ElideRight
                    text: {
                        if (root.audio && root.audio.trackApp) return root.audio.trackApp
                        if (root.audio && root.audio.trackArtist) return root.audio.trackArtist
                        return "System Audio"
                    }
                    color: root.dim
                    font.pixelSize: MediaControlBarStyle.nowPlayingAppFontPx
                    font.weight: Font.Medium
                }
            }
        }

        // ── View A: Media Controls (Previous, Play/Pause, Next — shown on hover or when nothing is playing) ──
        Row {
            id: mediaControlsRow
            anchors.centerIn: parent
            spacing: MediaControlBarStyle.mediaControlSpacing
            opacity: dropMedia.showMediaControls ? 1.0 : 0.0
            enabled: dropMedia.showMediaControls
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: MediaControlBarStyle.mediaFadeDurationMs; easing.type: Easing.OutCubic } }

            // Previous Track Button
            Item {
                width: MediaControlBarStyle.mediaBtnWidth
                height: MediaControlBarStyle.mediaBtnHeight
                anchors.verticalCenter: parent.verticalCenter
                scale: prevMouse.pressed ? MediaControlBarStyle.btnPressedScale : (prevMouse.containsMouse ? MediaControlBarStyle.prevNextHoverScale : 1.0)
                Behavior on scale { NumberAnimation { duration: MediaControlBarStyle.btnScaleDurationMs } }

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: MediaControlBarStyle.prevNextIconFontPx
                    color: prevMouse.containsMouse ? root.accent : root.fg
                    Behavior on color { ColorAnimation { duration: MediaControlBarStyle.btnColorDurationMs } }
                }

                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    anchors.margins: -MediaControlBarStyle.btnHitPadding
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.audio) root.audio.previous()
                    }
                }
            }

            // Play / Pause Button
            Item {
                width: MediaControlBarStyle.playBtnWidth
                height: MediaControlBarStyle.mediaBtnHeight
                anchors.verticalCenter: parent.verticalCenter
                scale: playMouse.pressed ? MediaControlBarStyle.btnPressedScale : (playMouse.containsMouse ? MediaControlBarStyle.playHoverScale : 1.0)
                Behavior on scale { NumberAnimation { duration: MediaControlBarStyle.btnScaleDurationMs } }

                Text {
                    anchors.centerIn: parent
                    text: (root.audio && root.audio.isPlaying) ? "" : ""
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: MediaControlBarStyle.playPauseIconFontPx
                    color: (root.audio && root.audio.isPlaying) ? root.accent : (playMouse.containsMouse ? root.accent : root.fg)
                    Behavior on color { ColorAnimation { duration: MediaControlBarStyle.btnColorDurationMs } }
                }

                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    anchors.margins: -MediaControlBarStyle.btnHitPadding
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.audio) root.audio.togglePlay()
                    }
                }
            }

            // Next Track Button
            Item {
                width: MediaControlBarStyle.mediaBtnWidth
                height: MediaControlBarStyle.mediaBtnHeight
                anchors.verticalCenter: parent.verticalCenter
                scale: nextMouse.pressed ? MediaControlBarStyle.btnPressedScale : (nextMouse.containsMouse ? MediaControlBarStyle.prevNextHoverScale : 1.0)
                Behavior on scale { NumberAnimation { duration: MediaControlBarStyle.btnScaleDurationMs } }

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: MediaControlBarStyle.prevNextIconFontPx
                    color: nextMouse.containsMouse ? root.accent : root.fg
                    Behavior on color { ColorAnimation { duration: MediaControlBarStyle.btnColorDurationMs } }
                }

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    anchors.margins: -MediaControlBarStyle.btnHitPadding
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.audio) root.audio.next()
                    }
                }
            }
        }

        // ── View B: Merged Slider (Icon + Horizontal Bar + Percentage) ──
        Item {
            id: sliderControls
            anchors.fill: parent
            opacity: root.isMerged ? 1.0 : 0.0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: MediaControlBarStyle.contentSwitchDurationMs; easing.type: Easing.OutCubic } }

            // Left: Audio Icon (Click toggles mute)
            Item {
                id: audioIconBox
                width: MediaControlBarStyle.sliderMuteBtnWidth
                height: parent.height
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: root.currentAudioIcon()
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: MediaControlBarStyle.sliderMuteIconFontPx
                    color: root.isCurrentMuted ? root.danger : (iconMouse.containsMouse ? root.accent : root.fg)
                    Behavior on color { ColorAnimation { duration: MediaControlBarStyle.colorAnimDurationMs } }
                }

                MouseArea {
                    id: iconMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.mergedMode === "output") {
                            if (root.audio) root.audio.toggleSinkMute()
                        } else if (root.mergedMode === "input") {
                            if (root.audio) root.audio.toggleSourceMute()
                        }
                    }
                }
            }

            // Right: Percentage of Output / Input
            Text {
                id: percentLabel
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: MediaControlBarStyle.sliderPctWidth
                horizontalAlignment: Text.AlignRight
                text: root.audio ? (Math.round(root.currentVolume() * 100) + "%") : "100%"
                color: root.isCurrentMuted ? root.danger : root.fg
                font.pixelSize: MediaControlBarStyle.sliderPctFontPx
                font.weight: Font.DemiBold
            }

            // Center: Interactive Horizontal Volume Slider Track
            Item {
                id: sliderTrackContainer
                anchors.left: audioIconBox.right
                anchors.leftMargin: MediaControlBarStyle.sliderHorizontalMargin
                anchors.right: percentLabel.left
                anchors.rightMargin: MediaControlBarStyle.sliderHorizontalMargin
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height

                // Track background groove
                Rectangle {
                    id: trackBg
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: MediaControlBarStyle.sliderTrackHeight
                    radius: MediaControlBarStyle.sliderTrackRadius
                    color: MediaControlBarStyle.sliderTrackBg

                    // Track fill progress
                    Rectangle {
                        id: trackFill
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.max(0, Math.min(trackBg.width, trackBg.width * root.currentRatio()))
                        radius: MediaControlBarStyle.sliderTrackRadius
                        color: root.isCurrentMuted ? root.dim : root.accent
                        Behavior on color { ColorAnimation { duration: MediaControlBarStyle.colorAnimDurationMs } }
                    }
                }

                // Draggable knob indicator
                Rectangle {
                    id: sliderKnob
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(sliderTrackContainer.width - width, sliderTrackContainer.width * root.currentRatio() - width / 2))
                    width: MediaControlBarStyle.sliderThumbSize
                    height: MediaControlBarStyle.sliderThumbSize
                    radius: MediaControlBarStyle.sliderThumbRadius
                    color: root.isCurrentMuted ? root.dim : (trackMouse.containsMouse || trackMouse.pressed ? root.fg : root.accent)
                    border.width: 1
                    border.color: MediaControlBarStyle.sliderThumbBorder
                    scale: trackMouse.pressed ? MediaControlBarStyle.sliderThumbPressedScale : (trackMouse.containsMouse ? MediaControlBarStyle.sliderThumbHoverScale : 1.0)
                    Behavior on scale { NumberAnimation { duration: MediaControlBarStyle.sliderThumbScaleDurationMs } }
                    Behavior on color { ColorAnimation { duration: MediaControlBarStyle.colorAnimDurationMs } }
                }

                // MouseArea for track click, drag & wheel
                MouseArea {
                    id: trackMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    function updateFromMouse(mouseX) {
                        if (!root.audio) return
                        var ratio = Math.max(0.0, Math.min(1.0, mouseX / width))
                        if (root.mergedMode === "output") {
                            root.audio.setSinkVolume(ratio)
                        } else if (root.mergedMode === "input") {
                            root.audio.setSourceVolume(ratio)
                        }
                    }

                    onPressed: function(mouse) { updateFromMouse(mouse.x) }
                    onPositionChanged: function(mouse) {
                        if (pressed) updateFromMouse(mouse.x)
                    }
                    onReleased: {
                        if (!mergedBarHover.hovered) {
                            unmergeTimer.restart()
                        }
                    }
                    onWheel: function(wheel) {
                        root.handleWheel(wheel)
                    }
                }
            }
        }
    }
}
