// ============================================================================
// File: styles/workspace-central.style.qml
// Purpose: Grid tile dimensions, typography, and Theme tokens for WorkspaceCentral.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color textPrimary: Theme.textPrimary
    readonly property color textDim: Theme.textDim
    readonly property color accent: Theme.accent
    readonly property color tileEmpty: Theme.surfaceWhite05
    readonly property color tileOccupied: Theme.surfaceWhite12
    readonly property color tileHover: Theme.surfaceWhite20
    readonly property color urgentColor: Theme.danger
    readonly property color accentText: Theme.textOnAccent

    readonly property int columns: 5
    readonly property real tileWidth: 92
    readonly property real tileHeight: 76
    readonly property real tileSpacing: 10
    readonly property real tileRadius: 16
    readonly property int emptyStatusFontPx: 14
    readonly property int urgentBorderWidth: 2
    readonly property int colorAnimDurationMs: 90
    readonly property int numberFontPx: 26
    readonly property real stateLabelBottomMargin: 8
    readonly property int stateLabelFontPx: 10
}
