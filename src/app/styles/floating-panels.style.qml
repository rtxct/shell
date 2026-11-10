// ============================================================================
// File: styles/floating-panels.style.qml
// Purpose: Shared dimensions, typography, and Theme tokens for detached Floating*Panel views.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color textPrimary: Theme.textPrimary
    readonly property color textDim: Theme.textDim
    readonly property color textBright: Theme.textBright
    readonly property color textOnAccent: Theme.textOnAccent
    readonly property color accent: Theme.accent
    readonly property color danger: Theme.danger
    readonly property color searchBoxBg: Theme.surfaceWhite08
    readonly property color searchBoxBorder: Theme.surfaceWhite14
    readonly property color itemHoverBg: Theme.surfaceWhite10
    readonly property color sliderTrackBg: Theme.surfaceWhite14
    readonly property color buttonBg: Theme.surfaceWhite06
    readonly property color buttonHoverBg: Theme.surfaceWhite12
    readonly property color buttonBorder: Theme.surfaceWhite14
    readonly property color mutedTint: Theme.dangerTint18
    readonly property color cardBg: Theme.surfaceWhite05
    readonly property color cardBorder: Theme.surfaceWhite12
    readonly property color noteCardBg: Theme.surfaceWhite06
    readonly property color noteCardBorder: Theme.surfaceWhite10
    readonly property color editSwipeBg: Theme.editSwipeBg
    readonly property color transparent: Theme.transparent
    readonly property color cdSurfaceBg: Theme.circleOverrideExample
    readonly property color cdGrooveBorder: Theme.surfaceWhite14
    readonly property color cdSpindleBg: Theme.backgroundPrimary
    readonly property color cdOverlayBg: Theme.shadowBlack40
    readonly property color activeBadgeBg: Theme.accentGlowNearDock
    readonly property color paletteBlue: Theme.paletteBlue
    readonly property color paletteOrange: Theme.paletteOrange
    readonly property color paletteRed: Theme.paletteRed
    readonly property color paletteYellow: Theme.paletteYellow
    readonly property color paletteGreen: Theme.paletteGreen
    readonly property color paletteCyan: Theme.paletteCyan
    readonly property color palettePurple: Theme.palettePurple
    readonly property color palettePink: Theme.palettePink

    readonly property string iconFont: "Symbols Nerd Font"
    readonly property real cardRadius: 8
    readonly property real searchBoxHeight: 36
    readonly property int searchIconFontPx: 14
    readonly property int searchInputFontPx: 13
    readonly property real appRowHeight: 48
    readonly property int appTitleFontPx: 13
    readonly property int appCommentFontPx: 10

    readonly property real audioToggleSize: 28
    readonly property real audioToggleRadius: 14
    readonly property int audioIconFontPx: 15
    readonly property int audioLabelFontPx: 12
    readonly property real sliderTrackHeight: 22
    readonly property real sliderBarHeight: 6
    readonly property real sliderBarRadius: 3
    readonly property real sliderThumbSize: 12
    readonly property real sliderThumbRadius: 6
    readonly property real playBtnSize: 34
    readonly property real playBtnRadius: 17
    readonly property int mediaTransportFontPx: 14
    readonly property real cdDiscSize: 66
    readonly property real cdDiscRadius: 33
    readonly property real cdInnerGrooveSize: 44
    readonly property real cdSpindleRingSize: 16
    readonly property real cdSpindleHoleSize: 6
    readonly property int cdQuestionMarkFontPx: 26
    readonly property real pavuTabHeight: 28
    readonly property real pavuTabRadius: 7
    readonly property int pavuTabFontPx: 11
    readonly property real pavuPillHeight: 22
    readonly property real pavuPillRadius: 6
    readonly property int pavuPillFontPx: 10
    readonly property int pavuCardTitleFontPx: 12
    readonly property int pavuCardSubFontPx: 10

    readonly property real noteAddBtnSize: 26
    readonly property real noteAddBtnRadius: 13
    readonly property int noteAddInputDurationMs: 140
    readonly property real noteItemHeight: 38
    readonly property int noteSwipeSnapDurationMs: 180
    readonly property real noteSwipeMaxOffset: 65
    readonly property real noteSwipeActionThreshold: 34
}
