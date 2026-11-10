// ============================================================================
// File: modules/sway-workspaces.module.qml
// Purpose: Sway/i3 IPC workspace backend powered by Quickshell.I3.
// Public API:
//   - Properties: count, items
//   - Functions:  build(), activate(item)
// Dependencies: Quickshell.I3, QtQuick
// ============================================================================
import Quickshell.I3
import QtQuick

// Sway backend (Quickshell's i3/sway IPC module; it follows $SWAYSOCK on its own).
// Lists workspaces 1..count (empty ones too, so you can jump to them) plus any named ones.
// Note: it shows the workspaces of ALL outputs.
Item {
    id: root

    property int count: 10

    readonly property var items: build()

    function build() {
        var vals = I3.workspaces.values
        var byNum = {}
        var extras = []
        for (var i = 0; i < vals.length; i++) {
            var w = vals[i]
            if (w.number >= 1 && w.number <= root.count) byNum[w.number] = w
            else extras.push(w)
        }

        var out = []
        for (var n = 1; n <= root.count; n++) {
            var ws = byNum[n]
            out.push({
                id: n,
                number: n,
                name: ws ? ws.name : String(n),
                label: String(n),
                focused: ws ? ws.focused : false,
                occupied: ws !== undefined,
                urgent: ws ? !!ws.urgent : false
            })
        }
        extras.forEach(function (x) {
            out.push({
                id: x.name,
                number: x.number,
                name: x.name,
                label: x.name.slice(0, 3),
                focused: x.focused,
                occupied: true,
                urgent: !!x.urgent
            })
        })
        return out
    }

    function activate(item) {
        if (item.number >= 1) I3.dispatch("workspace number " + item.number)
        else I3.dispatch("workspace \"" + item.name + "\"")
    }
}
