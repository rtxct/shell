// ============================================================================
// File: modules/circle-down-middle.module.qml
// Purpose: Lower-middle left-bar launcher circle module (side: 'down', slot: 1).
//          Provides battery monitor with percentage, estimated runtime, cycle count,
//          health quality calculation, and hardware metrics.
// Dependencies: QtQuick, Quickshell, Quickshell.Io, Quickshell.Services.UPower, "../components", "../styles"
// ============================================================================
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../components"
import "../styles"

// Left bar · lower middle circle (Battery monitor & diagnostics)
Circle {
    id: root
    vertical: true
    side: "down"
    slot: 1              // 0 = outermost, 2 = closest to the workspaces island
    panelId: "down-middle"
    title: ""
    alwaysShowGlyph: true

    property bool isCharging: false
    property int batteryPercent: 100
    property string batteryStatus: "Connected"
    property bool acOnline: false
    property bool rawCharging: false

    function syncStatus() {
        var plugged = root.acOnline || root.rawCharging
        if (plugged) {
            if (root.batteryPercent >= 98) {
                root.isCharging = false
                root.batteryStatus = "Connected"
            } else {
                root.isCharging = true
                root.batteryStatus = "Charging"
            }
        } else {
            root.isCharging = false
            root.batteryStatus = "Discharging"
        }
    }

    onBatteryPercentChanged: root.syncStatus()
    onAcOnlineChanged: root.syncStatus()
    onRawChargingChanged: root.syncStatus()

    property int cycleCount: 0
    property real energyNow: 0
    property real energyFull: 0
    property real energyFullDesign: 0
    property real powerNow: 0
    property string modelName: ""
    property string technology: ""

    readonly property int healthPercent: energyFullDesign > 0 ? Math.round((energyFull / energyFullDesign) * 100) : 0
    readonly property string healthQuality: {
        if (healthPercent >= 80) return "Good"
        if (healthPercent >= 60) return "OK"
        if (healthPercent > 0) return "Poor"
        return "Unknown"
    }

    readonly property string timeRemainingString: {
        if (isCharging) {
            if (upowerDev && upowerDev.timeToFull > 0) {
                var hf = Math.floor(upowerDev.timeToFull / 3600)
                var mf = Math.floor((upowerDev.timeToFull % 3600) / 60)
                return hf + "h " + (mf < 10 ? "0" + mf : mf) + "m until full"
            }
            return "Charging on AC"
        }
        if (batteryStatus === "Connected" || acOnline) {
            return "Connected"
        }
        var sec = (upowerDev && upowerDev.timeToEmpty > 0) ? upowerDev.timeToEmpty : 0
        if (sec <= 0 && powerNow > 0 && energyNow > 0) {
            sec = Math.round((energyNow / powerNow) * 3600)
        }
        if (sec > 0) {
            var h = Math.floor(sec / 3600)
            var m = Math.floor((sec % 3600) / 60)
            return h + "h " + (m < 10 ? "0" + m : m) + "m left"
        }
        return "Calculating..."
    }

    // UPower integration (updates reactively if UPower is active)
    readonly property var upowerDev: UPower.displayDevice

    function updateFromUPower() {
        if (UPower.onBattery !== undefined) {
            root.acOnline = !UPower.onBattery
        }
        if (upowerDev) {
            var state = upowerDev.state
            if (state === UPowerDeviceState.Charging) {
                root.rawCharging = true
            } else if (state === UPowerDeviceState.Discharging) {
                root.rawCharging = false
            } else if (state === UPowerDeviceState.FullyCharged) {
                root.rawCharging = false
            }
            var p = upowerDev.percentage
            if (p !== undefined && p > 0) {
                root.batteryPercent = Math.round(p > 1.0 ? p : p * 100)
            }
        }
        root.syncStatus()
    }

    Connections {
        target: root.upowerDev
        function onPercentageChanged() { root.updateFromUPower() }
        function onStateChanged() { root.updateFromUPower() }
    }

    Connections {
        target: UPower
        function onOnBatteryChanged() { root.updateFromUPower() }
    }

    // Direct sysfs poller via scripts/battery/poll-battery-state.sh
    property int pollLineIndex: 0
    property string pendingStatus: ""

    Process {
        id: pollProc
        command: ["sh", Quickshell.shellPath("src/app/scripts/battery/poll-battery-state.sh")]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                var trimmed = line.trim()
                if (root.pollLineIndex === 0) {
                    root.pendingStatus = trimmed
                    root.rawCharging = (trimmed.toLowerCase() === "charging")
                } else if (root.pollLineIndex === 1) {
                    var cap = parseInt(trimmed, 10)
                    if (!isNaN(cap)) {
                        root.batteryPercent = cap
                    }
                } else if (root.pollLineIndex === 2) {
                    root.acOnline = (trimmed === "1")
                    root.syncStatus()
                } else if (root.pollLineIndex === 3) {
                    var cyc = parseInt(trimmed, 10)
                    if (!isNaN(cyc)) root.cycleCount = cyc
                } else if (root.pollLineIndex === 4) {
                    var en = parseFloat(trimmed)
                    if (!isNaN(en)) root.energyNow = en
                } else if (root.pollLineIndex === 5) {
                    var ef = parseFloat(trimmed)
                    if (!isNaN(ef)) root.energyFull = ef
                } else if (root.pollLineIndex === 6) {
                    var efd = parseFloat(trimmed)
                    if (!isNaN(efd)) root.energyFullDesign = efd
                } else if (root.pollLineIndex === 7) {
                    var pw = parseFloat(trimmed)
                    if (!isNaN(pw)) root.powerNow = pw
                } else if (root.pollLineIndex === 8) {
                    root.modelName = trimmed
                } else if (root.pollLineIndex === 9) {
                    root.technology = trimmed
                }
                root.pollLineIndex++
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!pollProc.running) {
                root.pollLineIndex = 0
                pollProc.running = true
            }
        }
    }

    // Icon stages according to user specification:
    // - Charging: charging icon
    // - Not charging: 3 stages (full, half, low)
    glyph: {
        if (isCharging) return "󰂄"
        if (batteryPercent >= 65) return "󰁹"
        if (batteryPercent > 20) return "󰁾"
        return "󰁻"
    }

    glyphColor: (!isCharging && batteryPercent <= 20) ? CircleStyle.dangerColor : CircleStyle.glyphColor

    panel: Component {
        Item {
            id: batteryPanel
            anchors.fill: parent

            Column {
                anchors.centerIn: parent
                width: Math.min(parent.width - 40, 460)
                spacing: 18

                // Header
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Battery & Power"
                        color: CircleStyle.textBright
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Hardware diagnostics & power status"
                        color: CircleStyle.textDim
                        font.pixelSize: 12
                    }
                }

                // Main Hero Card (Large percentage & charge progress)
                Rectangle {
                    width: parent.width
                    height: 104
                    radius: 16
                    color: CircleStyle.itemBg
                    border.width: 1
                    border.color: CircleStyle.itemBorder

                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Item {
                            width: parent.width
                            height: 38

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                Text {
                                    text: root.glyph
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 34
                                    color: root.isCharging
                                        ? CircleStyle.accentColor
                                        : (root.batteryPercent <= 20 ? CircleStyle.dangerColor : CircleStyle.textBright)
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: root.batteryPercent + "%"
                                    color: CircleStyle.textBright
                                    font.pixelSize: 30
                                    font.weight: Font.Bold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Status badge
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                height: 28
                                width: statusText.implicitWidth + 24
                                radius: 14
                                color: CircleStyle.itemSelectedBg
                                border.width: 1
                                border.color: root.isCharging ? CircleStyle.accentColor : CircleStyle.itemSelectedBorder

                                Text {
                                    id: statusText
                                    anchors.centerIn: parent
                                    text: root.batteryStatus
                                    color: root.isCharging ? CircleStyle.accentColor : CircleStyle.textBright
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                }
                            }
                        }

                        // Progress Bar Track
                        Rectangle {
                            width: parent.width
                            height: 8
                            radius: 4
                            color: CircleStyle.itemSelectedBg

                            Rectangle {
                                height: parent.height
                                width: Math.max(8, parent.width * Math.min(1.0, root.batteryPercent / 100))
                                radius: 4
                                color: root.isCharging
                                    ? CircleStyle.accentColor
                                    : (root.batteryPercent <= 20 ? CircleStyle.dangerColor : CircleStyle.textBright)

                                Behavior on width {
                                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                    }
                }

                // 2x2 Grid of Detailed Metrics
                Grid {
                    width: parent.width
                    columns: 2
                    spacing: 12

                    // Card 1: Estimated Runtime
                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 86
                        radius: 14
                        color: CircleStyle.itemBg
                        border.width: 1
                        border.color: CircleStyle.itemBorder

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4

                            Row {
                                spacing: 8
                                Text {
                                    text: "󱐋"
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 14
                                    color: CircleStyle.accentColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "ESTIMATED RUNTIME"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: CircleStyle.textDim
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                text: root.timeRemainingString
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                color: CircleStyle.textBright
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: root.isCharging ? "Charging on AC power" : (root.batteryStatus === "Connected" ? "Power adapter connected" : "Estimated runtime left")
                                font.pixelSize: 11
                                color: CircleStyle.textSecondary
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }
                    }

                    // Card 2: Battery Health & Quality
                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 86
                        radius: 14
                        color: CircleStyle.itemBg
                        border.width: 1
                        border.color: CircleStyle.itemBorder

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4

                            Row {
                                spacing: 8
                                Text {
                                    text: ""
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 14
                                    color: root.healthPercent >= 80 ? CircleStyle.textBright : (root.healthPercent >= 60 ? CircleStyle.accentColor : CircleStyle.dangerColor)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "BATTERY HEALTH"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: CircleStyle.textDim
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                text: root.healthQuality + (root.healthPercent > 0 ? " (" + root.healthPercent + "%)" : "")
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                color: CircleStyle.textBright
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: root.energyFull > 0
                                    ? (Math.round(root.energyFull / 100000) / 10 + " / " + Math.round(root.energyFullDesign / 100000) / 10 + " Wh")
                                    : "Capacity condition"
                                font.pixelSize: 11
                                color: CircleStyle.textSecondary
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }
                    }

                    // Card 3: Charge Cycles
                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 86
                        radius: 14
                        color: CircleStyle.itemBg
                        border.width: 1
                        border.color: CircleStyle.itemBorder

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4

                            Row {
                                spacing: 8
                                Text {
                                    text: "󰑓"
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 14
                                    color: CircleStyle.glyphColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "CYCLE COUNT"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: CircleStyle.textDim
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                text: root.cycleCount > 0 ? root.cycleCount + " cycles" : "N/A"
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                color: CircleStyle.textBright
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: "Completed charge cycles"
                                font.pixelSize: 11
                                color: CircleStyle.textSecondary
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }
                    }

                    // Card 4: Battery Model & Spec
                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 86
                        radius: 14
                        color: CircleStyle.itemBg
                        border.width: 1
                        border.color: CircleStyle.itemBorder

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4

                            Row {
                                spacing: 8
                                Text {
                                    text: "󰚥"
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 14
                                    color: CircleStyle.glyphColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "HARDWARE SPEC"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: CircleStyle.textDim
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                text: (root.modelName ? root.modelName : "Battery") + (root.technology ? " (" + root.technology + ")" : "")
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                color: CircleStyle.textBright
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: root.powerNow > 0
                                    ? (Math.round(root.powerNow / 100000) / 10 + " W power rate")
                                    : (root.isCharging ? "Charging" : (root.batteryStatus === "Connected" ? "Connected" : "Battery power"))
                                font.pixelSize: 11
                                color: CircleStyle.textSecondary
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }
                    }
                }
            }
        }
    }
}
