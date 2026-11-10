// ============================================================================
// File: styles/strip.style.qml
// Purpose: Dimensions, radii, and fill tokens for the top/left edge Strip.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color fill: Theme.backgroundPrimary
    readonly property real thickness: 6
    readonly property real defaultLength: 720
    readonly property real slant: 0
    readonly property real radius: 3
    readonly property real flare: 6
    readonly property int fadeDurationMs: 130
}
