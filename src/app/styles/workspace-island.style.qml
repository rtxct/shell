// ============================================================================
// File: styles/workspace-island.style.qml
// Purpose: Dimensions, indicator dot sizes, and Theme tokens for WorkspaceIsland.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color urgentColor: Theme.danger
    readonly property color accentText: Theme.textOnAccent
    readonly property color transparent: Theme.transparent

    readonly property real defaultBarLen: 620
    readonly property int maxVisible: 5
    readonly property real lengthPadding: 60

    readonly property real idleLen: 200
    readonly property real idleDepth: 44
    readonly property real hoverLen: 200
    readonly property real hoverDepth: 44
    readonly property real openScreenMargin: 100
    readonly property real openDepth: 560

    readonly property real idleSlant: 16
    readonly property real hoverSlant: 16
    readonly property real openSlant: 28
    readonly property real flare: 12

    readonly property real btnPressedScale: 0.98
    readonly property real btnHoverScale: 1.02
    readonly property int scaleAnimDurationMs: 100

    readonly property real cellSize: 28
    readonly property real dotSize: 24
    readonly property int urgentBorderWidth: 2
    readonly property int labelFontPx: 12
}
