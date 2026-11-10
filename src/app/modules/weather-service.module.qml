// ============================================================================
// File: modules/weather-service.module.qml
// Purpose: Open-Meteo weather fetcher service watching config/weather.config.json and polling current/7-day forecast data.
// Public API:
//   - Properties: refreshMinutes, locations, index, status, locName, desc, icon, temp, feels, humidity, wind, forecast ...
//   - Functions:  wmo(code), parseLocations(text), select(i), fetch(), handle(t)
// Dependencies: Quickshell, Quickshell.Io, QtQuick, "../components/service-parsers.js"
// ============================================================================
import Quickshell
import Quickshell.Io
import QtQuick
import "../components/service-parsers.js" as ServiceParsers

// Weather by coordinates (Open-Meteo, free, no API key; needs curl).
// Locations and refresh interval come from config/weather.config.json:
//   { "refreshMinutes": 20, "defaultIndex": 0, "locations": [ { "name": "Paris", "latitude": 48.8566, "longitude": 2.3522 }, ... ] }
// The first one is the default; the weather card in the clock panel lets you switch.
Item {
    id: root

    property int refreshMinutes: 20

    property var locations: []
    property int index: 0
    property string status: "loading"      // loading | ok | error | no-locations

    property string locName: ""
    property string desc: ""
    property string icon: ""
    property string temp: ""
    property string feels: ""
    property string humidity: ""
    property string wind: ""
    property string precip: ""
    property string pressure: ""
    property string uv: ""
    property var forecast: []

    property bool initialLoaded: false
    property int lastDefaultIndex: -1
    property bool queued: false

    // WMO weather codes -> emoji + text
    function wmo(code) { return ServiceParsers.wmo(code) }

    function parseLocations(text) {
        var parsed = ServiceParsers.parseWeatherConfig(text)
        if (parsed.refreshMinutes !== null)
            root.refreshMinutes = parsed.refreshMinutes
        locations = parsed.locations
        if (!initialLoaded || parsed.defaultIndex !== lastDefaultIndex || index >= locations.length) {
            index = parsed.defaultIndex
            initialLoaded = true
        }
        lastDefaultIndex = parsed.defaultIndex
        if (locations.length === 0) { status = "no-locations"; return }
        fetch()
    }

    function select(i) {
        if (i < 0 || i >= locations.length) return
        index = i
        fetch()
    }

    function fetch() {
        if (locations.length === 0) return
        if (proc.running) { queued = true; return }
        var l = locations[index]
        locName = l.name
        if (status !== "ok") status = "loading"
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + l.latitude
                + "&longitude=" + l.longitude
                + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,precipitation,surface_pressure,uv_index"
                + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,wind_speed_10m_max,uv_index_max"
                + "&hourly=temperature_2m,apparent_temperature,weather_code,precipitation_probability"
                + "&forecast_days=16&timezone=auto"
        proc.command = ["curl", "-sfL", "--max-time", "15", url]
        proc.running = true
    }

    function handle(t) {
        if (queued) return                 // a newer location was picked meanwhile
        var res = ServiceParsers.parseOpenMeteoResponse(t)
        if (!res.ok) {
            status = "error"
            return
        }
        temp = res.temp
        feels = res.feels
        humidity = res.humidity
        wind = res.wind
        precip = res.precip
        pressure = res.pressure
        uv = res.uv
        desc = res.desc
        icon = res.icon
        forecast = res.forecast
        status = "ok"
    }

    FileView {
        id: file
        path: Quickshell.shellPath("config/weather.config.json")
        watchChanges: true
        onFileChanged: file.reload()
        onLoaded: root.parseLocations(file.text())
        onLoadFailed: root.status = "no-locations"
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: root.handle(this.text)
        }
        onRunningChanged: {
            if (!running && root.queued) {
                root.queued = false
                root.fetch()
            }
        }
    }

    Timer {
        interval: root.refreshMinutes * 60000
        running: true
        repeat: true
        onTriggered: root.fetch()
    }
}
