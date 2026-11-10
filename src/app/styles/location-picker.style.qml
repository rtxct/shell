// ============================================================================
// File: styles/location-picker.style.qml
// Purpose: Row dimensions, typography, and Theme tokens for LocationPicker.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color textPrimary: Theme.textPrimary
    readonly property color accent: Theme.accent
    readonly property color rowHover: Theme.surfaceWhite06
    readonly property color rowCurrent: Theme.surfaceWhite10
    readonly property color transparent: Theme.transparent

    readonly property real rowHeight: 28
    readonly property real rowRadius: 8
    readonly property real rowTextX: 10
    readonly property int fontSize: 13
}
