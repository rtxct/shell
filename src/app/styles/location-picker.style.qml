// ============================================================================
// File: styles/location-picker.style.qml
// Purpose: Row dimensions, typography, and Theme tokens for LocationPicker.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color textPrimary: Theme.locationPickerTextPrimary
    readonly property color accent: Theme.locationPickerAccent
    readonly property color rowHover: Theme.locationPickerRowHover
    readonly property color rowCurrent: Theme.locationPickerRowCurrent
    readonly property color transparent: Theme.transparent

    readonly property real rowHeight: 28
    readonly property real rowRadius: 8
    readonly property real rowTextX: 10
    readonly property int fontSize: 13
}
