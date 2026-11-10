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
        property bool hasAudio: false
        property bool isPlaying: false
        property bool sinkMuted: false
        property real sinkVolume: 0.65
        property bool sourceMuted: false
        property real sourceVolume: 0.40
        property real wheelStep: 0.03
        function setSinkVolume(v) { sinkVolume = Math.max(0, Math.min(1.0, v)) }
        function setSourceVolume(v) { sourceVolume = Math.max(0, Math.min(1.0, v)) }
        function toggleSinkMute() { sinkMuted = !sinkMuted }
        function toggleSourceMute() { sourceMuted = !sourceMuted }
    }

    Item {
        id: mockFloatManager
        property var lastDragConfig: null
        property var lastDragPt: Qt.point(0, 0)
        property bool isSoundFloating: false
        property bool isVolumeBarFloating: false
        property bool isMicBarFloating: false
        signal windowDocked(string id)
        signal windowClosed(string id)

        function startDrag(cfg, x, y) {
            lastDragConfig = cfg
            lastDragPt = Qt.point(x, y)
        }
        function updateDrag(x, y) {
            lastDragPt = Qt.point(x, y)
        }
        function endDrag() {}
    }

    MediaControlBar {
        id: mediaBar
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        audio: mockAudio
        floatManager: mockFloatManager
    }

    FloatingWindow {
        id: floatWinVol
        winId: "volume-bar"
        title: "Volume"
        originSide: "bottom"
        posX: 400
        posY: 400
        winWidth: MediaControlBarStyle.floatBarWidth
        winHeight: MediaControlBarStyle.floatBarHeight
        screenW: 1920
        screenH: 1080
        active: true
        audio: mockAudio
    }

    FloatingWindow {
        id: floatWinMic
        winId: "mic-bar"
        title: "Microphone"
        originSide: "bottom"
        posX: 400
        posY: 400
        winWidth: MediaControlBarStyle.floatBarWidth
        winHeight: MediaControlBarStyle.floatBarHeight
        screenW: 1920
        screenH: 1080
        active: true
        audio: mockAudio
    }

    FloatingSliderBarPanel {
        id: panelOutput
        audio: mockAudio
        floatingWindow: floatWinVol
        mode: "output"
        width: MediaControlBarStyle.floatBarWidth
        height: MediaControlBarStyle.floatBarHeight
    }

    FloatingSliderBarPanel {
        id: panelInput
        audio: mockAudio
        floatingWindow: floatWinMic
        mode: "input"
        width: MediaControlBarStyle.floatBarWidth
        height: MediaControlBarStyle.floatBarHeight
    }

    SignalSpy {
        id: dockSpyVol
        target: floatWinVol
        signalName: "dockRequested"
    }

    SignalSpy {
        id: closeSpyVol
        target: floatWinVol
        signalName: "closeRequested"
    }

    TestCase {
        name: "FloatVolumeAndMicBarsTests"
        when: windowShown

        function test_volume_and_mic_bar_style_dimensions() {
            compare(mediaBar.width, 334, "Media control bar default total width is 334")
            compare(mediaBar.height, 36, "Media control bar default height is 36")
            compare(MediaControlBarStyle.floatBarWidth, 334, "Floating volume bar width matches glued bar width")
            compare(MediaControlBarStyle.floatBarHeight, 36, "Floating volume bar height matches glued bar height")
        }

        function test_floating_window_bar_mode_titlebar_and_radius() {
            compare(floatWinVol.isBarMode, true, "volume-bar must activate isBarMode")
            compare(floatWinVol.showTitlebar, false, "volume-bar must hide separate titlebar")
            compare(floatWinVol.winWidth, 334, "volume-bar width is 334")
            compare(floatWinVol.winHeight, 36, "volume-bar height is 36")
            compare(FloatingWindowStyle.barFrameRadius, 8, "Floating bar frame uses squared-with-rounded-corners radius (8px)")
            compare(MediaControlBarStyle.floatBarBtnRadius, 5, "Floating bar buttons use squared-with-rounded-corners radius (5px)")

            compare(floatWinMic.isBarMode, true, "mic-bar must activate isBarMode")
            compare(floatWinMic.showTitlebar, false, "mic-bar must hide separate titlebar")
            compare(floatWinMic.winWidth, 334, "mic-bar width is 334")
            compare(floatWinMic.winHeight, 36, "mic-bar height is 36")
        }

        function test_floating_slider_bar_panel_audio_controls() {
            // Test Output
            compare(panelOutput.isOutput, true, "panelOutput is output mode")
            compare(panelOutput.isMuted, false, "Initially not muted")
            compare(panelOutput.volume, 0.65, "Output volume is 0.65")
            panelOutput.toggleMute()
            compare(mockAudio.sinkMuted, true, "sinkMuted toggled")
            panelOutput.toggleMute()
            compare(mockAudio.sinkMuted, false, "sinkMuted restored")
            panelOutput.setVolume(0.85)
            compare(mockAudio.sinkVolume, 0.85, "sinkVolume updated to 0.85")

            // Test Input
            compare(panelInput.isOutput, false, "panelInput is input mode")
            compare(panelInput.isMuted, false, "Initially input not muted")
            compare(panelInput.volume, 0.40, "Input volume is 0.40")
            panelInput.toggleMute()
            compare(mockAudio.sourceMuted, true, "sourceMuted toggled")
            panelInput.toggleMute()
            compare(mockAudio.sourceMuted, false, "sourceMuted restored")
            panelInput.setVolume(0.55)
            compare(mockAudio.sourceVolume, 0.55, "sourceVolume updated to 0.55")
        }

        function test_dock_and_close_from_panel() {
            dockSpyVol.clear()
            closeSpyVol.clear()
            floatWinVol.dock()
            compare(dockSpyVol.count, 1, "Dock requested from floating bar")
            floatWinVol.close()
            compare(closeSpyVol.count, 1, "Close requested from floating bar")
        }

        function test_volume_and_mic_buttons_vanish_when_floating_and_fade_in_when_returned() {
            mediaBar.closeMerged()
            compare(mediaBar.isMerged, false, "Initially not merged")
            mockFloatManager.isVolumeBarFloating = true
            compare(mediaBar.isVolumeBarFloating, true, "isVolumeBarFloating tracks volume-bar floating state")
            mockFloatManager.isVolumeBarFloating = false
            compare(mediaBar.isVolumeBarFloating, false, "Volume button returns when volume-bar is docked/closed")

            mockFloatManager.isMicBarFloating = true
            compare(mediaBar.isMicBarFloating, true, "isMicBarFloating tracks mic-bar floating state")
            mockFloatManager.isMicBarFloating = false
            compare(mediaBar.isMicBarFloating, false, "Mic button returns when mic-bar is docked/closed")
        }
    }
}
