// ============================================================================
// File: styles/weather-card.style.qml
// Purpose: Compact card dimensions, typography, and Theme tokens for WeatherCard.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color textPrimary: Theme.textPrimary
    readonly property color textDim: Theme.textDim
    readonly property color cardColor: Theme.surfaceWhite06
    readonly property color cardHoverColor: Theme.surfaceWhite10
    readonly property color cardBorderColor: Theme.glassInnerBevel
    readonly property color glassRimHighlight: Theme.glassRimHighlight

    readonly property real cardRadius: 14
    readonly property real cardHoverScale: 1.02
    readonly property real cardPressedScale: 0.99
    readonly property int animDurationMs: 140
    readonly property int statusFontPx: 13
    readonly property real contentMargins: 12
    readonly property real columnSpacing: 9
    readonly property real headerRowSpacing: 12
    readonly property int iconFontPx: 34
    readonly property int tempFontPx: 24
    readonly property real descWidth: 180
    readonly property int descFontPx: 12
    readonly property int statsFontPx: 11
    readonly property real forecastSpacing: 6
    readonly property int forecastPreviewCount: 3
    readonly property real forecastItemWidth: 72
    readonly property int forecastFontPx: 11
    readonly property real pickerMargins: 8
    readonly property int pickerAnimDurationMs: 240
    readonly property real pickerSlideOffsetY: 16
}
