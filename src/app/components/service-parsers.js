// ============================================================================
// File: components/service-parsers.js
// Purpose: Pure, stateless parsing and formatting helpers for Weather
//          (Open-Meteo JSON & WMO weather codes), Audio (wpctl output),
//          Workspaces (Niri JSON & collapsed strip filtering), Processes,
//          Menu launch history and sorting, and Notification text sanitization.
//          Extracted as a stateless JS library (.pragma library) so both
//          Quickshell service modules and Qt Quick Test cases (qmltestrunner)
//          can execute and verify them without Quickshell I/O.
// ============================================================================
.pragma library

/** Map WMO weather code integer to { icon: string, text: string }. */
function wmo(code) {
    switch (code) {
    case 0: return { icon: "☀️", text: "Clear" }
    case 1: return { icon: "🌤️", text: "Mostly clear" }
    case 2: return { icon: "⛅", text: "Partly cloudy" }
    case 3: return { icon: "☁️", text: "Overcast" }
    case 45: case 48: return { icon: "🌫️", text: "Fog" }
    case 51: case 53: case 55: case 56: case 57: return { icon: "🌦️", text: "Drizzle" }
    case 61: case 63: case 65: case 66: case 67: return { icon: "🌧️", text: "Rain" }
    case 71: case 73: case 75: case 77: return { icon: "🌨️", text: "Snow" }
    case 80: case 81: case 82: return { icon: "🌧️", text: "Showers" }
    case 85: case 86: return { icon: "🌨️", text: "Snow showers" }
    case 95: case 96: case 99: return { icon: "⛈️", text: "Thunderstorm" }
    }
    return { icon: "🌡️", text: "—" }
}

/**
 * Parse weather.config.json text into { locations: Array, defaultIndex: int, refreshMinutes: int|null }.
 */
function parseWeatherConfig(text) {
    var arr = []
    var refreshMinutes = null
    var rawDefaultIndex = 0
    try {
        var j = JSON.parse(text)
        if (!Array.isArray(j)) {
            if (typeof j.refreshMinutes === "number" && j.refreshMinutes > 0)
                refreshMinutes = j.refreshMinutes
            if (typeof j.defaultIndex === "number" && j.defaultIndex >= 0)
                rawDefaultIndex = Math.floor(j.defaultIndex)
        }
        var src = Array.isArray(j) ? j : (j.locations || [])
        src.forEach(function (o) {
            var lat = parseFloat(o.latitude)
            var lon = parseFloat(o.longitude)
            if (!isNaN(lat) && !isNaN(lon))
                arr.push({ name: o.name || (lat + ", " + lon), latitude: lat, longitude: lon })
        })
    } catch (e) {
        arr = []
    }
    var defaultIndex = (rawDefaultIndex >= 0 && rawDefaultIndex < arr.length) ? rawDefaultIndex : 0
    return { locations: arr, defaultIndex: defaultIndex, refreshMinutes: refreshMinutes }
}

/**
 * Parse Open-Meteo response JSON string into current metrics, 16-day daily forecast, and hourly details.
 */
function parseOpenMeteoResponse(text) {
    try {
        var j = JSON.parse(text)
        var c = j.current || {}
        var w = wmo(c.weather_code)
        var temp = String(Math.round(c.temperature_2m || 0))
        var feels = String(Math.round(c.apparent_temperature || 0))
        var humidity = String(Math.round(c.relative_humidity_2m || 0))
        var wind = String(Math.round(c.wind_speed_10m || 0))
        var precip = c.precipitation !== undefined ? String(Math.round(c.precipitation * 10) / 10) : "0"
        var pressure = c.surface_pressure !== undefined ? String(Math.round(c.surface_pressure)) : "1013"
        var uv = c.uv_index !== undefined ? String(Math.round(c.uv_index * 10) / 10) : "0"
        var desc = w.text
        var icon = w.icon

        var f = []
        if (j.daily && j.daily.time) {
            for (var i = 0; i < j.daily.time.length; i++) {
                var rawDate = j.daily.time[i]
                var p = rawDate.split("-")
                var d = new Date(+p[0], +p[1] - 1, +p[2])
                var dayWmo = wmo(j.daily.weather_code ? j.daily.weather_code[i] : 0)

                var hourlyItems = []
                if (j.hourly && j.hourly.time) {
                    for (var h = 0; h < j.hourly.time.length; h++) {
                        var hTime = j.hourly.time[h]
                        if (hTime.indexOf(rawDate) === 0) {
                            var timeParts = hTime.split("T")
                            var timeStr = timeParts.length > 1 ? timeParts[1] : hTime
                            var hCode = j.hourly.weather_code ? j.hourly.weather_code[h] : 0
                            var hw = wmo(hCode)
                            var hPopRaw = (j.hourly && j.hourly.precipitation_probability) ? j.hourly.precipitation_probability[h] : null
                            var hPop = (hPopRaw !== null && hPopRaw !== undefined && !isNaN(hPopRaw)) ? Math.round(hPopRaw) : null
                            hourlyItems.push({
                                time: timeStr,
                                temp: Math.round(j.hourly.temperature_2m ? j.hourly.temperature_2m[h] : 0),
                                feels: Math.round(j.hourly.apparent_temperature ? j.hourly.apparent_temperature[h] : 0),
                                icon: hw.icon,
                                desc: hw.text,
                                pop: hPop
                            })
                        }
                    }
                }

                f.push({
                    date: rawDate,
                    day: Qt.formatDate(d, "ddd"),
                    dateFormatted: Qt.formatDate(d, "dd MMM"),
                    max: Math.round(j.daily.temperature_2m_max ? j.daily.temperature_2m_max[i] : 0),
                    min: Math.round(j.daily.temperature_2m_min ? j.daily.temperature_2m_min[i] : 0),
                    icon: dayWmo.icon,
                    desc: dayWmo.text,
                    precipSum: j.daily.precipitation_sum ? Math.round(j.daily.precipitation_sum[i] * 10) / 10 : 0,
                    precipProb: (j.daily.precipitation_probability_max && j.daily.precipitation_probability_max[i] !== null && j.daily.precipitation_probability_max[i] !== undefined && !isNaN(j.daily.precipitation_probability_max[i]))
                        ? Math.round(j.daily.precipitation_probability_max[i])
                        : null,
                    windMax: j.daily.wind_speed_10m_max ? Math.round(j.daily.wind_speed_10m_max[i]) : 0,
                    uvMax: j.daily.uv_index_max ? Math.round(j.daily.uv_index_max[i] * 10) / 10 : 0,
                    hourly: hourlyItems
                })
            }
        }
        return {
            ok: true,
            temp: temp,
            feels: feels,
            humidity: humidity,
            wind: wind,
            precip: precip,
            pressure: pressure,
            uv: uv,
            desc: desc,
            icon: icon,
            forecast: f
        }
    } catch (e) {
        return { ok: false }
    }
}

