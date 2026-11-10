// ============================================================================
// File: styles/middle-bar.style.qml
// Purpose: Dimensions, typography, and layout constants for MiddleBar (top clock island).
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color textPrimary: Theme.textPrimary

    readonly property real idleLen: 300
    readonly property real idleDepth: 44
    readonly property real hoverLen: 270
    readonly property real hoverDepth: 230
    readonly property real openDepth: 500

    readonly property real idleSlant: 30
    readonly property real hoverSlant: 24
    readonly property real openSlant: 28

    readonly property int idleClockFontPx: 15
    readonly property real hoverColumnTopMargin: 4
    readonly property real hoverCellSize: 26
}
