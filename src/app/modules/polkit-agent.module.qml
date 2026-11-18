// ============================================================================
// File: modules/polkit-agent.module.qml
// Purpose: GNOME-style Wayland Polkit authentication agent over WlrLayer.Overlay with Sway/Niri focus stealing.
// Public API:
//   - Properties: workspaces, isRegistered, isActive, flow, targetScreenName
//   - Signals:    focusRequested()
//   - Functions:  resolveTargetScreenName(), ensurePolkitFocus(outName)
// Dependencies: Quickshell, Quickshell.Wayland, Quickshell.Services.Polkit, Quickshell.Io, QtQuick, "../components", "../styles"
// ============================================================================
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import Quickshell.Io
import QtQuick
import "../components"
import "../styles"

Scope {
    id: root

    property var workspaces: null

    readonly property bool isRegistered: agent.isRegistered
    readonly property bool isActive: agent.isActive
    readonly property var flow: agent.flow
    readonly property string fallbackUserName: Quickshell.env("USER") || ""

    property string targetScreenName: ""

    signal focusRequested()

    function resolveTargetScreenName() {
        var screens = Quickshell.screens
        if (!screens || screens.length === 0) return ""

        if (root.workspaces && root.workspaces.items) {
            var items = root.workspaces.items
            for (var i = 0; i < items.length; i++) {
                var item = items[i]
                if (item && item.focused && item.output) {
                    var outName = String(item.output)
                    for (var j = 0; j < screens.length; j++) {
                        if (screens[j] && String(screens[j].name) === outName) {
                            return outName
                        }
                    }
                }
            }
        }

        // Fall back to the leftmost monitor when no focused output is reported (e.g. Sway backend)
        var bestScreen = screens[0]
        for (var k = 1; k < screens.length; k++) {
            var s = screens[k]
            if (s && bestScreen && typeof s.x === "number" && typeof bestScreen.x === "number" && s.x < bestScreen.x) {
                bestScreen = s
            }
        }
        return (bestScreen && bestScreen.name) ? String(bestScreen.name) : ""
    }

    function ensurePolkitFocus(outName) {
        if (!outName) return
        focusProc.command = [
            "sh", "-c",
            "if [ -n \"$NIRI_SOCKET\" ] || [ \"$XDG_CURRENT_DESKTOP\" = \"niri\" ]; then " +
            "niri msg action focus-monitor \"$1\" >/dev/null 2>&1 || true; " +
            "elif [ -n \"$SWAYSOCK\" ] || [ -n \"$I3SOCK\" ]; then " +
            "swaymsg focus output \"$1\" >/dev/null 2>&1 || true; fi",
            "--", String(outName)
        ]
        focusProc.running = true
    }

    Process {
        id: focusProc
        onExited: {
            if (root.isActive) {
                root.focusRequested()
            }
        }
    }

    PolkitAgent {
        id: agent

        onAuthenticationRequestStarted: {
            root.targetScreenName = root.resolveTargetScreenName()
            root.ensurePolkitFocus(root.targetScreenName)
            root.focusRequested()
        }

        onIsActiveChanged: {
            if (agent.isActive) {
                if (root.targetScreenName.length === 0) {
                    root.targetScreenName = root.resolveTargetScreenName()
                }
                root.ensurePolkitFocus(root.targetScreenName)
                root.focusRequested()
            } else {
                root.targetScreenName = ""
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overlayWin
            required property var modelData

            readonly property string screenName: (modelData && modelData.name) ? String(modelData.name) : ""
            readonly property bool isDialogScreen: {
                if (!root.isActive) return false
                if (root.targetScreenName.length > 0) {
                    return screenName === root.targetScreenName
                }
                var screens = Quickshell.screens
                return screens && screens.length > 0 && screens[0] === modelData
            }

            Component.onCompleted: if (modelData) screen = modelData

            anchors { top: true; bottom: true; left: true; right: true }
            color: PolkitAgentStyle.transparent
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-polkit"
            WlrLayershell.keyboardFocus: (root.isActive && isDialogScreen)
                ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.None

            visible: root.isActive

            Item {
                id: overlayRoot
                anchors.fill: parent
                focus: overlayWin.isDialogScreen

                Keys.onEscapePressed: {
                    if (overlayWin.isDialogScreen) {
                        dialog.cancelAuth()
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: PolkitAgentStyle.scrimColor

                    MouseArea {
                        anchors.fill: parent
                        onPressed: {
                            if (overlayWin.isDialogScreen) {
                                dialog.focusInput()
                            } else {
                                root.ensurePolkitFocus(root.targetScreenName)
                                root.focusRequested()
                            }
                        }
                    }
                }

                PolkitDialog {
                    id: dialog
                    anchors.centerIn: parent
                    visible: overlayWin.isDialogScreen
                    active: root.isActive && overlayWin.isDialogScreen
                    flow: overlayWin.isDialogScreen ? root.flow : null
                    fallbackUserName: root.fallbackUserName
                }

                Connections {
                    target: root
                    function onFocusRequested() {
                        if (overlayWin.isDialogScreen) {
                            dialog.focusInput()
                        }
                    }
                }
            }
        }
    }
}
