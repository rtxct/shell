// ============================================================================
// File: styles/side-bar.style.qml
// Purpose: Geometry, droplet travel timings, and Theme tokens for SideBar hover wings.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color fill: Theme.backgroundPrimary
    readonly property color transparent: Theme.transparent
    readonly property color textPrimary: Theme.textPrimary
    readonly property int panelFontPx: 15

    readonly property real floatWidth: 720
    readonly property real floatHeight: 320
    readonly property real detachThresholdY: 14
    readonly property real detachThresholdHypot: 18

    readonly property real zoneInset: 190
    readonly property real hitHeight: 10
    readonly property real pillStartWidth: 300
    readonly property real pillStartHeight: 44
    readonly property real pillStartSlant: 30
    readonly property real openHeight: 500

    readonly property int openDelayMs: 110
    readonly property int closeDelayMs: 140
    readonly property int travelDurationMs: 280
    readonly property int expandDurationMs: 320
    readonly property int collapseDurationMs: 240
    readonly property real openSlant: 28
    readonly property real dropRadius: 12
    readonly property real dropFlare: 12

    // ── Caelestia Performance Panel Tokens (TopRightBar) ──
    readonly property real perfOverviewHeight: 260
    readonly property color perfArcPrimary: Theme.accent
    readonly property color perfArcSecondary: Theme.textSecondary
    readonly property color perfTrackPrimary: Theme.surfaceWhite14
    readonly property color perfTrackSecondary: Theme.surfaceWhite08
    readonly property color perfTextDim: Theme.textDim
    readonly property real perfResourceSize: 160
    readonly property real perfPrimaryScale: 1.2
    readonly property real perfStrokeThickness: 10
    readonly property real perfRowSpacing: 36
    readonly property real perfMaxTemp: 90
    readonly property real perfLabel1FontPx: 26
    readonly property real perfSublabel1FontPx: 13
    readonly property real perfLabel2FontPx: 13
    readonly property real perfSublabel2FontPx: 14
    readonly property real perfGapLabelTopMargin: 6
    readonly property int perfPollIntervalMs: 2000
    readonly property int perfAnimDurationMs: 400
    readonly property color perfCardBg: Theme.surfaceWhite06
    readonly property color perfCardHoverBg: Theme.surfaceWhite12
    readonly property color perfRowHoverBg: Theme.surfaceWhite25
    readonly property real perfRowRadius: 5
    readonly property color perfCardBorder: Theme.surfaceWhite14
    readonly property color perfCardHoverBorder: Theme.borderWhite
    readonly property color perfCardPressedBg: Theme.surfaceWhite20
    readonly property color perfGraphFill: Theme.surfaceWhite10
    readonly property color perfDanger: Theme.danger
    readonly property real perfCircleHoverScale: 1.06
    readonly property real perfCirclePressedScale: 0.94
    readonly property real perfCardHoverScale: 1.03
    readonly property real perfCardPressedScale: 0.97
    readonly property real perfArrowHoverScale: 1.16
    readonly property real perfArrowPressedScale: 0.90
    readonly property int perfMorphDurationMs: 320
    readonly property int perfHoverDurationMs: 160
}
