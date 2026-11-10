// ============================================================================
// File: modules/audio-service.module.qml
// Purpose: PipeWire/WirePlumber audio volume/mute, peak monitor, and MPRIS/playerctl media service.
// Public API:
//   - Properties: pollIntervalMs, maxVolume, wheelStep, activePeakThreshold, audioPeak, audioPeaks, hasAudio, sinkVolume, sinkMuted, sourceVolume, sourceMuted, activePlayer ...
//   - Functions:  applyConfig(text), setSinkVolume(v), toggleSinkMute(), setSourceVolume(v), toggleSourceMute(), togglePlay(), previous(), next(), runCmd(args), parseWpctl(line)
// Dependencies: Quickshell, Quickshell.Io, Quickshell.Services.Mpris, Quickshell.Services.Pipewire, QtQuick
// ============================================================================
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import QtQuick
import "../components/service-parsers.js" as ServiceParsers

// Audio and media service for PipeWire / WirePlumber audio and MPRIS / playerctl media.
// Configuration comes from config/audio.config.json.
Item {
    id: root

    property int pollIntervalMs: 1000
    property real maxVolume: 1.5
    property real wheelStep: 0.03
    property real activePeakThreshold: 0.005
    property bool spectrumEnabled: true
    property int spectrumBars: 20
    property int spectrumFramerate: 60
    property int spectrumNoiseReduction: 45

    function applyConfig(text) {
        var parsed = ServiceParsers.parseAudioConfig(text, root)
        root.pollIntervalMs = parsed.pollIntervalMs
        root.maxVolume = parsed.maxVolume
        root.wheelStep = parsed.wheelStep
        root.activePeakThreshold = parsed.activePeakThreshold
        root.spectrumEnabled = parsed.spectrumEnabled
        root.spectrumBars = parsed.spectrumBars
        root.spectrumFramerate = parsed.spectrumFramerate
        root.spectrumNoiseReduction = parsed.spectrumNoiseReduction
        // Saving the config is the explicit "retry" action after a cava failure
        root.spectrumFailed = false
        if (root.sinkVolume > root.maxVolume)
            root.sinkVolume = root.maxVolume
        if (root.sourceVolume > root.maxVolume)
            root.sourceVolume = root.maxVolume
    }

    FileView {
        id: configFile
        path: Quickshell.shellPath("config/audio.config.json")
        watchChanges: true
        onFileChanged: configFile.reload()
        onLoaded: root.applyConfig(configFile.text())
    }

    // ── Live Audio Peak Monitor ──
    PwNodePeakMonitor {
        id: peakMonitor
        node: Pipewire.defaultAudioSink
        enabled: Pipewire.ready
    }

    readonly property real audioPeak: (sinkMuted || !Pipewire.ready) ? 0.0 : peakMonitor.peak
    readonly property var audioPeaks: (sinkMuted || !Pipewire.ready) ? [0.0, 0.0] : peakMonitor.peaks
    readonly property bool hasAudio: !sinkMuted && audioPeak > root.activePeakThreshold

    // ── Live Frequency Spectrum (cava FFT, see scripts/audio/stream-cava-bars.sh) ──
    // spectrum: normalized 0..1 band levels, bass first. Empty when unavailable,
    // in which case consumers should fall back to audioPeak/audioPeaks.
    property var spectrum: []
    property bool spectrumFailed: false
    property bool spectrumWanted: false
    property bool spectrumRestarting: false
    readonly property bool spectrumAvailable: spectrumProc.running && !spectrumFailed && spectrum.length === spectrumBars

    onHasAudioChanged: {
        if (root.hasAudio) {
            spectrumHold.stop()
            root.spectrumWanted = true
        } else {
            spectrumHold.restart()
        }
    }
    Component.onCompleted: {
        root.spectrumWanted = root.hasAudio
        if (!sinkPollProc.running) sinkPollProc.running = true
        if (!pavuPollProc.running) pavuPollProc.running = true
    }

    // Keep cava alive briefly after silence so pauses/track gaps don't respawn it
    Timer {
        id: spectrumHold
        interval: 4000
        onTriggered: root.spectrumWanted = false
    }

    // cava binds to the default sink monitor at start; restart it when the sink changes
    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() {
            if (!spectrumProc.running)
                return
            root.spectrumRestarting = true
            spectrumRestartDelay.restart()
        }
    }
    Timer {
        id: spectrumRestartDelay
        interval: 300
        onTriggered: root.spectrumRestarting = false
    }

    Process {
        id: spectrumProc
        command: ["sh", Quickshell.shellPath("src/app/scripts/audio/stream-cava-bars.sh"), String(root.spectrumBars), String(root.spectrumFramerate), String(root.spectrumNoiseReduction)]
        running: root.spectrumEnabled && root.spectrumWanted && !root.spectrumFailed && !root.spectrumRestarting && !root.sinkMuted
        stdout: SplitParser {
            onRead: data => {
                var frame = ServiceParsers.parseCavaFrame(data, root.spectrumBars, 1000)
                if (frame)
                    root.spectrum = frame
            }
        }
        stderr: StdioCollector {
            id: spectrumErr
        }
        onExited: (exitCode, exitStatus) => {
            root.spectrum = []
            // exitStatus 0 = normal exit; intentional stops (running=false) are signal kills
            if (exitStatus === 0 && exitCode !== 0) {
                root.spectrumFailed = true
                console.warn("Audio: cava spectrum stream exited with code " + exitCode + ": " + spectrumErr.text.trim() + " -- falling back to the peak-based visualizer. Fix the cause and save config/audio.config.json to retry.")
            }
        }
    }

    // ── Output (Speaker / Sink) ──
    property real sinkVolume: 1.0       // 0.0 to 1.5
    property bool sinkMuted: false

    // ── Input (Microphone / Source) ──
    property real sourceVolume: 1.0     // 0.0 to 1.5
    property bool sourceMuted: false

    // ── Media Playback ──
    readonly property var activePlayer: {
        var list = Mpris.players.values
        for (var i = 0; i < list.length; i++) {
            if (list[i].isPlaying) return list[i]
        }
        return list.length > 0 ? list[0] : null
    }

    readonly property bool isPlaying: activePlayer ? activePlayer.isPlaying : fallbackPlaying
    readonly property string trackTitle: (activePlayer && activePlayer.trackTitle) ? activePlayer.trackTitle : fallbackTitle
    readonly property string trackArtist: (activePlayer && activePlayer.trackArtist) ? activePlayer.trackArtist : fallbackArtist
    readonly property string trackArtUrl: (activePlayer && activePlayer.trackArtUrl) ? String(activePlayer.trackArtUrl) : fallbackArtUrl
    readonly property string trackApp: {
        if (activePlayer) {
            if (activePlayer.identity) return activePlayer.identity
            if (activePlayer.desktopEntry) {
                var de = String(activePlayer.desktopEntry)
                return de.charAt(0).toUpperCase() + de.slice(1)
            }
        }
        return fallbackApp
    }

    property bool fallbackPlaying: false
    property string fallbackTitle: ""
    property string fallbackArtist: ""
    property string fallbackApp: ""
    property string fallbackArtUrl: ""

    // ── Pavucontrol State (Devices, Streams, Cards/Drivers) ──
    property string defaultSinkName: ""
    property string defaultSourceName: ""
    property var sinks: []
    property var sources: []
    property var sinkInputs: []
    property var sourceOutputs: []
    property var cards: []

    function refreshPavu() {
        if (!pavuPollProc.running) pavuPollProc.running = true
    }

    function applyPavuJson(rawText) {
        if (!rawText || rawText.trim() === "") return
        try {
            var data = JSON.parse(rawText)
            if (!data || typeof data !== "object") return
            root.defaultSinkName = data.default_sink || ""
            root.defaultSourceName = data.default_source || ""
            root.sinks = Array.isArray(data.sinks) ? data.sinks : []
            root.sources = Array.isArray(data.sources) ? data.sources : []
            root.sinkInputs = Array.isArray(data.sink_inputs) ? data.sink_inputs : []
            root.sourceOutputs = Array.isArray(data.source_outputs) ? data.source_outputs : []
            root.cards = Array.isArray(data.cards) ? data.cards : []
        } catch (e) {
            console.warn("Audio: failed to parse pavucontrol status JSON:", e)
        }
    }

    Process {
        id: pavuPollProc
        command: ["python3", Quickshell.shellPath("src/app/scripts/audio/pavucontrol-manager.py"), "status"]
        stdout: StdioCollector {
            onStreamFinished: root.applyPavuJson(this.text)
        }
    }

    Process {
        id: pavuActionProc
        onExited: {
            root.refreshPavu()
            if (!sinkPollProc.running) sinkPollProc.running = true
        }
    }

    function runPavuAction(subArgs) {
        var cmd = ["python3", Quickshell.shellPath("src/app/scripts/audio/pavucontrol-manager.py")]
        for (var i = 0; i < subArgs.length; i++) {
            cmd.push(String(subArgs[i]))
        }
        pavuActionProc.running = false
        pavuActionProc.command = cmd
        pavuActionProc.running = true
    }

    function setDeviceSinkVolume(sinkName, ratio) {
        var clamped = Math.max(0.0, Math.min(root.maxVolume, ratio))
        var pct = Math.round(clamped * 100)
        var next = []
        for (var i = 0; i < root.sinks.length; i++) {
            var item = Object.assign({}, root.sinks[i])
            if (item.name === sinkName || String(item.index) === String(sinkName)) {
                item.volume = clamped
                item.volume_pct = pct
                if (item.is_default) root.sinkVolume = clamped
            }
            next.push(item)
        }
        root.sinks = next
        runPavuAction(["set-sink-volume", sinkName, pct])
    }

    function toggleDeviceSinkMute(sinkName) {
        var next = []
        for (var i = 0; i < root.sinks.length; i++) {
            var item = Object.assign({}, root.sinks[i])
            if (item.name === sinkName || String(item.index) === String(sinkName)) {
                item.mute = !item.mute
                if (item.is_default) root.sinkMuted = item.mute
            }
            next.push(item)
        }
        root.sinks = next
        runPavuAction(["set-sink-mute", sinkName, "toggle"])
    }

    function setDefaultSink(sinkName) {
        root.defaultSinkName = sinkName
        var next = []
        for (var i = 0; i < root.sinks.length; i++) {
            var item = Object.assign({}, root.sinks[i])
            item.is_default = (item.name === sinkName)
            if (item.is_default) {
                root.sinkVolume = item.volume
                root.sinkMuted = item.mute
            }
            next.push(item)
        }
        root.sinks = next
        runPavuAction(["set-default-sink", sinkName])
    }

    function setSinkPort(sinkName, portName) {
        var next = []
        for (var i = 0; i < root.sinks.length; i++) {
            var item = Object.assign({}, root.sinks[i])
            if (item.name === sinkName || String(item.index) === String(sinkName)) {
                item.active_port = portName
            }
            next.push(item)
        }
        root.sinks = next
        runPavuAction(["set-sink-port", sinkName, portName])
    }

    function setDeviceSourceVolume(sourceName, ratio) {
        var clamped = Math.max(0.0, Math.min(root.maxVolume, ratio))
        var pct = Math.round(clamped * 100)
        var next = []
        for (var i = 0; i < root.sources.length; i++) {
            var item = Object.assign({}, root.sources[i])
            if (item.name === sourceName || String(item.index) === String(sourceName)) {
                item.volume = clamped
                item.volume_pct = pct
                if (item.is_default) root.sourceVolume = clamped
            }
            next.push(item)
        }
        root.sources = next
        runPavuAction(["set-source-volume", sourceName, pct])
    }

    function toggleDeviceSourceMute(sourceName) {
        var next = []
        for (var i = 0; i < root.sources.length; i++) {
            var item = Object.assign({}, root.sources[i])
            if (item.name === sourceName || String(item.index) === String(sourceName)) {
                item.mute = !item.mute
                if (item.is_default) root.sourceMuted = item.mute
            }
            next.push(item)
        }
        root.sources = next
        runPavuAction(["set-source-mute", sourceName, "toggle"])
    }

    function setDefaultSource(sourceName) {
        root.defaultSourceName = sourceName
        var next = []
        for (var i = 0; i < root.sources.length; i++) {
            var item = Object.assign({}, root.sources[i])
            item.is_default = (item.name === sourceName)
            if (item.is_default) {
                root.sourceVolume = item.volume
                root.sourceMuted = item.mute
            }
            next.push(item)
        }
        root.sources = next
        runPavuAction(["set-default-source", sourceName])
    }

    function setSourcePort(sourceName, portName) {
        var next = []
        for (var i = 0; i < root.sources.length; i++) {
            var item = Object.assign({}, root.sources[i])
            if (item.name === sourceName || String(item.index) === String(sourceName)) {
                item.active_port = portName
            }
            next.push(item)
        }
        root.sources = next
        runPavuAction(["set-source-port", sourceName, portName])
    }

    function setSinkInputVolume(streamIndex, ratio) {
        var clamped = Math.max(0.0, Math.min(root.maxVolume, ratio))
        var pct = Math.round(clamped * 100)
        var next = []
        for (var i = 0; i < root.sinkInputs.length; i++) {
            var item = Object.assign({}, root.sinkInputs[i])
            if (item.index === streamIndex) {
                item.volume = clamped
                item.volume_pct = pct
            }
            next.push(item)
        }
        root.sinkInputs = next
        runPavuAction(["set-sink-input-volume", streamIndex, pct])
    }

    function toggleSinkInputMute(streamIndex) {
        var next = []
        for (var i = 0; i < root.sinkInputs.length; i++) {
            var item = Object.assign({}, root.sinkInputs[i])
            if (item.index === streamIndex) {
                item.mute = !item.mute
            }
            next.push(item)
        }
        root.sinkInputs = next
        runPavuAction(["set-sink-input-mute", streamIndex, "toggle"])
    }

    function moveSinkInput(streamIndex, targetSinkName) {
        runPavuAction(["move-sink-input", streamIndex, targetSinkName])
    }

    function setSourceOutputVolume(streamIndex, ratio) {
        var clamped = Math.max(0.0, Math.min(root.maxVolume, ratio))
        var pct = Math.round(clamped * 100)
        var next = []
        for (var i = 0; i < root.sourceOutputs.length; i++) {
            var item = Object.assign({}, root.sourceOutputs[i])
            if (item.index === streamIndex) {
                item.volume = clamped
                item.volume_pct = pct
            }
            next.push(item)
        }
        root.sourceOutputs = next
        runPavuAction(["set-source-output-volume", streamIndex, pct])
    }

    function toggleSourceOutputMute(streamIndex) {
        var next = []
        for (var i = 0; i < root.sourceOutputs.length; i++) {
            var item = Object.assign({}, root.sourceOutputs[i])
            if (item.index === streamIndex) {
                item.mute = !item.mute
            }
            next.push(item)
        }
        root.sourceOutputs = next
        runPavuAction(["set-source-output-mute", streamIndex, "toggle"])
    }

    function moveSourceOutput(streamIndex, targetSourceName) {
        runPavuAction(["move-source-output", streamIndex, targetSourceName])
    }

    function setCardProfile(cardName, profileName) {
        var next = []
        for (var i = 0; i < root.cards.length; i++) {
            var item = Object.assign({}, root.cards[i])
            if (item.name === cardName || String(item.index) === String(cardName)) {
                item.active_profile = profileName
                var profs = item.profiles || []
                for (var j = 0; j < profs.length; j++) {
                    if (profs[j].name === profileName) {
                        item.active_profile_description = profs[j].description
                        break
                    }
                }
            }
            next.push(item)
        }
        root.cards = next
        runPavuAction(["set-card-profile", cardName, profileName])
    }

    // ── Controls ──
    function setSinkVolume(v) {
        sinkVolume = Math.max(0.0, Math.min(root.maxVolume, v))
        sinkPollProc.running = false
        runCmd(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (Math.round(sinkVolume * 100) / 100).toFixed(2)])
        pollTimer.restart()
    }

    function toggleSinkMute() {
        sinkMuted = !sinkMuted
        sinkPollProc.running = false
        runCmd(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        pollTimer.restart()
    }

    function setSourceVolume(v) {
        sourceVolume = Math.max(0.0, Math.min(root.maxVolume, v))
        sinkPollProc.running = false
        runCmd(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", (Math.round(sourceVolume * 100) / 100).toFixed(2)])
        pollTimer.restart()
    }

    function toggleSourceMute() {
        sourceMuted = !sourceMuted
        sinkPollProc.running = false
        runCmd(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
        pollTimer.restart()
    }

    function togglePlay() {
        if (activePlayer && activePlayer.canTogglePlaying) {
            activePlayer.togglePlaying()
        } else {
            runCmd(["playerctl", "play-pause"])
        }
    }

    function previous() {
        if (activePlayer && activePlayer.canGoPrevious) {
            activePlayer.previous()
        } else {
            runCmd(["playerctl", "previous"])
        }
    }

    function next() {
        if (activePlayer && activePlayer.canGoNext) {
            activePlayer.next()
        } else {
            runCmd(["playerctl", "next"])
        }
    }

    // Process executor for CLI actions
    Process { id: cmdProc }
    function runCmd(args) {
        cmdProc.command = args
        cmdProc.running = true
    }

    // ── Polling Sink & Source Volume ──
    function parseWpctl(line) {
        return ServiceParsers.parseWpctlLine(line)
    }

    Process {
        id: sinkPollProc
        command: ["sh", Quickshell.shellPath("src/app/scripts/audio/poll-audio-state.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                if (lines.length >= 1 && lines[0].indexOf("Volume:") !== -1) {
                    var s = root.parseWpctl(lines[0])
                    root.sinkVolume = s.vol
                    root.sinkMuted = s.muted
                }
                if (lines.length >= 2 && lines[1].indexOf("Volume:") !== -1) {
                    var src = root.parseWpctl(lines[1])
                    root.sourceVolume = src.vol
                    root.sourceMuted = src.muted
                }
                if (lines.length >= 3) {
                    var statusStr = lines[2].trim()
                    root.fallbackPlaying = (statusStr === "Playing")
                    if (root.fallbackPlaying || statusStr === "Paused" || root.hasAudio) {
                        if (!metaPollProc.running) metaPollProc.running = true
                    } else {
                        root.fallbackTitle = ""
                        root.fallbackArtist = ""
                        root.fallbackApp = ""
                        root.fallbackArtUrl = ""
                    }
                }
            }
        }
    }

    Process {
        id: metaPollProc
        command: ["playerctl", "metadata", "--format", "{{title}}\n{{artist}}\n{{playerName}}\n{{mpris:artUrl}}"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n")
                root.fallbackTitle = lines.length >= 1 ? lines[0].trim() : ""
                root.fallbackArtist = lines.length >= 2 ? lines[1].trim() : ""
                var rawApp = lines.length >= 3 ? lines[2].trim() : ""
                root.fallbackApp = rawApp.length > 0 ? (rawApp.charAt(0).toUpperCase() + rawApp.slice(1)) : ""
                root.fallbackArtUrl = lines.length >= 4 ? lines[3].trim() : ""
            }
        }
    }

    property int _pavuTickCounter: 0

    Timer {
        id: pollTimer
        interval: root.pollIntervalMs
        running: true
        repeat: true
        onTriggered: {
            if (!sinkPollProc.running) sinkPollProc.running = true
            root._pavuTickCounter = (root._pavuTickCounter + 1) % 2
            if (root._pavuTickCounter === 0 && !pavuPollProc.running) {
                pavuPollProc.running = true
            }
        }
    }
}
