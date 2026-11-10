// ============================================================================
// File: styles/notification-center-bar.style.qml
// Purpose: Tab dimensions, drawer geometry, typography, and Theme tokens for NotificationCenterBar.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color textPrimary: Theme.textPrimary
    readonly property color textDim: Theme.textDim
    readonly property color textSecondary: Theme.textSecondary
    readonly property color textSubtle: Theme.textSubtle
    readonly property color textOnAccent: Theme.textOnAccent
    readonly property color accent: Theme.accent
    readonly property color fill: Theme.backgroundPrimary
    readonly property color danger: Theme.danger
    readonly property color dividerColor: Theme.surfaceWhite08
    readonly property color buttonBg: Theme.surfaceWhite06
    readonly property color buttonHoverBg: Theme.surfaceWhite12
    readonly property color buttonBorder: Theme.surfaceWhite10
    readonly property color dangerClampedTint: Theme.dangerClampedTint18
    readonly property color emptyBellColor: Theme.surfaceWhite20
    readonly property color rowBg: Theme.surfaceWhite05
    readonly property color rowHoverBg: Theme.surfaceWhite09
    readonly property color rowBorder: Theme.surfaceWhite08
    readonly property color urgencyLowBar: Theme.surfaceWhite25
    readonly property color transparent: Theme.transparent

    readonly property real floatWidth: 460
    readonly property real floatHeight: 460
    readonly property real detachThresholdY: 14
    readonly property real detachThresholdHypot: 18

    readonly property real idleWidth: 76
    readonly property real idleHeight: 8
    readonly property real hoverHeight: 40
    readonly property real openWidth: 460
    readonly property real openHeight: 440
    readonly property int tabHoverDurationMs: 180
    readonly property int unhoverDelayMs: 220

    readonly property real tabSlant: 12
    readonly property real tabRadius: 8
    readonly property real tabFlare: 8
    readonly property real tabInset: 4
    readonly property real openSlant: 18
    readonly property real openRadius: 14
    readonly property real openFlare: 14
    readonly property real openInset: 8
    readonly property real openBottomInset: 10
    readonly property int openDurationMs: 420
    readonly property int closeDurationMs: 360
    readonly property int tabFadeDurationMs: 180
    readonly property real tabRowSpacing: 4
    readonly property int tabBellFontPx: 16
    readonly property int colorAnimDurationMs: 120
    readonly property real badgeHeight: 16
    readonly property real badgeMinWidth: 16
    readonly property real badgePadding: 8
    readonly property real badgeRadius: 8
    readonly property int badgeFontPx: 9

    readonly property real panelPadding: 8
    readonly property real panelSpacing: 10
    readonly property real headerHeight: 28
    readonly property real headerDragRightMargin: 180
    readonly property real headerSpacing: 8
    readonly property int headerIconFontPx: 16
    readonly property int headerTitleFontPx: 14
    readonly property real headerCountBadgeHeight: 20
    readonly property real headerCountBadgePadding: 10
    readonly property real headerCountBadgeRadius: 10
    readonly property int headerCountFontPx: 11
    readonly property real actionBtnHeight: 26
    readonly property real actionBtnPadding: 16
    readonly property real actionBtnRadius: 8
    readonly property real actionRowSpacing: 5
    readonly property int actionIconFontPx: 12
    readonly property int actionLabelFontPx: 11
    readonly property real disabledOpacity: 0.4
    readonly property real closeBtnSize: 26
    readonly property real closeBtnRadius: 8
    readonly property int closeIconFontPx: 11
    readonly property real dividerHeight: 1
    readonly property real emptyColumnSpacing: 8
    readonly property int emptyBellFontPx: 36
    readonly property int emptyTitleFontPx: 13
    readonly property int emptySubFontPx: 11
    readonly property real listSpacing: 8
    readonly property real rowMinHeight: 56
    readonly property real rowVerticalPadding: 18
    readonly property real rowRadius: 10
    readonly property int rowColorAnimDurationMs: 90
    readonly property real urgencyBarMargin: 4
    readonly property real urgencyBarWidth: 3
    readonly property real urgencyBarRadius: 1.5
    readonly property real rowIconLeftMargin: 12
    readonly property real rowIconSize: 28
    readonly property real rowIconRadius: 6
    readonly property int rowFallbackIconFontPx: 13
    readonly property real msgLeftMargin: 10
    readonly property real msgRightMargin: 6
    readonly property real msgSpacing: 2
    readonly property real metaRowSpacing: 6
    readonly property int rowTimeFontPx: 10
    readonly property real appNameRightReserve: 50
    readonly property int rowTitleFontPx: 12
    readonly property int rowBodyFontPx: 11
    readonly property real deleteBtnRightMargin: 8
    readonly property real deleteBtnSize: 22
    readonly property real deleteBtnRadius: 6
    readonly property int deleteIconFontPx: 10
    readonly property int groupExpandDurationMs: 260
    readonly property int deleteAnimDurationMs: 220
    readonly property real deleteSlideOffsetX: 32
}
