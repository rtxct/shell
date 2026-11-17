// ============================================================================
// File: styles/circle.style.qml
// Purpose: Geometry, two-phase orthogonal flight timings, and Theme tokens for Circle launchers.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color fill: Theme.circleFill
    readonly property color borderColor: Theme.circleBorderColor
    readonly property color glyphColor: Theme.circleGlyphColor
    readonly property color textBright: Theme.circleTextBright
    readonly property color textSecondary: Theme.circleTextSecondary
    readonly property color dangerColor: Theme.circleDangerColor
    readonly property color dangerTint25: Theme.circleDangerTint25
    readonly property color accentColor: Theme.circleAccentColor
    readonly property color textDim: Theme.circleTextDim
    readonly property color itemBg: Theme.circleItemBg
    readonly property color itemHoverBg: Theme.circleItemHoverBg
    readonly property color itemSelectedBg: Theme.circleItemSelectedBg
    readonly property color itemBorder: Theme.circleItemBorder
    readonly property color itemSelectedBorder: Theme.circleItemSelectedBorder
    readonly property color transparent: Theme.transparent
    readonly property color glassSheenTop: Theme.circleGlassSheenTop
    readonly property color glassSheenMid: Theme.circleGlassSheenMid
    readonly property color glassSheenCore: Theme.circleGlassSheenCore
    readonly property color glassSheenBottom: Theme.circleGlassSheenBottom
    readonly property color glassInnerBevel: Theme.circleGlassInnerBevel

    readonly property real floatWidth: 480
    readonly property real floatHeight: 420
    readonly property real detachThresholdX: 14
    readonly property real detachThresholdHypot: 18

    readonly property real diameter: 26
    readonly property real hiddenTipSize: 8
    readonly property int unhoverDelayMs: 120
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