/**
 * Parse a single line of `wpctl get-volume` output (e.g. "Volume: 0.65 [MUTED]").
 */
function parseWpctlLine(line) {
    var m = /Volume:\s*([0-9.]+)/.exec(line || "")
    var vol = m ? parseFloat(m[1]) : 1.0
    var muted = (line || "").indexOf("[MUTED]") !== -1
    return { vol: isNaN(vol) ? 1.0 : vol, muted: muted }
}

/**
 * Filter workspace items down to at most `max` items for the collapsed strip,
 * guaranteeing that the focused workspace remains visible when trimming.
 */
function stripWorkspaces(items, max) {
    var list = items || []
    var active = list.filter(function (w) { return w.occupied || w.focused })
    if (active.length === 0) return list.slice(0, max)
    if (active.length <= max) return active
    var trimmed = active.slice(0, max)
    var hasFocused = trimmed.some(function (w) { return w.focused })
    if (!hasFocused) {
        var foc = active.find(function (w) { return w.focused })
        if (foc) trimmed[trimmed.length - 1] = foc
    }
    return trimmed
}

/**
 * Parse `niri msg --json workspaces` output into sorted workspace items.
 */
function parseNiriWorkspaces(text) {
    try {
        var arr = JSON.parse(text)
        if (!Array.isArray(arr)) return null
        arr.sort(function (a, b) { return a.idx - b.idx })
        return arr.map(function (w) {
            return {
                id: w.id,
                number: w.idx,
                name: w.name || String(w.idx),
                label: w.name ? w.name.slice(0, 3) : String(w.idx),
                focused: !!w.is_focused,
                occupied: w.active_window_id !== null && w.active_window_id !== undefined,
                urgent: !!w.is_urgent
            }
        })
    } catch (e) {
        return null
    }
}

/**
 * Parse calendar.config.json text into calendar service settings, preserving previous state for omitted/invalid fields.
 */
function parseCalendarConfig(text, prevState) {
    var out = {
        icsUrl: prevState && typeof prevState.icsUrl === "string" ? prevState.icsUrl : "",
        refreshMinutes: prevState && typeof prevState.refreshMinutes === "number" ? prevState.refreshMinutes : 10,
        listDays: prevState && typeof prevState.listDays === "number" ? prevState.listDays : 30,
        windowStartDays: prevState && typeof prevState.windowStartDays === "number" ? prevState.windowStartDays : -40,
        windowEndDays: prevState && typeof prevState.windowEndDays === "number" ? prevState.windowEndDays : 90,
        maxUpcoming: prevState && typeof prevState.maxUpcoming === "number" ? prevState.maxUpcoming : 60,
        curlMaxTimeSeconds: prevState && typeof prevState.curlMaxTimeSeconds === "number" ? prevState.curlMaxTimeSeconds : 20
    }
    try {
        var cfg = JSON.parse(text)
        if (typeof cfg.icsUrl === "string")
            out.icsUrl = cfg.icsUrl
        if (typeof cfg.refreshMinutes === "number" && cfg.refreshMinutes > 0)
            out.refreshMinutes = cfg.refreshMinutes
        if (typeof cfg.listDays === "number" && cfg.listDays > 0)
            out.listDays = cfg.listDays
        if (typeof cfg.windowStartDays === "number")
            out.windowStartDays = cfg.windowStartDays
        if (typeof cfg.windowEndDays === "number")
            out.windowEndDays = cfg.windowEndDays
        if (typeof cfg.maxUpcoming === "number" && cfg.maxUpcoming > 0)
            out.maxUpcoming = cfg.maxUpcoming
        if (typeof cfg.curlMaxTimeSeconds === "number" && cfg.curlMaxTimeSeconds > 0)
            out.curlMaxTimeSeconds = cfg.curlMaxTimeSeconds
    } catch (e) {
    }
    return out
}

/**
 * Parse audio.config.json text into audio service settings, preserving previous state for omitted/invalid fields.
 */
