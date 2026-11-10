// ============================================================================
// File: modules/stick-notes-service.module.qml
// Purpose: Asynchronous process service wrapping scripts/sticknotes/sticknote-storage.py for JSON CRUD.
// Public API:
//   - Properties: items, count, scriptPath
//   - Functions:  reload(), create(name), deleteNote(nid), renameNote(nid, name), addItem(nid, text), editItem(nid, index, text), deleteItem(nid, index)
// Dependencies: Quickshell, Quickshell.Io, QtQuick
// ============================================================================
import Quickshell
import Quickshell.Io
import QtQuick

// Stick Note Service managing ~/.cache/sticknote/*.json files
Item {
    id: root

    property var items: []
    readonly property int count: items.length
    readonly property string scriptPath: Quickshell.shellPath("src/app/scripts/sticknotes/sticknote-storage.py")

    Component.onCompleted: reload()

    // ── Asynchronous Process Runners ──
    Process {
        id: procList
        command: ["python3", root.scriptPath, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.items = JSON.parse(this.text)
                } catch (e) {
                    root.items = []
                }
            }
        }
    }

    Process {
        id: procAction
        onExited: root.reload()
    }

    function reload() {
        if (!procList.running) procList.running = true
    }

    function create(name) {
        procAction.command = ["python3", root.scriptPath, "create", name || "Stick Note"]
        procAction.running = true
    }

    function deleteNote(nid) {
        procAction.command = ["python3", root.scriptPath, "delete", nid]
        procAction.running = true
    }

    function renameNote(nid, name) {
        procAction.command = ["python3", root.scriptPath, "rename", nid, name || "Stick Note"]
        procAction.running = true
    }

    function setColor(nid, colorKey) {
        procAction.command = ["python3", root.scriptPath, "set_color", nid, String(colorKey || "")]
        procAction.running = true
    }

    function addItem(nid, text) {
        if (!text || !text.trim()) return
        procAction.command = ["python3", root.scriptPath, "add_item", nid, text.trim()]
        procAction.running = true
    }

    function editItem(nid, index, text) {
        if (!text || !text.trim()) return
        procAction.command = ["python3", root.scriptPath, "edit_item", nid, String(index), text.trim()]
        procAction.running = true
    }

    function deleteItem(nid, index) {
        procAction.command = ["python3", root.scriptPath, "delete_item", nid, String(index)]
        procAction.running = true
    }
}
