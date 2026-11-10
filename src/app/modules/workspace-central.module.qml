// ============================================================================
// File: modules/workspace-central.module.qml
// Purpose: Interactive 5-column workspace switcher grid hosted inside WorkspaceIsland and floating windows.
// Public API:
//   - Properties: ctl, columns, tileW, tileH, tileSpacing, tileRadius, fg, dim, accent, tileEmpty, tileOccupied, tileHover ...
// Dependencies: QtQuick, "../styles"
// ============================================================================
import QtQuick
import "../styles"

// The workspace central: every workspace as a tile. Click one to switch to it.
Item {
    id: root

    // ── input ──
    required property var ctl

    // ── style ──
    property int columns: WorkspaceCentralStyle.columns
    property real tileW: WorkspaceCentralStyle.tileWidth
    property real tileH: WorkspaceCentralStyle.tileHeight
    property real tileSpacing: WorkspaceCentralStyle.tileSpacing
    property real tileRadius: WorkspaceCentralStyle.tileRadius
    property color fg: WorkspaceCentralStyle.textPrimary
    property color dim: WorkspaceCentralStyle.textDim
    property color accent: WorkspaceCentralStyle.accent
    property color tileEmpty: WorkspaceCentralStyle.tileEmpty
    property color tileOccupied: WorkspaceCentralStyle.tileOccupied
    property color tileHover: WorkspaceCentralStyle.tileHover
    property color urgentColor: WorkspaceCentralStyle.urgentColor
    property color accentText: WorkspaceCentralStyle.accentText

    readonly property var items: ctl.workspaces ? ctl.workspaces.items : []

    Text {
        anchors.centerIn: parent
        visible: root.items.length === 0
        text: "No workspace data (is the compositor running?)"
        color: root.dim
        font.pixelSize: WorkspaceCentralStyle.emptyStatusFontPx
    }

    Grid {
        anchors.centerIn: parent
        columns: root.columns
        spacing: root.tileSpacing

        Repeater {
            model: root.items

            Rectangle {
                id: tile
                required property var modelData

                width: root.tileW
                height: root.tileH
                radius: root.tileRadius
                color: modelData.focused ? root.accent
                       : (tileMouse.containsMouse ? root.tileHover
                       : (modelData.occupied ? root.tileOccupied : root.tileEmpty))
                border.width: modelData.urgent ? WorkspaceCentralStyle.urgentBorderWidth : 0
                border.color: root.urgentColor
                Behavior on color { ColorAnimation { duration: WorkspaceCentralStyle.colorAnimDurationMs } }

                Text {
                    anchors.centerIn: parent
                    text: tile.modelData.label
                    color: tile.modelData.focused ? root.accentText : root.fg
                    font.pixelSize: WorkspaceCentralStyle.numberFontPx
                    font.weight: Font.Bold
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: WorkspaceCentralStyle.stateLabelBottomMargin
                    text: tile.modelData.focused ? "focused" : (tile.modelData.occupied ? "open" : "empty")
                    color: tile.modelData.focused ? root.accentText : root.dim
                    font.pixelSize: WorkspaceCentralStyle.stateLabelFontPx
                }

                MouseArea {
                    id: tileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.ctl.workspaces.activate(tile.modelData)
                        root.ctl.close()
                    }
                }
            }
        }
    }
}
