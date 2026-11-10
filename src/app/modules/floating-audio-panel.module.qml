// ============================================================================
// File: modules/floating-audio-panel.module.qml
// Purpose: Detached floating pavucontrol-equivalent sound control center (Output Devices,
//          Input Devices, Playback Streams, Recording Streams, Card Drivers/Profiles)
//          plus a dedicated Media Control deck featuring a spinning CD Play/Pause button
//          with circular track artwork (or '?' fallback), Previous/Next, track title, and origin.
// Public API:
//   - Properties: audio, activeTab, inputFilter, recordingFilter, discRotation, hasArtImage,
//                 trackTitleText, trackOriginText, fg, dim, accent, danger
// Dependencies: QtQuick, QtQuick.Layouts, QtQuick.Effects, "../styles"
// ============================================================================
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../styles"

Item {
    id: root

    property var audio: null

    property color fg: FloatingPanelsStyle.textPrimary
    property color dim: FloatingPanelsStyle.textDim
    property color accent: FloatingPanelsStyle.accent
    property color danger: FloatingPanelsStyle.danger

    // ── Pavucontrol Tab State ──
    // 0 = Output Devices, 1 = Input Devices, 2 = Playback, 3 = Recording, 4 = Drivers (Configuration)
    property int activeTab: 0
    property string inputFilter: "non-monitors" // "non-monitors" | "all" | "monitors"
    property string recordingFilter: "apps"     // "apps" | "all"
    property var expandedCards: ({})

    function isCardExpanded(cardName) {
        if (!cardName || !root.expandedCards) return false
        return root.expandedCards[cardName] === true
    }

    function toggleCardExpanded(cardName) {
        if (!cardName) return
        var next = {}
        var current = root.expandedCards || {}
        for (var k in current) {
            if (Object.prototype.hasOwnProperty.call(current, k)) {
                next[k] = current[k]
            }
        }
        next[cardName] = !next[cardName]
        root.expandedCards = next
    }

    // ── Media & Spinning CD State ──
    readonly property bool isPlaying: (root.audio && root.audio.isPlaying) ? true : false
    readonly property string trackArtUrl: (root.audio && root.audio.trackArtUrl) ? String(root.audio.trackArtUrl) : ""
    readonly property bool hasArtImage: trackArtUrl !== "" && cdArtImage.status === Image.Ready
    readonly property string trackTitleText: (root.audio && root.audio.trackTitle) ? root.audio.trackTitle : "No media playing"
    readonly property string trackOriginText: {
        if (!root.audio) return "No source"
        var app = root.audio.trackApp ? String(root.audio.trackApp) : ""
        var artist = root.audio.trackArtist ? String(root.audio.trackArtist) : ""
        if (app !== "" && artist !== "") return app + " · " + artist
        if (app !== "") return app
        if (artist !== "") return artist
        return root.isPlaying ? "System Audio" : "Idle"
    }

    // Continuous rotation angle (0..360) for the CD play button; pauses in-place when not playing
    property real discRotation: 0.0

    FrameAnimation {
        id: cdSpinAnim
        running: root.isPlaying && root.visible
        onTriggered: {
            root.discRotation = (root.discRotation + frameTime * 60.0) % 360.0
        }
    }

    function stepRotation(seconds) {
        if (root.isPlaying) {
            root.discRotation = (root.discRotation + seconds * 60.0) % 360.0
        }
    }

    // ── Filtered Pavucontrol Lists ──
    readonly property var sinksList: {
        if (root.audio && Array.isArray(root.audio.sinks) && root.audio.sinks.length > 0) {
            return root.audio.sinks
        }
        if (root.audio) {
            return [{
                index: 0,
                name: "@DEFAULT_AUDIO_SINK@",
                description: "Default Output Device",
                driver: "PipeWire",
                api: "alsa",
                state: "IDLE",
                mute: root.audio.sinkMuted ? true : false,
                volume: root.audio.sinkVolume !== undefined ? root.audio.sinkVolume : 1.0,
                volume_pct: Math.round((root.audio.sinkVolume !== undefined ? root.audio.sinkVolume : 1.0) * 100),
                db: "0.00 dB",
                is_default: true,
                active_port: "",
                ports: []
            }]
        }
        return []
    }

    readonly property var sourcesList: {
        var all = (root.audio && Array.isArray(root.audio.sources)) ? root.audio.sources : []
        if (all.length === 0 && root.audio) {
            all = [{
                index: 0,
                name: "@DEFAULT_AUDIO_SOURCE@",
                description: "Default Input Microphone",
                driver: "PipeWire",
                api: "alsa",
                state: "IDLE",
                mute: root.audio.sourceMuted ? true : false,
                volume: root.audio.sourceVolume !== undefined ? root.audio.sourceVolume : 1.0,
                volume_pct: Math.round((root.audio.sourceVolume !== undefined ? root.audio.sourceVolume : 1.0) * 100),
                db: "0.00 dB",
                is_default: true,
                is_monitor: false,
                active_port: "",
                ports: []
            }]
        }
        var out = []
        for (var i = 0; i < all.length; i++) {
            var s = all[i]
            if (root.inputFilter === "non-monitors" && s.is_monitor) continue
            if (root.inputFilter === "monitors" && !s.is_monitor) continue
            out.push(s)
        }
        return out
    }

    readonly property var sinkInputsList: (root.audio && Array.isArray(root.audio.sinkInputs)) ? root.audio.sinkInputs : []

    readonly property var sourceOutputsList: {
        var all = (root.audio && Array.isArray(root.audio.sourceOutputs)) ? root.audio.sourceOutputs : []
        var out = []
        for (var i = 0; i < all.length; i++) {
            var so = all[i]
            if (root.recordingFilter === "apps" && so.is_virtual) continue
            out.push(so)
        }
        return out
    }

    readonly property var cardsList: (root.audio && Array.isArray(root.audio.cards)) ? root.audio.cards : []

    onVisibleChanged: {
        if (visible && root.audio && typeof root.audio.refreshPavu === "function") {
            root.audio.refreshPavu()
        }
    }

    Component.onCompleted: {
        if (root.audio && typeof root.audio.refreshPavu === "function") {
            root.audio.refreshPavu()
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 8

        // ════════════════════════════════════════════════════════════════════
        // 1. MEDIA CONTROL SECTION (Spinning CD Play/Pause, Prev/Next, Name & Origin)
        // ════════════════════════════════════════════════════════════════════
        Rectangle {
            id: mediaDeckCard
            width: parent.width
            height: 136
            radius: FloatingPanelsStyle.cardRadius
            color: FloatingPanelsStyle.cardBg
            border.width: 1
            border.color: FloatingPanelsStyle.cardBorder

            Column {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                // Audio Name (Track Title)
                Text {
                    id: mediaTitleLabel
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: root.trackTitleText
                    color: root.fg
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                // Audio Origin (Application / Player & Artist)
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 5

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰎈"
                        font.family: FloatingPanelsStyle.iconFont
                        font.pixelSize: 11
                        color: root.accent
                    }

                    Text {
                        id: mediaOriginLabel
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, mediaDeckCard.width - 40)
                        elide: Text.ElideRight
                        text: root.trackOriginText
                        color: root.dim
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }
                }

                // Transport Controls Row: [ Previous ]   [ Spinning CD Play/Pause ]   [ Next ]
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 26

                    // Previous Button
                    Rectangle {
                        id: prevBtn
                        anchors.verticalCenter: parent.verticalCenter
                        width: FloatingPanelsStyle.playBtnSize
                        height: FloatingPanelsStyle.playBtnSize
                        radius: FloatingPanelsStyle.playBtnRadius
                        color: prevM.containsMouse ? FloatingPanelsStyle.buttonHoverBg : FloatingPanelsStyle.buttonBg
                        border.width: 1
                        border.color: prevM.containsMouse ? root.accent : FloatingPanelsStyle.buttonBorder
                        scale: prevM.pressed ? 0.90 : (prevM.containsMouse ? 1.08 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: FloatingPanelsStyle.iconFont
                            font.pixelSize: FloatingPanelsStyle.mediaTransportFontPx
                            color: prevM.containsMouse ? root.accent : root.fg
                        }

                        MouseArea {
                            id: prevM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (root.audio) root.audio.previous() }
                        }
                    }

                    // Middle: Spinning CD Play / Pause Button
                    Item {
                        id: cdPlayButton
                        objectName: "cdPlayButton"
                        anchors.verticalCenter: parent.verticalCenter
                        width: FloatingPanelsStyle.cdDiscSize
                        height: FloatingPanelsStyle.cdDiscSize
                        scale: playM.pressed ? 0.93 : (playM.containsMouse ? 1.05 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                        // Circular mask for album art
                        Rectangle {
                            id: cdMask
                            width: FloatingPanelsStyle.cdDiscSize - 4
                            height: FloatingPanelsStyle.cdDiscSize - 4
                            radius: (FloatingPanelsStyle.cdDiscSize - 4) / 2
                            layer.enabled: true
                            visible: false
                        }

                        // Hidden source Image for track artwork
                        Image {
                            id: cdArtImage
                            source: root.trackArtUrl
                            width: FloatingPanelsStyle.cdDiscSize - 4
                            height: FloatingPanelsStyle.cdDiscSize - 4
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            visible: false
                        }

                        // Rotating CD Disc assembly (turns around its own center axis)
                        Item {
                            id: cdRotatingDisc
                            objectName: "cdRotatingDisc"
                            anchors.fill: parent
                            transformOrigin: Item.Center
                            rotation: root.discRotation

                            // Base CD metallic/vinyl body
                            Rectangle {
                                anchors.fill: parent
                                radius: FloatingPanelsStyle.cdDiscRadius
                                color: FloatingPanelsStyle.cdSurfaceBg
                                border.width: 2
                                border.color: root.isPlaying ? root.accent : FloatingPanelsStyle.buttonBorder

                                // Concentric groove ring when no artwork is loaded
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: FloatingPanelsStyle.cdInnerGrooveSize
                                    height: FloatingPanelsStyle.cdInnerGrooveSize
                                    radius: FloatingPanelsStyle.cdInnerGrooveSize / 2
                                    color: FloatingPanelsStyle.transparent
                                    border.width: 1
                                    border.color: FloatingPanelsStyle.cdGrooveBorder
                                    visible: !root.hasArtImage
                                }

                                // Subtle orientation notch on the disc rim so rotation is always visually clear
                                Rectangle {
                                    width: 4
                                    height: 4
                                    radius: 2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.topMargin: 4
                                    color: root.accent
                                    opacity: 0.75
                                    visible: !root.hasArtImage
                                }

                                // Fallback Question Mark ('?') when audio has no image
                                Text {
                                    id: cdQuestionMark
                                    objectName: "cdQuestionMark"
                                    anchors.centerIn: parent
                                    visible: !root.hasArtImage
                                    text: "?"
                                    color: root.isPlaying ? root.accent : root.fg
                                    font.pixelSize: FloatingPanelsStyle.cdQuestionMarkFontPx
                                    font.weight: Font.Bold
                                }
                            }

                            // Circularly masked Album Art when audio has an image
                            MultiEffect {
                                anchors.centerIn: parent
                                width: cdMask.width
                                height: cdMask.height
                                source: cdArtImage
                                maskEnabled: true
                                maskSource: cdMask
                                visible: root.hasArtImage
                            }

                            // Outer specular ring over artwork
                            Rectangle {
                                anchors.fill: parent
                                radius: FloatingPanelsStyle.cdDiscRadius
                                color: FloatingPanelsStyle.transparent
                                border.width: 1.5
                                border.color: root.isPlaying ? root.accent : FloatingPanelsStyle.buttonBorder
                                visible: root.hasArtImage
                            }

                            // CD Center Spindle Ring (shown when artwork is present)
                            Rectangle {
                                anchors.centerIn: parent
                                width: FloatingPanelsStyle.cdSpindleRingSize
                                height: FloatingPanelsStyle.cdSpindleRingSize
                                radius: FloatingPanelsStyle.cdSpindleRingSize / 2
                                color: FloatingPanelsStyle.cdOverlayBg
                                border.width: 1
                                border.color: FloatingPanelsStyle.cdGrooveBorder
                                visible: root.hasArtImage

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: FloatingPanelsStyle.cdSpindleHoleSize
                                    height: FloatingPanelsStyle.cdSpindleHoleSize
                                    radius: FloatingPanelsStyle.cdSpindleHoleSize / 2
                                    color: FloatingPanelsStyle.cdSpindleBg
                                }
                            }
                        }

                        // Stationary Play / Pause badge overlay in bottom-right corner (and center hover indicator)
                        Rectangle {
                            id: playPauseBadge
                            width: 22
                            height: 22
                            radius: 11
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            color: playM.containsMouse ? root.accent : FloatingPanelsStyle.cdSpindleBg
                            border.width: 1.2
                            border.color: root.accent

                            Text {
                                anchors.centerIn: parent
                                text: root.isPlaying ? "" : ""
                                font.family: FloatingPanelsStyle.iconFont
                                font.pixelSize: 10
                                color: playM.containsMouse ? FloatingPanelsStyle.textOnAccent : root.fg
                            }
                        }

                        MouseArea {
                            id: playM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (root.audio) root.audio.togglePlay() }
                        }
                    }

                    // Forward / Next Button
                    Rectangle {
                        id: nextBtn
                        anchors.verticalCenter: parent.verticalCenter
                        width: FloatingPanelsStyle.playBtnSize
                        height: FloatingPanelsStyle.playBtnSize
                        radius: FloatingPanelsStyle.playBtnRadius
                        color: nextM.containsMouse ? FloatingPanelsStyle.buttonHoverBg : FloatingPanelsStyle.buttonBg
                        border.width: 1
                        border.color: nextM.containsMouse ? root.accent : FloatingPanelsStyle.buttonBorder
                        scale: nextM.pressed ? 0.90 : (nextM.containsMouse ? 1.08 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: FloatingPanelsStyle.iconFont
                            font.pixelSize: FloatingPanelsStyle.mediaTransportFontPx
                            color: nextM.containsMouse ? root.accent : root.fg
                        }

                        MouseArea {
                            id: nextM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (root.audio) root.audio.next() }
                        }
                    }
                }
            }
        }

        // ════════════════════════════════════════════════════════════════════
        // 2. PAVUCONTROL TAB BAR (Output, Input, Playback, Recording, Drivers)
        // ════════════════════════════════════════════════════════════════════
        Row {
            id: pavuTabBar
            width: parent.width
            spacing: 4

            Repeater {
                model: [
                    { idx: 0, icon: "󰕾", label: "Output", count: root.sinksList.length },
                    { idx: 1, icon: "󰍬", label: "Input", count: root.sourcesList.length },
                    { idx: 2, icon: "󰎈", label: "Playback", count: root.sinkInputsList.length },
                    { idx: 3, icon: "󰑊", label: "Recording", count: root.sourceOutputsList.length },
                    { idx: 4, icon: "󰒓", label: "Drivers", count: root.cardsList.length }
                ]

                Rectangle {
                    id: tabBtn
                    required property var modelData
                    readonly property bool isCurrent: root.activeTab === modelData.idx
                    width: (pavuTabBar.width - 16) / 5
                    height: FloatingPanelsStyle.pavuTabHeight
                    radius: FloatingPanelsStyle.pavuTabRadius
                    color: isCurrent ? root.accent : (tabMouse.containsMouse ? FloatingPanelsStyle.buttonHoverBg : FloatingPanelsStyle.buttonBg)
                    border.width: 1
                    border.color: isCurrent ? root.accent : FloatingPanelsStyle.buttonBorder

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tabBtn.modelData.icon
                            font.family: FloatingPanelsStyle.iconFont
                            font.pixelSize: FloatingPanelsStyle.pavuTabFontPx
                            color: tabBtn.isCurrent ? FloatingPanelsStyle.textOnAccent : root.fg
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tabBtn.modelData.label + " (" + tabBtn.modelData.count + ")"
                            font.pixelSize: FloatingPanelsStyle.pavuTabFontPx - 1
                            font.weight: tabBtn.isCurrent ? Font.Bold : Font.Medium
                            color: tabBtn.isCurrent ? FloatingPanelsStyle.textOnAccent : root.fg
                        }
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.activeTab = tabBtn.modelData.idx
                            if (root.audio && typeof root.audio.refreshPavu === "function") {
                                root.audio.refreshPavu()
                            }
                        }
                    }
                }
            }
        }

        // ════════════════════════════════════════════════════════════════════
        // 3. PAVUCONTROL SCROLLABLE TAB CONTENT
        // ════════════════════════════════════════════════════════════════════
        Flickable {
            id: tabScroll
            width: parent.width
            height: Math.max(80, parent.height - mediaDeckCard.height - pavuTabBar.height - 16)
            contentWidth: width
            contentHeight: tabContentCol.height + 8
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: tabContentCol
                width: parent.width
                spacing: 8

                // ────────────────────────────────────────────────────────────
                // TAB 0: OUTPUT DEVICES (Sinks, Default Sink, Ports, Volume)
                // ────────────────────────────────────────────────────────────
                Column {
                    visible: root.activeTab === 0
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: root.sinksList

                        Rectangle {
                            id: sinkCard
                            required property var modelData
                            width: tabContentCol.width
                            height: sinkInnerCol.height + 16
                            radius: FloatingPanelsStyle.cardRadius
                            color: FloatingPanelsStyle.cardBg
                            border.width: 1
                            border.color: modelData.is_default ? root.accent : FloatingPanelsStyle.cardBorder

                            Column {
                                id: sinkInnerCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 8
                                spacing: 6

                                // Header: Mute Button + Device Name & Driver + Set Default Button
                                Item {
                                    width: parent.width
                                    height: 30

                                    // Mute Toggle
                                    Rectangle {
                                        id: sinkMuteBtn
                                        width: FloatingPanelsStyle.audioToggleSize
                                        height: FloatingPanelsStyle.audioToggleSize
                                        radius: FloatingPanelsStyle.audioToggleRadius
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: sinkCard.modelData.mute ? FloatingPanelsStyle.mutedTint : (sinkMuteMouse.containsMouse ? FloatingPanelsStyle.itemHoverBg : FloatingPanelsStyle.buttonBg)
                                        border.width: 1
                                        border.color: sinkCard.modelData.mute ? root.danger : FloatingPanelsStyle.buttonBorder

                                        Text {
                                            anchors.centerIn: parent
                                            text: sinkCard.modelData.mute ? "󰝟" : "󰕾"
                                            font.family: FloatingPanelsStyle.iconFont
                                            font.pixelSize: FloatingPanelsStyle.audioIconFontPx
                                            color: sinkCard.modelData.mute ? root.danger : root.accent
                                        }

                                        MouseArea {
                                            id: sinkMuteMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (!root.audio) return
                                                if (typeof root.audio.toggleDeviceSinkMute === "function" && sinkCard.modelData.name !== "@DEFAULT_AUDIO_SINK@") {
                                                    root.audio.toggleDeviceSinkMute(sinkCard.modelData.name)
                                                } else {
                                                    root.audio.toggleSinkMute()
                                                }
                                            }
                                        }
                                    }

                                    // Device Name + Driver/State Subtitle
                                    Column {
                                        anchors.left: sinkMuteBtn.right
                                        anchors.leftMargin: 8
                                        anchors.right: sinkDefaultBtn.left
                                        anchors.rightMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1

                                        Text {
                                            width: parent.width
                                            elide: Text.ElideRight
                                            text: sinkCard.modelData.description || sinkCard.modelData.name
                                            color: root.fg
                                            font.pixelSize: FloatingPanelsStyle.pavuCardTitleFontPx
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            width: parent.width
                                            elide: Text.ElideRight
                                            text: (sinkCard.modelData.driver || "PipeWire")
                                                  + (sinkCard.modelData.api ? (" · " + sinkCard.modelData.api) : "")
                                                  + " · " + (sinkCard.modelData.state || "IDLE")
                                                  + (sinkCard.modelData.db ? (" · " + sinkCard.modelData.db) : "")
                                            color: root.dim
                                            font.pixelSize: FloatingPanelsStyle.pavuCardSubFontPx
                                        }
                                    }

                                    // Default Option Toggle Button
                                    Rectangle {
                                        id: sinkDefaultBtn
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: sinkDefaultRow.width + 14
                                        height: FloatingPanelsStyle.pavuPillHeight
                                        radius: FloatingPanelsStyle.pavuPillRadius
                                        color: sinkCard.modelData.is_default ? root.accent : (sinkDefMouse.containsMouse ? FloatingPanelsStyle.buttonHoverBg : FloatingPanelsStyle.buttonBg)
                                        border.width: 1
                                        border.color: sinkCard.modelData.is_default ? root.accent : FloatingPanelsStyle.buttonBorder

                                        Row {
                                            id: sinkDefaultRow
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: sinkCard.modelData.is_default ? "󰄬" : "󰄱"
                                                font.family: FloatingPanelsStyle.iconFont
                                                font.pixelSize: 11
                                                color: sinkCard.modelData.is_default ? FloatingPanelsStyle.textOnAccent : root.dim
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: sinkCard.modelData.is_default ? "Default" : "Set Default"
                                                font.pixelSize: FloatingPanelsStyle.pavuPillFontPx
                                                font.weight: sinkCard.modelData.is_default ? Font.Bold : Font.Medium
                                                color: sinkCard.modelData.is_default ? FloatingPanelsStyle.textOnAccent : root.fg
                                            }
                                        }

                                        MouseArea {
                                            id: sinkDefMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (root.audio && typeof root.audio.setDefaultSink === "function") {
                                                    root.audio.setDefaultSink(sinkCard.modelData.name)
                                                }
                                            }
                                        }
                                    }
                                }

                                // Volume Slider (0% .. 150%) + Percentage Label
                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Item {
                                        id: devSinkSlider
                                        width: parent.width - sinkPctText.width - 8
                                        height: FloatingPanelsStyle.sliderTrackHeight
                                        anchors.verticalCenter: parent.verticalCenter

                                        readonly property real maxVol: (root.audio && root.audio.maxVolume > 0) ? root.audio.maxVolume : 1.5
                                        readonly property real normRatio: Math.max(0.0, Math.min(1.0, (sinkCard.modelData.volume || 0) / maxVol))

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            height: FloatingPanelsStyle.sliderBarHeight
                                            radius: FloatingPanelsStyle.sliderBarRadius
                                            color: FloatingPanelsStyle.sliderTrackBg

                                            // 100% reference tick mark
                                            Rectangle {
                                                x: parent.width * (1.0 / devSinkSlider.maxVol)
                                                width: 1
                                                height: parent.height + 4
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: root.dim
                                                opacity: 0.6
                                            }

                                            Rectangle {
                                                anchors.left: parent.left
                                                anchors.top: parent.top
                                                anchors.bottom: parent.bottom
                                                width: parent.width * devSinkSlider.normRatio
                                                radius: FloatingPanelsStyle.sliderBarRadius
                                                color: sinkCard.modelData.mute ? root.dim : root.accent
                                            }
                                        }

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: Math.max(0, Math.min(devSinkSlider.width - width, devSinkSlider.width * devSinkSlider.normRatio - width / 2))
                                            width: FloatingPanelsStyle.sliderThumbSize
                                            height: FloatingPanelsStyle.sliderThumbSize
                                            radius: FloatingPanelsStyle.sliderThumbRadius
                                            color: sinkCard.modelData.mute ? root.dim : root.fg
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            function applyAt(mx) {
                                                if (!root.audio) return
                                                var val = Math.max(0.0, Math.min(devSinkSlider.maxVol, (mx / devSinkSlider.width) * devSinkSlider.maxVol))
                                                if (typeof root.audio.setDeviceSinkVolume === "function" && sinkCard.modelData.name !== "@DEFAULT_AUDIO_SINK@") {
                                                    root.audio.setDeviceSinkVolume(sinkCard.modelData.name, val)
                                                } else {
                                                    root.audio.setSinkVolume(val)
                                                }
                                            }
                                            onPressed: function(m) { applyAt(m.x) }
                                            onPositionChanged: function(m) { if (pressed) applyAt(m.x) }
                                            onWheel: function(w) {
                                                if (!root.audio) return
                                                var step = root.audio.wheelStep > 0 ? root.audio.wheelStep : 0.03
                                                var nextV = (sinkCard.modelData.volume || 0) + (w.angleDelta.y > 0 ? step : -step)
                                                if (typeof root.audio.setDeviceSinkVolume === "function" && sinkCard.modelData.name !== "@DEFAULT_AUDIO_SINK@") {
                                                    root.audio.setDeviceSinkVolume(sinkCard.modelData.name, nextV)
                                                } else {
                                                    root.audio.setSinkVolume(nextV)
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        id: sinkPctText
                                        width: 42
                                        anchors.verticalCenter: parent.verticalCenter
                                        horizontalAlignment: Text.AlignRight
                                        text: (sinkCard.modelData.volume_pct !== undefined ? sinkCard.modelData.volume_pct : Math.round((sinkCard.modelData.volume || 0) * 100)) + "%"
                                        color: sinkCard.modelData.mute ? root.danger : root.fg
                                        font.pixelSize: FloatingPanelsStyle.audioLabelFontPx
                                        font.weight: Font.DemiBold
                                    }
                                }

                                // Port Selector Row (when device has selectable ports like Speakers / Headphones)
                                Flow {
                                    width: parent.width
                                    spacing: 6
                                    visible: Array.isArray(sinkCard.modelData.ports) && sinkCard.modelData.ports.length > 0

                                    Text {
                                        text: "Port:"
                                        color: root.dim
                                        font.pixelSize: FloatingPanelsStyle.pavuPillFontPx
                                        height: FloatingPanelsStyle.pavuPillHeight
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Repeater {
                                        model: sinkCard.modelData.ports || []

                                        Rectangle {
                                            id: sinkPortPill
                                            required property var modelData
                                            readonly property bool isPortActive: sinkCard.modelData.active_port === modelData.name
                                            width: sinkPortText.implicitWidth + 14
                                            height: FloatingPanelsStyle.pavuPillHeight
                                            radius: FloatingPanelsStyle.pavuPillRadius
                                            color: isPortActive ? FloatingPanelsStyle.activeBadgeBg : (sinkPortMouse.containsMouse ? FloatingPanelsStyle.buttonHoverBg : FloatingPanelsStyle.buttonBg)
                                            border.width: 1
                                            border.color: isPortActive ? root.accent : FloatingPanelsStyle.buttonBorder

                                            Text {
                                                id: sinkPortText
                                                anchors.centerIn: parent
                                                text: sinkPortPill.modelData.description
                                                      + (sinkPortPill.modelData.available === "not available" ? " (unplugged)" : "")
                                                color: sinkPortPill.isPortActive ? root.accent : root.fg
                                                font.pixelSize: FloatingPanelsStyle.pavuPillFontPx
                                                font.weight: sinkPortPill.isPortActive ? Font.DemiBold : Font.Normal
                                            }

                                            MouseArea {
                                                id: sinkPortMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (root.audio && typeof root.audio.setSinkPort === "function") {
                                                        root.audio.setSinkPort(sinkCard.modelData.name, sinkPortPill.modelData.name)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ────────────────────────────────────────────────────────────
                // TAB 1: INPUT DEVICES (Sources, Filter Monitors, Default, Ports)
                // ────────────────────────────────────────────────────────────
                Column {
                    visible: root.activeTab === 1
                    width: parent.width
                    spacing: 8

                    // Filter Bar (All Except Monitors | All Input Devices | Monitors)
                    Row {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: [
                                { key: "non-monitors", label: "Hardware Inputs" },
                                { key: "all", label: "All Input Devices" },
                                { key: "monitors", label: "Monitors Only" }
                            ]

                            Rectangle {
                                id: inFilterBtn
                                required property var modelData
                                readonly property bool isSel: root.inputFilter === modelData.key
                                width: (tabContentCol.width - 12) / 3
                                height: FloatingPanelsStyle.pavuPillHeight
                                radius: FloatingPanelsStyle.pavuPillRadius
                                color: isSel ? FloatingPanelsStyle.activeBadgeBg : (inFilterMouse.containsMouse ? FloatingPanelsStyle.buttonHoverBg : FloatingPanelsStyle.buttonBg)
                                border.width: 1
                                border.color: isSel ? root.accent : FloatingPanelsStyle.buttonBorder

                                Text {
                                    anchors.centerIn: parent
                                    text: inFilterBtn.modelData.label
                                    color: inFilterBtn.isSel ? root.accent : root.dim
                                    font.pixelSize: FloatingPanelsStyle.pavuPillFontPx
                                    font.weight: inFilterBtn.isSel ? Font.DemiBold : Font.Normal
                                }

                                MouseArea {
                                    id: inFilterMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.inputFilter = inFilterBtn.modelData.key
                                }
                            }
                        }
                    }

                    Repeater {
                        model: root.sourcesList

                        Rectangle {
                            id: srcCard
                            required property var modelData
                            width: tabContentCol.width
                            height: srcInnerCol.height + 16
                            radius: FloatingPanelsStyle.cardRadius
                            color: FloatingPanelsStyle.cardBg
                            border.width: 1
                            border.color: modelData.is_default ? root.accent : FloatingPanelsStyle.cardBorder

                            Column {
                                id: srcInnerCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 8
                                spacing: 6

                                // Header: Mute Button + Source Name & Driver + Set Default Button
                                Item {
                                    width: parent.width
                                    height: 30

                                    Rectangle {
                                        id: srcMuteBtn
                                        width: 28
                                        height: 28
                                        radius: 14
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: srcCard.modelData.mute ? FloatingPanelsStyle.mutedTint : (srcMuteMouse.containsMouse ? FloatingPanelsStyle.itemHoverBg : FloatingPanelsStyle.buttonBg)
                                        border.width: 1
                                        border.color: srcCard.modelData.mute ? root.danger : FloatingPanelsStyle.buttonBorder

                                        Text {
                                            anchors.centerIn: parent
                                            text: srcCard.modelData.mute ? "󰍭" : "󰍬"
                                            font.family: FloatingPanelsStyle.iconFont
                                            font.pixelSize: 14
                                            color: srcCard.modelData.mute ? root.danger : root.accent
                                        }

                                        MouseArea {
                                            id: srcMuteMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (!root.audio) return
                                                if (typeof root.audio.toggleDeviceSourceMute === "function" && srcCard.modelData.name !== "@DEFAULT_AUDIO_SOURCE@") {
                                                    root.audio.toggleDeviceSourceMute(srcCard.modelData.name)
                                                } else {
                                                    root.audio.toggleSourceMute()
                                                }
                                            }
                                        }
                                    }

                                    Column {
                                        anchors.left: srcMuteBtn.right
                                        anchors.leftMargin: 8
                                        anchors.right: srcDefaultBtn.left
                                        anchors.rightMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1

                                        Text {
                                            width: parent.width
                                            elide: Text.ElideRight
                                            text: srcCard.modelData.description || srcCard.modelData.name
                                            color: root.fg
                                            font.pixelSize: FloatingPanelsStyle.pavuCardTitleFontPx
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            width: parent.width
                                            elide: Text.ElideRight
                                            text: (srcCard.modelData.driver || "PipeWire")
                                                  + (srcCard.modelData.api ? (" · " + srcCard.modelData.api) : "")
                                                  + " · " + (srcCard.modelData.state || "IDLE")
                                                  + (srcCard.modelData.db ? (" · " + srcCard.modelData.db) : "")
                                            color: root.dim
                                            font.pixelSize: FloatingPanelsStyle.pavuCardSubFontPx
                                        }
                                    }

                                    Rectangle {
                                        id: srcDefaultBtn
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: srcDefaultRow.width + 14
                                        height: FloatingPanelsStyle.pavuPillHeight
                                        radius: FloatingPanelsStyle.pavuPillRadius
                                        color: srcCard.modelData.is_default ? root.accent : (srcDefMouse.containsMouse ? FloatingPanelsStyle.buttonHoverBg : FloatingPanelsStyle.buttonBg)
                                        border.width: 1
                                        border.color: srcCard.modelData.is_default ? root.accent : FloatingPanelsStyle.buttonBorder

                                        Row {
                                            id: srcDefaultRow
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: srcCard.modelData.is_default ? "󰄬" : "󰄱"
                                                font.family: FloatingPanelsStyle.iconFont
                                                font.pixelSize: 11
                                                color: srcCard.modelData.is_default ? FloatingPanelsStyle.textOnAccent : root.dim
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: srcCard.modelData.is_default ? "Default" : "Set Default"
                                                font.pixelSize: FloatingPanelsStyle.pavuPillFontPx
                                                font.weight: srcCard.modelData.is_default ? Font.Bold : Font.Medium
                                                color: srcCard.modelData.is_default ? FloatingPanelsStyle.textOnAccent : root.fg
                                            }
                                        }

                                        MouseArea {
                                            id: srcDefMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (root.audio && typeof root.audio.setDefaultSource === "function") {
                                                    root.audio.setDefaultSource(srcCard.modelData.name)
                                                }
                                            }
                                        }
                                    }
                                }

                                // Volume Slider
                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Item {
                                        id: devSrcSlider
                                        width: parent.width - srcPctText.width - 8
                                        height: 20
                                        anchors.verticalCenter: parent.verticalCenter

                                        readonly property real maxVol: (root.audio && root.audio.maxVolume > 0) ? root.audio.maxVolume : 1.5
                                        readonly property real normRatio: Math.max(0.0, Math.min(1.0, (srcCard.modelData.volume || 0) / maxVol))

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            height: FloatingPanelsStyle.sliderBarHeight
                                            radius: FloatingPanelsStyle.sliderBarRadius
                                            color: FloatingPanelsStyle.sliderTrackBg

                                            Rectangle {
                                                x: parent.width * (1.0 / devSrcSlider.maxVol)
                                                width: 1
                                                height: parent.height + 4
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: root.dim
                                                opacity: 0.6
                                            }

                                            Rectangle {
                                                anchors.left: parent.left
                                                anchors.top: parent.top
                                                anchors.bottom: parent.bottom
                                                width: parent.width * devSrcSlider.normRatio
                                                radius: FloatingPanelsStyle.sliderBarRadius
                                                color: srcCard.modelData.mute ? root.dim : root.accent
                                            }
                                        }

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: Math.max(0, Math.min(devSrcSlider.width - width, devSrcSlider.width * devSrcSlider.normRatio - width / 2))
                                            width: FloatingPanelsStyle.sliderThumbSize
                                            height: FloatingPanelsStyle.sliderThumbSize
                                            radius: FloatingPanelsStyle.sliderThumbRadius
                                            color: srcCard.modelData.mute ? root.dim : root.fg
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            function applyAt(mx) {
                                                if (!root.audio) return
                                                var val = Math.max(0.0, Math.min(devSrcSlider.maxVol, (mx / devSrcSlider.width) * devSrcSlider.maxVol))
                                                if (typeof root.audio.setDeviceSourceVolume === "function" && srcCard.modelData.name !== "@DEFAULT_AUDIO_SOURCE@") {
                                                    root.audio.setDeviceSourceVolume(srcCard.modelData.name, val)
                                                } else {
                                                    root.audio.setSourceVolume(val)
                                                }
                                            }
                                            onPressed: function(m) { applyAt(m.x) }
                                            onPositionChanged: function(m) { if (pressed) applyAt(m.x) }
                                            onWheel: function(w) {
                                                if (!root.audio) return
                                                var step = root.audio.wheelStep > 0 ? root.audio.wheelStep : 0.03
                                                var nextV = (srcCard.modelData.volume || 0) + (w.angleDelta.y > 0 ? step : -step)
                                                if (typeof root.audio.setDeviceSourceVolume === "function" && srcCard.modelData.name !== "@DEFAULT_AUDIO_SOURCE@") {
                                                    root.audio.setDeviceSourceVolume(srcCard.modelData.name, nextV)
                                                } else {
                                                    root.audio.setSourceVolume(nextV)
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        id: srcPctText
                                        width: 42
                                        anchors.verticalCenter: parent.verticalCenter
                                        horizontalAlignment: Text.AlignRight
                                        text: (srcCard.modelData.volume_pct !== undefined ? srcCard.modelData.volume_pct : Math.round((srcCard.modelData.volume || 0) * 100)) + "%"
                                        color: srcCard.modelData.mute ? root.danger : root.fg
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                }

                                // Port Selector Row
                                Flow {
                                    width: parent.width
                                    spacing: 6
                                    visible: Array.isArray(srcCard.modelData.ports) && srcCard.modelData.ports.length > 0

                                    Text {
                                        text: "Port:"
                                        color: root.dim
                                        font.pixelSize: FloatingPanelsStyle.pavuPillFontPx
                                        height: FloatingPanelsStyle.pavuPillHeight
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Repeater {
                                        model: srcCard.modelData.ports || []

                                        Rectangle {
                                            id: srcPortPill
                                            required property var modelData
                                            readonly property bool isPortActive: srcCard.modelData.active_port === modelData.name
                                            width: srcPortText.implicitWidth + 14
                                            height: FloatingPanelsStyle.pavuPillHeight
                                            radius: FloatingPanelsStyle.pavuPillRadius
                                            color: isPortActive ? FloatingPanelsStyle.activeBadgeBg : (srcPortMouse.containsMouse ? FloatingPanelsStyle.buttonHoverBg : FloatingPanelsStyle.buttonBg)
                                            border.width: 1
                                            border.color: isPortActive ? root.accent : FloatingPanelsStyle.buttonBorder

                                            Text {
                                                id: srcPortText
                                                anchors.centerIn: parent
                                                text: srcPortPill.modelData.description
                                                      + (srcPortPill.modelData.available === "not available" ? " (unplugged)" : "")
                                                color: srcPortPill.isPortActive ? root.accent : root.fg
                                                font.pixelSize: FloatingPanelsStyle.pavuPillFontPx
                                                font.weight: srcPortPill.isPortActive ? Font.DemiBold : Font.Normal
                                            }

                                            MouseArea {
                                                id: srcPortMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (root.audio && typeof root.audio.setSourcePort === "function") {
                                                        root.audio.setSourcePort(srcCard.modelData.name, srcPortPill.modelData.name)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.sourcesList.length === 0
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 20
                        text: "No matching input devices"
                        color: root.dim
                        font.pixelSize: 12
                    }
                }

                // ────────────────────────────────────────────────────────────
                // TAB 2: PLAYBACK STREAMS (Per-Application Volume & Sink Routing)
                // ────────────────────────────────────────────────────────────
                Column {
                    visible: root.activeTab === 2
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: root.sinkInputsList

                        Rectangle {
                            id: siCard
                            required property var modelData
                            width: tabContentCol.width
                            height: siInnerCol.height + 16
                            radius: FloatingPanelsStyle.cardRadius
                            color: FloatingPanelsStyle.cardBg
                            border.width: 1
                            border.color: FloatingPanelsStyle.cardBorder

                            Column {
                                id: siInnerCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 8
                                spacing: 6

                                // Stream Header
                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Rectangle {
                                        width: 28
                                        height: 28
                                        radius: 14
                                        color: siCard.modelData.mute ? FloatingPanelsStyle.mutedTint : (siMuteMouse.containsMouse ? FloatingPanelsStyle.itemHoverBg : FloatingPanelsStyle.buttonBg)
                                        border.width: 1
                                        border.color: siCard.modelData.mute ? root.danger : FloatingPanelsStyle.buttonBorder

                                        Text {
                                            anchors.centerIn: parent
                                            text: siCard.modelData.mute ? "󰝟" : "󰎈"
                                            font.family: FloatingPanelsStyle.iconFont
                                            font.pixelSize: 13
                                            color: siCard.modelData.mute ? root.danger : root.accent
                                        }

                                        MouseArea {
                                            id: siMuteMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (root.audio && typeof root.audio.toggleSinkInputMute === "function") {
                                                    root.audio.toggleSinkInputMute(siCard.modelData.index)
                                                }
                                            }
                                        }
                                    }

                                    Column {
                                        width: parent.width - 36
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1

                                        Text {
                                            width: parent.width
                                            elide: Text.ElideRight
                                            text: siCard.modelData.app_name
                                                  + (siCard.modelData.media_name ? (" — " + siCard.modelData.media_name) : "")
                                            color: root.fg
                                            font.pixelSize: FloatingPanelsStyle.pavuCardTitleFontPx
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            width: parent.width
                                            elide: Text.ElideRight
                                            text: "on " + (siCard.modelData.sink_description || "Output")
                                                  + (siCard.modelData.db ? (" · " + siCard.modelData.db) : "")
                                            color: root.dim
                                            font.pixelSize: FloatingPanelsStyle.pavuCardSubFontPx
                                        }
                                    }
                                }

                                // Stream Volume Slider
                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Item {
                                        id: siSlider
                                        width: parent.width - siPctText.width - 8
                                        height: 20
                                        anchors.verticalCenter: parent.verticalCenter

                                        readonly property real maxVol: (root.audio && root.audio.maxVolume > 0) ? root.audio.maxVolume : 1.5
                                        readonly property real normRatio: Math.max(0.0, Math.min(1.0, (siCard.modelData.volume || 0) / maxVol))

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            height: FloatingPanelsStyle.sliderBarHeight
                                            radius: FloatingPanelsStyle.sliderBarRadius
                                            color: FloatingPanelsStyle.sliderTrackBg

                                            Rectangle {
                                                x: parent.width * (1.0 / siSlider.maxVol)
                                                width: 1
                                                height: parent.height + 4
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: root.dim
                                                opacity: 0.6
                                            }

                                            Rectangle {
                                                anchors.left: parent.left
                                                anchors.top: parent.top
                                                anchors.bottom: parent.bottom
                                                width: parent.width * siSlider.normRatio
                                                radius: FloatingPanelsStyle.sliderBarRadius
                                                color: siCard.modelData.mute ? root.dim : root.accent
                                            }
                                        }

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: Math.max(0, Math.min(siSlider.width - width, siSlider.width * siSlider.normRatio - width / 2))
                                            width: FloatingPanelsStyle.sliderThumbSize
                                            height: FloatingPanelsStyle.sliderThumbSize
                                            radius: FloatingPanelsStyle.sliderThumbRadius
                                            color: siCard.modelData.mute ? root.dim : root.fg
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            function applyAt(mx) {
                                                if (root.audio && typeof root.audio.setSinkInputVolume === "function") {
                                                    var val = Math.max(0.0, Math.min(siSlider.maxVol, (mx / siSlider.width) * siSlider.maxVol))
                                                    root.audio.setSinkInputVolume(siCard.modelData.index, val)
                                                }
                                            }
                                            onPressed: function(m) { applyAt(m.x) }
                                            onPositionChanged: function(m) { if (pressed) applyAt(m.x) }
                                        }
                                    }

                                    Text {
                                        id: siPctText
                                        width: 42
                                        anchors.verticalCenter: parent.verticalCenter
                                        horizontalAlignment: Text.AlignRight
                                        text: (siCard.modelData.volume_pct !== undefined ? siCard.modelData.volume_pct : Math.round((siCard.modelData.volume || 0) * 100)) + "%"
                                        color: siCard.modelData.mute ? root.danger : root.fg
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                }

                                // Output Device Routing Selector
                                Flow {
                                    width: parent.width
                                    spacing: 6
                                    visible: root.sinksList.length > 0

                                    Text {
                                        text: "Output:"
                                        color: root.dim
                                        font.pixelSize: FloatingPanelsStyle.pavuPillFontPx
                                        height: FloatingPanelsStyle.pavuPillHeight
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Repeater {
                                        model: root.sinksList

                                        Rectangle {
                                            id: routeSinkPill
                                            required property var modelData
                                            readonly property bool isTarget: siCard.modelData.sink === modelData.index || siCard.modelData.sink_name === modelData.name
                                            width: routeSinkLabel.implicitWidth + 14
                                            height: FloatingPanelsStyle.pavuPillHeight
                                            radius: FloatingPanelsStyle.pavuPillRadius
                                            color: isTarget ? FloatingPanelsStyle.activeBadgeBg : (routeSinkMouse.containsMouse ? FloatingPanelsStyle.buttonHoverBg : FloatingPanelsStyle.buttonBg)
                                            border.width: 1
                                            border.color: isTarget ? root.accent : FloatingPanelsStyle.buttonBorder

                                            Text {
                                                id: routeSinkLabel
                                                anchors.centerIn: parent
                                                text: routeSinkPill.modelData.description || routeSinkPill.modelData.name
                                                color: routeSinkPill.isTarget ? root.accent : root.fg
                                                font.pixelSize: FloatingPanelsStyle.pavuPillFontPx
                                                font.weight: routeSinkPill.isTarget ? Font.DemiBold : Font.Normal
                                            }

                                            MouseArea {
                                                id: routeSinkMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (root.audio && typeof root.audio.moveSinkInput === "function") {
                                                        root.audio.moveSinkInput(siCard.modelData.index, routeSinkPill.modelData.name)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.sinkInputsList.length === 0
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 24
                        text: "No applications are currently playing audio"
                        color: root.dim
                        font.pixelSize: 12
                    }
                }

                // ────────────────────────────────────────────────────────────
                // TAB 3: RECORDING STREAMS (Per-Application Capture & Source Routing)
                // ────────────────────────────────────────────────────────────
                Column {
                    visible: root.activeTab === 3
                    width: parent.width
                    spacing: 8

                    // Filter Bar (Applications | All Streams)
                    Row {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: [
                                { key: "apps", label: "Applications" },
                                { key: "all", label: "All Streams (incl. Monitors)" }
                            ]

                            Rectangle {
                                id: recFilterBtn
                                required property var modelData
                                readonly property bool isSel: root.recordingFilter === modelData.key
                                width: (tabContentCol.width - 6) / 2
                                height: FloatingPanelsStyle.pavuPillHeight
                                radius: FloatingPanelsStyle.pavuPillRadius
                                color: isSel ? FloatingPanelsStyle.activeBadgeBg : (recFilterMouse.containsMouse ? FloatingPanelsStyle.buttonHoverBg : FloatingPanelsStyle.buttonBg)
                                border.width: 1
                                border.color: isSel ? root.accent : FloatingPanelsStyle.buttonBorder

                                Text {
                                    anchors.centerIn: parent
                                    text: recFilterBtn.modelData.label
                                    color: recFilterBtn.isSel ? root.accent : root.dim
                                    font.pixelSize: FloatingPanelsStyle.pavuPillFontPx
                                    font.weight: recFilterBtn.isSel ? Font.DemiBold : Font.Normal
                                }

                                MouseArea {
                                    id: recFilterMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.recordingFilter = recFilterBtn.modelData.key
                                }
                            }
                        }
                    }

                    Repeater {
                        model: root.sourceOutputsList

                        Rectangle {
                            id: soCard
                            required property var modelData
                            width: tabContentCol.width
                            height: soInnerCol.height + 16
                            radius: FloatingPanelsStyle.cardRadius
                            color: FloatingPanelsStyle.cardBg
                            border.width: 1
                            border.color: FloatingPanelsStyle.cardBorder

                            Column {
                                id: soInnerCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 8
                                spacing: 6

                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Rectangle {
                                        width: 28
                                        height: 28
                                        radius: 14
                                        color: soCard.modelData.mute ? FloatingPanelsStyle.mutedTint : (soMuteMouse.containsMouse ? FloatingPanelsStyle.itemHoverBg : FloatingPanelsStyle.buttonBg)
                                        border.width: 1
                                        border.color: soCard.modelData.mute ? root.danger : FloatingPanelsStyle.buttonBorder

                                        Text {
                                            anchors.centerIn: parent
                                            text: soCard.modelData.mute ? "󰍭" : "󰑊"
                                            font.family: FloatingPanelsStyle.iconFont
                                            font.pixelSize: 13
                                            color: soCard.modelData.mute ? root.danger : root.accent
                                        }

                                        MouseArea {
                                            id: soMuteMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (root.audio && typeof root.audio.toggleSourceOutputMute === "function") {
                                                    root.audio.toggleSourceOutputMute(soCard.modelData.index)
                                                }
                                            }
                                        }
                                    }

                                    Column {
                                        width: parent.width - 36
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1

                                        Text {
                                            width: parent.width
                                            elide: Text.ElideRight
                                            text: soCard.modelData.app_name
                                                  + (soCard.modelData.media_name ? (" — " + soCard.modelData.media_name) : "")
                                            color: root.fg
                                            font.pixelSize: FloatingPanelsStyle.pavuCardTitleFontPx
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            width: parent.width
                                            elide: Text.ElideRight
                                            text: "from " + (soCard.modelData.source_description || "Input")
                                                  + (soCard.modelData.db ? (" · " + soCard.modelData.db) : "")
                                            color: root.dim
                                            font.pixelSize: FloatingPanelsStyle.pavuCardSubFontPx
                                        }
                                    }
                                }

                                // Recording Stream Volume Slider
                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Item {
                                        id: soSlider
                                        width: parent.width - soPctText.width - 8
                                        height: 20
                                        anchors.verticalCenter: parent.verticalCenter

                                        readonly property real maxVol: (root.audio && root.audio.maxVolume > 0) ? root.audio.maxVolume : 1.5
                                        readonly property real normRatio: Math.max(0.0, Math.min(1.0, (soCard.modelData.volume || 0) / maxVol))

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            height: FloatingPanelsStyle.sliderBarHeight
                                            radius: FloatingPanelsStyle.sliderBarRadius
                                            color: FloatingPanelsStyle.sliderTrackBg

                                            Rectangle {
                                                x: parent.width * (1.0 / soSlider.maxVol)
                                                width: 1
                                                height: parent.height + 4
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: root.dim
                                                opacity: 0.6
                                            }

                                            Rectangle {
                                                anchors.left: parent.left
                                                anchors.top: parent.top
                                                anchors.bottom: parent.bottom
                                                width: parent.width * soSlider.normRatio
                                                radius: FloatingPanelsStyle.sliderBarRadius
                                                color: soCard.modelData.mute ? root.dim : root.accent
                                            }
                                        }

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: Math.max(0, Math.min(soSlider.width - width, soSlider.width * soSlider.normRatio - width / 2))
                                            width: FloatingPanelsStyle.sliderThumbSize
                                            height: FloatingPanelsStyle.sliderThumbSize
                                            radius: FloatingPanelsStyle.sliderThumbRadius
                                            color: soCard.modelData.mute ? root.dim : root.fg
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            function applyAt(mx) {
                                                if (root.audio && typeof root.audio.setSourceOutputVolume === "function") {
                                                    var val = Math.max(0.0, Math.min(soSlider.maxVol, (mx / soSlider.width) * soSlider.maxVol))
                                                    root.audio.setSourceOutputVolume(soCard.modelData.index, val)
                                                }
                                            }
                                            onPressed: function(m) { applyAt(m.x) }
                                            onPositionChanged: function(m) { if (pressed) applyAt(m.x) }
                                        }
                                    }

                                    Text {
                                        id: soPctText
                                        width: 42
                                        anchors.verticalCenter: parent.verticalCenter
                                        horizontalAlignment: Text.AlignRight
                                        text: (soCard.modelData.volume_pct !== undefined ? soCard.modelData.volume_pct : Math.round((soCard.modelData.volume || 0) * 100)) + "%"
                                        color: soCard.modelData.mute ? root.danger : root.fg
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                }

                                // Input Source Routing Selector
                                Flow {
                                    width: parent.width
                                    spacing: 6
                                    visible: root.sourcesList.length > 0

                                    Text {
                                        text: "Input:"
                                        color: root.dim
                                        font.pixelSize: FloatingPanelsStyle.pavuPillFontPx
                                        height: FloatingPanelsStyle.pavuPillHeight
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Repeater {
                                        model: root.sourcesList

                                        Rectangle {
                                            id: routeSrcPill
                                            required property var modelData
                                            readonly property bool isTarget: soCard.modelData.source === modelData.index || soCard.modelData.source_name === modelData.name
                                            width: routeSrcLabel.implicitWidth + 14
                                            height: FloatingPanelsStyle.pavuPillHeight
                                            radius: FloatingPanelsStyle.pavuPillRadius
                                            color: isTarget ? FloatingPanelsStyle.activeBadgeBg : (routeSrcMouse.containsMouse ? FloatingPanelsStyle.buttonHoverBg : FloatingPanelsStyle.buttonBg)
                                            border.width: 1
                                            border.color: isTarget ? root.accent : FloatingPanelsStyle.buttonBorder

                                            Text {
                                                id: routeSrcLabel
                                                anchors.centerIn: parent
                                                text: routeSrcPill.modelData.description || routeSrcPill.modelData.name
                                                color: routeSrcPill.isTarget ? root.accent : root.fg
                                                font.pixelSize: FloatingPanelsStyle.pavuPillFontPx
                                                font.weight: routeSrcPill.isTarget ? Font.DemiBold : Font.Normal
                                            }

                                            MouseArea {
                                                id: routeSrcMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (root.audio && typeof root.audio.moveSourceOutput === "function") {
                                                        root.audio.moveSourceOutput(soCard.modelData.index, routeSrcPill.modelData.name)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.sourceOutputsList.length === 0
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 24
                        text: "No applications are currently recording audio"
                        color: root.dim
                        font.pixelSize: 12
                    }
                }

                // ────────────────────────────────────────────────────────────
                // TAB 4: CONFIGURATION / DRIVERS (Cards & Hardware Profiles)
                // ────────────────────────────────────────────────────────────
                Column {
                    visible: root.activeTab === 4
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: root.cardsList

                        Rectangle {
                            id: cardItem
                            required property var modelData
                            readonly property bool isExpanded: root.isCardExpanded(cardItem.modelData ? cardItem.modelData.name : "")
                            width: tabContentCol.width
                            height: cardInnerCol.height + 16
                            radius: FloatingPanelsStyle.cardRadius
                            color: FloatingPanelsStyle.cardBg
                            border.width: 1
                            border.color: cardItem.isExpanded ? root.accent : (cardHeaderMouse.containsMouse ? FloatingPanelsStyle.buttonBorder : FloatingPanelsStyle.cardBorder)

                            Column {
                                id: cardInnerCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 8
                                spacing: 6

                                // Clickable Card Header (Title + Driver Metadata + Top-Right Dropdown Arrow + Active Profile)
                                Item {
                                    id: cardHeaderArea
                                    width: parent.width
                                    height: cardHeaderCol.height

                                    Column {
                                        id: cardHeaderCol
                                        width: parent.width
                                        spacing: 6

                                        Row {
                                            width: parent.width
                                            spacing: 8

                                            Rectangle {
                                                width: 28
                                                height: 28
                                                radius: 14
                                                color: FloatingPanelsStyle.buttonBg
                                                border.width: 1
                                                border.color: FloatingPanelsStyle.buttonBorder

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󰒓"
                                                    font.family: FloatingPanelsStyle.iconFont
                                                    font.pixelSize: 14
                                                    color: root.accent
                                                }
                                            }

                                            Column {
                                                width: parent.width - 68
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 1

                                                Text {
                                                    width: parent.width
                                                    elide: Text.ElideRight
                                                    text: cardItem.modelData.description || cardItem.modelData.name
                                                    color: root.fg
                                                    font.pixelSize: FloatingPanelsStyle.pavuCardTitleFontPx
                                                    font.weight: Font.DemiBold
                                                }

                                                Text {
                                                    width: parent.width
                                                    elide: Text.ElideRight
                                                    text: "driver: " + (cardItem.modelData.driver || "alsa")
                                                          + (cardItem.modelData.api ? (" · api: " + cardItem.modelData.api) : "")
                                                          + (cardItem.modelData.bus ? (" · bus: " + cardItem.modelData.bus) : "")
                                                          + (cardItem.modelData.product_name ? (" · " + cardItem.modelData.product_name) : "")
                                                    color: root.dim
                                                    font.pixelSize: FloatingPanelsStyle.pavuCardSubFontPx
                                                }
                                            }

                                            // Top-right Dropdown Arrow Indicator
                                            Rectangle {
                                                width: 24
                                                height: 24
                                                radius: 6
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: cardItem.isExpanded ? FloatingPanelsStyle.activeBadgeBg : (cardHeaderMouse.containsMouse ? FloatingPanelsStyle.buttonHoverBg : FloatingPanelsStyle.buttonBg)
                                                border.width: 1
                                                border.color: cardItem.isExpanded ? root.accent : FloatingPanelsStyle.buttonBorder

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: cardItem.isExpanded ? "󰅃" : "󰅀"
                                                    font.family: FloatingPanelsStyle.iconFont
                                                    font.pixelSize: 13
                                                    color: cardItem.isExpanded ? root.accent : (cardHeaderMouse.containsMouse ? root.fg : root.dim)
                                                }
                                            }
                                        }

                                        Text {
                                            width: parent.width
                                            elide: Text.ElideRight
                                            text: "Active Profile: " + (cardItem.modelData.active_profile_description || cardItem.modelData.active_profile || "None")
                                            color: root.accent
                                            font.pixelSize: FloatingPanelsStyle.pavuPillFontPx
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    MouseArea {
                                        id: cardHeaderMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (cardItem.modelData && cardItem.modelData.name) {
                                                root.toggleCardExpanded(cardItem.modelData.name)
                                            }
                                        }
                                    }
                                }

                                // Selectable Profiles List (only shown when this hardware card is expanded)
                                Column {
                                    visible: cardItem.isExpanded
                                    width: parent.width
                                    spacing: 4

                                    Repeater {
                                        model: cardItem.modelData.profiles || []

                                        Rectangle {
                                            id: profRow
                                            required property var modelData
                                            readonly property bool isActiveProf: cardItem.modelData.active_profile === modelData.name
                                            width: parent.width
                                            height: 24
                                            radius: FloatingPanelsStyle.pavuPillRadius
                                            color: isActiveProf ? FloatingPanelsStyle.activeBadgeBg : (profMouse.containsMouse ? FloatingPanelsStyle.buttonHoverBg : FloatingPanelsStyle.buttonBg)
                                            border.width: 1
                                            border.color: isActiveProf ? root.accent : FloatingPanelsStyle.buttonBorder
                                            opacity: modelData.available === false ? 0.5 : 1.0

                                            Row {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 8
                                                anchors.right: parent.right
                                                anchors.rightMargin: 8
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 6

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: profRow.isActiveProf ? "󰄬" : "󰄱"
                                                    font.family: FloatingPanelsStyle.iconFont
                                                    font.pixelSize: 11
                                                    color: profRow.isActiveProf ? root.accent : root.dim
                                                }

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: parent.width - 24
                                                    elide: Text.ElideRight
                                                    text: profRow.modelData.description
                                                          + (profRow.modelData.available === false ? " (unavailable)" : "")
                                                    color: profRow.isActiveProf ? root.accent : root.fg
                                                    font.pixelSize: FloatingPanelsStyle.pavuPillFontPx
                                                    font.weight: profRow.isActiveProf ? Font.DemiBold : Font.Normal
                                                }
                                            }

                                            MouseArea {
                                                id: profMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (root.audio && typeof root.audio.setCardProfile === "function") {
                                                        root.audio.setCardProfile(cardItem.modelData.name, profRow.modelData.name)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.cardsList.length === 0
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 24
                        text: "No audio hardware cards detected"
                        color: root.dim
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
