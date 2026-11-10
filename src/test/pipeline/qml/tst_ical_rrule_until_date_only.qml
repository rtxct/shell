import QtQuick
import QtTest
import "../../../app/components/ical-parser.js" as ICalParser

TestCase {
    name: "ICalRruleUntilDateOnlyTests"

    function test_date_only_until_includes_timed_event_on_until_day() {
        // RFC 5545: date-only UNTIL=20261020 must include occurrences on 2026-10-20
        // even when DTSTART has a non-midnight local time (09:00:00).
        var ics = [
            "BEGIN:VCALENDAR",
            "BEGIN:VEVENT",
            "UID:until-date-only@test",
            "SUMMARY:Morning Sync",
            "DTSTART:20261018T090000",
            "DTEND:20261018T093000",
            "RRULE:FREQ=DAILY;UNTIL=20261020",
            "END:VEVENT",
            "END:VCALENDAR"
        ].join("\r\n")

        var refNow = new Date(2026, 9, 18, 8, 0, 0)
        var parsed = ICalParser.parseCalendar(ics, refNow, { listDays: 14, maxUpcoming: 10 })
        compare(parsed.ok, true)
        // Must include Oct 18, Oct 19, AND Oct 20 (3 occurrences total)
        compare(parsed.upcoming.length, 3)
        compare(parsed.upcoming[2].start.getDate(), 20)
        compare(parsed.daysWithEvents["2026-9-20"], true)
    }
}
