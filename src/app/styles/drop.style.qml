// ============================================================================
// File: styles/drop.style.qml
// Purpose: Default procedural geometry and color parameters for Drop.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color fill: Theme.backgroundBlack
    readonly property color primaryFill: Theme.backgroundPrimary
    readonly property color fillStrokeColor: Theme.transparent
    readonly property color strokeColor: Theme.borderWhite
    readonly property real strokeWidth: 1.2
    readonly property color glassSheenTop: Theme.glassSheenTop
    readonly property color glassSheenMid: Theme.glassSheenMid
    readonly property color glassSheenCore: Theme.glassSheenCore
    readonly property color glassSheenBottom: Theme.glassSheenBottom
    readonly property color glassInnerBevel: Theme.glassInnerBevel
    readonly property real bevelStrokeWidth: 3.5
    readonly property real slant: 0
    readonly property real radius: 12
    readonly property real flare: 12
    readonly property real inset: 12
    readonly property real bottomInset: 6
}
