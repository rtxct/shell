// ============================================================================
// File: modules/screen-locker.module.qml
// Purpose: Wayland session locker implementing ext_session_lock_v1 protocol with PAM authentication, dynamic awww wallpaper background, large clock & date display, and shutdown/reboot triggers.
// Dependencies: Quickshell, Quickshell.Wayland, Quickshell.Services.Pam, Quickshell.Io, QtQuick, "../theme", "../styles", "../components/service-parsers.js", config/wallpaper.config.json
// ============================================================================
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Io
import QtQuick
import "../styles"
import "../components/service-parsers.js" as ServiceParsers
import "../../../themes"

Scope {
    id: root

    property bool isLocked: false
    property string wallpaperPath: ""
    property var screenWallpapers: ({})
    readonly property string userName: Quickshell.env("USER") || ""
    property bool authError: false
    property real contentOpacity: 0.0
    property string passwordText: ""

    // Fallback wallpaper from config/wallpaper.config.json; `awww query` overrides it on lock().
    function applyWallpaperConfig(text) {
        root.wallpaperPath = ServiceParsers.parseWallpaperConfig(text, { path: root.wallpaperPath }, Quickshell.env("HOME")).path
    }

    FileView {
        id: wallpaperConfigFile
        path: Quickshell.shellPath("config/wallpaper.config.json")
        watchChanges: true
        onFileChanged: wallpaperConfigFile.reload()
        onLoaded: root.applyWallpaperConfig(wallpaperConfigFile.text())
    }

    signal lockRequested()
    signal unlockRequested()

    NumberAnimation {
        id: fadeInAnim
        target: root
        property: "contentOpacity"
        from: 0.0
        to: 1.0
        duration: ScreenLockerStyle.fadeInDurationMs
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: fadeOutAnim
        target: root
        property: "contentOpacity"
        from: 1.0
        to: 0.0
        duration: ScreenLockerStyle.fadeOutDurationMs
        easing.type: Easing.InCubic
        onFinished: {
            pam.abort()
            root.isLocked = false
        }
    }

    function lock(): void {
        queryWallpaperProc.running = true
        root.authError = false
        root.passwordText = ""
        root.contentOpacity = 0.0
        root.isLocked = true
        fadeInAnim.start()
        pam.start()
    }

    function unlock(): void {
        root.authError = false
        root.passwordText = ""
        if (root.contentOpacity > 0.05) {
            fadeOutAnim.start()
        } else {
            pam.abort()
            root.isLocked = false
        }
    }

    function shutdown(): void {
        actionProc.command = ["systemctl", "poweroff"]
        actionProc.running = true
    }

    function reboot(): void {
        actionProc.command = ["systemctl", "reboot"]
        actionProc.running = true
    }

    function submitPassword(pwd: string): void {
        if (pam.responseRequired) {
            pam.respond(pwd)
        }
        root.passwordText = ""
    }

    function formatLockDate(date: date): string {
        var d = date || new Date()
        var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        return days[d.getDay()] + ", " + d.getDate() + " of " + months[d.getMonth()]
    }

    Process {
        id: queryWallpaperProc
        command: ["awww", "query"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                var trimmed = line.trim()
                var imgIdx = trimmed.indexOf("image: ")
                if (imgIdx !== -1) {
                    var path = trimmed.substring(imgIdx + 7).trim()
                    if (path.length > 0) {
                        root.wallpaperPath = path
                        var colIdx = trimmed.indexOf(":")
                        if (colIdx !== -1) {
                            var rest = trimmed.substring(colIdx + 1).trim()
                            var col2 = rest.indexOf(":")
                            if (col2 !== -1) {
                                var sName = rest.substring(0, col2).trim()
                                var map = Object.assign({}, root.screenWallpapers)
                                map[sName] = path
                                root.screenWallpapers = map
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: actionProc
    }

    SystemClock {
        id: lockClock
        precision: SystemClock.Seconds
    }

    Timer {
        id: authErrorTimer
        interval: 2000
        onTriggered: root.authError = false
    }

    PamContext {
        id: pam
        config: "swaylock"
        onCompleted: (result) => {
            if (result === PamResult.Success) {
                root.unlock()
            } else {
                root.authError = true
                root.passwordText = ""
                authErrorTimer.restart()
                pam.start()
            }
        }
        onError: (_err) => {
            root.authError = true
            root.passwordText = ""
            authErrorTimer.restart()
            pam.start()
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: root.isLocked

        surface: WlSessionLockSurface {
            id: lockSurface
            color: ScreenLockerStyle.backgroundColor

            Item {
                id: surfaceContent
                anchors.fill: parent
                opacity: root.contentOpacity

                Image {
                    anchors.fill: parent
                    source: {
                        var sName = lockSurface.screen ? lockSurface.screen.name : ""
                        var p = (sName && root.screenWallpapers[sName]) ? root.screenWallpapers[sName] : root.wallpaperPath
                        return p ? ("file://" + p) : ""
                    }
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                Rectangle {
                    anchors.fill: parent
                    color: ScreenLockerStyle.scrimColor
                    opacity: ScreenLockerStyle.scrimOpacity
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: pwdInput.forceActiveFocus()
                }

                // Top Left: big clock & day formatted as "Friday, 8 of May"
                Column {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 70
                    spacing: 10

                    Text {
                        text: Qt.formatDateTime(lockClock.date, "hh:mm:ss")
                        font.pixelSize: 76
                        font.weight: Font.Bold
                        color: ScreenLockerStyle.clockColor
                    }

                    Text {
                        text: root.formatLockDate(lockClock.date)
                        font.pixelSize: 22
                        font.weight: Font.Medium
                        color: ScreenLockerStyle.dateColor
                    }
                }

                // Bottom Right: name of logged in user, password line, written shutdown & reboot
                Column {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 70
                    spacing: 16
                    width: 300

                    Row {
                        anchors.right: parent.right
                        spacing: 10

                        Text {
                            text: ""
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 20
                            color: ScreenLockerStyle.userIconColor
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: root.userName
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            color: ScreenLockerStyle.userColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Item {
                        width: parent.width
                        height: 42

                        TextInput {
                            id: pwdInput
                            anchors.fill: parent
                            anchors.bottomMargin: 8
                            echoMode: TextInput.Password
                            color: ScreenLockerStyle.inputColor
                            font.pixelSize: 16
                            verticalAlignment: TextInput.AlignVCenter
                            horizontalAlignment: TextInput.AlignRight
                            focus: true
                            text: root.passwordText

                            onTextEdited: {
                                root.passwordText = text
                            }

                            Component.onCompleted: forceActiveFocus()

                            Connections {
                                target: root
                                function onIsLockedChanged() {
                                    if (root.isLocked) {
                                        pwdInput.forceActiveFocus()
                                    }
                                }
                            }

                            Text {
                                anchors.fill: parent
                                text: root.authError ? "incorrect password" : "password"
                                color: root.authError ? ScreenLockerStyle.inputBorderError : ScreenLockerStyle.placeholderColor
                                font.pixelSize: 16
                                font.italic: true
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignRight
                                visible: root.passwordText.length === 0
                            }

                            onAccepted: {
                                if (root.passwordText.length > 0) {
                                    root.submitPassword(root.passwordText)
                                }
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: root.authError ? 2 : (pwdInput.activeFocus ? 2 : 1)
                            color: root.authError ? ScreenLockerStyle.inputBorderError : (pwdInput.activeFocus ? ScreenLockerStyle.inputBorderFocused : ScreenLockerStyle.inputBorder)

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on height { NumberAnimation { duration: 150 } }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        spacing: 24

                        Text {
                            text: "shutdown"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: shutdownMa.containsMouse ? ScreenLockerStyle.actionDangerHoverColor : ScreenLockerStyle.actionColor
                            Behavior on color { ColorAnimation { duration: 120 } }

                            MouseArea {
                                id: shutdownMa
                                anchors.fill: parent
                                anchors.margins: -6
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.shutdown()
                            }
                        }

                        Text {
                            text: "reboot"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: rebootMa.containsMouse ? ScreenLockerStyle.actionHoverColor : ScreenLockerStyle.actionColor
                            Behavior on color { ColorAnimation { duration: 120 } }

                            MouseArea {
                                id: rebootMa
                                anchors.fill: parent
                                anchors.margins: -6
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.reboot()
                            }
                        }
                    }
                }
            }
        }
    }
}
