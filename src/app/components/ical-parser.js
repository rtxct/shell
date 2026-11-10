// ============================================================================
// File: components/ical-parser.js
// Purpose: Pure, deterministic RFC 5545 iCal (.ics) parser and recurring
//          event expander (DAILY, WEEKLY, MONTHLY, YEARLY, INTERVAL, COUNT,
//          UNTIL, EXDATE, RECURRENCE-ID).
//          Extracted as a stateless JS library (.pragma library) so both
//          modules/events-service.module.qml and Qt Quick Test cases
//          (qmltestrunner) can execute and verify it without Quickshell I/O.
// ============================================================================
.pragma library

var DOW = { SU: 0, MO: 1, TU: 2, WE: 3, TH: 4, FR: 5, SA: 6 }

/** Return a canonical local date key "yyyy-m-d" (month is 0-based). */
function key(d) {
    return d.getFullYear() + "-" + d.getMonth() + "-" + d.getDate()
}

/** Return a new Date shifted by `n` calendar days preserving local wall-clock time. */
function addDays(d, n) {
    return new Date(d.getFullYear(), d.getMonth(), d.getDate() + n,
                    d.getHours(), d.getMinutes(), d.getSeconds())
}

/** Unescape RFC 5545 text escapes (\n, \,, \;, \\). */
function unesc(s) {
    return s.replace(/\\n/gi, " ").replace(/\\,/g, ",").replace(/\\;/g, ";").replace(/\\\\/g, "\\")
}

/** Unescape RFC 5545 description text escapes (\n -> newline, \,, \;, \\). */
function unescDesc(s) {
    return s.replace(/\\n/gi, "\n").replace(/\\,/g, ",").replace(/\\;/g, ";").replace(/\\\\/g, "\\")
}

/** Parse an RFC 5545 date or date-time value into { date: Date, allDay: bool } or null. */
function parseDT(val) {
    var m = /^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?$/.exec(val.trim())
    if (!m) return null
    var allDay = (m[4] === undefined)
    var d
    if (allDay) d = new Date(+m[1], +m[2] - 1, +m[3])
    else if (m[7]) d = new Date(Date.UTC(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6]))
    else d = new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6])
    return { date: d, allDay: allDay }
}

/** Expand one parsed VEVENT into occurrence start dates inside [winStart, winEnd]. */
function occurrences(ev, winStart, winEnd, dur) {
    var s = ev.start
    var out = []
    if (!ev.rrule) { out.push(s); return out }

    var r = {}
    ev.rrule.split(";").forEach(function (p) { var kv = p.split("="); r[kv[0]] = kv[1] })

    var freq = r.FREQ
    var interval = parseInt(r.INTERVAL || "1")
    if (!(interval > 0)) interval = 1
    var count = r.COUNT ? parseInt(r.COUNT) : -1
    var until = r.UNTIL ? parseDT(r.UNTIL) : null
    var untilD = until ? (until.allDay
        ? new Date(until.date.getFullYear(), until.date.getMonth(), until.date.getDate(), 23, 59, 59, 999)
        : until.date) : null
    var limit = (untilD && untilD < winEnd) ? untilD : winEnd

    var n = 0
    function push(d) {
        if (d < s) return true
        if (untilD && d > untilD) return false
        if (count > 0 && n >= count) return false
        n++
        if (d.getTime() + dur >= winStart.getTime() && d <= winEnd) out.push(d)
        return d <= limit
    }

    if (freq === "DAILY") {
        for (var d = new Date(s), g = 0; d <= limit && g < 4000; d = addDays(d, interval), g++)
            if (!push(d)) break
    } else if (freq === "WEEKLY") {
        var days = r.BYDAY ? r.BYDAY.split(",").map(function (x) { return DOW[x.slice(-2)] }).sort(function (a, b) { return a - b })
                           : [s.getDay()]
        var ws = addDays(s, -s.getDay())
        for (var w = 0; w < 600; w++) {
            var base = addDays(ws, w * 7 * interval)
            if (base > limit) break
            for (var i = 0; i < days.length; i++) {
                var c = addDays(base, days[i])
                if (!push(c) && c > limit) return out
            }
        }
    } else if (freq === "MONTHLY") {
        var mspec = r.BYDAY ? /^(-?\d+)?([A-Z]{2})$/.exec(r.BYDAY.split(",")[0]) : null
        var mdays = r.BYMONTHDAY ? r.BYMONTHDAY.split(",").map(function (x) { return parseInt(x) })
                                 : [s.getDate()]
        for (var m = 0; m < 240; m++) {
            var y = s.getFullYear(), mo = s.getMonth() + m * interval
            if (new Date(y, mo, 1) > limit) break
            if (mspec && mspec[1]) {
                var nth = parseInt(mspec[1]), wd = DOW[mspec[2]], cand
                if (nth > 0) {
                    var f = new Date(y, mo, 1)
                    cand = new Date(y, mo, 1 + ((wd - f.getDay() + 7) % 7) + (nth - 1) * 7,
                                    s.getHours(), s.getMinutes(), s.getSeconds())
                } else {
                    var l = new Date(y, mo + 1, 0)
                    cand = new Date(y, mo, l.getDate() - ((l.getDay() - wd + 7) % 7) + (nth + 1) * 7,
                                    s.getHours(), s.getMinutes(), s.getSeconds())
                }
                if (cand.getMonth() === ((mo % 12) + 12) % 12 && !push(cand)) return out
            } else {
                for (var j = 0; j < mdays.length; j++) {
                    var c = new Date(y, mo, mdays[j], s.getHours(), s.getMinutes(), s.getSeconds())
                    if (c.getDate() === mdays[j] && !push(c)) return out
                }
            }
        }
    } else if (freq === "YEARLY") {
        for (var k = 0; k < 50; k++) {
            var c = new Date(s.getFullYear() + k * interval, s.getMonth(), s.getDate(),
                             s.getHours(), s.getMinutes(), s.getSeconds())
            if (!push(c)) break
        }
    } else {
        out.push(s)
    }
    return out
}