function parseAudioConfig(text, prevState) {
    var out = {
        pollIntervalMs: prevState && typeof prevState.pollIntervalMs === "number" ? prevState.pollIntervalMs : 1000,
        maxVolume: prevState && typeof prevState.maxVolume === "number" ? prevState.maxVolume : 1.5,
        wheelStep: prevState && typeof prevState.wheelStep === "number" ? prevState.wheelStep : 0.03,
        activePeakThreshold: prevState && typeof prevState.activePeakThreshold === "number" ? prevState.activePeakThreshold : 0.005,
        spectrumEnabled: prevState && typeof prevState.spectrumEnabled === "boolean" ? prevState.spectrumEnabled : true,
        spectrumBars: prevState && typeof prevState.spectrumBars === "number" ? prevState.spectrumBars : 20,
        spectrumFramerate: prevState && typeof prevState.spectrumFramerate === "number" ? prevState.spectrumFramerate : 60,
        spectrumNoiseReduction: prevState && typeof prevState.spectrumNoiseReduction === "number" ? prevState.spectrumNoiseReduction : 45
    }
    try {
        var cfg = JSON.parse(text)
        if (typeof cfg.pollIntervalMs === "number" && cfg.pollIntervalMs > 0)
            out.pollIntervalMs = cfg.pollIntervalMs
        if (typeof cfg.maxVolume === "number" && cfg.maxVolume > 0)
            out.maxVolume = cfg.maxVolume
        if (typeof cfg.wheelStep === "number" && cfg.wheelStep > 0)
            out.wheelStep = cfg.wheelStep
        if (typeof cfg.activePeakThreshold === "number" && cfg.activePeakThreshold >= 0)
            out.activePeakThreshold = cfg.activePeakThreshold
        if (typeof cfg.spectrumEnabled === "boolean")
            out.spectrumEnabled = cfg.spectrumEnabled
        if (typeof cfg.spectrumBars === "number" && cfg.spectrumBars >= 2 && cfg.spectrumBars <= 64)
            out.spectrumBars = Math.round(cfg.spectrumBars)
        if (typeof cfg.spectrumFramerate === "number" && cfg.spectrumFramerate >= 10 && cfg.spectrumFramerate <= 144)
            out.spectrumFramerate = Math.round(cfg.spectrumFramerate)
        if (typeof cfg.spectrumNoiseReduction === "number" && cfg.spectrumNoiseReduction >= 0 && cfg.spectrumNoiseReduction <= 100)
            out.spectrumNoiseReduction = Math.round(cfg.spectrumNoiseReduction)
    } catch (e) {
    }
    return out
}

/**
 * Parse one raw ASCII cava frame ("v0;v1;...;vN;", values 0..maxRange, bass first)
 * into an array of normalized 0..1 band levels.
 * Returns null when the frame is malformed or its band count differs from expectedBars
 * (e.g. a partial line read during a cava restart), so callers can keep the previous frame.
 */
function parseCavaFrame(line, expectedBars, maxRange) {
    if (typeof line !== "string")
        return null
    var trimmed = line.trim()
    if (trimmed.length === 0)
        return null
    var parts = trimmed.split(";")
    if (parts.length > 0 && parts[parts.length - 1] === "")
        parts.pop()
    if (parts.length !== expectedBars)
        return null
    var range = maxRange > 0 ? maxRange : 1000
    var out = []
    for (var i = 0; i < parts.length; i++) {
        if (!/^\d+$/.test(parts[i]))
            return null
        out.push(Math.min(1.0, parseInt(parts[i], 10) / range))
    }
    return out
}

/**
 * Parse notifications.config.json text into notification service settings, preserving previous state for omitted/invalid fields.
 */
function parseNotificationsConfig(text, prevState) {
    var out = {
        defaultTimeoutMs: prevState && typeof prevState.defaultTimeoutMs === "number" ? prevState.defaultTimeoutMs : 5000,
        criticalTimeoutMs: prevState && typeof prevState.criticalTimeoutMs === "number" ? prevState.criticalTimeoutMs : 8000,
        maxVisibleCount: prevState && typeof prevState.maxVisibleCount === "number" ? prevState.maxVisibleCount : 4
    }
    try {
        var cfg = JSON.parse(text)
        if (typeof cfg.defaultTimeoutMs === "number" && cfg.defaultTimeoutMs > 0)
            out.defaultTimeoutMs = cfg.defaultTimeoutMs
        if (typeof cfg.criticalTimeoutMs === "number" && cfg.criticalTimeoutMs > 0)
            out.criticalTimeoutMs = cfg.criticalTimeoutMs
        if (typeof cfg.maxVisibleCount === "number" && cfg.maxVisibleCount > 0)
            out.maxVisibleCount = cfg.maxVisibleCount
    } catch (e) {
    }
    return out
}

/**
 * Parse workspaces.config.json text into workspace service settings, preserving previous state for omitted/invalid fields.
 */
function parseWorkspacesConfig(text, prevState) {
    var out = {
        backend: prevState && typeof prevState.backend === "string" ? prevState.backend : "sway",
        count: prevState && typeof prevState.count === "number" ? prevState.count : 10,
        pollIntervalMs: prevState && typeof prevState.pollIntervalMs === "number" ? prevState.pollIntervalMs : 1000
    }
    try {
        var cfg = JSON.parse(text)
        if (typeof cfg.backend === "string" && cfg.backend !== "")
            out.backend = cfg.backend
        if (typeof cfg.count === "number" && cfg.count > 0)
            out.count = cfg.count
        if (typeof cfg.pollIntervalMs === "number" && cfg.pollIntervalMs > 0)
            out.pollIntervalMs = cfg.pollIntervalMs
    } catch (e) {
    }
    return out
}

