import QtQuick
import QtTest
import "../../../app/components/ical-parser.js" as ICalParser
import "../../../app/components/service-parsers.js" as ServiceParsers

TestCase {
    name: "ServiceAndICalParsersTests"

    function test_ical_parse_dt_and_unfolding() {
        var allDay = ICalParser.parseDT("20261018")
        compare(allDay.allDay, true)
        compare(allDay.date.getFullYear(), 2026)
        compare(allDay.date.getMonth(), 9)
        compare(allDay.date.getDate(), 18)

        var utcTime = ICalParser.parseDT("20261018T123000Z")
        compare(utcTime.allDay, false)
        compare(utcTime.date.getUTCFullYear(), 2026)
        compare(utcTime.date.getUTCMonth(), 9)
        compare(utcTime.date.getUTCDate(), 18)
        compare(utcTime.date.getUTCHours(), 12)
        compare(utcTime.date.getUTCMinutes(), 30)
    }

    function test_ical_recurring_and_overrides() {
        var ics = [
            "BEGIN:VCALENDAR",
            "BEGIN:VEVENT",
            "UID:daily-standup@test",
            "SUMMARY:Daily Standup",
            "DTSTART:20261018T090000",
            "DTEND:20261018T091500",
            "RRULE:FREQ=DAILY;COUNT=3",
            "EXDATE:20261019T090000",
            "END:VEVENT",
            "BEGIN:VEVENT",
            "UID:daily-standup@test",
            "RECURRENCE-ID:20261020T090000",
            "SUMMARY:Moved Standup",
            "DTSTART:20261020T100000",
            "DTEND:20261020T103000",
            "END:VEVENT",
            "END:VCALENDAR"
        ].join("\r\n")

        var refNow = new Date(2026, 9, 17, 12, 0, 0)
        var parsed = ICalParser.parseCalendar(ics, refNow, { listDays: 30, maxUpcoming: 10 })
        compare(parsed.ok, true)
        compare(parsed.upcoming.length, 2)
        compare(parsed.upcoming[0].title, "Daily Standup")
        compare(parsed.upcoming[0].start.getDate(), 18)
        compare(parsed.upcoming[1].title, "Moved Standup")
        compare(parsed.upcoming[1].start.getDate(), 20)
        compare(parsed.upcoming[1].start.getHours(), 10)
        compare(parsed.daysWithEvents["2026-9-18"], true)
        compare(parsed.daysWithEvents["2026-9-19"], undefined)
        compare(parsed.daysWithEvents["2026-9-20"], true)
    }

    function test_ical_description_and_location_parsing() {
        var ics = [
            "BEGIN:VCALENDAR",
            "BEGIN:VEVENT",
            "UID:detailed-event@test",
            "SUMMARY:Sprint Retrospective",
            "DESCRIPTION:Sprint retrospective and review.\\nAction items\\, Q4 roadmap\\; next steps.",
            "LOCATION:Room 402 / Zoom link",
            "DTSTART:20261018T140000",
            "DTEND:20261018T153000",
            "RRULE:FREQ=WEEKLY;INTERVAL=2",
            "END:VEVENT",
            "END:VCALENDAR"
        ].join("\r\n")

        var refNow = new Date(2026, 9, 17, 12, 0, 0)
        var parsed = ICalParser.parseCalendar(ics, refNow)
        compare(parsed.ok, true)
        compare(parsed.upcoming.length, 3)
        var ev = parsed.upcoming[0]
        compare(ev.title, "Sprint Retrospective")
        compare(ev.location, "Room 402 / Zoom link")
        compare(ev.rrule, "FREQ=WEEKLY;INTERVAL=2")
        compare(ev.description, "Sprint retrospective and review.\nAction items, Q4 roadmap; next steps.")
    }

    function test_service_parsers_weather_audio_and_workspaces() {
        var wmoClear = ServiceParsers.wmo(0)
        compare(wmoClear.text, "Clear")
        compare(wmoClear.icon, "☀️")

        var wxJson = JSON.stringify({
            current: {
                temperature_2m: 21.4,
                apparent_temperature: 20.1,
                relative_humidity_2m: 65,
                wind_speed_10m: 14.2,
                weather_code: 1,
                precipitation: 0.5,
                surface_pressure: 1015.3,
                uv_index: 4.8
            },
            daily: {
                time: ["2026-10-18", "2026-10-19"],
                weather_code: [1, 61],
                temperature_2m_max: [24.3, 21.0],
                temperature_2m_min: [16.2, 15.1],
                precipitation_sum: [0.2, 5.4],
                precipitation_probability_max: [20, 85],
                wind_speed_10m_max: [18.2, 25.1],
                uv_index_max: [5.2, 3.1]
            },
            hourly: {
                time: ["2026-10-18T00:00", "2026-10-18T12:00", "2026-10-19T12:00"],
                temperature_2m: [17.1, 23.5, 20.0],
                apparent_temperature: [16.8, 23.1, 19.5],
                weather_code: [1, 2, 61],
                precipitation_probability: [10, 20, 85]
            }
        })
        var wxParsed = ServiceParsers.parseOpenMeteoResponse(wxJson)
        compare(wxParsed.ok, true)
        compare(wxParsed.temp, "21")
        compare(wxParsed.feels, "20")
        compare(wxParsed.humidity, "65")
        compare(wxParsed.wind, "14")
        compare(wxParsed.precip, "0.5")
        compare(wxParsed.pressure, "1015")
        compare(wxParsed.uv, "4.8")
        compare(wxParsed.forecast.length, 2)
        compare(wxParsed.forecast[0].max, 24)
        compare(wxParsed.forecast[0].min, 16)
        compare(wxParsed.forecast[0].precipSum, 0.2)
        compare(wxParsed.forecast[0].precipProb, 20)
        compare(wxParsed.forecast[0].windMax, 18)
        compare(wxParsed.forecast[0].uvMax, 5.2)
        compare(wxParsed.forecast[0].hourly.length, 2)
        compare(wxParsed.forecast[0].hourly[0].pop, 10)
        compare(wxParsed.forecast[0].hourly[1].time, "12:00")
        compare(wxParsed.forecast[0].hourly[1].temp, 24)
        compare(wxParsed.forecast[0].hourly[1].pop, 20)

        // Null precipitation probability preservation (missing API data -> null, 0 -> 0)
        var wxJsonNullPop = JSON.stringify({
            current: { temperature_2m: 20 },
            daily: {
                time: ["2026-10-18"],
                weather_code: [1],
                temperature_2m_max: [22],
                temperature_2m_min: [15],
                precipitation_probability_max: [null]
            },
            hourly: {
                time: ["2026-10-18T00:00", "2026-10-18T06:00"],
                temperature_2m: [16, 18],
                precipitation_probability: [null, 0]
            }
        })
        var wxParsedNull = ServiceParsers.parseOpenMeteoResponse(wxJsonNullPop)
        compare(wxParsedNull.forecast[0].precipProb, null)
        compare(wxParsedNull.forecast[0].hourly[0].pop, null)
        compare(wxParsedNull.forecast[0].hourly[1].pop, 0)

        var volMuted = ServiceParsers.parseWpctlLine("Volume: 0.45 [MUTED]")
        compare(Math.round(volMuted.vol * 100), 45)
        compare(volMuted.muted, true)

        var volNormal = ServiceParsers.parseWpctlLine("Volume: 1.25")
        compare(Math.round(volNormal.vol * 100), 125)
        compare(volNormal.muted, false)

        var niriWs = ServiceParsers.parseNiriWorkspaces(JSON.stringify([
            { id: 10, idx: 1, is_focused: true, active_window_id: 100 },
            { id: 11, idx: 2, is_focused: false, active_window_id: null },
            { id: 12, idx: 3, is_focused: false, active_window_id: 200 }
        ]))
        compare(niriWs.length, 3)
        compare(niriWs[0].focused, true)
        compare(niriWs[0].occupied, true)
        compare(niriWs[1].occupied, false)
        compare(niriWs[2].occupied, true)

        var stripWs = ServiceParsers.stripWorkspaces(niriWs, 2)
        compare(stripWs.length, 2)
        compare(stripWs[0].number, 1)
        compare(stripWs[1].number, 3)
    }

    function test_config_parsers_hot_reload_and_partial_fallback() {
        var cal1 = ServiceParsers.parseCalendarConfig(JSON.stringify({
            icsUrl: "https://example.com/a.ics",
            refreshMinutes: 15,
            listDays: 45,
            windowStartDays: -10,
            windowEndDays: 60,
            maxUpcoming: 25,
            curlMaxTimeSeconds: 12
        }), null)
        compare(cal1.icsUrl, "https://example.com/a.ics")
        compare(cal1.refreshMinutes, 15)
        compare(cal1.listDays, 45)
        compare(cal1.windowStartDays, -10)
        compare(cal1.windowEndDays, 60)
        compare(cal1.maxUpcoming, 25)
        compare(cal1.curlMaxTimeSeconds, 12)

        // Hot-reload with updated URL and partial fields preserves previous valid fields
        var cal2 = ServiceParsers.parseCalendarConfig(JSON.stringify({
            icsUrl: "https://example.com/b.ics",
            listDays: 14
        }), cal1)
        compare(cal2.icsUrl, "https://example.com/b.ics")
        compare(cal2.listDays, 14)
        compare(cal2.refreshMinutes, 15)

        var aud = ServiceParsers.parseAudioConfig(JSON.stringify({
            pollIntervalMs: 500,
            maxVolume: 1.2,
            wheelStep: 0.05,
            activePeakThreshold: 0.01,
            spectrumEnabled: false,
            spectrumBars: 16,
            spectrumFramerate: 30,
            spectrumNoiseReduction: 60
        }), null)
        compare(aud.pollIntervalMs, 500)
        compare(Math.round(aud.maxVolume * 100), 120)
        compare(Math.round(aud.wheelStep * 100), 5)
        compare(Math.round(aud.activePeakThreshold * 1000), 10)
        compare(aud.spectrumEnabled, false)
        compare(aud.spectrumBars, 16)
        compare(aud.spectrumFramerate, 30)
        compare(aud.spectrumNoiseReduction, 60)

        var notif = ServiceParsers.parseNotificationsConfig(JSON.stringify({
            defaultTimeoutMs: 3000,
            criticalTimeoutMs: 10000,
            maxVisibleCount: 6
        }), null)
        compare(notif.defaultTimeoutMs, 3000)
        compare(notif.criticalTimeoutMs, 10000)
        compare(notif.maxVisibleCount, 6)

        var ws = ServiceParsers.parseWorkspacesConfig(JSON.stringify({
            backend: "niri",
            count: 8,
            pollIntervalMs: 500
        }), null)
        compare(ws.backend, "niri")
        compare(ws.count, 8)
        compare(ws.pollIntervalMs, 500)

        var layout = ServiceParsers.parseLayoutConfig(JSON.stringify({
            windowGap: 20,
            barMaxWidth: 800,
            screenMargin: 48,
            leftBarMaxLength: 680,
            launcherX: 210,
            bottomGap: 22,
            rightGap: 24
        }), null)
        compare(layout.windowGap, 20)
        compare(layout.barMaxWidth, 800)
        compare(layout.screenMargin, 48)
        compare(layout.leftBarMaxLength, 680)
        compare(layout.launcherX, 210)
        compare(layout.bottomGap, 22)
        compare(layout.rightGap, 24)
    }

    function test_wallpaper_config_parser() {
        var wp = ServiceParsers.parseWallpaperConfig(JSON.stringify({ path: "~/pics/bg.jpg" }), null, "/home/tester")
        compare(wp.path, "/home/tester/pics/bg.jpg")
        compare(ServiceParsers.parseWallpaperConfig(JSON.stringify({ path: "/abs/bg.png" }), null, "/home/tester").path, "/abs/bg.png")
        // Invalid JSON or empty path keeps the previous value
        compare(ServiceParsers.parseWallpaperConfig("{bad", { path: "/prev.jpg" }, "/home/tester").path, "/prev.jpg")
        compare(ServiceParsers.parseWallpaperConfig(JSON.stringify({ path: "" }), { path: "/prev.jpg" }, "/home/tester").path, "/prev.jpg")
        compare(ServiceParsers.parseWallpaperConfig("{}", null, "/home/tester").path, "")
    }

    function test_cava_frame_parser() {
        var valid = ServiceParsers.parseCavaFrame("0;250;500;1000;", 4, 1000)
        verify(valid !== null)
        compare(valid.length, 4)
        compare(Math.round(valid[0] * 100), 0)
        compare(Math.round(valid[1] * 100), 25)
        compare(Math.round(valid[2] * 100), 50)
        compare(Math.round(valid[3] * 100), 100)

        // Invalid cases return null so callers preserve the previous frame
        compare(ServiceParsers.parseCavaFrame("", 4, 1000), null)
        compare(ServiceParsers.parseCavaFrame("   ", 4, 1000), null)
        compare(ServiceParsers.parseCavaFrame(null, 4, 1000), null)
        compare(ServiceParsers.parseCavaFrame("0;250;500;", 4, 1000), null)
        compare(ServiceParsers.parseCavaFrame("0;250;500;750;1000;", 4, 1000), null)
        compare(ServiceParsers.parseCavaFrame("0;abc;500;1000;", 4, 1000), null)
    }

    function test_menu_history_parsing_and_sorting() {
        var rawHist = "firefox:10\r\nalacritty:5\ncode:2\n"
        var parsed = ServiceParsers.parseMenuHistory(rawHist)
        compare(parsed["firefox"], 10)
        compare(parsed["alacritty"], 5)
        compare(parsed["code"], 2)
        compare(parsed["unknown"], undefined)

        var apps = [
            { name: "Code" },
            { name: "Alacritty" },
            { name: "Firefox" },
            { name: "Zathura" },
            { name: "GIMP" }
        ]

        // Alphabetical sort (default)
        var alphaSorted = ServiceParsers.filterAndSortApps(apps, "", "alphabetically", parsed)
        compare(alphaSorted.length, 5)
        compare(alphaSorted[0].name, "Alacritty")
        compare(alphaSorted[1].name, "Code")
        compare(alphaSorted[2].name, "Firefox")
        compare(alphaSorted[3].name, "GIMP")
        compare(alphaSorted[4].name, "Zathura")

        // Most used sort
        // Expected order: Firefox (10), Alacritty (5), Code (2), then 0-use alphabetically: GIMP, Zathura
        var mostUsedSorted = ServiceParsers.filterAndSortApps(apps, "", "most used", parsed)
        compare(mostUsedSorted.length, 5)
        compare(mostUsedSorted[0].name, "Firefox")
        compare(mostUsedSorted[1].name, "Alacritty")
        compare(mostUsedSorted[2].name, "Code")
        compare(mostUsedSorted[3].name, "GIMP")
        compare(mostUsedSorted[4].name, "Zathura")

        // Most used sort with search query "z"
        var querySorted = ServiceParsers.filterAndSortApps(apps, "z", "most used", parsed)
        compare(querySorted.length, 1)
        compare(querySorted[0].name, "Zathura")
    }

    function test_clean_notification_text_line_breaks_and_html() {
        // Null and empty handling
        compare(ServiceParsers.cleanNotificationText(null), "")
        compare(ServiceParsers.cleanNotificationText(undefined), "")
        compare(ServiceParsers.cleanNotificationText(""), "")

        // Plain text with line breaks
        compare(ServiceParsers.cleanNotificationText("Hello\nWorld"), "Hello World")
        compare(ServiceParsers.cleanNotificationText("Hello\r\nWorld\r\nAgain"), "Hello World Again")
        compare(ServiceParsers.cleanNotificationText("Line 1\n\n\nLine 2"), "Line 1 Line 2")

        // Unicode line and paragraph separators
        compare(ServiceParsers.cleanNotificationText("First\u2028Second\u2029Third"), "First Second Third")

        // HTML break and block tags
        compare(ServiceParsers.cleanNotificationText("First<br>Second<br/>Third<br />Fourth"), "First Second Third Fourth")
        compare(ServiceParsers.cleanNotificationText("<p class=\"msg\">Hello</p><p>World</p>"), "Hello World")
        compare(ServiceParsers.cleanNotificationText("<div>Line A</div><div>Line B</div>"), "Line A Line B")

        // Mixed whitespace and tabs
        compare(ServiceParsers.cleanNotificationText("   Trim \t leading \n\n and trailing   "), "Trim leading and trailing")

        // Preservation of inline markup while converting breaks
        compare(ServiceParsers.cleanNotificationText("<b>Sender</b>:\nMessage body"), "<b>Sender</b>: Message body")
    }
}


