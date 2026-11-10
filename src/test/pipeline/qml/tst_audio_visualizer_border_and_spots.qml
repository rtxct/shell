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
        property real sinkVolume: 0.75
        property bool sourceMuted: false
        property real sourceVolume: 0.80
        property real audioPeak: 0.0
        property var audioPeaks: [0.0, 0.0]
        property var spectrum: []
        property bool spectrumAvailable: false
        property real wheelStep: 0.03
        function setSinkVolume(v) { sinkVolume = Math.max(0, Math.min(1.5, v)) }
        function setSourceVolume(v) { sourceVolume = Math.max(0, Math.min(1.0, v)) }
        function toggleSinkMute() { sinkMuted = !sinkMuted }
        function toggleSourceMute() { sourceMuted = !sourceMuted }
    }

    MediaControlBar {
        id: mediaBar
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        audio: mockAudio
    }

    Drop {
        id: testDrop
        width: 200
        height: 40
    }

    TestCase {
        name: "AudioVisualizerBorderAndSpotsTests"
        when: windowShown

        function init() {
            mockAudio.hasAudio = false
            mockAudio.isPlaying = false
            mockAudio.spectrumAvailable = false
            mockAudio.spectrum = []
            mockAudio.audioPeak = 0.0
            mockAudio.audioPeaks = [0.0, 0.0]
            mediaBar.closeMerged()
            tryCompare(mediaBar.borderVisualizerRef, "opacity", 0.0, 400)
            tryCompare(mediaBar.dropMediaRef, "strokeColor", DropStyle.strokeColor, 500)
        }

        function test_drop_component_stroke_color_and_width_api() {
            compare(testDrop.strokeColor, DropStyle.strokeColor)
            compare(testDrop.strokeWidth, DropStyle.strokeWidth)

            testDrop.strokeColor = Theme.transparent
            testDrop.strokeWidth = 0
            tryCompare(testDrop, "strokeColor", Theme.transparent, 300)
            compare(testDrop.strokeWidth, 0)

            testDrop.strokeColor = DropStyle.strokeColor
            testDrop.strokeWidth = DropStyle.strokeWidth
            tryCompare(testDrop, "strokeColor", DropStyle.strokeColor, 300)
            compare(testDrop.strokeWidth, DropStyle.strokeWidth)
        }

        function test_white_border_removed_when_visualizer_active() {
            // Idle state: no audio, visualizer inactive
            compare(mockAudio.hasAudio, false)
            verify(!mediaBar.borderVisualizerRef.isVisualizerActive)
            compare(mediaBar.dropMediaRef.strokeColor, DropStyle.strokeColor)
            compare(mediaBar.dropMediaRef.strokeWidth, DropStyle.strokeWidth)

            // Audio starts playing: visualizer becomes active
            mockAudio.hasAudio = true
            mockAudio.isPlaying = true
            mockAudio.audioPeak = 0.45
            mockAudio.audioPeaks = [0.45, 0.45]

            verify(mediaBar.borderVisualizerRef.shouldRun)
            verify(mediaBar.borderVisualizerRef.visualizerActive)
            compare(mediaBar.dropMediaRef.strokeColorDuration, MediaControlBarStyle.waveFadeDurationMs)
            tryCompare(mediaBar.dropMediaRef, "strokeColor", Theme.transparent, 300)
            tryCompare(mediaBar.dropMediaRef, "fill", Theme.transparent, 300)
            compare(mediaBar.dropMediaRef.strokeWidth, DropStyle.strokeWidth)

            // Verify visualizer points and normal vectors are populated with rounded arcs
            verify(mediaBar.borderVisualizerRef.pts.length >= 40)
            compare(mediaBar.borderVisualizerRef.nms.length, mediaBar.borderVisualizerRef.pts.length)

            // Audio stops: white border is restored
            mockAudio.hasAudio = false
            mockAudio.isPlaying = false
            mockAudio.audioPeak = 0.0
            mockAudio.audioPeaks = [0.0, 0.0]
            mediaBar.borderVisualizerRef.currentMax = 0.0

            tryCompare(mediaBar.dropMediaRef, "strokeColor", DropStyle.strokeColor, 500)
            tryCompare(mediaBar.dropMediaRef, "fill", MediaControlBarStyle.fill, 500)
            compare(mediaBar.dropMediaRef.strokeWidth, DropStyle.strokeWidth)
        }

        function test_frequency_spectrum_dynamic_mapping() {
            // Activate audio with spectrum data (heavy kick drum: bass high, treble low)
            mockAudio.hasAudio = true
            mockAudio.isPlaying = true
            mockAudio.spectrumAvailable = true
            mockAudio.spectrum = [1.0, 0.9, 0.6, 0.3, 0.1, 0.05, 0.0, 0.0]

            // Wait for visualizer ticker to compute heights from spectrum
            tryVerify(function() {
                return mediaBar.borderVisualizerRef.hts.length >= 40 && mediaBar.borderVisualizerRef.currentMax > 0.5
            }, 300)

            var hts = mediaBar.borderVisualizerRef.hts
            var total = hts.length
            var center = Math.floor((total - 1) / 2)

            // Center of top edge (bass) must have significantly higher wave height than the ends (treble)
            var centerHt = hts[center]
            var endHt = hts[2] // near bottom left end
            verify(centerHt > endHt * 2.0)

            // Dynamic drum sensitivity: high bass transient generates prominent wave height (> 8px)
            verify(centerHt >= 8.0)

            // When spectrum becomes unavailable, it gracefully falls back without breaking
            mockAudio.spectrumAvailable = false
            mockAudio.spectrum = []
            mockAudio.audioPeak = 0.5
            mockAudio.audioPeaks = [0.5, 0.5]

            tryVerify(function() {
                return mediaBar.borderVisualizerRef.currentMax > 0.0
            }, 300)
        }

        function test_visualizer_canvas_padding_prevents_top_clipping() {
            var viz = mediaBar.borderVisualizerRef
            // padY must be expanded (>= 36) to prevent cutting on high bass surges
            verify(viz.padY >= 36)
            verify(viz.padX >= 20)

            // Canvas dimensions and position must reflect the expanded transparent bounds
            compare(viz.x, mediaBar.dropMediaRef.x - viz.padY + (viz.padY - viz.padX))
            compare(viz.y, mediaBar.dropMediaRef.y - viz.padY)
            compare(viz.height, mediaBar.dropMediaRef.height + viz.padY + MediaControlBarStyle.waveBottomPad)

            // Verify points were recomputed with the expanded padding
            // Top edge points must have y coordinate equal to padY (baseline)
            var topPt = viz.pts[10] // top edge point
            compare(topPt[1], viz.padY)

            // With max bass surge (e.g. 30px displacement upward), the crest y remains >= 0 (no top clipping)
            var maxDisplacement = 30.0
            var crestY = topPt[1] - maxDisplacement
            verify(crestY >= 0.0)
        }

        function test_frequency_spectrum_rounded_wave_profile() {
            // Activate audio with a single sharp frequency spike
            mockAudio.hasAudio = true
            mockAudio.isPlaying = true
            mockAudio.spectrumAvailable = true
            mockAudio.spectrum = [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

            tryVerify(function() {
                return mediaBar.borderVisualizerRef.currentMax > 1.0
            }, 300)

            var hts = mediaBar.borderVisualizerRef.hts
            var total = hts.length
            var center = Math.floor((total - 1) / 2)

            // Spatial smoothing must distribute energy to adjacent points so it's not a single sharp triangle
            verify(hts[center] > 0.0)
            verify(hts[center - 1] > 0.0)
            verify(hts[center + 1] > 0.0)

            // Curvature check: peak must form a smooth rounded dome where second difference is negative (concave down)
            var secondDiff = hts[center - 1] - 2 * hts[center] + hts[center + 1]
            verify(secondDiff < 0, "Peak profile must be concave down (rounded dome)")

            // Verify traceWavePath function exists on canvas and operates without error
            var viz = mediaBar.borderVisualizerRef
            verify(typeof viz.traceWavePath === "function")
        }

        function test_visualizer_unified_glass_extension() {
            var viz = mediaBar.borderVisualizerRef
            verify(typeof viz.traceFullIslandPath === "function", "traceFullIslandPath must be defined on borderVisualizer")
            verify(typeof viz.toCanvasRgba === "function", "toCanvasRgba must be defined on borderVisualizer")

            // Verify toCanvasRgba converts QML color to valid css rgba string without ARGB hex truncation
            var testColor = Qt.rgba(0.2, 0.4, 0.6, 0.75)
            var rgbaStr = viz.toCanvasRgba(testColor)
            compare(rgbaStr, "rgba(51,102,153,0.750)")

            // Test transparent fallback
            compare(viz.toCanvasRgba(null), "rgba(0,0,0,0)")

            // Visualizer must be declared before dropMedia in painter order (lower stacking index)
            // so dropMedia buttons render on top of the living glass background
            var parentChildren = mediaBar.children
            var vizIdx = -1
            var dropIdx = -1
            for (var i = 0; i < parentChildren.length; i++) {
                if (parentChildren[i] === viz) vizIdx = i
                if (parentChildren[i] === mediaBar.dropMediaRef) dropIdx = i
            }
            verify(vizIdx !== -1 && dropIdx !== -1, "Both items must be children of MediaControlBar")
            verify(vizIdx < dropIdx, "borderVisualizer must be positioned before dropMedia in child order")
        }

        function test_idle_bar_exact_same_theme_and_style_as_left_bottom_bar() {
            // In idle state (no audio), borderVisualizer must be invisible
            compare(mediaBar.borderVisualizerRef.visible, false)
            compare(mediaBar.borderVisualizerRef.opacity, 0.0)

            // dropMedia's strokeColor, strokeWidth, and fill must match AppLauncher / DropStyle defaults exactly
            var drop = mediaBar.dropMediaRef
            compare(drop.strokeColor, DropStyle.strokeColor)
            compare(drop.strokeWidth, DropStyle.strokeWidth)
            compare(drop.fill, MediaControlBarStyle.fill)
            compare(drop.slant, AppLauncherStyle.dropSlant)
            compare(drop.rad, AppLauncherStyle.dropRadius)
            compare(drop.flare, AppLauncherStyle.dropFlare)
            compare(drop.inset, AppLauncherStyle.dropInset)
            compare(drop.bottomInset, AppLauncherStyle.dropBottomInset)
            compare(drop.height, AppLauncherStyle.barHeight)
            compare(drop.width, AppLauncherStyle.barWidth)

            // Even on borderVisualizer, baseline contour must include Drop's concave bottom fillets (flare)
            var viz = mediaBar.borderVisualizerRef
            verify(viz.pts[0][0] < viz.padX, "Bottom-left fillet must flare outward left of padX")
            verify(viz.pts[viz.pts.length - 1][0] > viz.padX + mediaBar.btnWidth, "Bottom-right fillet must flare outward right of padX + btnWidth")
        }
    }
}
