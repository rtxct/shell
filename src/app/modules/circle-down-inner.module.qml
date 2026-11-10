// ============================================================================
// File: modules/circle-down-inner.module.qml
// Purpose: Lower-inner left-bar launcher circle module closest to the workspace island (side: 'down', slot: 2).
//          Provides power profile selection between Performance, Balanced, and Power Saver.
// Dependencies: QtQuick, Quickshell, Quickshell.Io, "../components", "../styles"
// ============================================================================
import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import "../styles"

// Left bar · lower inner circle (Power Profile Chooser)
Circle {
    id: root
    vertical: true
    side: "down"
    slot: 2              // 0 = outermost, 2 = closest to the workspaces island
    panelId: "down-inner"
    title: ""
    alwaysShowGlyph: true

    // Current profile selection: "performance" | "balanced" | "power-saver"
    property string currentProfile: "balanced"

    // Profile icons mapping
    readonly property var profileIcons: ({
        "performance": "󰓅",
        "balanced": "󰾅",
        "power-saver": "󰾆"
    })

    // Profile human-readable labels
    readonly property var profileLabels: ({
        "performance": "Performance",
        "balanced": "Balanced",
        "power-saver": "Power Saver"
    })

    // Profile definitions model
    readonly property var profiles: [
        {
            id: "performance",
            name: "Performance",
            icon: "󰓅",
            description: "Maximum performance, higher power usage"
        },
        {
            id: "balanced",
            name: "Balanced",
            icon: "󰾅",
            description: "Standard balance between power and battery"
        },
        {
            id: "power-saver",
            name: "Power Saver",
            icon: "󰾆",
            description: "Saves battery, reduces system performance"
        }
    ]

    // Glyph bound to current profile's icon
    glyph: profileIcons[currentProfile] || "󰾅"

    // Select profile handler (sets currentProfile and executes powerprofilesctl)
    function selectProfile(profileId) {
        currentProfile = profileId
        applyProc.command = ["powerprofilesctl", "set", profileId]
        applyProc.running = true
    }

    // Detect system active profile on launch
    Process {
        id: queryProc
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                var p = line.trim()
                if (root.profileIcons[p]) {
                    root.currentProfile = p
                }
            }
        }
    }

    // Applies power profile changes asynchronously
    Process {
        id: applyProc
    }

    // Interactive power profile selection panel
    panel: Component {
        Item {
            id: panelRoot
            anchors.fill: parent

            Column {
                anchors.centerIn: parent
                width: Math.min(parent.width - 40, 440)
                spacing: 16

                // Section header
                Column {
                    width: parent.width
                    spacing: 4

                    Text {
                        text: "Select Power Profile"
                        color: CircleStyle.glyphColor
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "Choose system performance mode and energy consumption behavior."
                        color: CircleStyle.textDim
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }

                // Profile options list
                Column {
                    width: parent.width
                    spacing: 10

                    Repeater {
                        model: root.profiles

                        Rectangle {
                            id: profileCard
                            required property var modelData
                            readonly property bool isSelected: root.currentProfile === modelData.id
                            readonly property bool isHovered: cardMouse.containsMouse

                            width: parent.width
                            height: 64
                            radius: 12
                            color: isSelected ? CircleStyle.itemSelectedBg : (isHovered ? CircleStyle.itemHoverBg : CircleStyle.transparent)
                            border.width: isSelected ? 1.5 : 1
                            border.color: isSelected ? CircleStyle.accentColor : (isHovered ? CircleStyle.itemSelectedBorder : CircleStyle.itemBorder)

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 14

                                // Icon badge
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 40
                                    height: 40
                                    radius: 20
                                    color: profileCard.isSelected ? CircleStyle.itemSelectedBg : CircleStyle.itemHoverBg
                                    border.width: 1
                                    border.color: profileCard.isSelected ? CircleStyle.accentColor : CircleStyle.itemBorder

                                    Text {
                                        anchors.centerIn: parent
                                        text: profileCard.modelData.icon
                                        font.family: "Symbols Nerd Font"
                                        font.pixelSize: 20
                                        color: profileCard.isSelected ? CircleStyle.accentColor : CircleStyle.glyphColor
                                    }
                                }

                                // Title and description
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 40 - 24 - 28
                                    spacing: 3

                                    Text {
                                        text: profileCard.modelData.name
                                        color: profileCard.isSelected ? CircleStyle.accentColor : CircleStyle.glyphColor
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: profileCard.modelData.description
                                        color: CircleStyle.textDim
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                }

                                // Selection indicator radio / check dot
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: CircleStyle.transparent
                                    border.width: profileCard.isSelected ? 2 : 1
                                    border.color: profileCard.isSelected ? CircleStyle.accentColor : CircleStyle.itemBorder

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 10
                                        height: 10
                                        radius: 5
                                        color: CircleStyle.accentColor
                                        visible: profileCard.isSelected
                                    }
                                }
                            }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectProfile(profileCard.modelData.id)
                            }
                        }
                    }
                }

                // Footer status
                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 8
                    color: CircleStyle.itemHoverBg
                    border.width: 1
                    border.color: CircleStyle.itemBorder

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "Active Profile:"
                            color: CircleStyle.textDim
                            font.pixelSize: 11
                        }

                        Text {
                            text: root.profileLabels[root.currentProfile] || root.currentProfile
                            color: CircleStyle.accentColor
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }
    }
}
