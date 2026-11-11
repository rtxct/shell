// ============================================================================
// File: styles/app-menu.style.qml
// Purpose: Popup dimensions, search bar sizing, list row metrics, and Theme tokens for AppMenu.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color textPrimary: Theme.textPrimary
    readonly property color textDim: Theme.textDim
    readonly property color textPlaceholder: Theme.textPlaceholder
    readonly property color textOnAccent: Theme.textOnAccent
    readonly property color accent: Theme.accent
    readonly property color cardBg: Theme.backgroundPrimary
    readonly property color dragPillColor: Theme.surfaceWhite25
    readonly property color searchBoxBg: Theme.surfaceWhite06
    readonly property color searchBoxBorder: Theme.surfaceWhite10
    readonly property color rowSelectedBg: Theme.surfaceWhite12
    readonly property color rowHoverBg: Theme.surfaceWhite06
    readonly property color rowDividerColor: Theme.surfaceWhite05
    readonly property color transparent: Theme.transparent

    readonly property real floatWidth: 720
    readonly property real floatHeight: 560
    readonly property real detachThresholdY: 14
    readonly property real detachThresholdHypot: 18

    readonly property real menuWidth: 720
    readonly property real maxPopupHeight: 560
    readonly property real screenHeightMargin: 40
    readonly property real dipHeight: 6
    readonly property real phase1End: 0.18
    readonly property real phase2End: 0.52
    readonly property int openDurationMs: 640
    readonly property int closeDurationMs: 520

    readonly property real openSlant: 18
    readonly property real cardRadius: 14
    readonly property real openFlare: 14
    readonly property real openInset: 8
    readonly property real openBottomInset: 10
    readonly property real cardPadding: 8
    readonly property real cardSpacing: 6
    readonly property real dragHandleHeight: 14
    readonly property real dragPillWidth: 36
    readonly property real dragPillHeight: 4
    readonly property real dragPillRadius: 2
    readonly property real dragHitPadding: 4

    readonly property real searchBarHeight: 44
    readonly property int searchRevealDurationMs: 180
    readonly property int searchFadeDurationMs: 150
    readonly property real searchBoxRadius: 10
    readonly property int borderColorAnimMs: 120
    readonly property real searchBoxLeftMargin: 12
    readonly property real searchBoxRightMargin: 10
    readonly property real searchRowSpacing: 8
    readonly property int searchInputFontPx: 13
    readonly property int clearIconFontPx: 12
    readonly property real clearHitPadding: 6

    readonly property real scrollBarRightMargin: 2
    readonly property real scrollBarWidth: 3
    readonly property real scrollBarMinHeight: 16
    readonly property real scrollBarRadius: 1.5
    readonly property int scrollFadeDurationMs: 180

    readonly property real itemRowHeight: 52
    readonly property real rowRadius: 10
    readonly property int rowColorAnimDurationMs: 90
    readonly property real textLeftMargin: 16
    readonly property real textRightMargin: 16
    readonly property real textSpacing: 2
    readonly property int appNameFontPx: 13
    readonly property int appDescFontPx: 11
    readonly property real dividerLeftMargin: 16
    readonly property real dividerRightMargin: 16
    readonly property real dividerHeight: 1

    // ── Sort Options Footer Tokens ──
    readonly property real sortFooterHeight: 28
    readonly property real sortDividerMargin: 12
    readonly property real sortDividerHeight: 1
    readonly property color sortDividerColor: Theme.borderWhite
    readonly property int sortTextFontPx: 11
    readonly property color sortTextColor: Theme.textDim
    readonly property color sortTextHoverColor: Theme.textBright
    readonly property int sortAnimDurationMs: 180
    readonly property int sortFadeDurationMs: 150
}
