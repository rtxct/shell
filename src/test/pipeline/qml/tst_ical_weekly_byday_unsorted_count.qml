import QtQuick
import QtTest
import "../../../app/components/ical-parser.js" as ICalParser

TestCase {
    name: "ICalWeeklyBydayUnsortedCountTests"

    function test_unsorted_byday_preserves_chronological_count_and_until() {
        // DTSTART is Monday Oct 19, 2026. BYDAY=FR,WE,MO is listed in reverse order with COUNT=2.
        // Chronologically, the 2 occurrences must be Monday Oct 19 and Wednesday Oct 21 (NOT Friday Oct 23 + Wednesday Oct 21).
        var ics = [
            "BEGIN:VCALENDAR",
            "BEGIN:VEVENT",
            "UID:unsorted-byday@test",
            "SUMMARY:Workout",
            "DTSTART:20261019T100000",
            "DTEND:20261019T110000",
            "RRULE:FREQ=WEEKLY;COUNT=2;BYDAY=FR,WE,MO",
            "END:VEVENT",
            "END:VCALENDAR"
        ].join("\r\n")

        var refNow = new Date(2026, 9, 19, 8, 0, 0)
        var parsed = ICalParser.parseCalendar(ics, refNow, { listDays: 14, maxUpcoming: 10 })
        compare(parsed.ok, true)
        compare(parsed.upcoming.length, 2)
        compare(parsed.upcoming[0].start.getDate(), 19) // Monday Oct 19
        compare(parsed.upcoming[1].start.getDate(), 21) // Wednesday Oct 21
    }
}
