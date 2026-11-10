// ============================================================================
// File: modules/workspaces-service.module.qml
// Purpose: Compositor-agnostic workspace service frontend selecting between SwayWorkspaces and NiriWorkspaces.
// Public API:
//   - Properties: backend, count, pollIntervalMs, items
//   - Functions:  activate(item), applyConfig(text), stripList(max)
// Dependencies: Quickshell, Quickshell.Io, QtQuick, "../components/service-parsers.js"
// ============================================================================
import Quickshell
import Quickshell.Io
import QtQuick
import "../components/service-parsers.js" as ServiceParsers

// Workspace data for the left bar, independent of the compositor.
// Pick the backend in config/workspaces.config.json or shell.qml:  Workspaces { backend: "sway" }  (or "niri")
//
// Every backend provides:
//   items: [ { id, number, name, label, focused, occupied, urgent }, ... ]
//   activate(item): switch to that workspace
Item {
    id: root

    property string backend: "sway"       // "sway" | "niri"
    property int count: 10                // how many numbered workspaces the central shows
    property int pollIntervalMs: 1000

    readonly property var items: loader.item ? loader.item.items : []
    function activate(item) { if (loader.item) loader.item.activate(item) }

    function applyConfig(text) {
        var parsed = ServiceParsers.parseWorkspacesConfig(text, root)
        root.backend = parsed.backend
        root.count = parsed.count
        root.pollIntervalMs = parsed.pollIntervalMs
    }

    FileView {
        id: configFile
        path: Quickshell.shellPath("config/workspaces.config.json")
        watchChanges: true
        onFileChanged: configFile.reload()
        onLoaded: root.applyConfig(configFile.text())
    }

    // Return up to `max` workspaces for the collapsed strip:
    // every occupied/focused workspace, padded with 1..max so the strip is never empty.
    function stripList(max) {
        return ServiceParsers.stripWorkspaces(items, max)
    }

    Component { id: sway; SwayWorkspaces { count: root.count } }
    Component { id: niri; NiriWorkspaces { count: root.count; pollIntervalMs: root.pollIntervalMs } }

    Loader {
        id: loader
        sourceComponent: root.backend === "niri" ? niri : sway
    }
}
