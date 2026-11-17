// ============================================================================
// File: styles/drop.style.qml
// Purpose: Default procedural geometry and color parameters for Drop.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color fill: Theme.dropFill
    readonly property color primaryFill: Theme.dropPrimaryFill
    readonly property color fillStrokeColor: Theme.dropFillStrokeColor
    readonly property color strokeColor: Theme.dropStrokeColor
    readonly property real strokeWidth: 1.2
    readonly property color glassSheenTop: Theme.dropGlassSheenTop
    readonly property color glassSheenMid: Theme.dropGlassSheenMid
    readonly property color glassSheenCore: Theme.dropGlassSheenCore
    readonly property color glassSheenBottom: Theme.dropGlassSheenBottom
    readonly property color glassInnerBevel: Theme.dropGlassInnerBevel
    readonly property real bevelStrokeWidth: 3.5
    readonly property real slant: 0
    readonly property real radius: 12
    readonly property real flare: 12
    readonly property real inset: 12
    readonly property real bottomInset: 6
}
