// ============================================================================
// File: styles/screen-locker.style.qml
// Purpose: Geometry, typography, and Theme tokens for ScreenLocker.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color backgroundColor: Theme.backgroundPrimary
    readonly property color scrimColor: Theme.backgroundPrimary
    readonly property real scrimOpacity: 0.50

    readonly property color clockColor: Theme.textBright
    readonly property color dateColor: Theme.textSecondary

    readonly property color userColor: Theme.textBright
    readonly property color userIconColor: Theme.textDim

    readonly property color inputColor: Theme.textBright
    readonly property color placeholderColor: Theme.textPlaceholder
    readonly property color inputBorder: Theme.surfaceWhite28
    readonly property color inputBorderFocused: Theme.borderWhite
    readonly property color inputBorderError: Theme.danger

    readonly property color actionColor: Theme.textSecondary
    readonly property color actionHoverColor: Theme.textBright
    readonly property color actionDangerHoverColor: Theme.danger

    readonly property int fadeInDurationMs: 320
    readonly property int fadeOutDurationMs: 220
}
