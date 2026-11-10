// ============================================================================
// File: styles/floating-window.style.qml
// Purpose: Frame borders, titlebar geometry, dock snap distance, and Theme tokens for FloatingWindow.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color background: Theme.backgroundPrimary
    readonly property color accent: Theme.accent
    readonly property color danger: Theme.danger
    readonly property color textPrimary: Theme.textPrimary
    readonly property color textDim: Theme.textDim
    readonly property color borderDragging: Theme.accentBorderDragging
    readonly property color borderIdle: Theme.borderWhite
    readonly property color innerGlowNearDock: Theme.accentGlowNearDock
    readonly property color innerGlowIdle: Theme.surfaceWhite04
    readonly property color titlebarDivider: Theme.surfaceWhite08
    readonly property color closeBtnHoverBg: Theme.dangerTint20
    readonly property color glassSheenTop: Theme.glassSheenTop
    readonly property color glassSheenMid: Theme.glassSheenMid
    readonly property color glassSheenCore: Theme.glassSheenCore
    readonly property color glassSheenBottom: Theme.glassSheenBottom
    readonly property color glassInnerBevel: Theme.glassInnerBevel
    readonly property color glassRimHighlight: Theme.glassRimHighlight
    readonly property color transparent: Theme.transparent

    readonly property real defaultWidth: 440
    readonly property real defaultHeight: 400
    readonly property real managerDefaultWidth: 460
    readonly property real managerDefaultHeight: 400
    readonly property real snapDistance: 90
    readonly property real closedScale: 0.88
    readonly property int opacityDurationMs: 160
    readonly property int scaleDurationMs: 180
    readonly property int borderAnimDurationMs: 120

    readonly property real frameRadius: 14
    readonly property real barFrameRadius: 8
    readonly property real borderWidthNearDock: 2.0
    readonly property real borderWidthDragging: 1.5
    readonly property real borderWidthIdle: 1.0
    readonly property real innerGlowMargin: 1
    readonly property real innerGlowRadius: 15
    readonly property real titlebarHeight: 36
    readonly property real titlebarDividerMarginX: 12
    readonly property real titlebarPaddingX: 14
    readonly property real titlebarRowSpacing: 8
    readonly property string iconFont: "Symbols Nerd Font"
    readonly property int titleIconFontPx: 14
    readonly property int titleFontPx: 12
    readonly property real titleLetterSpacing: 1.2
    readonly property real dragDotsSpacing: 4
    readonly property real dragDotSize: 4
    readonly property real dragDotRadius: 2
    readonly property real dragDotsOpacityIdle: 0.4
    readonly property real dragDotsOpacityActive: 0.9
    readonly property real actionsRightMargin: 10
    readonly property real actionsSpacing: 6
    readonly property real titleBtnSize: 24
    readonly property real titleBtnRadius: 12
    readonly property int closeIconFontPx: 13
    readonly property real dragRightMargin: 38
    readonly property real bodyPadding: 8
    readonly property int managerHideDelayMs: 250
}