/**
 * Parse wallpaper.config.json text into { path }, expanding a leading "~" with `home`.
 * Keeps the previous path when the JSON is invalid or `path` is missing/empty.
 */
function parseWallpaperConfig(text, prevState, home) {
    var out = {
        path: prevState && typeof prevState.path === "string" ? prevState.path : ""
    }
    try {
        var cfg = JSON.parse(text)
        if (typeof cfg.path === "string" && cfg.path !== "") {
            var p = cfg.path
            if (home && (p === "~" || p.indexOf("~/") === 0))
                p = home + p.substring(1)
            out.path = p
        }
    } catch (e) {
    }
    return out
}

/**
 * Parse layout.config.json text into bar layout settings, preserving previous state for omitted/invalid fields.
 */
function parseLayoutConfig(text, prevState) {
    var out = {
        windowGap: prevState && typeof prevState.windowGap === "number" ? prevState.windowGap : 16,
        barMaxWidth: prevState && typeof prevState.barMaxWidth === "number" ? prevState.barMaxWidth : 720,
        screenMargin: prevState && typeof prevState.screenMargin === "number" ? prevState.screenMargin : 40,
        leftBarMaxLength: prevState && typeof prevState.leftBarMaxLength === "number" ? prevState.leftBarMaxLength : 620,
        launcherX: prevState && typeof prevState.launcherX === "number" ? prevState.launcherX : 190,
        bottomGap: prevState && typeof prevState.bottomGap === "number" ? prevState.bottomGap : 18,
        rightGap: prevState && typeof prevState.rightGap === "number" ? prevState.rightGap : 18
    }
    try {
        var cfg = JSON.parse(text)
        if (typeof cfg.windowGap === "number" && cfg.windowGap >= 0)
            out.windowGap = cfg.windowGap
        if (typeof cfg.barMaxWidth === "number" && cfg.barMaxWidth > 0)
            out.barMaxWidth = cfg.barMaxWidth
        if (typeof cfg.screenMargin === "number" && cfg.screenMargin >= 0)
            out.screenMargin = cfg.screenMargin
        if (typeof cfg.leftBarMaxLength === "number" && cfg.leftBarMaxLength > 0)
            out.leftBarMaxLength = cfg.leftBarMaxLength
        if (typeof cfg.launcherX === "number" && cfg.launcherX >= 0)
            out.launcherX = cfg.launcherX
        if (typeof cfg.bottomGap === "number" && cfg.bottomGap >= 0)
            out.bottomGap = cfg.bottomGap
        if (typeof cfg.rightGap === "number" && cfg.rightGap >= 0)
            out.rightGap = cfg.rightGap
    } catch (e) {
    }
    return out
}

/**
 * Parse scripts/system/poll-performance.sh stdout into GPU, CPU (aggregate + per-core), and Memory breakdown metrics.
 */
