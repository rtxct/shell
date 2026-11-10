// ============================================================================
// File: modules/circle-up-middle.module.qml
// Purpose: Upper-middle left-bar launcher circle module (side: 'up', slot: 1).
//          Provides interactive Bluetooth management: power ON/OFF toggle, scan toggle,
//          paired/connected devices list with signal strength & battery, discovered devices list,
//          connect/disconnect, and dynamic PIN/passkey authentication view with seamless transition back to lists.
// Dependencies: QtQuick, Quickshell, Quickshell.Io, "../components", "../styles"
// ============================================================================
import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import "../styles"

// Left bar · upper middle circle (Bluetooth Controller)
Circle {
    id: root
    vertical: true
    side: "up"
    slot: 1              // 0 = outermost, 2 = closest to the workspaces island
    panelId: "up-middle"
    title: ""
    alwaysShowGlyph: true

    // Bluetooth icon reflecting state: powered off vs connected bolt vs scanning vs idle
    glyph: !isPowered ? "󰂲" : (hasConnectedDevice ? "󰂱" : (isScanning ? "󰂳" : "󰂯"))

    readonly property string scriptPath: Quickshell.shellPath("src/app/scripts/bluetooth/bluetooth-manager.py")

    // State data
    property bool isPowered: true
    property bool isScanning: false
    property bool scanTransition: false
    property var pairedDevices: []
    property var scannedDevices: []
    property bool hasConnectedDevice: false
    property string connectingAddress: ""
    property string connectingName: ""
    property bool showPinInput: false
    property string pinPrompt: "Enter PIN / Passkey:"
    property string extractedPin: ""
    property bool isConfirmDialog: false
    property string pendingPin: ""
    property string statusMessage: ""
    property bool isError: false

    function refreshStatus() {
        if (!statusProc.running) statusProc.running = true
    }

    function togglePower() {
        powerProc.command = ["python3", root.scriptPath, "power", root.isPowered ? "off" : "on"]
        powerProc.running = true
    }

    function toggleScan() {
        if (!root.isPowered) return
        root.scanTransition = true
        scanTransitionTimer.restart()
        if (!root.isScanning) {
            root.isScanning = true
            scanProc.running = true
        } else {
            root.isScanning = false
            scanProc.running = false
            stopScanProc.running = true
        }
    }

    function connectDevice(address) {
        root.statusMessage = "Connecting..."
        root.isError = false
        actionProc.command = ["python3", root.scriptPath, "connect", address]
        actionProc.running = true
    }

    function disconnectDevice(address) {
        root.statusMessage = "Disconnecting..."
        root.isError = false
        actionProc.command = ["python3", root.scriptPath, "disconnect", address]
        actionProc.running = true
    }

    function forgetDevice(address) {
        root.statusMessage = "Unpairing device..."
        root.isError = false
        actionProc.command = ["python3", root.scriptPath, "forget", address]
        actionProc.running = true
    }

    function startPairing(device) {
        root.connectingAddress = device.address
        root.connectingName = device.name || device.address
        root.statusMessage = "Pairing with " + root.connectingName + "..."
        root.isError = false
        pairProc.command = ["python3", root.scriptPath, "pair", device.address]
        pairProc.running = true
    }

    function submitPin(pin) {
        var cleanPin = (pin !== undefined && pin !== null) ? pin.trim() : ""
        root.statusMessage = "Verifying PIN / password..."
        root.isError = false
        if (pairProc.running) {
            pairProc.write((cleanPin.length > 0 ? cleanPin : "yes") + "\n")
        } else if (root.connectingAddress) {
            root.pendingPin = cleanPin
            root.startPairing({ address: root.connectingAddress, name: root.connectingName })
        }
    }

    function cancelPairing() {
        pairProc.running = false
        root.showPinInput = false
        root.connectingAddress = ""
        root.connectingName = ""
        root.extractedPin = ""
        root.isConfirmDialog = false
        root.pendingPin = ""
        root.statusMessage = ""
        root.isError = false
        root.refreshStatus()
    }

    function getSignalIcon(rssi) {
        if (rssi === null || rssi === undefined) return "󰓊"
        if (rssi >= -60) return "󰓊"
        if (rssi >= -75) return "󰓋"
        if (rssi >= -88) return "󰓌"
        return "󰓍"
    }

    function getDeviceIcon(iconType) {
        if (!iconType) return "󰂯"
        var t = iconType.toLowerCase()
        if (t.indexOf("audio") !== -1 || t.indexOf("head") !== -1) return "󰋋"
        if (t.indexOf("mouse") !== -1) return "󰍽"
        if (t.indexOf("keyboard") !== -1) return "󰌌"
        if (t.indexOf("phone") !== -1) return "󰏲"
        if (t.indexOf("computer") !== -1 || t.indexOf("laptop") !== -1) return "󰌢"
        if (t.indexOf("game") !== -1) return "󰊴"
        return "󰂯"
    }

    // Status query process
    Process {
        id: statusProc
        command: ["python3", root.scriptPath, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text)
                    root.pairedDevices = data.paired || []
                    root.scannedDevices = data.scanned || []
                    var anyConn = false
                    for (var i = 0; i < root.pairedDevices.length; i++) {
                        if (root.pairedDevices[i].connected) {
                            anyConn = true
                            break
                        }
                    }
                    root.hasConnectedDevice = anyConn
                    if (data.adapter) {
                        root.isPowered = data.adapter.powered === true
                        if (!root.isPowered) {
                            root.isScanning = false
                            root.scanTransition = false
                            scanProc.running = false
                        } else if (!root.scanTransition) {
                            root.isScanning = data.adapter.discovering === true
                        }
                    }
                } catch (e) {
                    // Ignore parse errors
                }
            }
        }
    }

    // Periodic poller
    Timer {
        id: pollTimer
        interval: root.isScanning ? 2000 : 5000
        running: true
        repeat: true
        onTriggered: root.refreshStatus()
    }

    // Background scan daemon process
    Process {
        id: scanProc
        command: ["python3", root.scriptPath, "scan_daemon"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                var trimmed = line.trim()
                if (trimmed === "SCAN_ACTIVE") {
                    root.isScanning = true
                    root.scanTransition = false
                    scanTransitionTimer.stop()
                    root.refreshStatus()
                } else if (trimmed.indexOf("SCAN_ERROR:") === 0) {
                    root.isScanning = false
                    root.scanTransition = false
                    scanTransitionTimer.stop()
                    root.statusMessage = trimmed.substring(11)
                    root.isError = true
                    root.refreshStatus()
                }
            }
        }
        onExited: {
            if (root.scanTransition) {
                root.scanTransition = false
                scanTransitionTimer.stop()
            }
            root.refreshStatus()
        }
    }

    // Stop scan process
    Process {
        id: stopScanProc
        command: ["python3", root.scriptPath, "scan", "off"]
        onExited: {
            root.scanTransition = false
            scanTransitionTimer.stop()
            root.refreshStatus()
        }
    }

    // Safety guard for scan start/stop transitions
    Timer {
        id: scanTransitionTimer
        interval: 3000
        repeat: false
        onTriggered: {
            root.scanTransition = false
            root.refreshStatus()
        }
    }

    // Power toggle process
    Process {
        id: powerProc
        onExited: root.refreshStatus()
    }

    // Action runner (connect / disconnect)
    Process {
        id: actionProc
        onExited: {
            root.statusMessage = ""
            root.refreshStatus()
        }
    }

    // Interactive pairing runner with PIN handling
    Process {
        id: pairProc
        stdinEnabled: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                var trimmed = line.trim()
                if (trimmed.indexOf("PIN_REQUIRED:") === 0) {
                    var rawPayload = trimmed.substring(13)
                    var pinInfo = { pin: "", prompt: "", is_confirm: false }
                    try {
                        pinInfo = JSON.parse(rawPayload)
                    } catch (e) {
                        pinInfo = { pin: "", prompt: rawPayload, is_confirm: false }
                    }
                    root.extractedPin = pinInfo.pin || ""
                    root.pinPrompt = pinInfo.prompt || ""
                    root.isConfirmDialog = pinInfo.is_confirm || false
                    root.showPinInput = true
                    if (root.pendingPin.length > 0) {
                        var toSend = root.pendingPin
                        root.pendingPin = ""
                        pairProc.write(toSend + "\n")
                    } else {
                        root.statusMessage = ""
                        root.isError = false
                    }
                } else if (trimmed === "SUCCESS") {
                    root.showPinInput = false
                    root.connectingAddress = ""
                    root.connectingName = ""
                    root.extractedPin = ""
                    root.isConfirmDialog = false
                    root.pendingPin = ""
                    root.statusMessage = "Connected successfully!"
                    root.isError = false
                    root.refreshStatus()
                } else if (trimmed.indexOf("ERROR:") === 0) {
                    root.statusMessage = trimmed.substring(6)
                    root.isError = true
                }
            }
        }
    }

    Component.onCompleted: root.refreshStatus()

    // Bluetooth panel inside Island
    panel: Component {
        Item {
            id: panelRoot
            anchors.fill: parent

            // ── Main View (2 Lists + Top Scan Toggle) ──
            Item {
                id: mainView
                anchors.fill: parent
                visible: opacity > 0.01
                opacity: root.showPinInput ? 0.0 : 1.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Column {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 40, 440)
                    height: Math.min(parent.height - 40, 600)
                    spacing: 12

                    // Top Bar: Title & Control Buttons (Bluetooth ON/OFF + Scan Toggle)
                    Item {
                        width: parent.width
                        height: 38

                        Column {
                            anchors.left: parent.left
                            anchors.right: ctrlButtons.left
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: "Bluetooth Settings"
                                color: CircleStyle.glyphColor
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: !root.isPowered ? "Bluetooth is turned off" : (root.statusMessage ? root.statusMessage : (root.isScanning ? "Scanning for nearby devices..." : "Manage paired & connected devices"))
                                color: root.isError ? CircleStyle.dangerColor : CircleStyle.textDim
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        // Right control buttons: Power ON/OFF + Scan
                        Row {
                            id: ctrlButtons
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            // Bluetooth Power ON/OFF Button
                            Rectangle {
                                width: 72
                                height: 32
                                radius: 16
                                color: root.isPowered ? CircleStyle.itemSelectedBg : CircleStyle.itemHoverBg
                                border.width: 1
                                border.color: root.isPowered ? CircleStyle.accentColor : CircleStyle.itemBorder

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.isPowered ? "󰂯" : "󰂲"
                                        font.family: "Symbols Nerd Font"
                                        font.pixelSize: 13
                                        color: root.isPowered ? CircleStyle.accentColor : CircleStyle.textDim
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.isPowered ? "On" : "Off"
                                        color: root.isPowered ? CircleStyle.glyphColor : CircleStyle.textDim
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.togglePower()
                                }
                            }

                            // Scan Toggle Button
                            Rectangle {
                                width: 104
                                height: 32
                                radius: 16
                                opacity: root.isPowered ? 1.0 : 0.4
                                color: root.isScanning ? CircleStyle.itemSelectedBg : (scanBtnMouse.containsMouse ? CircleStyle.itemHoverBg : CircleStyle.transparent)
                                border.width: 1
                                border.color: root.isScanning ? CircleStyle.accentColor : (scanBtnMouse.containsMouse ? CircleStyle.itemSelectedBorder : CircleStyle.itemBorder)

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.isScanning ? "󰂳" : "󰂯"
                                        font.family: "Symbols Nerd Font"
                                        font.pixelSize: 13
                                        color: root.isScanning ? CircleStyle.accentColor : CircleStyle.glyphColor
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.isScanning ? "Stop Scan" : "Scan"
                                        color: root.isScanning ? CircleStyle.accentColor : CircleStyle.glyphColor
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                }

                                MouseArea {
                                    id: scanBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: root.isPowered
                                    cursorShape: root.isPowered ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: root.toggleScan()
                                }
                            }
                        }
                    }

                    // Scrollable List Container
                    Flickable {
                        width: parent.width
                        height: parent.height - 50
                        contentWidth: width
                        contentHeight: contentCol.implicitHeight
                        clip: true

                        Column {
                            id: contentCol
                            width: parent.width
                            spacing: 14

                            // ── Bluetooth Disabled State View ──
                            Column {
                                visible: !root.isPowered
                                width: parent.width
                                spacing: 14
                                topPadding: 40

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 64
                                    height: 64
                                    radius: 32
                                    color: CircleStyle.itemHoverBg
                                    border.width: 1
                                    border.color: CircleStyle.itemBorder

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰂲"
                                        font.family: "Symbols Nerd Font"
                                        font.pixelSize: 32
                                        color: CircleStyle.textDim
                                    }
                                }

                                Column {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width - 40
                                    spacing: 6

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Bluetooth is Disabled"
                                        color: CircleStyle.glyphColor
                                        font.pixelSize: 15
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Turn on Bluetooth to connect to paired devices and discover nearby accessories."
                                        color: CircleStyle.textDim
                                        font.pixelSize: 12
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WordWrap
                                        width: parent.width
                                    }
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 140
                                    height: 36
                                    radius: 18
                                    color: CircleStyle.accentColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Turn Bluetooth On"
                                        color: CircleStyle.fill
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.togglePower()
                                    }
                                }
                            }

                            // ── 1. Top List: Paired & Connected Devices ──
                            Column {
                                visible: root.isPowered
                                width: parent.width
                                spacing: 8

                                Row {
                                    width: parent.width
                                    spacing: 8
                                    Text {
                                        text: "PAIRED & CONNECTED"
                                        color: CircleStyle.textDim
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 1.0
                                    }
                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: CircleStyle.itemHoverBg
                                        border.width: 1
                                        border.color: CircleStyle.itemBorder
                                        Text {
                                            anchors.centerIn: parent
                                            text: root.pairedDevices.length
                                            color: CircleStyle.textDim
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                // Empty state
                                Text {
                                    visible: root.pairedDevices.length === 0
                                    text: "No paired Bluetooth devices"
                                    color: CircleStyle.textDim
                                    font.pixelSize: 12
                                    font.italic: true
                                }

                                Repeater {
                                    model: root.pairedDevices

                                    Rectangle {
                                        id: pairedCard
                                        required property var modelData
                                        width: parent.width
                                        height: 56
                                        radius: 12
                                        color: modelData.connected ? CircleStyle.itemSelectedBg : (pairedMouse.containsMouse ? CircleStyle.itemHoverBg : CircleStyle.transparent)
                                        border.width: modelData.connected ? 1.5 : 1
                                        border.color: modelData.connected ? CircleStyle.accentColor : (pairedMouse.containsMouse ? CircleStyle.itemSelectedBorder : CircleStyle.itemBorder)

                                        // Left: Device Icon badge
                                        Rectangle {
                                            id: pairedIconBadge
                                            anchors.left: parent.left
                                            anchors.leftMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 36
                                            height: 36
                                            radius: 18
                                            color: pairedCard.modelData.connected ? CircleStyle.itemSelectedBg : CircleStyle.itemHoverBg
                                            border.width: 1
                                            border.color: pairedCard.modelData.connected ? CircleStyle.accentColor : CircleStyle.itemBorder

                                            Text {
                                                anchors.centerIn: parent
                                                text: root.getDeviceIcon(pairedCard.modelData.icon)
                                                font.family: "Symbols Nerd Font"
                                                font.pixelSize: 18
                                                color: pairedCard.modelData.connected ? CircleStyle.accentColor : CircleStyle.glyphColor
                                            }
                                        }

                                        // Right: Signal strength & Action button
                                        Row {
                                            id: pairedActionsRow
                                            anchors.right: parent.right
                                            anchors.rightMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 8

                                            // Signal strength icon
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: root.getSignalIcon(pairedCard.modelData.rssi)
                                                font.family: "Symbols Nerd Font"
                                                font.pixelSize: 16
                                                color: pairedCard.modelData.connected ? CircleStyle.accentColor : CircleStyle.textDim
                                            }

                                            // Forget / Unpair button (only when paired but not connected)
                                            Rectangle {
                                                visible: !pairedCard.modelData.connected
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 58
                                                height: 28
                                                radius: 14
                                                color: forgetMouse.containsMouse ? CircleStyle.itemHoverBg : CircleStyle.transparent
                                                border.width: 1
                                                border.color: forgetMouse.containsMouse ? CircleStyle.dangerColor : CircleStyle.itemBorder

                                                Behavior on color { ColorAnimation { duration: 150 } }
                                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Forget"
                                                    color: forgetMouse.containsMouse ? CircleStyle.dangerColor : CircleStyle.textDim
                                                    font.pixelSize: 11
                                                    font.weight: Font.DemiBold
                                                }

                                                MouseArea {
                                                    id: forgetMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.forgetDevice(pairedCard.modelData.address)
                                                }
                                            }

                                            // Connect / Disconnect button
                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: pairedCard.modelData.connected ? 84 : 68
                                                height: 28
                                                radius: 14
                                                color: cardActionMouse.containsMouse ? CircleStyle.itemHoverBg : CircleStyle.transparent
                                                border.width: 1
                                                border.color: pairedCard.modelData.connected ? CircleStyle.dangerColor : CircleStyle.itemBorder

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: pairedCard.modelData.connected ? "Disconnect" : "Connect"
                                                    color: pairedCard.modelData.connected ? CircleStyle.dangerColor : CircleStyle.glyphColor
                                                    font.pixelSize: 11
                                                    font.weight: Font.DemiBold
                                                }

                                                MouseArea {
                                                    id: cardActionMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (pairedCard.modelData.connected) {
                                                            root.disconnectDevice(pairedCard.modelData.address)
                                                        } else {
                                                            root.connectDevice(pairedCard.modelData.address)
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // Center: Device Name & Status / Battery Info
                                        Column {
                                            anchors.left: pairedIconBadge.right
                                            anchors.leftMargin: 12
                                            anchors.right: pairedActionsRow.left
                                            anchors.rightMargin: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 3

                                            Text {
                                                text: pairedCard.modelData.name
                                                color: pairedCard.modelData.connected ? CircleStyle.glyphColor : CircleStyle.textDim
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                                width: parent.width
                                            }

                                            Row {
                                                spacing: 8
                                                Text {
                                                    text: pairedCard.modelData.connected ? "Connected" : "Paired"
                                                    color: pairedCard.modelData.connected ? CircleStyle.accentColor : CircleStyle.textDim
                                                    font.pixelSize: 11
                                                    font.weight: pairedCard.modelData.connected ? Font.DemiBold : Font.Normal
                                                }

                                                // Battery indicator
                                                Text {
                                                    visible: pairedCard.modelData.battery !== null && pairedCard.modelData.battery !== undefined
                                                    text: "󰁹 " + (pairedCard.modelData.battery || 0) + "%"
                                                    color: CircleStyle.textDim
                                                    font.family: "Symbols Nerd Font"
                                                    font.pixelSize: 11
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: pairedMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            z: -1
                                        }
                                    }
                                }
                            }

                            // ── 2. Horizontal Line Separator (Visible when Scan is Active) ──
                            Rectangle {
                                visible: root.isPowered && root.isScanning
                                width: parent.width
                                height: 1
                                color: CircleStyle.itemBorder
                            }

                            // ── 3. Bottom List: Discovered / Found Bluetooth Devices ──
                            Column {
                                visible: root.isPowered && root.isScanning
                                width: parent.width
                                spacing: 8

                                Row {
                                    width: parent.width
                                    spacing: 8
                                    Text {
                                        text: "DISCOVERED DEVICES"
                                        color: CircleStyle.accentColor
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 1.0
                                    }
                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: CircleStyle.itemHoverBg
                                        border.width: 1
                                        border.color: CircleStyle.accentColor
                                        Text {
                                            anchors.centerIn: parent
                                            text: root.scannedDevices.length
                                            color: CircleStyle.accentColor
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                Text {
                                    visible: root.scannedDevices.length === 0
                                    text: "Searching for nearby devices..."
                                    color: CircleStyle.textDim
                                    font.pixelSize: 12
                                    font.italic: true
                                }

                                Repeater {
                                    model: root.scannedDevices

                                    Rectangle {
                                        id: scannedCard
                                        required property var modelData
                                        width: parent.width
                                        height: 52
                                        radius: 12
                                        color: scannedMouse.containsMouse ? CircleStyle.itemHoverBg : CircleStyle.transparent
                                        border.width: 1
                                        border.color: scannedMouse.containsMouse ? CircleStyle.accentColor : CircleStyle.itemBorder

                                        Behavior on border.color { ColorAnimation { duration: 150 } }

                                        // Left: Icon badge
                                        Rectangle {
                                            id: scannedIconBadge
                                            anchors.left: parent.left
                                            anchors.leftMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 32
                                            height: 32
                                            radius: 16
                                            color: CircleStyle.itemHoverBg
                                            border.width: 1
                                            border.color: CircleStyle.itemBorder

                                            Text {
                                                anchors.centerIn: parent
                                                text: root.getDeviceIcon(scannedCard.modelData.icon)
                                                font.family: "Symbols Nerd Font"
                                                font.pixelSize: 16
                                                color: CircleStyle.glyphColor
                                            }
                                        }

                                        // Right: Signal strength & Pair button
                                        Row {
                                            id: scannedActionsRow
                                            anchors.right: parent.right
                                            anchors.rightMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 8

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: root.getSignalIcon(scannedCard.modelData.rssi)
                                                font.family: "Symbols Nerd Font"
                                                font.pixelSize: 15
                                                color: CircleStyle.glyphColor
                                            }

                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 48
                                                height: 26
                                                radius: 13
                                                color: CircleStyle.itemSelectedBg
                                                border.width: 1
                                                border.color: CircleStyle.accentColor

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Pair"
                                                    color: CircleStyle.accentColor
                                                    font.pixelSize: 11
                                                    font.weight: Font.DemiBold
                                                }
                                            }
                                        }

                                        // Center: Device Name & MAC Address
                                        Column {
                                            anchors.left: scannedIconBadge.right
                                            anchors.leftMargin: 12
                                            anchors.right: scannedActionsRow.left
                                            anchors.rightMargin: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2

                                            Text {
                                                text: scannedCard.modelData.name
                                                color: CircleStyle.glyphColor
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                                width: parent.width
                                            }

                                            Text {
                                                text: scannedCard.modelData.address
                                                color: CircleStyle.textDim
                                                font.pixelSize: 10
                                            }
                                        }

                                        MouseArea {
                                            id: scannedMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.startPairing(scannedCard.modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── PIN / Password Authentication View ──
            // Vanishes the lists view when a PIN/passkey is requested by the device
            Item {
                id: pinView
                anchors.fill: parent
                visible: opacity > 0.01
                opacity: root.showPinInput ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Connections {
                    target: root
                    function onShowPinInputChanged() {
                        if (root.showPinInput && root.extractedPin.length === 0) {
                            pinFocusTimer.restart()
                        }
                    }
                    function onExtractedPinChanged() {
                        if (root.showPinInput && root.extractedPin.length === 0) {
                            pinFocusTimer.restart()
                        }
                    }
                }

                Timer {
                    id: pinFocusTimer
                    interval: 60
                    repeat: false
                    onTriggered: {
                        if (root.extractedPin.length === 0) {
                            pinInput.forceActiveFocus()
                            pinInput.selectAll()
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 40, 380)
                    spacing: 14

                    // Key badge icon
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 50
                        height: 50
                        radius: 25
                        color: CircleStyle.itemSelectedBg
                        border.width: 1.5
                        border.color: CircleStyle.accentColor

                        Text {
                            anchors.centerIn: parent
                            text: "󰌆"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 24
                            color: CircleStyle.accentColor
                        }
                    }

                    // Title
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Bluetooth Pairing"
                        color: CircleStyle.glyphColor
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }

                    // ── Clean PIN Display (when PIN / Passkey is provided) ──
                    Column {
                        visible: root.extractedPin.length > 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.isConfirmDialog ? "Confirm this PIN matches on your device:" : "Type this PIN on your device and press Enter on it:"
                            color: CircleStyle.textDim
                            font.pixelSize: 12
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.max(160, pinBadgeText.implicitWidth + 44)
                            height: 48
                            radius: 12
                            color: CircleStyle.itemSelectedBg
                            border.width: 1.5
                            border.color: CircleStyle.accentColor

                            Text {
                                id: pinBadgeText
                                anchors.centerIn: parent
                                text: root.extractedPin
                                font.family: "monospace"
                                font.pixelSize: 24
                                font.weight: Font.Bold
                                font.letterSpacing: 6
                                color: CircleStyle.accentColor
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Waiting for device..."
                            color: CircleStyle.textDim
                            font.pixelSize: 11
                            font.italic: true
                        }
                    }

                    // Subtitle when NO generated PIN is provided (manual entry)
                    Text {
                        visible: root.extractedPin.length === 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.pinPrompt ? root.pinPrompt : ("Enter device PIN for " + (root.connectingName || "device"))
                        color: CircleStyle.textDim
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    // PIN / Password Input Field with inside right arrow button
                    Rectangle {
                        id: pinInputBox
                        visible: root.extractedPin.length === 0
                        width: parent.width
                        height: 46
                        radius: 12
                        color: CircleStyle.itemHoverBg
                        border.width: pinInput.activeFocus ? 1.5 : 1
                        border.color: root.isError ? CircleStyle.dangerColor : (pinInput.activeFocus ? CircleStyle.accentColor : CircleStyle.itemSelectedBorder)

                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        TextInput {
                            id: pinInput
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.right: submitArrowBtn.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: CircleStyle.glyphColor
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            verticalAlignment: TextInput.AlignVCenter
                            focus: root.showPinInput && root.extractedPin.length === 0
                            onAccepted: root.submitPin(pinInput.text)
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Enter PIN / Password"
                            color: CircleStyle.textDim
                            font.pixelSize: 13
                            visible: pinInput.text.length === 0 && !pinInput.activeFocus
                        }

                        // Right arrow button inside the input div
                        Rectangle {
                            id: submitArrowBtn
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            height: 34
                            radius: 9
                            color: submitArrowMouse.pressed ? CircleStyle.accentColor : (submitArrowMouse.containsMouse ? CircleStyle.itemSelectedBg : CircleStyle.transparent)
                            border.width: 1
                            border.color: submitArrowMouse.containsMouse ? CircleStyle.accentColor : CircleStyle.transparent

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰁔"
                                font.family: "Symbols Nerd Font"
                                font.pixelSize: 16
                                color: submitArrowMouse.containsMouse ? CircleStyle.accentColor : (pinInput.text.length > 0 ? CircleStyle.glyphColor : CircleStyle.textDim)
                            }

                            MouseArea {
                                id: submitArrowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.submitPin(pinInput.text)
                            }
                        }
                    }

                    // Status / Error message
                    Text {
                        visible: root.statusMessage.length > 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.statusMessage
                        color: root.isError ? CircleStyle.dangerColor : CircleStyle.accentColor
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    // Cancel button
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 90
                        height: 32
                        radius: 16
                        color: cancelMouse.containsMouse ? CircleStyle.itemHoverBg : CircleStyle.transparent
                        border.width: 1
                        border.color: CircleStyle.itemBorder

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: CircleStyle.textDim
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cancelPairing()
                        }
                    }
                }
            }
        }
    }
}
