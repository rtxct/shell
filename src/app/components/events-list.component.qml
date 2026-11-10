// ============================================================================
// File: components/events-list.component.qml
// Purpose: Scrollable list of upcoming calendar events with single-day filtering, animated transitions, and full event detail inspection.
// Public API:
//   - Properties: events, selectedDate, selectedEvent, fg, dim, accent, cardColor, cardHeight, cardRadius
//   - Functions:  dayLabel(d), timeLabel(e), dateTimeSubLabel(e), durationLabel(e), recurrenceLabel(rrule), resetSelection(), message()
//   - Signals:    resetRequested()
// Dependencies: QtQuick, "../styles", QtQuick.Layouts
// ============================================================================
import QtQuick
import "../styles"
import QtQuick.Layouts

// Upcoming events from the iCal feed.
ColumnLayout {
    id: root

    // ── input ──
    property var events: null
    property var selectedDate: null      // Date or null
    property var selectedEvent: null     // Event object or null

    signal resetRequested()

    // ── style ──
    property color fg: EventsListStyle.textPrimary
    property color dim: EventsListStyle.textDim
    property color accent: EventsListStyle.accent
    property color cardColor: EventsListStyle.cardColor
    property real cardHeight: EventsListStyle.cardHeight
    property real cardRadius: EventsListStyle.cardRadius

    spacing: EventsListStyle.layoutSpacing

    property real detailProgress: selectedEvent !== null ? 1.0 : 0.0
    Behavior on detailProgress { NumberAnimation { duration: EventsListStyle.detailAnimDurationMs; easing.type: Easing.OutCubic } }

    function resetSelection() {
        root.selectedEvent = null
    }

    onSelectedDateChanged: {
        root.selectedEvent = null
    }

    function dayLabel(d) {
        var t = new Date()
        var a = new Date(t.getFullYear(), t.getMonth(), t.getDate())
        var b = new Date(d.getFullYear(), d.getMonth(), d.getDate())
        var diff = Math.round((b - a) / 86400000)
        if (diff === 0) return "Today"
        if (diff === 1) return "Tomorrow"
        return Qt.formatDate(d, "ddd d MMM")
    }

    function timeLabel(e) {
        if (!e) return ""
        if (e.allDay) return "All day"
        var s = Qt.formatTime(e.start, "hh:mm")
        return e.end > e.start ? s + " – " + Qt.formatTime(e.end, "hh:mm") : s
    }

    function durationLabel(e) {
        if (!e || !e.start || !e.end || e.allDay) return ""
        var diffMs = e.end.getTime() - e.start.getTime()
        if (diffMs <= 0) return ""
        var totalMins = Math.round(diffMs / 60000)
        var hours = Math.floor(totalMins / 60)
        var mins = totalMins % 60
        if (hours > 0 && mins > 0) return hours + "h " + mins + "m"
        if (hours > 0) return hours + "h"
        return mins + "m"
    }

    function dateTimeSubLabel(e) {
        if (!e) return ""
        if (e.allDay) return "All day"
        var s = Qt.formatTime(e.start, "hh:mm")
        var t = e.end > e.start ? s + " – " + Qt.formatTime(e.end, "hh:mm") : s
        var dur = root.durationLabel(e)
        return dur !== "" ? (t + " (" + dur + ")") : t
    }

    function recurrenceLabel(rrule) {
        if (!rrule) return ""
        var m = /FREQ=([A-Z]+)/.exec(rrule)
        var freq = m ? m[1] : ""
        if (freq === "DAILY") return "Repeats daily"
        if (freq === "WEEKLY") return "Repeats weekly"
        if (freq === "MONTHLY") return "Repeats monthly"
        if (freq === "YEARLY") return "Repeats yearly"
        return "Recurring event"
    }

    function filterEventsForDay(date, evList) {
        if (!date || !evList || evList.length === 0) return []
        var y = date.getFullYear()
        var m = date.getMonth()
        var d = date.getDate()
        var dayStart = new Date(y, m, d, 0, 0, 0, 0).getTime()
        var dayEnd = new Date(y, m, d, 23, 59, 59, 999).getTime()

        var out = []
        for (var i = 0; i < evList.length; i++) {
            var e = evList[i]
            if (!e || !e.start) continue
            var st = e.start.getTime()
            var en = e.end ? (e.allDay ? e.end.getTime() - 1 : e.end.getTime()) : st
            if (st <= dayEnd && en >= dayStart) {
                out.push(e)
            }
        }
        out.sort(function(a, b) { return a.start.getTime() - b.start.getTime() })
        return out
    }

    readonly property var activeEventsList: {
        if (!root.events) return []
        if (root.selectedDate !== null) {
            var source = (root.events.allEvents && root.events.allEvents.length > 0) ? root.events.allEvents : (root.events.upcoming || [])
            return root.filterEventsForDay(root.selectedDate, source)
        }
        return root.events.upcoming || []
    }

    property var displayedEvents: activeEventsList
    property real listOpacity: 1.0
    property real listOffsetY: 0
    property bool initialized: false

    Component.onCompleted: {
        initialized = true
    }

    onActiveEventsListChanged: {
        if (!initialized) {
            displayedEvents = activeEventsList
            return
        }
        swapAnim.restart()
    }

    SequentialAnimation {
        id: swapAnim
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "listOpacity"
                to: 0.0
                duration: EventsListStyle.fadeOutDurationMs
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: root
                property: "listOffsetY"
                to: -EventsListStyle.transitionSlideOffsetY
                duration: EventsListStyle.fadeOutDurationMs
                easing.type: Easing.InQuad
            }
        }
        ScriptAction {
            script: {
                root.displayedEvents = root.activeEventsList
                root.listOffsetY = EventsListStyle.transitionSlideOffsetY
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "listOpacity"
                to: 1.0
                duration: EventsListStyle.fadeInDurationMs
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: root
                property: "listOffsetY"
                to: 0
                duration: EventsListStyle.fadeInDurationMs
                easing.type: Easing.OutCubic
            }
        }
    }

    function message() {
        if (!events) return ""
        if (events.status === "no-url")
            return "No calendar connected. \n\n To sync your account paste your Google Calendar iCal secret into: \n\n ~/.config/quickshell/config/calendar.config.json \n\n Or create a new environment variable: \n\n QS_ICS_URL."
        if (events.status === "loading") return "Loading events…"
        if (events.status === "error") return "Couldn't fetch the calendar (check the URL and your network)."
        if (root.selectedDate !== null) {
            if (root.activeEventsList.length === 0) return "No events scheduled for this day."
            return ""
        }
        if (events.upcoming.length === 0) return "Nothing coming up."
        return ""
    }

    // ── Header Area (Cross-fading between List Overview and Event Detail) ──
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: EventsListStyle.headerHeight

        // Overview Header
        RowLayout {
            anchors.fill: parent
            spacing: 8
            opacity: 1.0 - root.detailProgress
            visible: opacity > 0.01

            Item {
                id: evHomeContainer
                readonly property bool active: root.selectedDate !== null
                visible: opacity > 0.01
                Layout.preferredWidth: active ? EventsListStyle.homeButtonBoxSize : 0
                Layout.preferredHeight: EventsListStyle.homeButtonBoxSize
                Layout.alignment: Qt.AlignVCenter
                clip: true
                opacity: active ? 1.0 : 0.0

                Behavior on Layout.preferredWidth { NumberAnimation { duration: EventsListStyle.animDurationMs; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: EventsListStyle.animDurationMs; easing.type: Easing.OutCubic } }

                Text {
                    id: evHomeIcon
                    anchors.centerIn: parent
                    text: EventsListStyle.homeGlyph
                    font.family: EventsListStyle.iconFont
                    font.pixelSize: EventsListStyle.homeIconFontPx
                    color: evHomeMouse.containsMouse ? root.accent : root.dim
                    scale: !evHomeContainer.active ? 0.2 : (evHomeMouse.pressed ? EventsListStyle.buttonPressedScale : (evHomeMouse.containsMouse ? EventsListStyle.buttonHoverScale : 1.0))
                    Behavior on color { ColorAnimation { duration: EventsListStyle.animDurationMs } }
                    Behavior on scale { NumberAnimation { duration: EventsListStyle.animDurationMs; easing.type: Easing.OutCubic } }

                    MouseArea {
                        id: evHomeMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        enabled: evHomeContainer.active && (root.detailProgress < 0.5)
                        hoverEnabled: evHomeContainer.active
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.resetRequested()
                    }
                }
            }

            Text {
                text: root.selectedDate !== null ? ("EVENTS · " + Qt.formatDate(root.selectedDate, "dd MMM").toUpperCase()) : "UPCOMING"
                color: root.dim
                font.pixelSize: EventsListStyle.headerFontPx
                font.letterSpacing: EventsListStyle.headerLetterSpacing
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Detail Header: [ ← ] EVENT DETAILS
        RowLayout {
            anchors.fill: parent
            spacing: 8
            opacity: root.detailProgress
            visible: opacity > 0.01

            Item {
                Layout.preferredWidth: EventsListStyle.homeButtonBoxSize
                Layout.preferredHeight: EventsListStyle.homeButtonBoxSize
                Layout.alignment: Qt.AlignVCenter

                Text {
                    id: evBackIcon
                    anchors.centerIn: parent
                    text: EventsListStyle.backGlyph
                    font.family: EventsListStyle.iconFont
                    font.pixelSize: EventsListStyle.backIconFontPx
                    color: evBackMouse.containsMouse ? root.accent : root.dim
                    scale: evBackMouse.pressed ? EventsListStyle.buttonPressedScale : (evBackMouse.containsMouse ? EventsListStyle.buttonHoverScale : 1.0)
                    Behavior on color { ColorAnimation { duration: EventsListStyle.animDurationMs } }
                    Behavior on scale { NumberAnimation { duration: EventsListStyle.animDurationMs; easing.type: Easing.OutCubic } }

                    MouseArea {
                        id: evBackMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        enabled: root.detailProgress > 0.5
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedEvent = null
                    }
                }
            }

            Text {
                text: "EVENT DETAILS"
                color: root.dim
                font.pixelSize: EventsListStyle.headerFontPx
                font.letterSpacing: EventsListStyle.headerLetterSpacing
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // ── Body Area (List / Detail Sliding Cross-fade) ──
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        // Overview List View
        Item {
            id: overviewLayer
            anchors.fill: parent
            opacity: 1.0 - root.detailProgress
            x: -EventsListStyle.detailSlideOffsetX * root.detailProgress
            visible: opacity > 0.001
            enabled: root.detailProgress < 0.5

            Item {
                id: contentContainer
                anchors.fill: parent
                opacity: root.listOpacity
                y: root.listOffsetY

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    visible: text !== ""
                    text: root.message()
                    color: root.dim
                    font.pixelSize: EventsListStyle.statusFontPx
                    wrapMode: Text.WordWrap
                }

                ListView {
                    anchors.fill: parent
                    clip: true
                    spacing: EventsListStyle.listSpacing
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.displayedEvents

                    delegate: Rectangle {
                        id: card
                        required property var modelData

                        width: ListView.view ? ListView.view.width : 0
                        height: root.cardHeight
                        radius: root.cardRadius
                        color: cardMouse.containsMouse ? EventsListStyle.cardHoverColor : root.cardColor
                        scale: cardMouse.pressed ? EventsListStyle.cardPressedScale : (cardMouse.containsMouse ? EventsListStyle.cardHoverScale : 1.0)

                        Behavior on color { ColorAnimation { duration: EventsListStyle.animDurationMs } }
                        Behavior on scale { NumberAnimation { duration: EventsListStyle.animDurationMs; easing.type: Easing.OutCubic } }

                        Rectangle {
                            x: EventsListStyle.accentBarX
                            width: EventsListStyle.accentBarWidth
                            height: parent.height - EventsListStyle.accentBarVerticalInset
                            anchors.verticalCenter: parent.verticalCenter
                            radius: EventsListStyle.accentBarRadius
                            color: root.accent
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: EventsListStyle.contentLeftMargin
                            anchors.right: parent.right
                            anchors.rightMargin: EventsListStyle.contentRightMargin
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: EventsListStyle.contentSpacing

                            Text {
                                width: parent.width
                                text: card.modelData.title
                                color: root.fg
                                font.pixelSize: EventsListStyle.titleFontPx
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: root.dayLabel(card.modelData.start) + "  ·  " + root.timeLabel(card.modelData)
                                      + (card.modelData.location ? "  ·  " + card.modelData.location : "")
                                color: root.dim
                                font.pixelSize: EventsListStyle.metaFontPx
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedEvent = card.modelData
                        }
                    }
                }
            }
        }

        // Full Event Details View
        Item {
            id: detailLayer
            anchors.fill: parent
            opacity: root.detailProgress
            x: EventsListStyle.detailSlideOffsetX * (1.0 - root.detailProgress)
            visible: opacity > 0.001
            enabled: root.detailProgress > 0.5

            Flickable {
                anchors.fill: parent
                contentWidth: width
                contentHeight: detailCol.implicitHeight + 16
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Column {
                    id: detailCol
                    width: parent.width
                    spacing: EventsListStyle.detailSpacing

                    // 1. Title Card
                    Rectangle {
                        width: parent.width
                        implicitHeight: Math.max(44, titleText.implicitHeight + 20)
                        radius: EventsListStyle.detailCardRadius
                        color: root.cardColor

                        Rectangle {
                            x: 10
                            width: EventsListStyle.detailAccentBarWidth
                            height: parent.height - 18
                            anchors.verticalCenter: parent.verticalCenter
                            radius: EventsListStyle.detailAccentBarRadius
                            color: root.accent
                        }

                        Text {
                            id: titleText
                            anchors.left: parent.left
                            anchors.leftMargin: 22
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            wrapMode: Text.WordWrap
                            text: root.selectedEvent ? root.selectedEvent.title : ""
                            font.pixelSize: EventsListStyle.detailTitleFontPx
                            font.weight: Font.DemiBold
                            color: root.fg
                        }
                    }

                    // 2. Date & Time Card
                    Rectangle {
                        width: parent.width
                        implicitHeight: dateTimeCol.implicitHeight + EventsListStyle.detailCardPadding * 2
                        radius: EventsListStyle.detailCardRadius
                        color: root.cardColor

                        Row {
                            anchors.fill: parent
                            anchors.margins: EventsListStyle.detailCardPadding
                            spacing: 12

                            Text {
                                text: EventsListStyle.clockGlyph
                                font.family: EventsListStyle.iconFont
                                font.pixelSize: EventsListStyle.detailIconFontPx
                                color: root.accent
                                anchors.top: parent.top
                                anchors.topMargin: 2
                            }

                            Column {
                                id: dateTimeCol
                                width: parent.width - 28
                                spacing: 4

                                Text {
                                    width: parent.width
                                    text: root.selectedEvent ? Qt.formatDate(root.selectedEvent.start, "dddd, d MMMM yyyy") : ""
                                    font.pixelSize: EventsListStyle.detailMetaFontPx
                                    font.weight: Font.Medium
                                    color: root.fg
                                }

                                Text {
                                    width: parent.width
                                    text: root.selectedEvent ? root.dateTimeSubLabel(root.selectedEvent) : ""
                                    font.pixelSize: EventsListStyle.metaFontPx
                                    color: root.dim
                                }
                            }
                        }
                    }

                    // 3. Location Card (if any)
                    Rectangle {
                        width: parent.width
                        visible: !!(root.selectedEvent && root.selectedEvent.location)
                        implicitHeight: visible ? (locCol.implicitHeight + EventsListStyle.detailCardPadding * 2) : 0
                        radius: EventsListStyle.detailCardRadius
                        color: root.cardColor

                        Row {
                            anchors.fill: parent
                            anchors.margins: EventsListStyle.detailCardPadding
                            spacing: 12

                            Text {
                                text: EventsListStyle.locationGlyph
                                font.family: EventsListStyle.iconFont
                                font.pixelSize: EventsListStyle.detailIconFontPx
                                color: root.accent
                                anchors.top: parent.top
                                anchors.topMargin: 2
                            }

                            Column {
                                id: locCol
                                width: parent.width - 28
                                spacing: 2

                                Text {
                                    text: "LOCATION"
                                    font.pixelSize: EventsListStyle.detailSectionFontPx
                                    font.letterSpacing: 1.0
                                    color: root.dim
                                }

                                Text {
                                    width: parent.width
                                    text: (root.selectedEvent && root.selectedEvent.location) ? root.selectedEvent.location : ""
                                    wrapMode: Text.WordWrap
                                    font.pixelSize: EventsListStyle.metaFontPx
                                    color: root.fg
                                }
                            }
                        }
                    }

                    // 4. Recurrence Card (if any)
                    Rectangle {
                        width: parent.width
                        visible: !!(root.selectedEvent && root.selectedEvent.rrule)
                        implicitHeight: visible ? (repeatCol.implicitHeight + EventsListStyle.detailCardPadding * 2) : 0
                        radius: EventsListStyle.detailCardRadius
                        color: root.cardColor

                        Row {
                            anchors.fill: parent
                            anchors.margins: EventsListStyle.detailCardPadding
                            spacing: 12

                            Text {
                                text: EventsListStyle.repeatGlyph
                                font.family: EventsListStyle.iconFont
                                font.pixelSize: EventsListStyle.detailIconFontPx
                                color: root.accent
                                anchors.top: parent.top
                                anchors.topMargin: 2
                            }

                            Column {
                                id: repeatCol
                                width: parent.width - 28
                                spacing: 2

                                Text {
                                    text: "RECURRENCE"
                                    font.pixelSize: EventsListStyle.detailSectionFontPx
                                    font.letterSpacing: 1.0
                                    color: root.dim
                                }

                                Text {
                                    width: parent.width
                                    text: (root.selectedEvent && root.selectedEvent.rrule) ? root.recurrenceLabel(root.selectedEvent.rrule) : ""
                                    wrapMode: Text.WordWrap
                                    font.pixelSize: EventsListStyle.metaFontPx
                                    color: root.fg
                                }
                            }
                        }
                    }

                    // 5. Description Card
                    Rectangle {
                        width: parent.width
                        implicitHeight: descCol.implicitHeight + EventsListStyle.detailCardPadding * 2
                        radius: EventsListStyle.detailCardRadius
                        color: root.cardColor

                        Column {
                            id: descCol
                            anchors.fill: parent
                            anchors.margins: EventsListStyle.detailCardPadding
                            spacing: 6

                            Text {
                                text: "DESCRIPTION"
                                font.pixelSize: EventsListStyle.detailSectionFontPx
                                font.letterSpacing: 1.0
                                color: root.dim
                            }

                            Text {
                                width: parent.width
                                text: (root.selectedEvent && root.selectedEvent.description) ? root.selectedEvent.description : "No description provided."
                                wrapMode: Text.WordWrap
                                font.pixelSize: EventsListStyle.detailDescFontPx
                                lineHeight: 1.25
                                color: (root.selectedEvent && root.selectedEvent.description) ? root.fg : root.dim
                            }
                        }
                    }
                }
            }
        }
    }
}
