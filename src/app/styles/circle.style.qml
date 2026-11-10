// ============================================================================
// File: styles/circle.style.qml
// Purpose: Geometry, two-phase orthogonal flight timings, and Theme tokens for Circle launchers.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color fill: Theme.backgroundPrimary
    readonly property color borderColor: Theme.borderWhite
    readonly property color glyphColor: Theme.textPrimary
    readonly property color textBright: Theme.textBright
    readonly property color textSecondary: Theme.textSecondary
    readonly property color dangerColor: Theme.danger
    readonly property color dangerTint25: Theme.dangerTint25
    readonly property color accentColor: Theme.accent
    readonly property color textDim: Theme.textDim
    readonly property color itemBg: Theme.surfaceWhite05
    readonly property color itemHoverBg: Theme.surfaceWhite08
    readonly property color itemSelectedBg: Theme.surfaceWhite12
    readonly property color itemBorder: Theme.surfaceWhite10
    readonly property color itemSelectedBorder: Theme.surfaceWhite20
    readonly property color transparent: Theme.transparent
    readonly property color glassSheenTop: Theme.glassSheenTop
    readonly property color glassSheenMid: Theme.glassSheenMid
    readonly property color glassSheenCore: Theme.glassSheenCore
    readonly property color glassSheenBottom: Theme.glassSheenBottom
    readonly property color glassInnerBevel: Theme.glassInnerBevel

    readonly property real floatWidth: 480
    readonly property real floatHeight: 420
    readonly property real detachThresholdX: 14
    readonly property real detachThresholdHypot: 18

    readonly property real diameter: 26
    readonly property int glyphFontPx: 11
    readonly property real spacing: 60
    readonly property real innerOffset: 140
    readonly property real innerGap: 40
    readonly property real topGap: 6
    readonly property real hoverScale: 1.14
    readonly property int flightDurationMs: 440
    readonly property real phase1End: 0.60
    readonly property real phase2Start: 0.50
    readonly property real hoverSpring: 4.5
    readonly property real hoverDamping: 0.72
    readonly property int fadeDurationMs: 160
    readonly property int glyphFadeDurationMs: 140
    readonly property real glyphHoverOpacity: 0.8
}
