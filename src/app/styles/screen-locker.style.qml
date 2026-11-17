// ============================================================================
// File: styles/screen-locker.style.qml
// Purpose: Geometry, typography, and Theme tokens for ScreenLocker.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color backgroundColor: Theme.screenLockerBackgroundColor
    readonly property color scrimColor: Theme.screenLockerScrimColor
    readonly property real scrimOpacity: 0.50

    readonly property color clockColor: Theme.screenLockerClockColor
    readonly property color dateColor: Theme.screenLockerDateColor

    readonly property color userColor: Theme.screenLockerUserColor
    readonly property color userIconColor: Theme.screenLockerUserIconColor

    readonly property color inputColor: Theme.screenLockerInputColor
    readonly property color placeholderColor: Theme.screenLockerPlaceholderColor
    readonly property color inputBorder: Theme.screenLockerInputBorder
    readonly property color inputBorderFocused: Theme.screenLockerInputBorderFocused
    readonly property color inputBorderError: Theme.screenLockerInputBorderError

    readonly property color actionColor: Theme.screenLockerActionColor
    readonly property color actionHoverColor: Theme.screenLockerActionHoverColor
    readonly property color actionDangerHoverColor: Theme.screenLockerActionDangerHoverColor

    readonly property int fadeInDurationMs: 320
    readonly property int fadeOutDurationMs: 220
}
