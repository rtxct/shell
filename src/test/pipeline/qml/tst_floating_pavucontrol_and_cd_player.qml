import QtQuick
import QtTest
import "../../../../themes"
import "../../../app/styles"
import "../../../app/components"
import "../../../app/modules"

Item {
    id: root
    width: 1920
    height: 1080

    QtObject {
        id: mockAudio
        property bool isPlaying: false
        property string trackTitle: "Starlight"
        property string trackArtist: "Muse"
        property string trackApp: "Spotify"
        property string trackArtUrl: ""
        property real maxVolume: 1.5
        property real wheelStep: 0.03
        property real sinkVolume: 0.80
        property bool sinkMuted: false
        property real sourceVolume: 0.90
        property bool sourceMuted: false

        property string lastDefaultSink: "alsa_output.pci"
        property string lastDefaultSource: "alsa_input.pci"
        property string lastSinkPort: ""
        property string lastSourcePort: ""
        property string lastMovedSinkInputTarget: ""
        property string lastMovedSourceOutputTarget: ""
        property string lastCardProfile: ""
        property int playToggleCount: 0
        property int prevCount: 0
        property int nextCount: 0

        property var sinks: [
            {
                index: 51,
                name: "alsa_output.pci",
                description: "Built-in Audio Analog Stereo",
                driver: "PipeWire",
                api: "alsa",
                state: "RUNNING",
                mute: false,
                volume: 0.80,
                volume_pct: 80,
                db: "-5.81 dB",
                is_default: true,
                active_port: "analog-output-speaker",
                ports: [
                    { name: "analog-output-speaker", description: "Speakers", available: "available" },
                    { name: "analog-output-headphones", description: "Headphones", available: "not available" }
                ]
            },
            {
                index: 77,
                name: "bluez_output.headset",
                description: "Bluetooth Headphones",
                driver: "PipeWire",
                api: "bluez5",
                state: "IDLE",
                mute: false,
                volume: 0.65,
                volume_pct: 65,
                db: "-11.0 dB",
                is_default: false,
                active_port: "headset-output",
                ports: [
                    { name: "headset-output", description: "Headphones", available: "available" }
                ]
            }
        ]

        property var sources: [
            {
                index: 52,
                name: "alsa_input.pci",
                description: "Built-in Microphone",
                driver: "PipeWire",
                api: "alsa",
                state: "RUNNING",
                mute: false,
                volume: 0.90,
                volume_pct: 90,
                db: "-2.50 dB",
                is_default: true,
                is_monitor: false,
                active_port: "analog-input-internal-mic",
                ports: [
                    { name: "analog-input-internal-mic", description: "Internal Microphone", available: "available" }
                ]
            },
            {
                index: 53,
                name: "alsa_output.pci.monitor",
                description: "Monitor of Built-in Audio",
                driver: "PipeWire",
                api: "alsa",
                state: "IDLE",
                mute: false,
                volume: 1.0,
                volume_pct: 100,
                db: "0.00 dB",
                is_default: false,
                is_monitor: true,
                active_port: "",
                ports: []
            }
        ]

        property var sinkInputs: [
            {
                index: 501,
                app_name: "Spotify",
                media_name: "Starlight",
                sink: 51,
                sink_name: "alsa_output.pci",
                sink_description: "Built-in Audio Analog Stereo",
                driver: "PipeWire",
                corked: false,
                mute: false,
                volume: 0.75,
                volume_pct: 75,
                db: "-7.50 dB"
            }
        ]

        property var sourceOutputs: [
            {
                index: 601,
                app_name: "Discord",
                media_name: "Voice Call",
                source: 52,
                source_name: "alsa_input.pci",
                source_description: "Built-in Microphone",
                driver: "PipeWire",
                corked: false,
                mute: false,
                volume: 1.0,
                volume_pct: 100,
                db: "0.00 dB",
                is_virtual: false
            },
            {
                index: 602,
                app_name: "Quickshell Peak Detect",
                media_name: "Peak detect",
                source: 53,
                source_name: "alsa_output.pci.monitor",
                source_description: "Monitor of Built-in Audio",
                driver: "PipeWire",
                corked: false,
                mute: false,
                volume: 1.0,
                volume_pct: 100,
                db: "0.00 dB",
                is_virtual: true
            }
        ]

        property var cards: [
            {
                index: 44,
                name: "alsa_card.pci-0000_00_1f.3",
                description: "Built-in Audio",
                product_name: "Alder Lake PCH-P High Definition Audio Controller",
                driver: "alsa",
                api: "alsa",
                bus: "pci",
                active_profile: "output:analog-stereo+input:analog-stereo",
                active_profile_description: "Analog Stereo Duplex",
                profiles: [
                    {
                        name: "output:analog-stereo+input:analog-stereo",
                        description: "Analog Stereo Duplex",
                        sinks: 1,
                        sources: 1,
                        priority: 6565,
                        available: true
                    },
                    {
                        name: "output:analog-stereo",
                        description: "Analog Stereo Output",
                        sinks: 1,
                        sources: 0,
                        priority: 6500,
                        available: true
                    },
                    {
                        name: "off",
                        description: "Off",
                        sinks: 0,
                        sources: 0,
                        priority: 0,
                        available: true
                    }
                ]
            }
        ]

        function togglePlay() {
            playToggleCount++
            isPlaying = !isPlaying
        }
        function previous() { prevCount++ }
        function next() { nextCount++ }
        function refreshPavu() {}
        function setDefaultSink(name) { lastDefaultSink = name }
        function setDefaultSource(name) { lastDefaultSource = name }
        function setSinkPort(sink, port) { lastSinkPort = port }
        function setSourcePort(src, port) { lastSourcePort = port }
        function moveSinkInput(idx, targetSink) { lastMovedSinkInputTarget = targetSink }
        function moveSourceOutput(idx, targetSrc) { lastMovedSourceOutputTarget = targetSrc }
        function setCardProfile(card, prof) { lastCardProfile = prof }
    }

    FloatingAudioPanel {
        id: audioPanel
        width: MediaControlBarStyle.floatWidth
        height: MediaControlBarStyle.floatHeight
        audio: mockAudio
    }

    TestCase {
        name: "FloatingPavucontrolAndCdPlayerTests"
        when: windowShown

        function findByObjectName(item, targetName) {
            if (!item) return null
            if (item.objectName === targetName) return item
            var kids = item.children || []
            for (var i = 0; i < kids.length; i++) {
                var found = findByObjectName(kids[i], targetName)
                if (found) return found
            }
            return null
        }

        function test_media_deck_and_cd_question_mark_fallback() {
            compare(audioPanel.trackTitleText, "Starlight")
            compare(audioPanel.trackOriginText, "Spotify · Muse")
            compare(audioPanel.hasArtImage, false, "Without art URL, hasArtImage is false")

            var qMark = findByObjectName(audioPanel, "cdQuestionMark")
            verify(qMark !== null, "Question mark fallback Text exists inside CD button")
            compare(qMark.visible, true, "Question mark is visible when audio has no image")
            compare(qMark.text, "?")
        }

        function test_cd_spins_when_playing_and_stops_when_paused() {
            mockAudio.isPlaying = false
            audioPanel.discRotation = 0
            audioPanel.stepRotation(1.0)
            compare(audioPanel.discRotation, 0, "CD does not spin when audio is paused")

            mockAudio.isPlaying = true
            audioPanel.stepRotation(0.5)
            verify(audioPanel.discRotation > 0, "CD rotates around its own axis when playing")
            var stoppedAngle = audioPanel.discRotation

            mockAudio.isPlaying = false
            audioPanel.stepRotation(1.0)
            compare(audioPanel.discRotation, stoppedAngle, "CD stops spinning in-place when paused")
        }

        function test_pavucontrol_tabs_and_filters() {
            // Output devices
            compare(audioPanel.sinksList.length, 2, "Both output sinks are listed")

            // Input devices filter (default hides monitor sources)
            audioPanel.inputFilter = "non-monitors"
            compare(audioPanel.sourcesList.length, 1, "Hardware inputs filter excludes monitor source")
            audioPanel.inputFilter = "all"
            compare(audioPanel.sourcesList.length, 2, "All inputs filter includes monitor source")
            audioPanel.inputFilter = "monitors"
            compare(audioPanel.sourcesList.length, 1, "Monitors filter shows only monitor source")
            audioPanel.inputFilter = "non-monitors"

            // Playback streams
            compare(audioPanel.sinkInputsList.length, 1, "Playback stream is listed")
            compare(audioPanel.sinkInputsList[0].app_name, "Spotify")

            // Recording streams filter (default hides virtual peak detector)
            audioPanel.recordingFilter = "apps"
            compare(audioPanel.sourceOutputsList.length, 1, "Apps filter excludes Quickshell Peak Detect")
            compare(audioPanel.sourceOutputsList[0].app_name, "Discord")
            audioPanel.recordingFilter = "all"
            compare(audioPanel.sourceOutputsList.length, 2, "All streams filter includes virtual peak detector")

            // Drivers / Cards
            compare(audioPanel.cardsList.length, 1, "Sound card is listed")
            compare(audioPanel.cardsList[0].driver, "alsa")
            compare(audioPanel.cardsList[0].profiles.length, 3, "All card profiles are listed")

            // Drivers card dropdown collapse/expand behavior
            var cardName = audioPanel.cardsList[0].name
            compare(audioPanel.isCardExpanded(cardName), false, "Hardware card driver list is collapsed by default")
            audioPanel.toggleCardExpanded(cardName)
            compare(audioPanel.isCardExpanded(cardName), true, "Clicking hardware card expands its driver options")
            audioPanel.toggleCardExpanded(cardName)
            compare(audioPanel.isCardExpanded(cardName), false, "Clicking hardware card again collapses its driver options")
        }
    }
}
