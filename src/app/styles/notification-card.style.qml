// ============================================================================
// File: styles/notification-card.style.qml
// Purpose: Water bubble rise physics, card dimensions, urgency colors, and timings for NotificationCard.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color background: Theme.notificationCardBackground
    readonly property color urgencyCritical: Theme.notificationCardUrgencyCritical
    readonly property color urgencyNormal: Theme.notificationCardUrgencyNormal
    readonly property color urgencyLow: Theme.notificationCardUrgencyLow
    readonly property color risingBorder: Theme.notificationCardRisingBorder
    readonly property color bubbleShine: Theme.notificationCardBubbleShine
    readonly property color iconBadgeBg: Theme.notificationCardIconBadgeBg
    readonly property color iconBadgeBorder: Theme.notificationCardIconBadgeBorder
    readonly property color summaryText: Theme.notificationCardSummaryText
    readonly property color bodyText: Theme.notificationCardBodyText
    readonly property color closeTextIdle: Theme.notificationCardCloseTextIdle
    readonly property color closeTextHover: Theme.notificationCardCloseTextHover
    readonly property color closeBtnHoverBg: Theme.notificationCardCloseBtnHoverBg
    readonly property color closeBtnIdleBg: Theme.notificationCardCloseBtnIdleBg
    readonly property color glassSheenTop: Theme.notificationCardGlassSheenTop
    readonly property color glassSheenMid: Theme.notificationCardGlassSheenMid
    readonly property color glassSheenCore: Theme.notificationCardGlassSheenCore
    readonly property color glassSheenBottom: Theme.notificationCardGlassSheenBottom
    readonly property color glassInnerBevel: Theme.notificationCardGlassInnerBevel
    readonly property color glassRimHighlight: Theme.notificationCardGlassRimHighlight
    readonly property color transparent: Theme.transparent
    readonly property real cardWidth: 350
    readonly property real cardHeight: 54
    readonly property real bubbleStartWidth: 32
    readonly property real bubbleStartHeight: 24
    readonly property real cardRadius: 12
    readonly property real cardBorderWidth: 1.0

    readonly property int riseDurationMs: 440
    readonly property int stretchUpMs: 170
    readonly property int stretchDownMs: 270
    readonly property real stretchScaleY: 1.25
    readonly property real squashScaleX: 0.85
    readonly property int expandDurationMs: 260
    readonly property int contentFadeInMs: 220
    readonly property int borderColorAnimMs: 240
    readonly property int dismissContentFadeMs: 100
    readonly property int dismissBubbleFadeMs: 160
    readonly property int dismissCollapseMs: 220
    readonly property int defaultTimeoutMs: 5000
    readonly property int criticalTimeoutMs: 8000

    readonly property real shineWidthRatio: 0.45
    readonly property real shineMaxWidth: 14
    readonly property real shineHeight: 3
    readonly property real shineRadius: 1.5
    readonly property real shineTopMargin: 3
    readonly property real shineRisingOpacity: 0.85
    readonly property int shineFadeDurationMs: 150
    readonly property real contentHorizontalMargin: 12
    readonly property real contentVerticalMargin: 6
    readonly property real iconSize: 32
    readonly property real iconRadius: 8
    readonly property int iconBorderWidth: 1
    readonly property int fallbackBellFontPx: 15
    readonly property real contentLeftMargin: 10
    readonly property real contentRightMargin: 8
    readonly property real contentTextSpacing: 2
    readonly property int summaryFontPx: 13
    readonly property int bodyFontPx: 11
    readonly property real closeBtnSize: 22
    readonly property int closeIconFontPx: 11
}