function parsePerformanceMetrics(text, prevState) {
    var prev = prevState || {}
    var out = {
        cpuPerc: typeof prev.cpuPerc === "number" ? prev.cpuPerc : 0.0,
        cpuTemp: typeof prev.cpuTemp === "number" ? prev.cpuTemp : 0.0,
        cpuModel: typeof prev.cpuModel === "string" ? prev.cpuModel : "Processor",
        cpuFreqGhz: typeof prev.cpuFreqGhz === "number" ? prev.cpuFreqGhz : 0.0,
        cpuMaxGhz: typeof prev.cpuMaxGhz === "number" ? prev.cpuMaxGhz : 0.0,
        load1: typeof prev.load1 === "string" ? prev.load1 : "0.00",
        load5: typeof prev.load5 === "string" ? prev.load5 : "0.00",
        load15: typeof prev.load15 === "string" ? prev.load15 : "0.00",
        procs: typeof prev.procs === "string" ? prev.procs : "0/0",
        cores: Array.isArray(prev.cores) ? prev.cores.slice() : [],
        lastCores: prev.lastCores ? Object.assign({}, prev.lastCores) : {},
        gpuPerc: typeof prev.gpuPerc === "number" ? prev.gpuPerc : 0.0,
        gpuTemp: typeof prev.gpuTemp === "number" ? prev.gpuTemp : 0.0,
        gpuName: typeof prev.gpuName === "string" ? prev.gpuName : "Graphics Processor",
        gpuType: typeof prev.gpuType === "string" ? prev.gpuType : "GPU",
        gpuCurMhz: typeof prev.gpuCurMhz === "number" ? prev.gpuCurMhz : 0,
        gpuMaxMhz: typeof prev.gpuMaxMhz === "number" ? prev.gpuMaxMhz : 1000,
        gpuMinMhz: typeof prev.gpuMinMhz === "number" ? prev.gpuMinMhz : 100,
        memPerc: typeof prev.memPerc === "number" ? prev.memPerc : 0.0,
        memUsedKib: typeof prev.memUsedKib === "number" ? prev.memUsedKib : 0.0,
        memAvailKib: typeof prev.memAvailKib === "number" ? prev.memAvailKib : 0.0,
        memFreeKib: typeof prev.memFreeKib === "number" ? prev.memFreeKib : 0.0,
        memCachedKib: typeof prev.memCachedKib === "number" ? prev.memCachedKib : 0.0,
        memBuffersKib: typeof prev.memBuffersKib === "number" ? prev.memBuffersKib : 0.0,
        memTotalKib: typeof prev.memTotalKib === "number" ? prev.memTotalKib : 1.0,
        swapTotalKib: typeof prev.swapTotalKib === "number" ? prev.swapTotalKib : 0.0,
        swapFreeKib: typeof prev.swapFreeKib === "number" ? prev.swapFreeKib : 0.0,
        swapUsedKib: typeof prev.swapUsedKib === "number" ? prev.swapUsedKib : 0.0,
        swapPerc: typeof prev.swapPerc === "number" ? prev.swapPerc : 0.0,
        memTemp: typeof prev.memTemp === "number" ? prev.memTemp : 0.0,
        lastCpuTotal: typeof prev.lastCpuTotal === "number" ? prev.lastCpuTotal : 0,
        lastCpuIdle: typeof prev.lastCpuIdle === "number" ? prev.lastCpuIdle : 0,
        lastGpuRc6Ms: typeof prev.lastGpuRc6Ms === "number" ? prev.lastGpuRc6Ms : 0,
        lastGpuUptimeMs: typeof prev.lastGpuUptimeMs === "number" ? prev.lastGpuUptimeMs : 0,
        cpuHistory: Array.isArray(prev.cpuHistory) ? prev.cpuHistory.slice() : [],
        gpuHistory: Array.isArray(prev.gpuHistory) ? prev.gpuHistory.slice() : [],
        memHistory: Array.isArray(prev.memHistory) ? prev.memHistory.slice() : []
    }
    if (typeof text !== "string" || text.trim().length === 0)
        return out

    var parsedCores = []
    var lines = text.trim().split("\n")
    for (var i = 0; i < lines.length; i++) {
        var rawLine = lines[i].trim()
        if (rawLine.length === 0)
            continue
        var parts = rawLine.split(/\s+/)
        if (parts.length < 2)
            continue
        var key = parts[0]
        if (key === "CPU" && parts.length >= 5) {
            var total = 0
            for (var c = 1; c < parts.length; c++) {
                var v = parseInt(parts[c], 10)
                if (!isNaN(v))
                    total += v
            }
            var idle = (parseInt(parts[4], 10) || 0) + (parseInt(parts[5], 10) || 0)
            if (out.lastCpuTotal > 0 && total > out.lastCpuTotal) {
                var totalDiff = total - out.lastCpuTotal
                var idleDiff = Math.max(0, idle - out.lastCpuIdle)
                out.cpuPerc = Math.max(0.0, Math.min(1.0, 1.0 - idleDiff / totalDiff))
            }
            out.lastCpuTotal = total
            out.lastCpuIdle = idle
        } else if (key === "CORE" && parts.length >= 10) {
            var coreIdx = parseInt(parts[1], 10)
            var cTotal = 0
            for (var k = 2; k <= 9 && k < parts.length; k++) {
                var cv = parseInt(parts[k], 10)
                if (!isNaN(cv))
                    cTotal += cv
            }
            var cIdle = (parseInt(parts[5], 10) || 0) + (parseInt(parts[6], 10) || 0)
            var cFreqKhz = parts.length >= 11 ? (parseInt(parts[10], 10) || 0) : 0
            var prevCore = out.lastCores[coreIdx]
            var cUsage = prevCore && typeof prevCore.usage === "number" ? prevCore.usage : 0.0
            if (prevCore && prevCore.total > 0 && cTotal > prevCore.total) {
                var cTotDiff = cTotal - prevCore.total
                var cIdlDiff = Math.max(0, cIdle - prevCore.idle)
                cUsage = Math.max(0.0, Math.min(1.0, 1.0 - cIdlDiff / cTotDiff))
            }
            out.lastCores[coreIdx] = { total: cTotal, idle: cIdle, usage: cUsage }
            parsedCores.push({
                index: coreIdx,
                usage: cUsage,
                freqGhz: cFreqKhz > 0 ? (cFreqKhz / 1000000.0) : 0.0
            })
        } else if (key === "CPU_INFO") {
            var pipeIdx = rawLine.indexOf("|")
            var leftPart = pipeIdx !== -1 ? rawLine.slice(0, pipeIdx).trim() : rawLine
            var modelPart = pipeIdx !== -1 ? rawLine.slice(pipeIdx + 1).trim() : ""
            if (modelPart.length > 0) {
                out.cpuModel = modelPart.replace(/\(R\)|\(TM\)|CPU|Processor/gi, "").replace(/\s+/g, " ").trim()
            }
            var infoParts = leftPart.split(/\s+/)
            if (infoParts.length >= 7) {
                var curKhz = parseFloat(infoParts[1]) || 0
                var maxKhz = parseFloat(infoParts[2]) || 0
                if (curKhz > 0) out.cpuFreqGhz = curKhz / 1000000.0
                if (maxKhz > 0) out.cpuMaxGhz = maxKhz / 1000000.0
                out.load1 = infoParts[3]
                out.load5 = infoParts[4]
                out.load15 = infoParts[5]
                out.procs = infoParts[6]
            }
        } else if (key === "CPU_TEMP") {
            var ct = parseFloat(parts[1])
            if (!isNaN(ct))
                out.cpuTemp = ct
        } else if (key === "GPU") {
            var gType = parts[1]
            out.gpuType = gType
            if ((gType === "NVIDIA" || gType === "GENERIC") && parts.length >= 4) {
                var gu = parseFloat(parts[2])
                var gt = parseFloat(parts[3])
                if (!isNaN(gu))
                    out.gpuPerc = Math.max(0.0, Math.min(1.0, gu / 100.0))
                if (!isNaN(gt))
                    out.gpuTemp = gt
                if (parts.length >= 6) {
                    out.gpuCurMhz = parseFloat(parts[4]) || 0
                    out.gpuMaxMhz = parseFloat(parts[5]) || 1000
                }
            } else if (gType === "INTEL" && parts.length >= 7) {
                var rc6Ms = parseFloat(parts[2])
                var upMs = parseFloat(parts[3])
                var actFreq = parseFloat(parts[4]) || 0.0
                var maxFreq = parseFloat(parts[5]) || 1000.0
                var igTemp = parseFloat(parts[6])
                var curFreq = parts.length >= 8 ? (parseFloat(parts[7]) || actFreq) : actFreq
                var minFreq = parts.length >= 9 ? (parseFloat(parts[8]) || 100.0) : 100.0
                out.gpuCurMhz = actFreq > 0 ? actFreq : curFreq
                out.gpuMaxMhz = maxFreq
                out.gpuMinMhz = minFreq
                if (!isNaN(igTemp))
                    out.gpuTemp = igTemp
                if (out.lastGpuUptimeMs > 0 && upMs > out.lastGpuUptimeMs && rc6Ms >= out.lastGpuRc6Ms) {
                    var dtMs = upMs - out.lastGpuUptimeMs
                    var dRc6 = rc6Ms - out.lastGpuRc6Ms
                    var activeRatio = Math.max(0.0, Math.min(1.0, (dtMs - dRc6) / dtMs))
                    out.gpuPerc = activeRatio
                } else if (maxFreq > 0) {
                    out.gpuPerc = Math.max(0.0, Math.min(1.0, actFreq / maxFreq))
                }
                out.lastGpuRc6Ms = rc6Ms
                out.lastGpuUptimeMs = upMs
            } else if (parts.length >= 4) {
                var nt = parseFloat(parts[3])
                if (!isNaN(nt))
                    out.gpuTemp = nt
            }
        } else if (key === "GPU_NAME") {
            var gn = rawLine.slice(8).trim()
            if (gn.length > 0) {
                out.gpuName = gn.replace(/Corporation|\(rev [0-9a-f]+\)/gi, "").replace(/\s+/g, " ").trim()
            }
        } else if (key === "MEM" && parts.length >= 3) {
            var mTotal = parseFloat(parts[1])
            var mAvail = parseFloat(parts[2])
            if (!isNaN(mTotal) && mTotal > 0 && !isNaN(mAvail)) {
                var mUsed = Math.max(0.0, mTotal - mAvail)
                out.memTotalKib = mTotal
                out.memAvailKib = mAvail
                out.memUsedKib = mUsed
                out.memPerc = Math.max(0.0, Math.min(1.0, mUsed / mTotal))
            }
            if (parts.length >= 8) {
                out.memFreeKib = parseFloat(parts[3]) || 0.0
                out.memCachedKib = parseFloat(parts[4]) || 0.0
                out.memBuffersKib = parseFloat(parts[5]) || 0.0
                out.swapTotalKib = parseFloat(parts[6]) || 0.0
                out.swapFreeKib = parseFloat(parts[7]) || 0.0
                out.swapUsedKib = Math.max(0.0, out.swapTotalKib - out.swapFreeKib)
                out.swapPerc = out.swapTotalKib > 0 ? Math.max(0.0, Math.min(1.0, out.swapUsedKib / out.swapTotalKib)) : 0.0
            }
        } else if (key === "MEM_TEMP") {
            var mt = parseFloat(parts[1])
            if (!isNaN(mt))
                out.memTemp = mt
        }
    }

    if (parsedCores.length > 0) {
        parsedCores.sort(function(a, b) { return a.index - b.index })
        out.cores = parsedCores
    }

    var maxHist = 36
    out.cpuHistory.push(out.cpuPerc)
    if (out.cpuHistory.length > maxHist) out.cpuHistory.shift()
    out.gpuHistory.push(out.gpuPerc)
    if (out.gpuHistory.length > maxHist) out.gpuHistory.shift()
    out.memHistory.push(out.memPerc)
    if (out.memHistory.length > maxHist) out.memHistory.shift()

    return out
}

