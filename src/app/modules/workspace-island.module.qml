// ============================================================================
// File: modules/workspace-island.module.qml
// Purpose: Vertical left-bar island module displaying active workspace indicators and expanding into WorkspaceCentral or circle launcher panels.
// Public API:
//   - Properties: maxShown, cellSize, dotSize, urgentColor, accentText, shown
//   - Functions:  pick()
// Dependencies: QtQuick, "../components", "../styles", "../theme"
// ============================================================================
import QtQuick
import "../components"
import "../styles"
import "../../../themes"

// The workspaces island in the middle of the LEFT bar.
//   idle  -> the workspaces that exist, the focused one highlighted
//   hover -> the island grows a little
//   click -> opens the workspace central (pick the workspace you want)
Island {
    id: root

    property real barLen: WorkspaceIslandStyle.defaultBarLen

    vertical: true
    panelId: "workspaces"
    title: "Workspaces"
    clickPanel: centralPanel

    // Dynamic island length: expands/contracts dynamically with active workspaces (no limit)
    readonly property real dynamicLen: Math.max(
        WorkspaceIslandStyle.cellSize + WorkspaceIslandStyle.lengthPadding,
        shown.length * WorkspaceIslandStyle.cellSize + WorkspaceIslandStyle.lengthPadding
    )

    // ── shape (this island's own numbers) ──
    idleLen: dynamicLen
    idleDepth: WorkspaceIslandStyle.idleDepth
    idleSlant: WorkspaceIslandStyle.idleSlant
    dropFlare: WorkspaceIslandStyle.flare
    hoverLen: dynamicLen + Math.max(0, WorkspaceIslandStyle.hoverLen - WorkspaceIslandStyle.idleLen)
    hoverDepth: WorkspaceIslandStyle.hoverDepth
    hoverSlant: WorkspaceIslandStyle.hoverSlant
    hoverScale: WorkspaceIslandStyle.btnHoverScale
    pressedScale: WorkspaceIslandStyle.btnPressedScale
    scaleAnimDurationMs: WorkspaceIslandStyle.scaleAnimDurationMs
    openLen: Math.max(hoverLen, barLen - WorkspaceIslandStyle.openScreenMargin)
    openDepth: WorkspaceIslandStyle.openDepth
    openSlant: WorkspaceIslandStyle.openSlant

    // ── style of the workspace indicators ──
    property int maxShown: WorkspaceIslandStyle.maxVisible              // how many workspaces fit in the idle island
    property real cellSize: WorkspaceIslandStyle.cellSize
    property real dotSize: WorkspaceIslandStyle.dotSize
    property color urgentColor: WorkspaceIslandStyle.urgentColor
    property color accentText: WorkspaceIslandStyle.accentText    // number colour on the highlighted workspace

    // the workspaces that exist (or are focused)
    readonly property var shown: pick()
    function pick() {
        var all = ctl.workspaces ? ctl.workspaces.items : []
        var open = []
        for (var i = 0; i < all.length; i++) {
            if (all[i].focused || all[i].occupied) {
                open.push(all[i])
            }
        }
        if (open.length === 0 && all.length > 0) {
            return [all[0]]
        }
        return open
    }

    Component {
        id: centralPanel
        WorkspaceCentral {
            ctl: root.ctl
        }
    }

    Column {
        anchors.centerIn: parent
        opacity: root.idleOpacity
        visible: opacity > 0.01

        Repeater {
            model: root.shown

            Item {
                id: cell
                required property var modelData
                width: root.cellSize
                height: root.cellSize

                Rectangle {
                    anchors.centerIn: parent
                    width: root.dotSize
                    height: width
                    radius: width / 2
                    color: cell.modelData.focused ? root.accent : WorkspaceIslandStyle.transparent
                    border.width: cell.modelData.urgent ? WorkspaceIslandStyle.urgentBorderWidth : 0
                    border.color: root.urgentColor
                }
                Text {
                    anchors.centerIn: parent
                    text: cell.modelData.label
                    color: cell.modelData.focused ? root.accentText : root.fg
                    font.pixelSize: WorkspaceIslandStyle.labelFontPx
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
