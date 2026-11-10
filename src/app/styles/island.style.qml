// ============================================================================
// File: styles/island.style.qml
// Purpose: Dimensions, springs, animation durations, and Theme tokens for Island.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color fill: Theme.backgroundPrimary
    readonly property color textPrimary: Theme.textPrimary
    readonly property color textDim: Theme.textDim
    readonly property color accent: Theme.accent

    readonly property real verticalFloatWidth: 520
    readonly property real verticalFloatHeight: 440
    readonly property real horizontalFloatWidth: 740
    readonly property real horizontalFloatHeight: 500
    readonly property real detachThresholdAxis: 14
    readonly property real detachThresholdHypot: 18
    readonly property real titlebarDragHeight: 24

    readonly property real idleLen: 300
    readonly property real idleDepth: 44
    readonly property real hoverLen: 270
    readonly property real hoverDepth: 266
    readonly property real openLen: 720
    readonly property real openDepth: 500

    readonly property real idleSlant: 30
    readonly property real hoverSlant: 24
    readonly property real openSlant: 28
    readonly property real radius: 12
    readonly property real flare: 12

    readonly property int hoverReleaseMs: 100
    readonly property real hoverSpring: 5.5
    readonly property real hoverDamping: 0.72
    readonly property real hoverEpsilon: 0.05
    readonly property int openDurationMs: 320
    readonly property int closeDurationMs: 240
    readonly property int hoverFadeDurationMs: 130
    readonly property int fadeDurationMs: 120
    readonly property real hoverScale: 1.0
    readonly property real pressedScale: 1.0
    readonly property int scaleAnimDurationMs: 100
    readonly property int titleFontPx: 13
    readonly property int closeIconFontPx: 16
    readonly property real closeHoverScale: 1.04
    readonly property real closePressedScale: 0.99
    readonly property int closeAnimDurationMs: 140
}
