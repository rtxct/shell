// ============================================================================
// File: modules/floating-slider-bar-panel.module.qml
// Purpose: Detached floating volume and microphone slider bar with interactive track, mute toggle, and edge dock/close actions.
// Public API:
//   - Properties: audio, floatingWindow, mode, extraData, fg, dim, accent, danger ...
//   - Functions:  toggleMute(), setVolume(val), handleWheel(wheel)
// Dependencies: QtQuick, "../styles"
// ============================================================================
import QtQuick
import "../styles"

Item {
    id: root

    property var audio: null
    property var floatingWindow: null
    property string mode: "output" // "output" | "input"
    property var extraData: null

    readonly property string effectiveMode: (extraData && extraData.mode) ? extraData.mode : mode
    readonly property bool isOutput: effectiveMode === "output"

    property color fg: MediaControlBarStyle.textPrimary
    property color dim: MediaControlBarStyle.textDim
    property color accent: MediaControlBarStyle.accent
    property color danger: MediaControlBarStyle.danger

    readonly property bool isMuted: {
        if (!audio) return false
        return isOutput ? audio.sinkMuted : audio.sourceMuted
    }

    readonly property real volume: {
        if (!audio) return 1.0
        return isOutput ? audio.sinkVolume : audio.sourceVolume
    }

    readonly property real ratio: Math.max(0.0, Math.min(1.0, volume))

    readonly property string iconGlyph: {
        if (isOutput) {
            if (!audio) return "󰕾"
            if (audio.sinkMuted) return "󰝟"
            var v = audio.sinkVolume
            if (v <= 0.01) return "󰕿"
            if (v < 0.5) return "󰖀"
            return "󰕾"
        } else {
            if (!audio) return "󰍬"
            return audio.sourceMuted ? "󰍭" : "󰍬"
        }
    }

    function toggleMute() {
        if (!audio) return
        if (isOutput) {
            audio.toggleSinkMute()
        } else {
            audio.toggleSourceMute()
        }
    }

    function setVolume(val) {
        if (!audio) return
        var clamped = Math.max(0.0, Math.min(1.0, val))
        if (isOutput) {
            audio.setSinkVolume(clamped)
        } else {
            audio.setSourceVolume(clamped)
        }
    }

    readonly property real wheelStep: (audio && audio.wheelStep > 0) ? audio.wheelStep : MediaControlBarStyle.wheelVolumeStep

    function handleWheel(wheel) {
        var delta = wheel.angleDelta.y > 0 ? wheelStep : -wheelStep
        setVolume(volume + delta)
    }

    // ── Full-bar drag MouseArea (background) ──
    MouseArea {
        id: bgDragArea
        anchors.fill: parent
        z: -1
        cursorShape: Qt.ArrowCursor

        onPressed: function(mouse) {
            if (floatingWindow) {
                var pt = mapToItem(null, mouse.x, mouse.y)
                floatingWindow.dragStart(pt.x, pt.y)
            }
        }

        onPositionChanged: function(mouse) {
            if (floatingWindow && pressed) {
                var pt = mapToItem(null, mouse.x, mouse.y)
                floatingWindow.dragMove(pt.x, pt.y)
            }
        }

        onReleased: {
            if (floatingWindow) floatingWindow.dragEnd()
        }

        onCanceled: {
            if (floatingWindow) floatingWindow.dragEnd()
        }

        onWheel: function(wheel) {
            root.handleWheel(wheel)
        }
    }

    // ── Content Layout ──
    // 1. Drag grip dots handle on the left
    Item {
        id: dragGrip
        width: MediaControlBarStyle.floatBarDragGripWidth
        height: parent.height
        anchors.left: parent.left
        anchors.leftMargin: MediaControlBarStyle.floatBarPaddingX
        anchors.verticalCenter: parent.verticalCenter

        Column {
            anchors.centerIn: parent
            spacing: MediaControlBarStyle.floatBarDragDotSpacing
            Repeater {
                model: 2
                Rectangle {
                    width: MediaControlBarStyle.floatBarDragDotSize
                    height: MediaControlBarStyle.floatBarDragDotSize
                    radius: width / 2
                    color: gripMouse.containsMouse ? root.accent : root.dim
                    opacity: gripMouse.containsMouse ? 0.9 : 0.5
                }
            }
        }

        MouseArea {
            id: gripMouse
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.SizeAllCursor

            onPressed: function(mouse) {
                if (floatingWindow) {
                    var pt = mapToItem(null, mouse.x, mouse.y)
                    floatingWindow.dragStart(pt.x, pt.y)
                }
            }

            onPositionChanged: function(mouse) {
                if (floatingWindow && pressed) {
                    var pt = mapToItem(null, mouse.x, mouse.y)
                    floatingWindow.dragMove(pt.x, pt.y)
                }
            }

            onReleased: {
                if (floatingWindow) floatingWindow.dragEnd()
            }

            onCanceled: {
                if (floatingWindow) floatingWindow.dragEnd()
            }
        }
    }

    // 2. Mute Toggle Icon Button
    Item {
        id: muteBtn
        width: MediaControlBarStyle.sliderMuteBtnWidth
        height: parent.height
        anchors.left: dragGrip.right
        anchors.leftMargin: MediaControlBarStyle.floatBarSpacing
        anchors.verticalCenter: parent.verticalCenter

        Text {
            anchors.centerIn: parent
            text: root.iconGlyph
            font.family: "Symbols Nerd Font"
            font.pixelSize: MediaControlBarStyle.sliderMuteIconFontPx
            color: root.isMuted ? root.danger : (muteMouse.containsMouse ? root.accent : root.fg)
            Behavior on color { ColorAnimation { duration: MediaControlBarStyle.colorAnimDurationMs } }
        }

        MouseArea {
            id: muteMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleMute()
        }
    }

    // 3. Close window button on the far right
    Rectangle {
        id: closeBtn
        width: MediaControlBarStyle.floatBarBtnSize
        height: MediaControlBarStyle.floatBarBtnSize
        radius: MediaControlBarStyle.floatBarBtnRadius
        anchors.right: parent.right
        anchors.rightMargin: MediaControlBarStyle.floatBarPaddingX
        anchors.verticalCenter: parent.verticalCenter
        color: closeMouse.containsMouse ? FloatingWindowStyle.closeBtnHoverBg : FloatingWindowStyle.transparent
        border.width: FloatingWindowStyle.borderWidthIdle
        border.color: closeMouse.containsMouse ? root.danger : FloatingWindowStyle.transparent

        Text {
            anchors.centerIn: parent
            text: "✕"
            font.pixelSize: FloatingWindowStyle.closeIconFontPx
            color: closeMouse.containsMouse ? root.danger : root.dim
        }

        MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.floatingWindow) root.floatingWindow.close()
            }
        }
    }

    // 4. Percentage Text (to the left of close)
    Text {
        id: pctLabel
        anchors.right: closeBtn.left
        anchors.rightMargin: MediaControlBarStyle.floatBarSpacing
        anchors.verticalCenter: parent.verticalCenter
        width: MediaControlBarStyle.sliderPctWidth
        horizontalAlignment: Text.AlignRight
        text: root.audio ? (Math.round(root.volume * 100) + "%") : "100%"
        color: root.isMuted ? root.danger : root.fg
        font.pixelSize: MediaControlBarStyle.sliderPctFontPx
        font.weight: Font.DemiBold
    }

    // 5. Interactive Horizontal Slider Track (stretches between mute button and percentage)
    Item {
        id: sliderTrackContainer
        anchors.left: muteBtn.right
        anchors.leftMargin: MediaControlBarStyle.sliderHorizontalMargin
        anchors.right: pctLabel.left
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
                width: Math.max(0, Math.min(trackBg.width, trackBg.width * root.ratio))
                radius: MediaControlBarStyle.sliderTrackRadius
                color: root.isMuted ? root.dim : root.accent
                Behavior on color { ColorAnimation { duration: MediaControlBarStyle.colorAnimDurationMs } }
            }
        }

        // Draggable knob indicator
        Rectangle {
            id: sliderKnob
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(sliderTrackContainer.width - width, sliderTrackContainer.width * root.ratio - width / 2))
            width: MediaControlBarStyle.sliderThumbSize
            height: MediaControlBarStyle.sliderThumbSize
            radius: MediaControlBarStyle.sliderThumbRadius
            color: root.isMuted ? root.dim : (trackMouse.containsMouse || trackMouse.pressed ? root.fg : root.accent)
            border.width: 1
            border.color: MediaControlBarStyle.sliderThumbBorder
            scale: trackMouse.pressed ? MediaControlBarStyle.sliderThumbPressedScale : (trackMouse.containsMouse ? MediaControlBarStyle.sliderThumbHoverScale : 1.0)
            Behavior on scale { NumberAnimation { duration: MediaControlBarStyle.sliderThumbScaleDurationMs } }
            Behavior on color { ColorAnimation { duration: MediaControlBarStyle.colorAnimDurationMs } }
        }

        // Track MouseArea for click, drag & wheel
        MouseArea {
            id: trackMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            function updateFromMouse(mouseX) {
                var r = Math.max(0.0, Math.min(1.0, mouseX / width))
                root.setVolume(r)
            }

            onPressed: function(mouse) { updateFromMouse(mouse.x) }
            onPositionChanged: function(mouse) {
                if (pressed) updateFromMouse(mouse.x)
            }
            onWheel: function(wheel) {
                root.handleWheel(wheel)
            }
        }
    }
}
