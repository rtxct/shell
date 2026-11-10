// ============================================================================
// File: modules/niri-workspaces.module.qml
// Purpose: Niri compositor workspace backend polling `niri msg --json workspaces`.
// Public API:
//   - Properties: count, items
//   - Functions:  activate(item), parse(t)
// Dependencies: Quickshell.Io, QtQuick, "../components/service-parsers.js"
// ============================================================================
import Quickshell.Io
import QtQuick
import "../components/service-parsers.js" as ServiceParsers

// niri backend (STARTER, untested): polls `niri msg --json workspaces` once a second.
// Switch to it with  Workspaces { backend: "niri" }  in shell.qml.
// niri workspaces are dynamic and per-output, so this lists the ones niri reports.
Item {
    id: root

    property int count: 10                // unused here, kept for the same interface as sway
    property int pollIntervalMs: 1000

    property var items: []

    function activate(item) {
        act.command = ["niri", "msg", "action", "focus-workspace", String(item.number)]
        act.running = true
    }

    function parse(t) {
        var parsed = ServiceParsers.parseNiriWorkspaces(t)
        if (parsed !== null) {
            items = parsed
        }
    }

    Process {
        id: poll
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector { onStreamFinished: root.parse(this.text) }
    }
    Process { id: act }

    Timer {
        interval: root.pollIntervalMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!poll.running) poll.running = true }
    }
}