// ── 9. Active Process List Telemetry & Sorting/Filtering (TopLeftBar) ──────
function parseProcessList(text, prevState) {
    var prev = prevState || {}
    var prevMap = prev.procMap || {}
    var lastTsNs = prev.lastTsNs || 0
    var lastTotalJiffies = prev.lastTotalJiffies || 0

    var tsNs = 0
    var totalJiffies = 0
    var memTotalKb = 1
    var clkTck = 100
    var uptimeSec = 1.0
    var numCores = 1
    var nextMap = {}
    var list = []

    var lines = (text || "").trim().split("\n")
    for (var i = 0; i < lines.length; i++) {
        var raw = lines[i].trim()
        if (!raw)
            continue
        var parts = raw.split("|")
        var tag = parts[0]
        if (tag === "META" && parts.length >= 7) {
            tsNs = parseFloat(parts[1]) || 0
            totalJiffies = parseFloat(parts[2]) || 1
            memTotalKb = Math.max(1, parseFloat(parts[3]) || 1)
            clkTck = Math.max(1, parseFloat(parts[4]) || 100)
            uptimeSec = Math.max(1.0, parseFloat(parts[5]) || 1.0)
            numCores = Math.max(1, parseInt(parts[6], 10) || 1)
        } else if (tag === "PROC" && parts.length >= 11) {
            var pid = parseInt(parts[1], 10) || 0
            var name = parts[2] || "process"
            var user = parts[3] || "user"
            var threads = parseInt(parts[4], 10) || 1
            var cpuTicks = parseFloat(parts[5]) || 0
            var rssKb = parseFloat(parts[6]) || 0
            var gpuNs = parseFloat(parts[7]) || 0
            var gpuMemKb = parseFloat(parts[8]) || 0
            var startTime = parseFloat(parts[9]) || 0
            var cmd = parts[10] || name

            var pOld = prevMap[pid]
            var cpuPerc = 0.0
            if (pOld && lastTotalJiffies > 0 && totalJiffies > lastTotalJiffies && cpuTicks >= pOld.cpuTicks) {
                var dTicks = cpuTicks - pOld.cpuTicks
                var dTotal = totalJiffies - lastTotalJiffies
                cpuPerc = Math.min(100.0, Math.max(0.0, (dTicks / dTotal) * 100.0))
            } else {
                var elapsedTicks = Math.max(1.0, (uptimeSec * clkTck) - startTime)
                cpuPerc = Math.min(100.0, Math.max(0.0, ((cpuTicks / elapsedTicks) / numCores) * 100.0))
            }

            var gpuPerc = 0.0
            if (pOld && lastTsNs > 0 && tsNs > lastTsNs && gpuNs >= pOld.gpuNs) {
                var dGpuNs = gpuNs - pOld.gpuNs
                var dTimeNs = tsNs - lastTsNs
                gpuPerc = Math.min(100.0, Math.max(0.0, (dGpuNs / dTimeNs) * 100.0))
            } else if (gpuNs > 0) {
                var elapsedNs = Math.max(1e6, ((uptimeSec * clkTck) - startTime) / clkTck * 1e9)
                gpuPerc = Math.min(100.0, Math.max(0.0, (gpuNs / elapsedNs) * 100.0))
            }

            var memPerc = Math.min(100.0, Math.max(0.0, (rssKb / memTotalKb) * 100.0))

            nextMap[pid] = {
                cpuTicks: cpuTicks,
                gpuNs: gpuNs
            }

            list.push({
                pid: pid,
                name: name,
                user: user,
                threads: threads,
                cpuPerc: cpuPerc,
                cpuTicks: cpuTicks,
                gpuPerc: gpuPerc,
                gpuNs: gpuNs,
                gpuMemKb: gpuMemKb,
                memPerc: memPerc,
                rssKb: rssKb,
                cmd: cmd
            })
        }
    }

    return {
        lastTsNs: tsNs > 0 ? tsNs : lastTsNs,
        lastTotalJiffies: totalJiffies > 0 ? totalJiffies : lastTotalJiffies,
        memTotalKb: memTotalKb,
        procMap: nextMap,
        processes: list
    }
}

