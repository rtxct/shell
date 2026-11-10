// ============================================================================
// File: styles/events-list.style.qml
// Purpose: Card dimensions, typography, and Theme tokens for EventsList.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color textPrimary: Theme.textPrimary
    readonly property color textDim: Theme.textDim
    readonly property color accent: Theme.accent
    readonly property color cardColor: Theme.surfaceWhite06
    readonly property color cardHoverColor: Theme.surfaceWhite10

    readonly property real layoutSpacing: 10
    readonly property real headerHeight: 24
    readonly property int headerFontPx: 12
    readonly property real headerLetterSpacing: 1.5
    readonly property int statusFontPx: 13
    readonly property real listSpacing: 8
    readonly property real cardHeight: 52
    readonly property real cardRadius: 12
    readonly property real accentBarX: 11
    readonly property real accentBarWidth: 4
    readonly property real accentBarVerticalInset: 22
    readonly property real accentBarRadius: 2
    readonly property real contentLeftMargin: 28
    readonly property real contentRightMargin: 12
    readonly property real contentSpacing: 3
    readonly property int titleFontPx: 14
    readonly property int metaFontPx: 12
    readonly property string iconFont: "Symbols Nerd Font"
    readonly property string homeGlyph: ""
    readonly property int homeIconFontPx: 13
    readonly property real homeButtonBoxSize: 20
    readonly property string backGlyph: "←"
    readonly property int backIconFontPx: 14
    readonly property string clockGlyph: ""
    readonly property string locationGlyph: ""
    readonly property string repeatGlyph: ""
    readonly property int detailIconFontPx: 13
    readonly property real buttonHoverScale: 1.04
    readonly property real buttonPressedScale: 0.99
    readonly property real cardHoverScale: 1.015
    readonly property real cardPressedScale: 0.99
    readonly property int fadeOutDurationMs: 90
    readonly property int fadeInDurationMs: 140
    readonly property real transitionSlideOffsetY: 6
    readonly property int animDurationMs: 140

    readonly property int detailAnimDurationMs: 220
    readonly property real detailSlideOffsetX: 20
    readonly property real detailSpacing: 10
    readonly property int detailTitleFontPx: 15
    readonly property int detailMetaFontPx: 13
    readonly property int detailSectionFontPx: 11
    readonly property int detailDescFontPx: 12
    readonly property real detailCardRadius: 10
    readonly property real detailCardPadding: 12
    readonly property real detailAccentBarWidth: 3
    readonly property real detailAccentBarRadius: 1.5
}
