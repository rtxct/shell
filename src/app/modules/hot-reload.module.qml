// ============================================================================
// File: modules/hot-reload.module.qml
// Purpose: Automatic QML/JS/qmldir hot-reload watcher for subdirectories (theme/, styles/, components/, modules/) using dotted filenames.
// Public API:
//   - Properties: watchedFiles, debounceMs
//   - Functions:  triggerReload()
// Dependencies: Quickshell, Quickshell.Io, QtQuick
// ============================================================================
import Quickshell
import Quickshell.Io
import QtQuick

// Quickshell's built-in file watcher only auto-tracks shell.qml and standard PascalCase QML files.
// Because our modular architecture uses dotted filenames (*.style.qml, *.component.qml, *.module.qml)
// registered via qmldir, this service discovers and watches all files under theme/, styles/,
// components/, and modules/ and triggers Quickshell.reload(false) whenever any file is saved.
Item {
    id: root

    property var watchedFiles: []
    property int debounceMs: 80

    function triggerReload() {
        reloadTimer.restart()
    }

    Process {
        id: discoverProc
        running: true
        command: [
            "find",
            Quickshell.shellPath("themes"),
            Quickshell.shellPath("src/app/styles"),
            Quickshell.shellPath("src/app/components"),
            Quickshell.shellPath("src/app/modules"),
            "-type", "f",
            "(", "-name", "*.qml", "-o", "-name", "*.js", "-o", "-name", "qmldir", ")"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = this.text.trim()
                if (raw.length === 0) return
                var lines = raw.split("\n")
                var out = []
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (line.length > 0) out.push(line)
                }
                root.watchedFiles = out
            }
        }
    }

    Variants {
        model: root.watchedFiles
        FileView {
            required property string modelData
            path: modelData
            preload: false
            watchChanges: true
            onFileChanged: root.triggerReload()
        }
    }

    Timer {
        id: reloadTimer
        interval: root.debounceMs
        repeat: false
        onTriggered: Quickshell.reload(false)
    }
}
