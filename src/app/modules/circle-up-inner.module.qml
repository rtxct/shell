// ============================================================================
// File: modules/circle-up-inner.module.qml
// Purpose: Upper-inner left-bar launcher circle module closest to the workspace island (side: 'up', slot: 2).
//          Provides interactive wlsunset (Night Light) controls: ON/OFF toggle,
//          latitude & longitude coordinates, daytime & nighttime color temperatures,
//          quick temperature presets, and an update & apply configuration action.
// Dependencies: QtQuick, Quickshell, Quickshell.Io, "../components", "../styles"
// ============================================================================
import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import "../styles"

// Left bar · upper inner circle (Night Light / wlsunset Controller)
Circle {
    id: root
    vertical: true
    side: "up"
    slot: 2              // 0 = outermost, 2 = closest to the workspaces island
    panelId: "up-inner"
    title: ""
    alwaysShowGlyph: true

    glyph: isRunning ? "󰖔" : "󰖙"
    glyphColor: isRunning ? CircleStyle.accentColor : CircleStyle.glyphColor

    readonly property string scriptPath: Quickshell.shellPath("src/app/scripts/sunset/sunset-manager.py")

    // State data
    property bool isRunning: false
    property bool isEnabled: false
    property bool userEditing: false
    property string feedbackMessage: ""
    property bool isError: false

    // Input fields state
    property string inputLat: "0.0"
    property string inputLong: "0.0"
    property string inputDayTemp: "6500"
    property string inputNightTemp: "4000"

    function togglePower() {
        if (!toggleProc.running) {
            toggleProc.running = true
        }
    }

    function applyConfig() {
        var lat = parseFloat(String(root.inputLat).trim())
        var lon = parseFloat(String(root.inputLong).trim())
        var day = parseInt(String(root.inputDayTemp).trim(), 10)
        var night = parseInt(String(root.inputNightTemp).trim(), 10)

        if (isNaN(lat) || lat < -90 || lat > 90) {
            root.feedbackMessage = "Invalid latitude (-90° to +90°)"
            root.isError = true
            feedbackTimer.restart()
            return
        }
        if (isNaN(lon) || lon < -180 || lon > 180) {
            root.feedbackMessage = "Invalid longitude (-180° to +180°)"
            root.isError = true
            feedbackTimer.restart()
            return
        }
        if (isNaN(day) || day < 1000 || day > 10000) {
            root.feedbackMessage = "Invalid daytime temp (1000K to 10000K)"
            root.isError = true
            feedbackTimer.restart()
            return
        }
        if (isNaN(night) || night < 1000 || night > 10000) {
            root.feedbackMessage = "Invalid nighttime temp (1000K to 10000K)"
            root.isError = true
            feedbackTimer.restart()
            return
        }

        root.userEditing = false
        root.feedbackMessage = "Applying configuration..."
        root.isError = false

        if (applyProc.running) {
            applyProc.running = false
        }
        applyProc.command = [
            "python3",
            "-u",
            root.scriptPath,
            "apply",
            "--lat",
            String(lat),
            "--long",
            String(lon),
            "--day",
            String(day),
            "--night",
            String(night),
            "--enabled",
            "true"
        ]
        applyProc.running = true
    }

    FileView {
        id: configFile
        path: Quickshell.shellPath("config/sunset.config.json")
        watchChanges: true
        onLoaded: {
            var shouldRestore = false
            try {
                var data = JSON.parse(text())
                root.isEnabled = data.enabled === true
                root.isRunning = data.enabled === true
                shouldRestore = data.enabled === true
                if (!root.userEditing) {
                    if (data.latitude !== undefined) root.inputLat = String(data.latitude)
                    if (data.longitude !== undefined) root.inputLong = String(data.longitude)
                    if (data.dayTemperature !== undefined) root.inputDayTemp = String(data.dayTemperature)
                    if (data.nightTemperature !== undefined) root.inputNightTemp = String(data.nightTemperature)
                }
            } catch (e) {}
            if (shouldRestore) {
                if (!restoreProc.running) restoreProc.running = true
            } else {
                if (!statusProc.running) statusProc.running = true
            }
        }
    }

    Process {
        id: restoreProc
        command: ["python3", "-u", root.scriptPath, "restore"]
        stdout: StdioCollector {
            onStreamFinished: {
                var trimmed = this.text.trim()
                if (trimmed.length > 0) {
                    try {
                        var data = JSON.parse(trimmed)
                        root.isEnabled = data.enabled === true
                        root.isRunning = (data.running === true) || (data.enabled === true)
                        if (!root.userEditing) {
                            if (data.latitude !== undefined) root.inputLat = String(data.latitude)
                            if (data.longitude !== undefined) root.inputLong = String(data.longitude)
                            if (data.dayTemperature !== undefined) root.inputDayTemp = String(data.dayTemperature)
                            if (data.nightTemperature !== undefined) root.inputNightTemp = String(data.nightTemperature)
                        }
                    } catch (e) {}
                }
            }
        }
    }

    Process {
        id: statusProc
        command: ["python3", "-u", root.scriptPath, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                var trimmed = this.text.trim()
                if (trimmed.length > 0) {
                    try {
                        var data = JSON.parse(trimmed)
                        root.isEnabled = data.enabled === true
                        root.isRunning = (data.running === true) || (data.enabled === true)
                        if (data.enabled === true && data.running !== true && data.installed !== false) {
                            if (!restoreProc.running) restoreProc.running = true
                        }
                        if (!root.userEditing) {
                            if (data.latitude !== undefined) root.inputLat = String(data.latitude)
                            if (data.longitude !== undefined) root.inputLong = String(data.longitude)
                            if (data.dayTemperature !== undefined) root.inputDayTemp = String(data.dayTemperature)
                            if (data.nightTemperature !== undefined) root.inputNightTemp = String(data.nightTemperature)
                        }
                    } catch (e) {}
                }
            }
        }
    }

    Process {
        id: toggleProc
        command: ["python3", "-u", root.scriptPath, "toggle"]
        stdout: StdioCollector {
            onStreamFinished: {
                var trimmed = this.text.trim()
                if (trimmed.length > 0) {
                    try {
                        var data = JSON.parse(trimmed)
                        root.isRunning = data.running === true
                        root.isEnabled = data.enabled === true
                    } catch (e) {}
                }
            }
        }
        onExited: {
            if (!statusProc.running) statusProc.running = true
        }
    }

    Process {
        id: applyProc
        stdout: StdioCollector {
            onStreamFinished: {
                var trimmed = this.text.trim()
                if (trimmed.length > 0) {
                    try {
                        var data = JSON.parse(trimmed)
                        root.isRunning = data.running === true
                        root.isEnabled = data.enabled === true
                        root.feedbackMessage = " Configuration updated & applied!"
                        root.isError = false
                        feedbackTimer.restart()
                    } catch (e) {
                        root.feedbackMessage = "Failed to apply configuration"
                        root.isError = true
                        feedbackTimer.restart()
                    }
                }
            }
        }
        stderr: StdioCollector {
            id: applyErr
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                var err = applyErr.text.trim()
                root.feedbackMessage = err.length > 0 ? err : "Failed to apply configuration"
                root.isError = true
                feedbackTimer.restart()
            }
            if (!statusProc.running) statusProc.running = true
        }
    }

    Timer {
        id: pollTimer
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statusProc.running) statusProc.running = true
        }
    }

    Timer {
        id: feedbackTimer
        interval: 3500
        onTriggered: {
            root.feedbackMessage = ""
            root.isError = false
        }
    }

    panel: Component {
        Item {
            id: sunsetPanel
            anchors.fill: parent

            Flickable {
                id: flick
                anchors.fill: parent
                contentWidth: width
                contentHeight: contentCol.implicitHeight + 24
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: false

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: function(event) {
                        var delta = event.angleDelta.y
                        if (delta !== 0) {
                            var maxScroll = Math.max(0, flick.contentHeight - flick.height)
                            var step = delta > 0 ? -40 : 40
                            flick.contentY = Math.max(0, Math.min(maxScroll, flick.contentY + step))
                        }
                    }
                }

                Column {
                    id: contentCol
                    x: Math.round((flick.width - width) / 2)
                    y: 4
                    width: Math.min(flick.width - 24, 460)
                    spacing: 14

                // Header
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Night Light"
                        color: CircleStyle.textBright
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Circadian blue light filter & screen color temperature"
                        color: CircleStyle.textDim
                        font.pixelSize: 12
                    }
                }

                // Hero State Card (Toggle switch and active temperature readout)
                Rectangle {
                    width: parent.width
                    height: 84
                    radius: 16
                    color: CircleStyle.itemBg
                    border.width: 1
                    border.color: CircleStyle.itemBorder

                    Row {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 14

                        Rectangle {
                            width: 48
                            height: 48
                            radius: 24
                            color: root.isRunning ? CircleStyle.itemSelectedBg : CircleStyle.itemBg
                            border.width: 1
                            border.color: root.isRunning ? CircleStyle.accentColor : CircleStyle.itemBorder
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: root.isRunning ? "󰖔" : "󰖙"
                                font.family: "Symbols Nerd Font"
                                font.pixelSize: 24
                                color: root.isRunning ? CircleStyle.accentColor : CircleStyle.textSecondary
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            width: parent.width - 48 - 14 - toggleButton.width - 14

                            Text {
                                text: root.isRunning ? "Night Light Active" : "Night Light Disabled"
                                color: CircleStyle.textBright
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: root.isRunning
                                    ? ("Auto transitions · " + root.inputNightTemp + " K night target")
                                    : "Color temperature natural / unmanaged"
                                color: CircleStyle.textDim
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        // On/Off Toggle Button
                        Rectangle {
                            id: toggleButton
                            anchors.verticalCenter: parent.verticalCenter
                            width: 78
                            height: 34
                            radius: 17
                            color: root.isRunning ? CircleStyle.accentColor : CircleStyle.itemSelectedBg
                            border.width: 1
                            border.color: root.isRunning ? CircleStyle.accentColor : CircleStyle.itemSelectedBorder

                            Rectangle {
                                id: togglePill
                                width: 26
                                height: 26
                                radius: 13
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.isRunning ? (parent.width - width - 4) : 4
                                color: root.isRunning ? CircleStyle.fill : CircleStyle.glyphColor

                                Behavior on x {
                                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: root.isRunning ? -12 : 12
                                text: root.isRunning ? "ON" : "OFF"
                                color: root.isRunning ? CircleStyle.fill : CircleStyle.textDim
                                font.pixelSize: 11
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.togglePower()
                            }
                        }
                    }
                }

                // 2x2 Grid of Parameters (Latitude, Longitude, Daytime Temp, Nighttime Temp)
                Grid {
                    width: parent.width
                    columns: 2
                    spacing: 12

                    // Parameter 1: Latitude
                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 94
                        radius: 14
                        color: CircleStyle.itemBg
                        border.width: 1
                        border.color: CircleStyle.itemBorder

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6

                            Row {
                                spacing: 6
                                Text {
                                    text: "󰍹"
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 12
                                    color: CircleStyle.glyphColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "LATITUDE"
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    color: CircleStyle.textDim
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 32
                                radius: 8
                                color: CircleStyle.itemSelectedBg
                                border.width: 1
                                border.color: latInput.activeFocus ? CircleStyle.accentColor : CircleStyle.itemSelectedBorder

                                TextInput {
                                    id: latInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: CircleStyle.textBright
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    selectByMouse: true
                                    selectionColor: CircleStyle.accentColor
                                    text: root.inputLat
                                    onTextEdited: {
                                        root.userEditing = true
                                        root.inputLat = text
                                    }
                                }
                            }

                            Text {
                                text: "Degrees (-90° to +90°)"
                                font.pixelSize: 10
                                color: CircleStyle.textDim
                            }
                        }
                    }

                    // Parameter 2: Longitude
                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 94
                        radius: 14
                        color: CircleStyle.itemBg
                        border.width: 1
                        border.color: CircleStyle.itemBorder

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6

                            Row {
                                spacing: 6
                                Text {
                                    text: "󰍹"
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 12
                                    color: CircleStyle.glyphColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "LONGITUDE"
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    color: CircleStyle.textDim
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 32
                                radius: 8
                                color: CircleStyle.itemSelectedBg
                                border.width: 1
                                border.color: lonInput.activeFocus ? CircleStyle.accentColor : CircleStyle.itemSelectedBorder

                                TextInput {
                                    id: lonInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: CircleStyle.textBright
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    selectByMouse: true
                                    selectionColor: CircleStyle.accentColor
                                    text: root.inputLong
                                    onTextEdited: {
                                        root.userEditing = true
                                        root.inputLong = text
                                    }
                                }
                            }

                            Text {
                                text: "Degrees (-180° to +180°)"
                                font.pixelSize: 10
                                color: CircleStyle.textDim
                            }
                        }
                    }

                    // Parameter 3: Daytime Temperature
                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 94
                        radius: 14
                        color: CircleStyle.itemBg
                        border.width: 1
                        border.color: CircleStyle.itemBorder

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6

                            Row {
                                spacing: 6
                                Text {
                                    text: "󰖙"
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 12
                                    color: CircleStyle.accentColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "DAY TEMPERATURE"
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    color: CircleStyle.textDim
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 32
                                radius: 8
                                color: CircleStyle.itemSelectedBg
                                border.width: 1
                                border.color: dayInput.activeFocus ? CircleStyle.accentColor : CircleStyle.itemSelectedBorder

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8

                                    TextInput {
                                        id: dayInput
                                        width: parent.width - 24
                                        height: parent.height
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: CircleStyle.textBright
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        selectByMouse: true
                                        selectionColor: CircleStyle.accentColor
                                        text: root.inputDayTemp
                                        onTextEdited: {
                                            root.userEditing = true
                                            root.inputDayTemp = text
                                        }
                                    }

                                    Text {
                                        text: "K"
                                        color: CircleStyle.textDim
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            Text {
                                text: "Default: 6500 K (Cool white)"
                                font.pixelSize: 10
                                color: CircleStyle.textDim
                            }
                        }
                    }

                    // Parameter 4: Nighttime Temperature
                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 94
                        radius: 14
                        color: CircleStyle.itemBg
                        border.width: 1
                        border.color: CircleStyle.itemBorder

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6

                            Row {
                                spacing: 6
                                Text {
                                    text: "󰖔"
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 12
                                    color: CircleStyle.accentColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "NIGHT TEMPERATURE"
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    color: CircleStyle.textDim
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 32
                                radius: 8
                                color: CircleStyle.itemSelectedBg
                                border.width: 1
                                border.color: nightInput.activeFocus ? CircleStyle.accentColor : CircleStyle.itemSelectedBorder

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8

                                    TextInput {
                                        id: nightInput
                                        width: parent.width - 24
                                        height: parent.height
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: CircleStyle.textBright
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        selectByMouse: true
                                        selectionColor: CircleStyle.accentColor
                                        text: root.inputNightTemp
                                        onTextEdited: {
                                            root.userEditing = true
                                            root.inputNightTemp = text
                                        }
                                    }

                                    Text {
                                        text: "K"
                                        color: CircleStyle.textDim
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            Text {
                                text: "Warm amber (e.g. 4000 K / 3500 K)"
                                font.pixelSize: 10
                                color: CircleStyle.textDim
                            }
                        }
                    }
                }

                // Quick Night Temperature Presets
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Text {
                        text: "Presets:"
                        color: CircleStyle.textDim
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Repeater {
                        model: [
                            { label: "4500K", val: "4500" },
                            { label: "4000K", val: "4000" },
                            { label: "3500K", val: "3500" },
                            { label: "3000K", val: "3000" }
                        ]

                        Rectangle {
                            required property var modelData
                            width: 58
                            height: 24
                            radius: 12
                            color: root.inputNightTemp === modelData.val ? CircleStyle.itemSelectedBg : CircleStyle.itemBg
                            border.width: 1
                            border.color: root.inputNightTemp === modelData.val ? CircleStyle.accentColor : CircleStyle.itemBorder

                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData.label
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: parent.modelData.val === root.inputNightTemp ? CircleStyle.accentColor : CircleStyle.textSecondary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.userEditing = true
                                    root.inputNightTemp = parent.modelData.val
                                }
                            }
                        }
                    }
                }

                // Action / Apply Button
                Rectangle {
                    width: parent.width
                    height: 42
                    radius: 12
                    color: applyMouse.pressed
                        ? CircleStyle.itemSelectedBg
                        : (applyMouse.containsMouse ? CircleStyle.itemHoverBg : CircleStyle.itemBg)
                    border.width: 1.2
                    border.color: root.isError
                        ? CircleStyle.dangerColor
                        : (applyMouse.containsMouse ? CircleStyle.accentColor : CircleStyle.itemSelectedBorder)

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: root.feedbackMessage ? (root.isError ? "" : "") : "󰑓"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 14
                            color: root.isError
                                ? CircleStyle.dangerColor
                                : (root.feedbackMessage ? CircleStyle.accentColor : CircleStyle.textBright)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: root.feedbackMessage ? root.feedbackMessage : "Update & Apply Configuration"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: root.isError
                                ? CircleStyle.dangerColor
                                : (root.feedbackMessage ? CircleStyle.accentColor : CircleStyle.textBright)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: applyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.applyConfig()
                    }
                }
            }
        }

        // Visual scroll indicator
            Item {
                id: scrollBarTrack
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.rightMargin: 2
                width: 4
                visible: flick.contentHeight > flick.height

                Rectangle {
                    id: scrollBarThumb
                    y: Math.min(scrollBarTrack.height - height, Math.max(0, flick.visibleArea.yPosition * scrollBarTrack.height))
                    width: parent.width
                    height: Math.max(20, Math.min(scrollBarTrack.height, flick.visibleArea.heightRatio * scrollBarTrack.height))
                    radius: width / 2
                    color: CircleStyle.itemBorder
                }
            }
        }
    }
}
