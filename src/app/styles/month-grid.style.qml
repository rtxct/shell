// ============================================================================
// File: styles/month-grid.style.qml
// Purpose: Cell dimensions, typography, and Theme tokens for MonthGrid.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color textPrimary: Theme.textPrimary
    readonly property color textMuted: Theme.textMuted
    readonly property color accent: Theme.accent
    readonly property color todayText: Theme.textOnAccent
    readonly property color hoverCircleColor: Theme.surfaceWhite12
    readonly property color selectedCircleColor: Theme.surfaceWhite20
    readonly property color textBright: Theme.textBright
    readonly property int defaultCellSize: 30
    readonly property real headerHeight: 30
    readonly property int titleFontPx: 14
    readonly property real headerTitleSpacing: 8
    readonly property string iconFont: "Symbols Nerd Font"
    readonly property string homeGlyph: ""
    readonly property int homeIconFontPx: 14
    readonly property real homeButtonBoxSize: 20
    readonly property real navArrowMargin: 6
    readonly property int navArrowFontPx: 22
    readonly property real navHitPadding: 8
    readonly property real dowHeight: 22
    readonly property int dowFontPx: 9
    readonly property real todayPillInset: 6
    readonly property real dayFontRatio: 0.40
    readonly property real eventDotSize: 4
    readonly property real eventDotBottomOffset: 8
    readonly property real dayHoverScale: 1.04
    readonly property real dayPressedScale: 0.99
    readonly property real todayHoverScale: 1.04
    readonly property real buttonHoverScale: 1.04
    readonly property real buttonPressedScale: 0.99
    readonly property int animDurationMs: 140
}
