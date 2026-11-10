// ============================================================================
// File: styles/weather-view.style.qml
// Purpose: Full weather view layout, forecast card sizing, and Theme tokens for WeatherView.
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
    readonly property color accent: Theme.accent
    readonly property color cardColor: Theme.surfaceWhite06
    readonly property color cardHoverColor: Theme.surfaceWhite10
    readonly property color dividerColor: Theme.surfaceWhite08
    readonly property color scrollBarColor: Theme.surfaceWhite20

    readonly property string iconFont: "JetBrainsMono Nerd Font"
    readonly property real headerPaddingX: 16
    readonly property real contentPaddingX: 90
    readonly property real headerHeight: 46
    readonly property int backIconFontPx: 20
    readonly property real backHitPadding: 12
    readonly property real locLeftMargin: 16
    readonly property int locNameFontPx: 16
    readonly property real locHitPadding: 8
    readonly property real bodyTopGap: 8
    readonly property int statusFontPx: 14

    readonly property real heroWidth: 190
    readonly property real heroSpacing: 4
    readonly property int heroIconFontPx: 72
    readonly property int heroTempFontPx: 48
    readonly property int heroDescFontPx: 15
    readonly property real heroStatsGap: 16
    readonly property int statsFontPx: 13

    readonly property real forecastLeftMargin: 24
    readonly property real forecastSpacing: 6
    readonly property real forecastRowHeight: 40
    readonly property real forecastCardRadius: 10
    readonly property real forecastDayX: 14
    readonly property real forecastDayWidth: 50
    readonly property int forecastDayFontPx: 13
    readonly property real forecastIconX: 84
    readonly property int forecastIconFontPx: 18
    readonly property real forecastTempRightMargin: 14
    readonly property int forecastTempFontPx: 13
    readonly property real forecastBottomMargin: 50
    readonly property real forecastRightMargin: 14
    readonly property real scrollBarWidth: 3
    readonly property real scrollBarRadius: 1.5
    readonly property real scrollBarRightMargin: 2
    readonly property real arrowHoverScale: 1.04
    readonly property real arrowPressedScale: 0.99
    readonly property real buttonHoverScale: 1.03
    readonly property real buttonPressedScale: 0.99
    readonly property real heroHoverScale: 1.03
    readonly property real heroPressedScale: 0.99
    readonly property real forecastItemHoverScale: 1.02
    readonly property real forecastItemPressedScale: 0.99
    readonly property real hourlyItemHoverScale: 1.03
    readonly property int buttonAnimDurationMs: 140
    readonly property int pickerAnimDurationMs: 240
    readonly property real pickerSlideOffsetY: 20

    readonly property int detailAnimDurationMs: 240
    readonly property real detailSlideOffsetX: 24
    readonly property int detailHeroIconFontPx: 42
    readonly property int detailTitleFontPx: 18
    readonly property int detailSubtitleFontPx: 13
    readonly property int detailSectionHeaderFontPx: 11
    readonly property real detailSectionGap: 10
    readonly property real hourlyCardWidth: 62
    readonly property real hourlyCardHeight: 84
    readonly property real hourlyCardRadius: 8
    readonly property real hourlyCardSpacing: 6
    readonly property int hourlyTimeFontPx: 11
    readonly property int hourlyIconFontPx: 18
    readonly property int hourlyTempFontPx: 13
    readonly property int hourlyPopFontPx: 10
    readonly property real metricCardHeight: 62
    readonly property real metricCardRadius: 8
    readonly property real metricGridSpacing: 8
    readonly property int metricLabelFontPx: 11
    readonly property int metricValueFontPx: 14
    readonly property int metricSubFontPx: 11
}