function filterAndSortProcesses(processes, filterText, sortBy, sortDescending) {
    var src = processes || []
    var query = (filterText || "").trim().toLowerCase()
    var filtered = []

    if (!query) {
        filtered = src.slice()
    } else {
        for (var i = 0; i < src.length; i++) {
            var p = src[i]
            if ((p.name && p.name.toLowerCase().indexOf(query) !== -1) ||
                (p.cmd && p.cmd.toLowerCase().indexOf(query) !== -1) ||
                (p.user && p.user.toLowerCase().indexOf(query) !== -1) ||
                String(p.pid).indexOf(query) !== -1) {
                filtered.push(p)
            }
        }
    }

    var dir = (sortDescending === undefined || sortDescending) ? -1 : 1
    var key = sortBy || "cpu"

    filtered.sort(function(a, b) {
        var cmp = 0
        if (key === "name") {
            var na = (a.name || "").toLowerCase()
            var nb = (b.name || "").toLowerCase()
            if (na < nb) cmp = -1
            else if (na > nb) cmp = 1
            else cmp = a.pid - b.pid
            return sortDescending ? -cmp : cmp
        } else if (key === "gpu") {
            cmp = (a.gpuPerc || 0) - (b.gpuPerc || 0)
            if (Math.abs(cmp) < 1e-6) cmp = (a.gpuNs || 0) - (b.gpuNs || 0)
            if (Math.abs(cmp) < 1e-6) cmp = (a.gpuMemKb || 0) - (b.gpuMemKb || 0)
            if (Math.abs(cmp) < 1e-6) cmp = (a.cpuPerc || 0) - (b.cpuPerc || 0)
            return dir * cmp
        } else if (key === "mem") {
            cmp = (a.rssKb || 0) - (b.rssKb || 0)
            if (Math.abs(cmp) < 1e-6) cmp = (a.cpuPerc || 0) - (b.cpuPerc || 0)
            return dir * cmp
        } else {
            // Default: "cpu"
            cmp = (a.cpuPerc || 0) - (b.cpuPerc || 0)
            if (Math.abs(cmp) < 1e-6) cmp = (a.cpuTicks || 0) - (b.cpuTicks || 0)
            if (Math.abs(cmp) < 1e-6) cmp = (a.rssKb || 0) - (b.rssKb || 0)
            return dir * cmp
        }
    })

    return filtered
}

/**
 * Parse raw history text lines (format: "<name>:<count>") into a dictionary of { [name]: count }.
 */
function parseMenuHistory(text) {
    var counts = {}
    if (!text || typeof text !== "string") return counts
    var lines = text.split("\n")
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (!line) continue
        var lastColon = line.lastIndexOf(":")
        if (lastColon > 0) {
            var key = line.substring(0, lastColon).trim()
            var cnt = parseInt(line.substring(lastColon + 1).trim(), 10)
            if (key && !isNaN(cnt)) {
                counts[key] = cnt
            }
        }
    }
    return counts
}

