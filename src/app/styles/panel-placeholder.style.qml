// ============================================================================
// File: styles/panel-placeholder.style.qml
// Purpose: Typography and Theme tokens for PanelPlaceholder.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color textColor: Theme.textDim
    readonly property int fontPx: 18
}
