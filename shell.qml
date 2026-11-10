// ============================================================================
// File: shell.qml
// Purpose: Application entry point. Instantiates shared service modules
//          (Weather, Events, Workspaces, Audio, StickNotes, Notifications)
//          and mounts a per-monitor Bar module across Quickshell.screens.
// Dependencies: Quickshell, QtQuick, modules/
// ============================================================================
import Quickshell
import Quickshell.Io
import QtQuick
import "src/app/modules"

ShellRoot {
    id: root

    // Automatic hot-reload watcher for theme/, styles/, components/, and modules/
    HotReload { id: hotReload }

    // IPC interface for window managers (e.g. Sway `bindsym $mod+e exec qs ipc call menu toggle`), scripts, and external shortcuts
    IpcHandler {
        target: "menu"

        function toggle(): void {
            root.toggleAppMenuRequested()
        }

        function open(): void {
            root.openAppMenuRequested()
        }

        function close(): void {
            root.closeAppMenuRequested()
        }

        function clipboard(): void {
            root.toggleClipboardRequested()
        }

        function openClipboard(): void {
            root.openClipboardRequested()
        }
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            root.toggleClipboardRequested()
        }

        function open(): void {
            root.openClipboardRequested()
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            screenLockerSvc.lock()
        }

        function unlock(): void {
            screenLockerSvc.unlock()
        }
    }

    signal toggleAppMenuRequested()
    signal openAppMenuRequested()
    signal closeAppMenuRequested()
    signal toggleClipboardRequested()
    signal openClipboardRequested()

    property bool anyMenuOpen: false

    // Shared services (one instance for all monitors).
    // NOTE: ids must NOT match Bar's property names: inside `Bar { weather: weather }` the
    // right-hand side resolves to Bar's own `weather` property (null), not to the service id.
    Weather { id: weatherSvc }
    Events { id: eventsSvc }
    Workspaces { id: workspacesSvc; backend: "sway" }
    Audio { id: audioSvc }
    StickNotes { id: stickNotesSvc }
    Notifications { id: notificationsSvc }
    ScreenLocker { id: screenLockerSvc }

    Variants {
        model: Quickshell.screens
        Bar {
            id: barItem
            weather: weatherSvc
            events: eventsSvc
            workspaces: workspacesSvc
            audio: audioSvc
            sticknotes: stickNotesSvc
            notifications: notificationsSvc
            screenLocker: screenLockerSvc
            anyMenuOpen: root.anyMenuOpen

            onAppMenuOpenChanged: {
                if (barItem.isLeftmostScreen && barItem.isBottommostScreen) {
                    root.anyMenuOpen = barItem.appMenuOpen
                }
            }

            onCloseAllRequested: {
                root.closeAppMenuRequested()
            }

            Connections {
                target: root
                function onToggleAppMenuRequested() {
                    barItem.toggleAppMenu()
                }
                function onOpenAppMenuRequested() {
                    barItem.openAppMenu()
                }
                function onCloseAppMenuRequested() {
                    barItem.closeAppMenu()
                }
                function onToggleClipboardRequested() {
                    barItem.toggleClipboard()
                }
                function onOpenClipboardRequested() {
                    barItem.openClipboard()
                }
            }
        }
    }
}
