// ============================================================================
// File: components/panel-placeholder.component.qml
// Purpose: Starter placeholder view displayed inside newly configured launcher circle panels.
// Public API:
//   - Properties: text, color, size
// Dependencies: QtQuick, "../styles"
// ============================================================================
import QtQuick
import "../styles"

// Stand-in content for the circles. Copy this file, build your own panel, and point the
// circle's `panel:` at it.
Item {
    id: root

    property string text: ""

    // ── style ──
    property color color: PanelPlaceholderStyle.textColor
    property real size: PanelPlaceholderStyle.fontPx

    Text {
        anchors.centerIn: parent
        text: root.text + "\n(replace this panel)"
        horizontalAlignment: Text.AlignHCenter
        color: root.color
        font.pixelSize: root.size
    }
}