/**
 * Parse a complete RFC 5545 VCALENDAR string relative to `nowDate` and options.
 * Returns { ok: bool, upcoming: Array, daysWithEvents: Object }.
 */
function parseCalendar(text, nowDate, opts) {
    if (!text || text.indexOf("BEGIN:VCALENDAR") === -1) {
        return { ok: false, upcoming: [], daysWithEvents: {} }
    }
    var options = opts || {}
    var windowStartDays = (options.windowStartDays !== undefined) ? options.windowStartDays : -40
    var windowEndDays = (options.windowEndDays !== undefined) ? options.windowEndDays : 90
    var listDays = (options.listDays !== undefined) ? options.listDays : 30
    var maxUpcoming = (options.maxUpcoming !== undefined) ? options.maxUpcoming : 60

    var unfolded = text.replace(/\r\n/g, "\n").replace(/\n[ \t]/g, "")
    var lines = unfolded.split("\n")

    var evs = []
    var cur = null
    for (var i = 0; i < lines.length; i++) {
        var ln = lines[i]
        if (ln === "BEGIN:VEVENT") { cur = { exdates: {} }; continue }
        if (ln === "END:VEVENT") { if (cur && cur.start) evs.push(cur); cur = null; continue }
        if (!cur) continue
        var col = ln.indexOf(":")
        if (col === -1) continue
        var nm = ln.substring(0, col).split(";")[0].toUpperCase()
        var val = ln.substring(col + 1)

        if (nm === "SUMMARY") cur.title = unesc(val)
        else if (nm === "DESCRIPTION") cur.description = unescDesc(val)
        else if (nm === "LOCATION") cur.location = unesc(val)
        else if (nm === "UID") cur.uid = val.trim()
        else if (nm === "STATUS" && val.trim().toUpperCase() === "CANCELLED") cur.cancelled = true
        else if (nm === "RRULE") cur.rrule = val.trim()
        else if (nm === "DTSTART") { var p = parseDT(val); if (p) { cur.start = p.date; cur.allDay = p.allDay } }
        else if (nm === "DTEND") { var q = parseDT(val); if (q) cur.end = q.date }
        else if (nm === "RECURRENCE-ID") { var r = parseDT(val); if (r) cur.recId = r.date }
        else if (nm === "EXDATE") {
            val.split(",").forEach(function (v) {
                var x = parseDT(v)
                if (x) cur.exdates[key(x.date)] = true
            })
        }
    }

    var now = nowDate || new Date()
    var today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    var winStart = addDays(today, windowStartDays)
    var winEnd = addDays(today, windowEndDays)

    var overrides = {}
    evs.forEach(function (e) { if (e.recId && e.uid) overrides[e.uid + "|" + key(e.recId)] = true })

    var list = []
    var marks = {}
    evs.forEach(function (e) {
        if (!e.start || e.cancelled) return
        var dur = e.end ? (e.end.getTime() - e.start.getTime()) : (e.allDay ? 86400000 : 0)
        var starts = occurrences(e, winStart, winEnd, dur)
        starts.forEach(function (st) {
            if (e.rrule && !e.recId) {
                var k = key(st)
                if (e.exdates[k] || overrides[e.uid + "|" + k]) return
            }
            var en = new Date(st.getTime() + dur)
            list.push({
                title: e.title || "(no title)",
                start: st,
                end: en,
                allDay: !!e.allDay,
                location: e.location || "",
                description: e.description || "",
                rrule: e.rrule || ""
            })
            var lastDay = e.allDay ? new Date(en.getTime() - 1) : en
            for (var d = new Date(st.getFullYear(), st.getMonth(), st.getDate()), c2 = 0;
                 d <= lastDay && c2 < 31; d = addDays(d, 1), c2++)
                marks[key(d)] = true
        })
    })

    var horizon = addDays(today, listDays)
    var up = list.filter(function (x) {
        var endRef = x.allDay ? x.end.getTime() - 1 : Math.max(x.end.getTime(), x.start.getTime())
        return endRef >= now.getTime() && x.start < horizon
    })
    up.sort(function (a, b) { return a.start - b.start })

    return {
        ok: true,
        upcoming: up.slice(0, maxUpcoming),
        allEvents: list,
        daysWithEvents: marks
    }
}
