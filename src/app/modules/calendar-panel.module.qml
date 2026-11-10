// ============================================================================
// File: modules/calendar-panel.module.qml
// Purpose: Dual-layer calendar, events, and morphing weather forecast panel hosted inside MiddleBar and floating windows.
// Public API:
//   - Properties: ctl, leftColumnW, columnGap, leftSpacing, calendarCell, divider, weatherBg, weatherRadius, transitionDuration, view, p, cardRect
//   - Functions:  clamp01(v), showWeather(), showCalendar(), reset()
// Dependencies: QtQuick, "../components", "../styles", QtQuick.Layouts
// ============================================================================
import QtQuick
import "../components"
import "../styles"
import QtQuick.Layouts

// Content of the clock's big panel: calendar (left), weather card under it, events on the right.
// Left-clicking the weather card turns the whole panel into the weather view (the view grows
// out of the card); the arrow in the weather view turns it back into the calendar.
Item {
    id: root

    // ── input ──
    required property var ctl
    property bool isFloatingWindow: false

    // ── style ──
    readonly property real effectiveLeftColW: isFloatingWindow ? Math.max(leftColumnW, (width - columnGap - CalendarPanelStyle.dividerWidth) / 2) : leftColumnW
    property real leftColumnW: CalendarPanelStyle.leftColumnWidth
    property real columnGap: CalendarPanelStyle.columnGap
    property real leftSpacing: CalendarPanelStyle.leftColumnSpacing
    property int calendarCell: CalendarPanelStyle.monthCellSize
    property color divider: CalendarPanelStyle.dividerColor
    property color weatherBg: CalendarPanelStyle.weatherBg          // = the weather card's colour on the black panel
    property real weatherRadius: CalendarPanelStyle.weatherCardOpenRadius
    property int transitionDuration: CalendarPanelStyle.morphDurationMs

    property string view: "calendar"             // "calendar" | "weather"
    property real p: 0                           // 0 = calendar, 1 = weather
    property rect cardRect: Qt.rect(0, 0, 0, 0)  // where the weather card sits (start of the transition)
    property var selectedDate: null

    function clamp01(v) { return Math.max(0, Math.min(1, v)) }

    function showWeather() {
        var pt = weatherCard.mapToItem(root, 0, 0)
        cardRect = Qt.rect(pt.x, pt.y, weatherCard.width, weatherCard.height)
        view = "weather"
        anim.stop(); anim.to = 1; anim.easing.type = Easing.OutCubic; anim.restart()
    }

    function showCalendar() {
        view = "calendar"
        anim.stop(); anim.to = 0; anim.easing.type = Easing.InOutCubic; anim.restart()
    }

    function resetSelection() {
        root.selectedDate = null
        if (monthGrid) {
            monthGrid.resetSelection()
        }
        if (eventsList) {
            eventsList.resetSelection()
        }
    }

    function reset() { anim.stop(); view = "calendar"; p = 0; resetSelection() }

    NumberAnimation { id: anim; target: root; property: "p"; duration: root.transitionDuration }

    // a closed panel always reopens on the calendar
    Connections {
        target: root.ctl
        function onPhaseChanged() { if (root.ctl && root.ctl.phase === "closed") root.reset() }
    }

    // ───── calendar layer ─────
    Item {
        anchors.fill: parent
        opacity: 1 - root.clamp01(root.p * 1.5)
        enabled: root.p < 0.5
        visible: opacity > 0.01

        RowLayout {
            anchors.fill: parent
            spacing: root.columnGap

            ColumnLayout {
                Layout.preferredWidth: root.effectiveLeftColW
                Layout.maximumWidth: root.effectiveLeftColW
                Layout.fillHeight: true
                spacing: root.leftSpacing

                MonthGrid {
                    id: monthGrid
                    Layout.alignment: Qt.AlignHCenter
                    now: root.ctl.now
                    navigable: true
                    interactive: true
                    cell: root.calendarCell
                    markers: root.ctl.events ? root.ctl.events.daysWithEvents : ({})
                    selectedDate: root.selectedDate
                    onDaySelected: function(d) { root.selectedDate = d }
                    onHomeRequested: root.resetSelection()
                }

                WeatherCard {
                    id: weatherCard
                    Layout.preferredWidth: monthGrid.width
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillHeight: true
                    weather: root.ctl.weather
                    onOpenRequested: root.showWeather()
                }
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: CalendarPanelStyle.dividerWidth
                color: root.divider
            }

            EventsList {
                id: eventsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                events: root.ctl.events
                selectedDate: root.selectedDate
                onResetRequested: root.resetSelection()
            }
        }
    }

    // ───── weather layer: grows out of the weather card to fill the panel ─────
    Rectangle {
        id: morphCard
        x: root.cardRect.x * (1 - root.p)
        y: root.cardRect.y * (1 - root.p)
        width: root.cardRect.width + (root.width - root.cardRect.width) * root.p
        height: root.cardRect.height + (root.height - root.cardRect.height) * root.p
        radius: root.weatherRadius
        color: root.weatherBg
        clip: true
        opacity: root.clamp01(root.p * 3)
        visible: root.p > 0.001

        WeatherView {
            anchors.fill: parent
            weather: root.ctl.weather
            enabled: root.p > 0.5
            opacity: root.clamp01((root.p - 0.15) / 0.85)
            onBackRequested: root.showCalendar()
        }
    }
}