/**
 * Return launch usage count for a given name from a history count map, checking case-insensitively as fallback.
 */
function getMenuHistoryUsage(historyMap, name) {
    if (!historyMap || !name) return 0
    if (typeof historyMap[name] === "number") return historyMap[name]
    var lower = String(name).toLowerCase()
    if (typeof historyMap[lower] === "number") return historyMap[lower]
    return 0
}

/**
 * Pure filter and sort function for applications.
 * - Filters by query (if provided).
 * - When sortOption === "most used": sorts by usage count descending; if counts are equal (or 0), sorts alphabetically.
 * - When sortOption === "alphabetically": sorts alphabetically (with query prefix match priority if query present).
 */
function filterAndSortApps(allApps, searchQuery, sortOption, historyMap) {
    var src = allApps || []
    var q = (searchQuery || "").trim().toLowerCase()
    var filtered = []

    if (!q) {
        filtered = src.slice()
    } else {
        for (var i = 0; i < src.length; i++) {
            var app = src[i]
            var name = (app.name || "").toLowerCase()
            var comment = (app.comment || "").toLowerCase()
            var gen = (app.genericName || "").toLowerCase()
            if (name.indexOf(q) !== -1 || comment.indexOf(q) !== -1 || gen.indexOf(q) !== -1) {
                filtered.push(app)
            }
        }
    }

    var isMostUsed = (sortOption === "most used")

    filtered.sort(function(a, b) {
        var nameA = a.name || ""
        var nameB = b.name || ""

        if (q) {
            var aStarts = nameA.toLowerCase().indexOf(q) === 0
            var bStarts = nameB.toLowerCase().indexOf(q) === 0
            if (aStarts !== bStarts) return aStarts ? -1 : 1
        }

        if (isMostUsed) {
            var countA = getMenuHistoryUsage(historyMap, nameA)
            var countB = getMenuHistoryUsage(historyMap, nameB)
            if (countB !== countA) return countB - countA
        }

        return nameA.localeCompare(nameB)
    })

    return filtered
}

/**
 * Pure filter and sort function for commands.
 * - If query present and not empty, optionally prefixes custom exec command.
 * - When sortOption === "most used": sorts by usage count descending; if counts equal, alphabetically.
 * - When sortOption === "alphabetically": sorts alphabetically.
 */
function filterAndSortCommands(allCommands, searchQuery, sortOption, historyMap) {
    var src = allCommands || []
    var raw = (searchQuery || "").trim()
    var q = raw.toLowerCase()
    var list = []

    if (raw.length > 0) {
        list.push({
            name: raw,
            desc: "Run with bash: " + raw,
            type: "exec",
            isCustomExec: true
        })
    }

    if (src.length === 0) {
        return list
    }

    var isMostUsed = (sortOption === "most used")

    function compareCmds(a, b) {
        var nameA = a.name || ""
        var nameB = b.name || ""
        if (isMostUsed) {
            var countA = getMenuHistoryUsage(historyMap, nameA)
            var countB = getMenuHistoryUsage(historyMap, nameB)
            if (countB !== countA) return countB - countA
        }
        return nameA.localeCompare(nameB)
    }

    if (!q) {
        var sortedAll = src.slice()
        sortedAll.sort(compareCmds)
        for (var i = 0; i < sortedAll.length && list.length < 50; i++) {
            list.push(sortedAll[i])
        }
    } else {
        var exactMatches = []
        var prefixMatches = []
        var containsMatches = []
        for (var j = 0; j < src.length; j++) {
            var c = src[j]
            var cName = (c.name || "").toLowerCase()
            if (cName === q) {
                exactMatches.push(c)
            } else if (cName.indexOf(q) === 0) {
                prefixMatches.push(c)
            } else if (cName.indexOf(q) !== -1 || (c.desc && c.desc.toLowerCase().indexOf(q) !== -1)) {
                containsMatches.push(c)
            }
        }

        exactMatches.sort(compareCmds)
        prefixMatches.sort(compareCmds)
        containsMatches.sort(compareCmds)

        var combined = exactMatches.concat(prefixMatches).concat(containsMatches)
        for (var k = 0; k < combined.length && list.length < 50; k++) {
            if (list.length > 0 && list[0].isCustomExec && (list[0].name || "").toLowerCase() === (combined[k].name || "").toLowerCase()) {
                continue
            }
            list.push(combined[k])
        }
    }

    return list
}

/**
 * Sanitize notification summary/body text by converting line breaks and HTML
 * block/break tags (<p>, <br>, <div>, etc.) into spaces, collapsing consecutive
 * whitespace, and trimming, preventing multiline overflow in compact cards and bars.
 */
function cleanNotificationText(raw) {
    if (!raw) return ""
    var s = String(raw)
    // Replace HTML block & break tags (and any attributes) with a single space
    s = s.replace(/<\/?(?:div|p|h[1-6]|li|tr|blockquote|br)(?:\s+[^>]*|\s*\/)?>/gi, " ")
    // Replace all carriage returns, newlines, tabs, and unicode line/paragraph breaks with a space
    s = s.replace(/[\r\n\t\u2028\u2029]+/g, " ")
    // Collapse multiple consecutive spaces into a single space
    s = s.replace(/\s{2,}/g, " ")
    return s.trim()
}





