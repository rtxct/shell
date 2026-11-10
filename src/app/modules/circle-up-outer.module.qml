// ============================================================================
// File: modules/circle-up-outer.module.qml
// Purpose: Uppermost left-bar launcher circle module (side: 'up', slot: 0).
//          Provides interactive Wi-Fi management: power ON/OFF toggle, scan/rescan,
//          saved & connected networks list with signal strength & frequency,
//          discovered available networks list, connect/disconnect, and dynamic
//          password authentication view with seamless transition back to lists.
// Dependencies: QtQuick, Quickshell, Quickshell.Io, "../components", "../styles"
// ============================================================================
import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import "../styles"

// Left bar · top circle (Wi-Fi Controller)
Circle {
    id: root
    vertical: true
    side: "up"
    slot: 0              // 0 = outermost, 2 = closest to the workspaces island
    panelId: "up-outer"
    title: ""
    alwaysShowGlyph: true

    // Dynamic glyph reflecting ethernet plug, airplane, power, connection, signal, or scanning
    glyph: getNetworkGlyph()

    function getNetworkGlyph() {
        if (root.isAirplaneMode) return "󰀝"
        if (root.isEthernetConnected) return "󰌘"
        if (!root.isPowered) return "󰖪"
        if (root.isScanning) return "󰤫"
        if (!root.hasConnectedNetwork) return "󰤨"
        if (root.connectedSignal >= 75) return "󰤨"
        if (root.connectedSignal >= 50) return "󰤥"
        if (root.connectedSignal >= 25) return "󰤢"
        return "󰤟"
    }

    readonly property string scriptPath: Quickshell.shellPath("src/app/scripts/wifi/wifi-manager.py")

    // State data
    property bool isAirplaneMode: false
    property bool isEthernetConnected: false
    property string ethernetDevice: ""
    property string ethernetConnection: ""
    property string ethernetIp: ""
    property string ethernetSpeed: ""

    property bool isPowered: true
    property bool isScanning: false
    property var savedNetworks: []
    property var scannedNetworks: []
    property bool hasConnectedNetwork: false
    property string connectedSsid: ""
    property int connectedSignal: 0
    property string connectingSsid: ""
    property string connectingSecurity: ""
    property bool showPasswordInput: false
    property string statusMessage: ""
    property bool isError: false

    function refreshStatus() {
        if (!statusProc.running) statusProc.running = true
    }

    function toggleAirplane() {
        root.isAirplaneMode = !root.isAirplaneMode
        airplaneProc.command = ["python3", root.scriptPath, "airplane", root.isAirplaneMode ? "on" : "off"]
        airplaneProc.running = true
    }

    function togglePower() {
        powerProc.command = ["python3", root.scriptPath, "power", root.isPowered ? "off" : "on"]
        powerProc.running = true
    }

    function triggerScan() {
        if (!root.isPowered) return
        root.isScanning = true
        scanProc.running = true
    }

    function connectNetwork(ssid, password) {
        root.statusMessage = "Connecting to " + ssid + "..."
        root.isError = false
        var args = ["python3", root.scriptPath, "connect", ssid]
        if (password) args.push(password)
        connectProc.command = args
        connectProc.running = true
    }

    function disconnectNetwork() {
        root.statusMessage = "Disconnecting..."
        root.isError = false
        disconnectProc.running = true
    }

    function forgetNetwork(identifier) {
        root.statusMessage = "Forgetting network..."
        root.isError = false
        forgetProc.command = ["python3", root.scriptPath, "forget", identifier]
        forgetProc.running = true
    }

    function startConnect(network) {
        root.connectingSsid = network.ssid
        root.connectingSecurity = network.security || ""
        var sec = (network.security || "").toLowerCase()
        if (network.is_saved || !sec || sec === "none") {
            root.connectNetwork(network.ssid, null)
        } else {
            root.showPasswordInput = true
        }
    }

    function submitPassword(pwd) {
        root.showPasswordInput = false
        root.connectNetwork(root.connectingSsid, pwd)
    }

    function cancelPassword() {
        root.showPasswordInput = false
        root.connectingSsid = ""
        root.connectingSecurity = ""
        root.statusMessage = ""
        root.isError = false
    }

    function getSignalIcon(sig) {
        if (sig >= 75) return "󰤨"
        if (sig >= 50) return "󰤥"
        if (sig >= 25) return "󰤢"
        if (sig > 0) return "󰤟"
        return "󰤮"
    }

    // Status query process
    Process {
        id: statusProc
        command: ["python3", root.scriptPath, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text)
                    if (data.airplane !== undefined && data.airplane !== null) {
                        root.isAirplaneMode = data.airplane === true
                    }
                    if (data.ethernet) {
                        root.isEthernetConnected = data.ethernet.connected === true
                        root.ethernetDevice = data.ethernet.device || ""
                        root.ethernetConnection = data.ethernet.connection || ""
                        root.ethernetIp = data.ethernet.ip || ""
                        root.ethernetSpeed = data.ethernet.speed || ""
                    } else {
                        root.isEthernetConnected = false
                    }
                    root.savedNetworks = data.saved || []
                    root.scannedNetworks = data.scanned || []
                    if (data.adapter) {
                        root.isPowered = data.adapter.powered === true
                        root.hasConnectedNetwork = data.adapter.connected === true
                        root.connectedSsid = data.adapter.ssid || ""
                    }
                    if (root.hasConnectedNetwork && root.savedNetworks.length > 0) {
                        root.connectedSignal = root.savedNetworks[0].signal || 0
                    }
                } catch (e) {
                    // Ignore JSON parse errors
                }
            }
        }
    }

    // Airplane mode toggle process
    Process {
        id: airplaneProc
        onExited: root.refreshStatus()
    }

    // Periodic poller
    Timer {
        id: pollTimer
        interval: (root.mine && root.ctl && root.ctl.phase === "open") ? 2000 : (root.isScanning ? 3000 : 5000)
        running: true
        repeat: true
        onTriggered: root.refreshStatus()
    }

    // Rescan process
    Process {
        id: scanProc
        command: ["python3", root.scriptPath, "scan"]
        onExited: {
            root.isScanning = false
            root.refreshStatus()
        }
    }

    // Power toggle process
    Process {
        id: powerProc
        onExited: root.refreshStatus()
    }

    // Connect process
    Process {
        id: connectProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var res = JSON.parse(this.text)
                    if (res.status === "ok") {
                        root.statusMessage = "Connected successfully!"
                        root.isError = false
                    } else {
                        root.statusMessage = res.message || "Connection failed"
                        root.isError = true
                    }
                } catch (e) {
                    // Ignore JSON parse errors
                }
                root.refreshStatus()
            }
        }
    }

    // Disconnect process
    Process {
        id: disconnectProc
        command: ["python3", root.scriptPath, "disconnect"]
        onExited: {
            root.statusMessage = ""
            root.refreshStatus()
        }
    }

    // Forget network process
    Process {
        id: forgetProc
        onExited: {
            root.statusMessage = ""
            root.refreshStatus()
        }
    }

    Component.onCompleted: root.refreshStatus()

    // Wi-Fi panel inside Island
    panel: Component {
        Item {
            id: panelRoot
            anchors.fill: parent
            property bool isFloatingWindow: false

            // ── Main View (2 Lists + Top Scan Toggle) ──
            Item {
                id: mainView
                anchors.fill: parent
                visible: opacity > 0.01
                opacity: root.showPasswordInput ? 0.0 : 1.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Column {
                    id: settingsCol
                    anchors.top: parent.top
                    anchors.topMargin: 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width - 40, 440)
                    height: parent.height
                    spacing: 16

                    // Top Bar: Title & Control Buttons (Airplane Mode on top + Wi-Fi ON/OFF & Rescan)
                    Item {
                        id: headerItem
                        width: parent.width
                        height: rightControls.implicitHeight

                        Column {
                            anchors.left: parent.left
                            anchors.right: rightControls.left
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                text: root.isEthernetConnected ? "Ethernet Settings" : "Wi-Fi Settings"
                                color: CircleStyle.glyphColor
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: root.isEthernetConnected
                                      ? ("Connected via " + (root.ethernetConnection || "Cabled network") + (root.ethernetDevice ? " (" + root.ethernetDevice + ")" : ""))
                                      : (!root.isPowered ? "Wi-Fi is turned off" : (root.statusMessage ? root.statusMessage : (root.isScanning ? "Scanning for available networks..." : (root.hasConnectedNetwork ? "Connected to " + root.connectedSsid : "Manage Wi-Fi networks"))))
                                color: root.isError ? CircleStyle.dangerColor : CircleStyle.textDim
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        // Right control group: Airplane Mode button on top, On/Off + Rescan below
                        Column {
                            id: rightControls
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            // Airplane Mode Button (spans exact combined width of On/Off + Rescan: 184px)
                            Rectangle {
                                id: airplaneBtn
                                anchors.right: parent.right
                                width: 184
                                height: 32
                                radius: 16
                                color: root.isAirplaneMode ? CircleStyle.itemSelectedBg : (airplaneBtnMouse.containsMouse ? CircleStyle.itemHoverBg : CircleStyle.itemBg)
                                border.width: 1
                                border.color: root.isAirplaneMode ? CircleStyle.accentColor : (airplaneBtnMouse.containsMouse ? CircleStyle.itemSelectedBorder : CircleStyle.itemBorder)

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰀝"
                                        font.family: "Symbols Nerd Font"
                                        font.pixelSize: 13
                                        color: root.isAirplaneMode ? CircleStyle.accentColor : (airplaneBtnMouse.containsMouse ? CircleStyle.accentColor : CircleStyle.textDim)
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.isAirplaneMode ? "Airplane Mode: On" : "Airplane Mode: Off"
                                        color: root.isAirplaneMode ? CircleStyle.glyphColor : (airplaneBtnMouse.containsMouse ? CircleStyle.glyphColor : CircleStyle.textDim)
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                }

                                MouseArea {
                                    id: airplaneBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleAirplane()
                                }
                            }

                            // Right control buttons: Power ON/OFF + Rescan OR Ethernet Status Pill
                            Row {
                                id: ctrlButtons
                                anchors.right: parent.right
                                spacing: 8

                                // Ethernet Connected Badge
                                Rectangle {
                                    visible: root.isEthernetConnected
                                    width: 184
                                    height: 32
                                    radius: 16
                                    color: CircleStyle.itemSelectedBg
                                    border.width: 1
                                    border.color: CircleStyle.accentColor

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "󰌘"
                                            font.family: "Symbols Nerd Font"
                                            font.pixelSize: 13
                                            color: CircleStyle.accentColor
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "Connected"
                                            color: CircleStyle.accentColor
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }

                                // Wi-Fi Power ON/OFF Button
                                Rectangle {
                                    visible: !root.isEthernetConnected
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
                                            text: root.isPowered ? "󰤨" : "󰖪"
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

                                // Scan / Rescan Button
                                Rectangle {
                                    visible: !root.isEthernetConnected
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
                                            text: root.isScanning ? "󰤫" : "󰤨"
                                            font.family: "Symbols Nerd Font"
                                            font.pixelSize: 13
                                            color: root.isScanning ? CircleStyle.accentColor : CircleStyle.glyphColor
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: root.isScanning ? "Scanning..." : "Rescan"
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
                                        onClicked: root.triggerScan()
                                    }
                                }
                            }
                        }
                    }

                    // Scrollable List Container
                    Flickable {
                        width: parent.width
                        height: Math.max(100, settingsCol.height - headerItem.height - settingsCol.spacing)
                        contentWidth: width
                        contentHeight: contentCol.implicitHeight
                        clip: true

                        Column {
                            id: contentCol
                            width: parent.width
                            spacing: 14

                            // ── Cabled / Ethernet Connection View ──
                            Column {
                                visible: root.isEthernetConnected
                                width: parent.width
                                spacing: 18
                                topPadding: 30

                                // Hero Plug Badge
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 72
                                    height: 72
                                    radius: 36
                                    color: CircleStyle.itemSelectedBg
                                    border.width: 1.5
                                    border.color: CircleStyle.accentColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰌘"
                                        font.family: "Symbols Nerd Font"
                                        font.pixelSize: 36
                                        color: CircleStyle.accentColor
                                    }
                                }

                                // Status Header
                                Column {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width - 40
                                    spacing: 5

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Connected"
                                        color: CircleStyle.glyphColor
                                        font.pixelSize: 18
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Cabled network connection is active"
                                        color: CircleStyle.accentColor
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }
                                }

                                // Ethernet Details Card
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width
                                    height: ethDetailsCol.implicitHeight + 28
                                    radius: 12
                                    color: CircleStyle.itemHoverBg
                                    border.width: 1
                                    border.color: CircleStyle.itemBorder

                                    Column {
                                        id: ethDetailsCol
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 12

                                        // Connection Name
                                        Row {
                                            width: parent.width
                                            Text {
                                                text: "Connection"
                                                color: CircleStyle.textDim
                                                font.pixelSize: 12
                                                width: 110
                                            }
                                            Text {
                                                text: root.ethernetConnection || "Wired connection"
                                                color: CircleStyle.glyphColor
                                                font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                                width: parent.width - 110
                                            }
                                        }

                                        // Interface Name
                                        Row {
                                            width: parent.width
                                            Text {
                                                text: "Interface"
                                                color: CircleStyle.textDim
                                                font.pixelSize: 12
                                                width: 110
                                            }
                                            Text {
                                                text: root.ethernetDevice || "Ethernet"
                                                color: CircleStyle.glyphColor
                                                font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                                width: parent.width - 110
                                            }
                                        }

                                        // IPv4 Address
                                        Row {
                                            visible: root.ethernetIp !== ""
                                            width: parent.width
                                            Text {
                                                text: "IPv4 Address"
                                                color: CircleStyle.textDim
                                                font.pixelSize: 12
                                                width: 110
                                            }
                                            Text {
                                                text: root.ethernetIp
                                                color: CircleStyle.accentColor
                                                font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                                width: parent.width - 110
                                            }
                                        }

                                        // Link Speed
                                        Row {
                                            visible: root.ethernetSpeed !== ""
                                            width: parent.width
                                            Text {
                                                text: "Speed"
                                                color: CircleStyle.textDim
                                                font.pixelSize: 12
                                                width: 110
                                            }
                                            Text {
                                                text: root.ethernetSpeed
                                                color: CircleStyle.glyphColor
                                                font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                                width: parent.width - 110
                                            }
                                        }
                                    }
                                }
                            }

                            // ── Wi-Fi Disabled State View ──
                            Column {
                                visible: !root.isEthernetConnected && !root.isPowered
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
                                        text: root.isAirplaneMode ? "󰀝" : "󰖪"
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
                                        text: root.isAirplaneMode ? "Airplane Mode is Active" : "Wi-Fi is Disabled"
                                        color: CircleStyle.glyphColor
                                        font.pixelSize: 15
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.isAirplaneMode ? "All wireless radios are turned off. Turn off Airplane Mode to restore Wi-Fi." : "Turn on Wi-Fi to connect to saved networks and browse available Wi-Fi access points."
                                        color: CircleStyle.textDim
                                        font.pixelSize: 12
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WordWrap
                                        width: parent.width
                                    }
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 170
                                    height: 36
                                    radius: 18
                                    color: CircleStyle.accentColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.isAirplaneMode ? "Turn Off Airplane Mode" : "Turn Wi-Fi On"
                                        color: CircleStyle.fill
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.isAirplaneMode) root.toggleAirplane()
                                            else root.togglePower()
                                        }
                                    }
                                }
                            }

                            // ── 1. Top List: Saved & Connected Networks ──
                            Column {
                                visible: !root.isEthernetConnected && root.isPowered
                                width: parent.width
                                spacing: 8

                                Row {
                                    width: parent.width
                                    spacing: 8
                                    Text {
                                        text: "CONNECTED & SAVED NETWORKS"
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
                                            text: root.savedNetworks.length
                                            color: CircleStyle.textDim
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                // Empty state
                                Text {
                                    visible: root.savedNetworks.length === 0
                                    text: "No saved Wi-Fi networks"
                                    color: CircleStyle.textDim
                                    font.pixelSize: 12
                                    font.italic: true
                                }

                                Repeater {
                                    model: root.savedNetworks

                                    Rectangle {
                                        id: savedCard
                                        required property var modelData
                                        width: parent.width
                                        height: 56
                                        radius: 12
                                        color: modelData.connected ? CircleStyle.itemSelectedBg : (savedMouse.containsMouse ? CircleStyle.itemHoverBg : CircleStyle.transparent)
                                        border.width: modelData.connected ? 1.5 : 1
                                        border.color: modelData.connected ? CircleStyle.accentColor : (savedMouse.containsMouse ? CircleStyle.itemSelectedBorder : CircleStyle.itemBorder)

                                        // Left: Wi-Fi signal icon badge
                                        Rectangle {
                                            id: savedIconBadge
                                            anchors.left: parent.left
                                            anchors.leftMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 36
                                            height: 36
                                            radius: 18
                                            color: savedCard.modelData.connected ? CircleStyle.itemSelectedBg : CircleStyle.itemHoverBg
                                            border.width: 1
                                            border.color: savedCard.modelData.connected ? CircleStyle.accentColor : CircleStyle.itemBorder

                                            Text {
                                                anchors.centerIn: parent
                                                text: root.getSignalIcon(savedCard.modelData.signal)
                                                font.family: "Symbols Nerd Font"
                                                font.pixelSize: 18
                                                color: savedCard.modelData.connected ? CircleStyle.accentColor : CircleStyle.glyphColor
                                            }
                                        }

                                        // Right: Signal strength & Action button
                                        Row {
                                            id: savedActionsRow
                                            anchors.right: parent.right
                                            anchors.rightMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 8

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: savedCard.modelData.signal > 0 ? (savedCard.modelData.signal + "%") : "Out of range"
                                                color: savedCard.modelData.connected ? CircleStyle.accentColor : CircleStyle.textDim
                                                font.pixelSize: 11
                                            }

                                            // Forget / Delete profile button (only when saved but not connected)
                                            Rectangle {
                                                visible: !savedCard.modelData.connected
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
                                                    onClicked: root.forgetNetwork(savedCard.modelData.uuid || savedCard.modelData.ssid)
                                                }
                                            }

                                            // Connect / Disconnect button
                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: savedCard.modelData.connected ? 84 : 68
                                                height: 28
                                                radius: 14
                                                color: cardActionMouse.containsMouse ? CircleStyle.itemHoverBg : CircleStyle.transparent
                                                border.width: 1
                                                border.color: savedCard.modelData.connected ? CircleStyle.dangerColor : CircleStyle.itemBorder

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: savedCard.modelData.connected ? "Disconnect" : "Connect"
                                                    color: savedCard.modelData.connected ? CircleStyle.dangerColor : CircleStyle.glyphColor
                                                    font.pixelSize: 11
                                                    font.weight: Font.DemiBold
                                                }

                                                MouseArea {
                                                    id: cardActionMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (savedCard.modelData.connected) {
                                                            root.disconnectNetwork()
                                                        } else {
                                                            root.startConnect(savedCard.modelData)
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // Center: Network SSID & Info
                                        Column {
                                            anchors.left: savedIconBadge.right
                                            anchors.leftMargin: 12
                                            anchors.right: savedActionsRow.left
                                            anchors.rightMargin: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 3

                                            Text {
                                                text: savedCard.modelData.ssid
                                                color: savedCard.modelData.connected ? CircleStyle.glyphColor : CircleStyle.textDim
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                                width: parent.width
                                            }

                                            Row {
                                                spacing: 8
                                                Text {
                                                    text: savedCard.modelData.connected ? "Connected" : "Saved"
                                                    color: savedCard.modelData.connected ? CircleStyle.accentColor : CircleStyle.textDim
                                                    font.pixelSize: 11
                                                    font.weight: savedCard.modelData.connected ? Font.DemiBold : Font.Normal
                                                }

                                                Text {
                                                    visible: savedCard.modelData.freq !== ""
                                                    text: savedCard.modelData.freq.indexOf("5") === 0 ? "5 GHz" : "2.4 GHz"
                                                    color: CircleStyle.textDim
                                                    font.pixelSize: 11
                                                }

                                                Text {
                                                    visible: savedCard.modelData.security !== ""
                                                    text: "󰌾 " + savedCard.modelData.security
                                                    color: CircleStyle.textDim
                                                    font.family: "Symbols Nerd Font"
                                                    font.pixelSize: 11
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: savedMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            z: -1
                                        }
                                    }
                                }
                            }

                            // ── 2. Horizontal Line Separator ──
                            Rectangle {
                                visible: !root.isEthernetConnected && root.isPowered && (root.isScanning || root.scannedNetworks.length > 0)
                                width: parent.width
                                height: 1
                                color: CircleStyle.itemBorder
                            }

                            // ── 3. Bottom List: Available / Discovered Wi-Fi Networks ──
                            Column {
                                visible: !root.isEthernetConnected && root.isPowered
                                width: parent.width
                                spacing: 8

                                Row {
                                    width: parent.width
                                    spacing: 8
                                    Text {
                                        text: "AVAILABLE NETWORKS"
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
                                            text: root.scannedNetworks.length
                                            color: CircleStyle.accentColor
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                Text {
                                    visible: root.scannedNetworks.length === 0
                                    text: root.isScanning ? "Scanning for available Wi-Fi networks..." : "No additional networks found"
                                    color: CircleStyle.textDim
                                    font.pixelSize: 12
                                    font.italic: true
                                }

                                Repeater {
                                    model: root.scannedNetworks

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

                                        // Left: Wi-Fi Icon
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
                                                text: root.getSignalIcon(scannedCard.modelData.signal)
                                                font.family: "Symbols Nerd Font"
                                                font.pixelSize: 16
                                                color: CircleStyle.glyphColor
                                            }
                                        }

                                        // Right: Signal strength & Connect button
                                        Row {
                                            id: scannedActionsRow
                                            anchors.right: parent.right
                                            anchors.rightMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 8

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: scannedCard.modelData.signal + "%"
                                                color: CircleStyle.textDim
                                                font.pixelSize: 11
                                            }

                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 58
                                                height: 26
                                                radius: 13
                                                color: CircleStyle.itemSelectedBg
                                                border.width: 1
                                                border.color: CircleStyle.accentColor

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Connect"
                                                    color: CircleStyle.accentColor
                                                    font.pixelSize: 11
                                                    font.weight: Font.DemiBold
                                                }
                                            }
                                        }

                                        // Center: SSID & Security
                                        Column {
                                            anchors.left: scannedIconBadge.right
                                            anchors.leftMargin: 12
                                            anchors.right: scannedActionsRow.left
                                            anchors.rightMargin: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2

                                            Text {
                                                text: scannedCard.modelData.ssid
                                                color: CircleStyle.glyphColor
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                                width: parent.width
                                            }

                                            Row {
                                                spacing: 6
                                                Text {
                                                    text: scannedCard.modelData.security ? ("󰌾 " + scannedCard.modelData.security) : "Open"
                                                    color: CircleStyle.textDim
                                                    font.family: "Symbols Nerd Font"
                                                    font.pixelSize: 10
                                                }
                                                Text {
                                                    visible: scannedCard.modelData.freq !== ""
                                                    text: "· " + (scannedCard.modelData.freq.indexOf("5") === 0 ? "5 GHz" : "2.4 GHz")
                                                    color: CircleStyle.textDim
                                                    font.pixelSize: 10
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: scannedMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.startConnect(scannedCard.modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Password Authentication View ──
            // Vanishes the lists view when a Wi-Fi password is required
            Item {
                id: passwordView
                anchors.fill: parent
                visible: opacity > 0.01
                opacity: root.showPasswordInput ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Column {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 40, 380)
                    spacing: 16

                    // Lock badge icon
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 54
                        height: 54
                        radius: 27
                        color: CircleStyle.itemSelectedBg
                        border.width: 1.5
                        border.color: CircleStyle.accentColor

                        Text {
                            anchors.centerIn: parent
                            text: "󰌾"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 26
                            color: CircleStyle.accentColor
                        }
                    }

                    // Header
                    Column {
                        width: parent.width
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Wi-Fi Password Required"
                            color: CircleStyle.glyphColor
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Enter password for network " + root.connectingSsid
                            color: CircleStyle.textDim
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                    }

                    // Password Input Field
                    Rectangle {
                        width: parent.width
                        height: 44
                        radius: 10
                        color: CircleStyle.itemHoverBg
                        border.width: pwdInput.activeFocus ? 1.5 : 1
                        border.color: pwdInput.activeFocus ? CircleStyle.accentColor : CircleStyle.itemSelectedBorder

                        TextInput {
                            id: pwdInput
                            anchors.fill: parent
                            anchors.margins: 10
                            color: CircleStyle.glyphColor
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            echoMode: TextInput.Password
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            focus: root.showPasswordInput
                            onAccepted: root.submitPassword(pwdInput.text)
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Enter Wi-Fi Password"
                            color: CircleStyle.textDim
                            font.pixelSize: 13
                            visible: pwdInput.text.length === 0 && !pwdInput.activeFocus
                        }
                    }

                    // Buttons (Connect / Submit & Cancel)
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 14

                        // Cancel button
                        Rectangle {
                            width: 100
                            height: 36
                            radius: 18
                            color: cancelMouse.containsMouse ? CircleStyle.itemHoverBg : CircleStyle.transparent
                            border.width: 1
                            border.color: CircleStyle.itemBorder

                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: CircleStyle.textDim
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                id: cancelMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.cancelPassword()
                            }
                        }

                        // Connect button
                        Rectangle {
                            width: 110
                            height: 36
                            radius: 18
                            color: CircleStyle.accentColor

                            Text {
                                anchors.centerIn: parent
                                text: "Connect"
                                color: CircleStyle.fill
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.submitPassword(pwdInput.text)
                            }
                        }
                    }
                }
            }
        }
    }
}
