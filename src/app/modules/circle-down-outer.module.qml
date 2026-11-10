// ============================================================================
// File: modules/circle-down-outer.module.qml
// Purpose: Lowermost left-bar launcher circle module (side: 'down', slot: 0).
//          Provides a 2x2 grid of square power actions: Reboot, Power Off, Sleep, Lock.
// Dependencies: QtQuick, Quickshell, Quickshell.Io, "../components", "../styles"
// ============================================================================
import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import "../styles"

// Left bar · bottom circle (Power and Session actions)
Circle {
    id: root
    vertical: true
    side: "down"
    slot: 0              // 0 = outermost, 2 = closest to the workspaces island
    panelId: "down-outer"
    title: ""
    glyph: ""
    alwaysShowGlyph: true

    property var screenLocker: null

    readonly property var powerActions: [
        {
            id: "reboot",
            name: "Reboot",
            icon: "󰑓",
            isDanger: false
        },
        {
            id: "poweroff",
            name: "Power Off",
            icon: "",
            isDanger: true
        },
        {
            id: "sleep",
            name: "Sleep",
            icon: "󰒲",
            isDanger: false
        },
        {
            id: "lock",
            name: "Lock",
            icon: "",
            isDanger: false
        }
    ]

    Process { id: rebootProc; command: ["systemctl", "reboot"] }
    Process { id: poweroffProc; command: ["systemctl", "poweroff"] }
    Process { id: sleepProc; command: ["systemctl", "suspend"] }
    Process { id: lockProc; command: ["sh", Quickshell.shellPath("commands/lock-screen.sh")] }

    function executeAction(actionId) {
        if (root.ctl) root.ctl.close()

        if (actionId === "reboot") {
            rebootProc.running = true
        } else if (actionId === "poweroff") {
            poweroffProc.running = true
        } else if (actionId === "sleep") {
            sleepProc.running = true
        } else if (actionId === "lock") {
            if (root.screenLocker) {
                root.screenLocker.lock()
            } else {
                lockProc.running = true
            }
        }
    }

    panel: Component {
        Item {
            id: panelContent
            anchors.fill: parent

            Column {
                anchors.centerIn: parent
                spacing: 24

                // Section title & caption
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Power & Session"
                        color: CircleStyle.textBright
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Select a system action"
                        color: CircleStyle.textDim
                        font.pixelSize: 12
                    }
                }

                // 2x2 Grid of Square Option Buttons
                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 2
                    spacing: 16

                    Repeater {
                        model: root.powerActions

                        Rectangle {
                            id: squareButton
                            required property var modelData
                            readonly property bool isHovered: actionMouse.containsMouse
                            readonly property bool isDanger: squareButton.modelData.isDanger

                            width: 124
                            height: 124
                            radius: 16

                            color: isHovered
                                ? (isDanger ? CircleStyle.dangerTint25 : CircleStyle.itemBorder)
                                : CircleStyle.itemBg

                            border.width: isHovered ? 1.5 : 1
                            border.color: isHovered
                                ? (isDanger ? CircleStyle.dangerColor : CircleStyle.borderColor)
                                : CircleStyle.itemBorder

                            scale: isHovered ? 1.05 : 1.0

                            Behavior on scale {
                                NumberAnimation { duration: 140; easing.type: Easing.OutQuad }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 140 }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 140 }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 12

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: squareButton.modelData.icon
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 34
                                    color: squareButton.isDanger
                                        ? CircleStyle.dangerColor
                                        : (squareButton.isHovered ? CircleStyle.textBright : CircleStyle.glyphColor)
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: squareButton.modelData.name
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    color: squareButton.isHovered ? CircleStyle.textBright : CircleStyle.textSecondary
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }
                            }

                            MouseArea {
                                id: actionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.executeAction(squareButton.modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
