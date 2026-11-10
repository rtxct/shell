// ============================================================================
// File: modules/events-service.module.qml
// Purpose: RFC 5545 iCal feed parser and recurring event expansion service watching config/calendar.config.json.
// Public API:
//   - Properties: icsUrl, refreshMinutes, listDays, windowStartDays, windowEndDays, maxUpcoming, curlMaxTimeSeconds, upcoming, daysWithEvents, status, url, dow
//   - Functions:  applyConfig(text), key(d), addDays(d, n), unesc(s), parseDT(val), occurrences(ev, winStart, winEnd, dur), handle(text), refresh()
// Dependencies: Quickshell, Quickshell.Io, QtQuick, "../components/ical-parser.js"
// ============================================================================
import Quickshell
import Quickshell.Io
import QtQuick
import "../components/ical-parser.js" as ICalParser
import "../components/service-parsers.js" as ServiceParsers

// Reads an .ics feed (Google Calendar "secret iCal address", or any file:// / https:// ics).
// Configuration comes from config/calendar.config.json (or QS_ICS_URL env fallback).
// Supports basic recurrence: DAILY / WEEKLY(+BYDAY) / MONTHLY(+BYMONTHDAY, 2TU, -1FR) / YEARLY,
// INTERVAL, COUNT, UNTIL, EXDATE and edited single instances.
// Limitation: TZID times are treated as local time.
Item {
    id: root

    property string icsUrl: ""
    property int refreshMinutes: 10
    property int listDays: 30
    property int windowStartDays: -40
    property int windowEndDays: 90
    property int maxUpcoming: 60
    property int curlMaxTimeSeconds: 20

    property var upcoming: []                // [{title, start, end, allDay, location}]
    property var allEvents: []               // all occurrences within the active date window
    property var daysWithEvents: ({})        // { "yyyy-m-d": true }  (m is 0-based)
    property string status: "idle"           // idle | no-url | loading | ok | error
    property string lastRawIcs: ""

    readonly property string url: icsUrl !== "" ? icsUrl : (Quickshell.env("QS_ICS_URL") || "")

    readonly property var dow: ICalParser.DOW

    function applyConfig(text) {
        var prevUrl = root.url
        var parsed = ServiceParsers.parseCalendarConfig(text, root)
        root.icsUrl = parsed.icsUrl
        root.refreshMinutes = parsed.refreshMinutes
        root.listDays = parsed.listDays
        root.windowStartDays = parsed.windowStartDays
        root.windowEndDays = parsed.windowEndDays
        root.maxUpcoming = parsed.maxUpcoming
        root.curlMaxTimeSeconds = parsed.curlMaxTimeSeconds

        if (root.url !== prevUrl) {
            root.lastRawIcs = ""
        } else if (root.lastRawIcs !== "") {
            root.handle(root.lastRawIcs)
        }
        refresh()
    }

    function key(d) { return ICalParser.key(d) }
    function addDays(d, n) { return ICalParser.addDays(d, n) }
    function unesc(s) { return ICalParser.unesc(s) }
    function parseDT(val) { return ICalParser.parseDT(val) }
    function occurrences(ev, winStart, winEnd, dur) { return ICalParser.occurrences(ev, winStart, winEnd, dur) }

    function handle(text) {
        var res = ICalParser.parseCalendar(text, new Date(), {
            windowStartDays: root.windowStartDays,
            windowEndDays: root.windowEndDays,
            listDays: root.listDays,
            maxUpcoming: root.maxUpcoming
        })
        if (!res.ok) {
            if (status !== "ok") status = "error"
            return
        }
        root.lastRawIcs = text
        upcoming = res.upcoming
        allEvents = res.allEvents || res.upcoming
        daysWithEvents = res.daysWithEvents
        status = "ok"
    }

    function refresh() {
        if (root.url === "") {
            if (proc.running) proc.running = false
            lastRawIcs = ""
            upcoming = []
            allEvents = []
            daysWithEvents = ({})
            status = "no-url"
            return
        }
        if (proc.running) proc.running = false
        status = "loading"
        proc.running = true
    }

    FileView {
        id: configFile
        path: Quickshell.shellPath("config/calendar.config.json")
        watchChanges: true
        onFileChanged: configFile.reload()
        onLoaded: root.applyConfig(configFile.text())
    }

    Process {
        id: proc
        command: ["curl", "-sfL", "--max-time", String(root.curlMaxTimeSeconds), root.url]
        stdout: StdioCollector {
            onStreamFinished: root.handle(this.text)
        }
    }

    Timer {
        interval: root.refreshMinutes * 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
