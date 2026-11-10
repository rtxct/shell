import QtQuick
import QtTest
import "../../../../themes"
import "../../../app/styles"
import "../../../app/components"

Item {
    width: 600
    height: 500

    QtObject {
        id: mockEvents
        property string status: "ok"
        property var upcoming: [
            {
                title: "Architecture Review",
                start: new Date(2026, 9, 18, 9, 0, 0),
                end: new Date(2026, 9, 18, 10, 30, 0),
                allDay: false
            },
            {
                title: "Release Freeze",
                start: new Date(2026, 9, 19, 0, 0, 0),
                end: new Date(2026, 9, 20, 0, 0, 0),
                allDay: true
            }
        ]
    }

    MonthGrid {
        id: grid
        now: new Date(2026, 9, 17, 12, 0, 0) // Oct 17, 2026 (Oct 1, 2026 is Thursday -> getDay() == 4)
        navigable: true
        markers: ({ "2026-9-18": true })
    }

    EventsList {
        id: evList
        y: 260
        width: 300
        height: 220
        events: mockEvents
    }

    TestCase {
        name: "MonthGridAndEventsListTests"
        when: windowShown

        function init() {
            grid.monthOffset = 0
            mockEvents.status = "ok"
        }

        function test_month_grid_calendar_calculations() {
            compare(grid.first.getFullYear(), 2026)
            compare(grid.first.getMonth(), 9) // October (0-indexed)
            compare(grid.daysIn, 31)
            compare(grid.lead, 4) // Oct 1, 2026 is Thursday
            compare(grid.cap("october"), "October")
        }

        function test_month_grid_navigation_clicks() {
            compare(grid.monthOffset, 0)
            // Click next month arrow ('›' on right side of header)
            mouseClick(grid, grid.width - 10, 15)
            compare(grid.monthOffset, 1)
            compare(grid.first.getMonth(), 10) // November
            compare(grid.daysIn, 30)

            // Click prev month arrow ('‹' on left side of header) twice
            mouseClick(grid, 10, 15)
            compare(grid.monthOffset, 0)
            mouseClick(grid, 10, 15)
            compare(grid.monthOffset, -1)
            compare(grid.first.getMonth(), 8) // September
        }

        function test_month_grid_interactive_day_selection_and_home_reset() {
            compare(grid.interactive, false)
            compare(grid.selectedDate, null)

            grid.interactive = true
            compare(grid.interactive, true)

            // Oct 1, 2026 is Thursday -> lead = 4.
            // Oct 18, 2026 -> index = 4 + 18 - 1 = 21. Row = Math.floor(21 / 7) = 3, Col = 21 % 7 = 0.
            var cell = grid.cell
            var topOffset = MonthGridStyle.headerHeight + MonthGridStyle.dowHeight
            var targetX = 0 * cell + cell / 2
            var targetY = topOffset + 3 * cell + cell / 2

            // Click day 18
            mouseClick(grid, targetX, targetY)
            verify(grid.selectedDate !== null)
            compare(grid.selectedDate.getFullYear(), 2026)
            compare(grid.selectedDate.getMonth(), 9)
            compare(grid.selectedDate.getDate(), 18)

            // Click day 18 again -> deselects
            mouseClick(grid, targetX, targetY)
            compare(grid.selectedDate, null)

            // Set selection and test home reset
            grid.selectedDate = new Date(2026, 9, 20)
            grid.monthOffset = 1
            grid.resetSelection()
            compare(grid.selectedDate, null)
            compare(grid.monthOffset, 0)

            grid.interactive = false
        }

        function test_events_list_single_day_filtering_and_empty_message() {
            compare(evList.selectedDate, null)
            compare(evList.activeEventsList.length, 2)
            compare(evList.message(), "")

            // Filter for Oct 18: only "Architecture Review"
            evList.selectedDate = new Date(2026, 9, 18)
            compare(evList.activeEventsList.length, 1)
            compare(evList.activeEventsList[0].title, "Architecture Review")
            compare(evList.message(), "")

            // Filter for Oct 19: only "Release Freeze"
            evList.selectedDate = new Date(2026, 9, 19)
            compare(evList.activeEventsList.length, 1)
            compare(evList.activeEventsList[0].title, "Release Freeze")
            compare(evList.message(), "")

            // Filter for Oct 25 (empty day)
            evList.selectedDate = new Date(2026, 9, 25)
            compare(evList.activeEventsList.length, 0)
            compare(evList.message(), "No events scheduled for this day.")

            // Reset back to general upcoming list
            evList.selectedDate = null
            compare(evList.activeEventsList.length, 2)
            compare(evList.message(), "")
        }

        function test_month_grid_and_events_list_style_tokens() {
            verify(MonthGridStyle.hoverCircleColor !== undefined)
            verify(MonthGridStyle.selectedCircleColor !== undefined)
            verify(MonthGridStyle.textBright !== undefined)
            compare(MonthGridStyle.homeGlyph, "")
            compare(MonthGridStyle.homeIconFontPx, 14)
            compare(MonthGridStyle.buttonHoverScale, 1.04)
            compare(MonthGridStyle.buttonPressedScale, 0.99)
            compare(MonthGridStyle.dayHoverScale, 1.04)
            compare(MonthGridStyle.dayPressedScale, 0.99)
            compare(MonthGridStyle.todayHoverScale, 1.04)

            compare(EventsListStyle.homeGlyph, "")
            compare(EventsListStyle.homeIconFontPx, 13)
            compare(EventsListStyle.homeButtonBoxSize, 20)
            compare(EventsListStyle.backGlyph, "←")
            compare(EventsListStyle.clockGlyph, "")
            compare(EventsListStyle.locationGlyph, "")
            compare(EventsListStyle.repeatGlyph, "")
            compare(EventsListStyle.buttonHoverScale, 1.04)
            compare(EventsListStyle.buttonPressedScale, 0.99)
            compare(EventsListStyle.cardHoverScale, 1.015)
            compare(EventsListStyle.cardPressedScale, 0.99)
            compare(EventsListStyle.fadeOutDurationMs, 90)
            compare(EventsListStyle.fadeInDurationMs, 140)
            compare(EventsListStyle.transitionSlideOffsetY, 6)
            compare(EventsListStyle.detailSlideOffsetX, 20)
            compare(EventsListStyle.detailAnimDurationMs, 220)
        }

        function test_events_list_formatting_and_messages() {
            var today = new Date()
            var tomorrow = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1)
            compare(evList.dayLabel(today), "Today")
            compare(evList.dayLabel(tomorrow), "Tomorrow")

            compare(evList.timeLabel(mockEvents.upcoming[0]), "09:00 – 10:30")
            compare(evList.timeLabel(mockEvents.upcoming[1]), "All day")

            compare(evList.message(), "")
            mockEvents.status = "loading"
            compare(evList.message(), "Loading events…")
            mockEvents.status = "error"
            verify(evList.message().indexOf("Couldn't fetch") >= 0)
            mockEvents.status = "no-url"
            verify(evList.message().indexOf("No calendar connected") >= 0)
        }

        function test_events_list_detail_inspection_and_reset() {
            compare(evList.selectedEvent, null)
            compare(evList.detailProgress, 0.0)

            // Duration and subtitle formatting
            compare(evList.durationLabel(mockEvents.upcoming[0]), "1h 30m")
            compare(evList.dateTimeSubLabel(mockEvents.upcoming[0]), "09:00 – 10:30 (1h 30m)")
            compare(evList.dateTimeSubLabel(mockEvents.upcoming[1]), "All day")

            // Recurrence formatting
            compare(evList.recurrenceLabel("FREQ=DAILY"), "Repeats daily")
            compare(evList.recurrenceLabel("FREQ=WEEKLY;INTERVAL=2"), "Repeats weekly")
            compare(evList.recurrenceLabel("FREQ=MONTHLY"), "Repeats monthly")
            compare(evList.recurrenceLabel("FREQ=YEARLY"), "Repeats yearly")
            compare(evList.recurrenceLabel("FREQ=HOURLY"), "Recurring event")

            // Select an event
            evList.selectedEvent = mockEvents.upcoming[0]
            compare(evList.selectedEvent.title, "Architecture Review")
            tryCompare(evList, "detailProgress", 1.0, 500)

            // Reset via resetSelection()
            evList.resetSelection()
            compare(evList.selectedEvent, null)
            tryCompare(evList, "detailProgress", 0.0, 500)

            // Select again, then change selectedDate -> should reset selectedEvent
            evList.selectedEvent = mockEvents.upcoming[1]
            verify(evList.selectedEvent !== null)
            evList.selectedDate = new Date(2026, 9, 18)
            compare(evList.selectedEvent, null)
            evList.selectedDate = null
        }

        function test_month_grid_cursor_shape_hover_vs_interactive() {
            // When interactive is false (hover island mini-calendar mode)
            grid.interactive = false
            compare(grid.dayCursorShape(0), Qt.PointingHandCursor)
            compare(grid.dayCursorShape(10), Qt.PointingHandCursor)

            // When interactive is true (open CalendarPanel)
            grid.interactive = true
            compare(grid.isDayInMonth(10), true)
            compare(grid.dayCursorShape(10), Qt.PointingHandCursor)
            compare(grid.isDayInMonth(0), false)
            compare(grid.dayCursorShape(0), Qt.ArrowCursor)

            grid.interactive = false
        }
    }
}
