// ============================================================================
// File: styles/stick-notes-bar.style.qml
// Purpose: Right-edge drawer geometry, swipe thresholds, and Theme tokens for StickNotesBar.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color textPrimary: Theme.textPrimary
    readonly property color textDim: Theme.textDim
    readonly property color textOnAccent: Theme.textOnAccent
    readonly property color accent: Theme.accent
    readonly property color fill: Theme.backgroundPrimary
    readonly property color danger: Theme.danger
    readonly property color cardBg: Theme.surfaceWhite07
    readonly property color inputBg: Theme.surfaceWhite08
    readonly property color inputBorder: Theme.surfaceWhite16
    readonly property color deleteHoverTint: Theme.dangerTint25
    readonly property color addBtnBg: Theme.surfaceWhite06
    readonly property color addBtnHoverBg: Theme.surfaceWhite12
    readonly property color addBtnBorder: Theme.surfaceWhite14
    readonly property color itemRowBg: Theme.surfaceWhite09
    readonly property color editSwipeTint: Theme.editTint25
    readonly property color editSwipeIcon: Theme.editSwipeIcon
    readonly property color editInputBorder: Theme.surfaceWhite12
    readonly property color transparent: Theme.transparent
    readonly property color textBright: Theme.textBright
    readonly property color paletteBlue: Theme.paletteBlue
    readonly property color paletteOrange: Theme.paletteOrange
    readonly property color paletteRed: Theme.paletteRed
    readonly property color paletteYellow: Theme.paletteYellow
    readonly property color paletteGreen: Theme.paletteGreen
    readonly property color paletteCyan: Theme.paletteCyan
    readonly property color palettePurple: Theme.palettePurple
    readonly property color palettePink: Theme.palettePink

    readonly property real floatWidth: 340
    readonly property real floatHeight: 440
    readonly property real detachThresholdX: -14
    readonly property real detachThresholdHypot: 18

    readonly property real plusIdleHeight: 60
    readonly property real plusHoverDepth: 44
    readonly property real drawerIdleDepth: 8
    readonly property real drawerOpenDepth: 300
    readonly property real drawerOpenHeight: 260
    readonly property real stackSpacing: 10

    readonly property int plusUnhoverMs: 240
    readonly property real plusSlant: 12
    readonly property real plusRadius: 10
    readonly property real plusFlare: 10
    readonly property real plusInset: 4
    readonly property int plusExpandDurationMs: 200
    readonly property int plusIconFontPx: 20
    readonly property real plusShowThreshold: 20
    readonly property int colorAnimDurationMs: 120

    readonly property real creationHeight: 240
    readonly property real creationWidth: 280
    readonly property int creationAnimDurationMs: 220
    readonly property real creationSlant: 18
    readonly property real creationRadius: 12
    readonly property real creationFlare: 12
    readonly property real creationInset: 8
    readonly property real creationMargins: 14
    readonly property real creationSpacing: 12
    readonly property real creationHeaderSpacing: 8
    readonly property int creationHeaderIconFontPx: 15
    readonly property int creationHeaderTitleFontPx: 13
    readonly property real creationInputHeight: 38
    readonly property real creationInputRadius: 8
    readonly property real creationInputMargin: 10
    readonly property int creationInputFontPx: 13
    readonly property int creationHintFontPx: 10
    readonly property real creationBtnWidth: 68
    readonly property real creationBtnHeight: 28
    readonly property real creationBtnRadius: 6
    readonly property int creationBtnFontPx: 11

    readonly property real drawerIdleHeight: 64
    readonly property int drawerHeightDurationMs: 220
    readonly property int drawerUnhoverMs: 350
    readonly property real drawerOpenSlant: 18
    readonly property real drawerIdleSlant: 10
    readonly property real drawerRadius: 12
    readonly property real drawerFlare: 12
    readonly property real drawerInset: 6
    readonly property int drawerDepthDurationMs: 240
    readonly property real closedTabBarWidth: 3
    readonly property real closedTabBarHeight: 24
    readonly property real closedTabBarRadius: 1.5
    readonly property real closedTabBarOpacity: 0.8

    readonly property real openContentMargins: 10
    readonly property real openShowThreshold: 120
    readonly property int openFadeDurationMs: 150
    readonly property real openColumnSpacing: 8
    readonly property real noteHeaderHeight: 26
    readonly property real noteHeaderSpacing: 6
    readonly property int noteHeaderIconFontPx: 14
    readonly property int noteHeaderTitleFontPx: 13
    readonly property real noteHeaderTitleRightReserve: 24
    readonly property real deleteBtnSize: 22
    readonly property int deleteIconFontPx: 12
    readonly property int fastColorAnimDurationMs: 100
    readonly property real addBtnHeight: 30
    readonly property real addBtnRadius: 8
    readonly property int addIconFontPx: 16
    readonly property int addLabelFontPx: 11
    readonly property real itemInputHeight: 34
    readonly property real itemInputRadius: 6
    readonly property real itemInputMargin: 8
    readonly property int itemInputFontPx: 12
    readonly property int itemPlaceholderFontPx: 11
    readonly property real notesListSpacing: 6
    readonly property real rowEditingHeight: 36
    readonly property real rowDisplayHeight: 38
    readonly property real swipeRevealedOffset: 48
    readonly property real swipeMaxOffset: 54
    readonly property real swipeCommitThreshold: 30
    readonly property real swipeActionRadius: 6
    readonly property int swipeActionIconFontPx: 14
    readonly property real noteCardTextMargin: 10
}
