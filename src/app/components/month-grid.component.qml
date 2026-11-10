// ============================================================================
// File: components/month-grid.component.qml
// Purpose: Calendar month grid displaying day headers, today highlight pill, event indicator dots, and optional month navigation.
// Public API:
//   - Properties: now, markers, navigable, weekStart, monthOffset, cell, fg, dim, accent, todayText, first, lead ...
//   - Functions:  cap(s)
// Dependencies: QtQuick, "../styles"
// ============================================================================
import QtQuick
import "../styles"

// Month calendar. Small on hover (clock pill), large inside the panel.
Item {
    id: root

    // ── input ──
    property var now: new Date()
    property var markers: ({})           // { "yyyy-m-d": true } -> dot under the day
    property bool navigable: false       // show ‹ › arrows
    property bool interactive: false     // enable hover highlight and day clicks
    property int weekStart: 0            // 0 = Sunday, 1 = Monday
    property int monthOffset: 0
    property var selectedDate: null      // Date or null

    signal daySelected(var date)
    signal homeRequested()

    // ── style ──
    property int cell: MonthGridStyle.defaultCellSize
    property color fg: MonthGridStyle.textPrimary
    property color dim: MonthGridStyle.textMuted
    property color accent: MonthGridStyle.accent
    property color todayText: MonthGridStyle.todayText

    readonly property var first: new Date(now.getFullYear(), now.getMonth() + monthOffset, 1)
    readonly property int lead: (first.getDay() - weekStart + 7) % 7
    readonly property int daysIn: new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate()

    implicitWidth: cell * 7
    implicitHeight: MonthGridStyle.headerHeight + MonthGridStyle.dowHeight + cell * 6
    width: implicitWidth
    height: implicitHeight

    function cap(s) { return s.charAt(0).toUpperCase() + s.slice(1) }

    function resetSelection() {
        root.selectedDate = null
        root.monthOffset = 0
        root.daySelected(null)
    }

    function isDayInMonth(index) {
        var dayNum = index - root.lead + 1
        return dayNum >= 1 && dayNum <= root.daysIn
    }

    function dayCursorShape(index) {
        return root.interactive ? (root.isDayInMonth(index) ? Qt.PointingHandCursor : Qt.ArrowCursor) : Qt.PointingHandCursor
    }

    Item {
        id: header
        width: root.width
        height: MonthGridStyle.headerHeight

        Row {
            anchors.centerIn: parent
            spacing: MonthGridStyle.headerTitleSpacing

            Item {
                id: homeBtnContainer
                readonly property bool active: root.interactive && (root.selectedDate !== null || root.monthOffset !== 0)
                visible: opacity > 0.01
                width: active ? MonthGridStyle.homeButtonBoxSize : 0
                height: MonthGridStyle.homeButtonBoxSize
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                opacity: active ? 1.0 : 0.0

                Behavior on width { NumberAnimation { duration: MonthGridStyle.animDurationMs; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: MonthGridStyle.animDurationMs; easing.type: Easing.OutCubic } }

                Text {
                    id: homeBtn
                    anchors.centerIn: parent
                    text: MonthGridStyle.homeGlyph
                    font.family: MonthGridStyle.iconFont
                    font.pixelSize: MonthGridStyle.homeIconFontPx
                    color: homeBtnMouse.containsMouse ? root.accent : root.dim
                    scale: !homeBtnContainer.active ? 0.2 : (homeBtnMouse.pressed ? MonthGridStyle.buttonPressedScale : (homeBtnMouse.containsMouse ? MonthGridStyle.buttonHoverScale : 1.0))
                    Behavior on color { ColorAnimation { duration: MonthGridStyle.animDurationMs } }
                    Behavior on scale { NumberAnimation { duration: MonthGridStyle.animDurationMs; easing.type: Easing.OutCubic } }

                    MouseArea {
                        id: homeBtnMouse
                        anchors.fill: parent
                        anchors.margins: -MonthGridStyle.navHitPadding
                        enabled: homeBtnContainer.active
                        hoverEnabled: homeBtnContainer.active
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.resetSelection()
                            root.homeRequested()
                        }
                    }
                }
            }

            Text {
                text: root.cap(root.first.toLocaleDateString(Qt.locale(), "MMMM yyyy"))
                color: root.fg
                font.pixelSize: MonthGridStyle.titleFontPx
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            id: prevArrow
            visible: root.navigable
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: MonthGridStyle.navArrowMargin
            text: "‹"
            color: prevArrowMouse.containsMouse ? root.accent : root.dim
            scale: prevArrowMouse.pressed ? MonthGridStyle.buttonPressedScale : (prevArrowMouse.containsMouse ? MonthGridStyle.buttonHoverScale : 1.0)
            font.pixelSize: MonthGridStyle.navArrowFontPx
            Behavior on color { ColorAnimation { duration: MonthGridStyle.animDurationMs } }
            Behavior on scale { NumberAnimation { duration: MonthGridStyle.animDurationMs; easing.type: Easing.OutCubic } }
            MouseArea {
                id: prevArrowMouse
                anchors.fill: parent
                anchors.margins: -MonthGridStyle.navHitPadding
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.monthOffset--
            }
        }

        Text {
            id: nextArrow
            visible: root.navigable
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: MonthGridStyle.navArrowMargin
            text: "›"
            color: nextArrowMouse.containsMouse ? root.accent : root.dim
            scale: nextArrowMouse.pressed ? MonthGridStyle.buttonPressedScale : (nextArrowMouse.containsMouse ? MonthGridStyle.buttonHoverScale : 1.0)
            font.pixelSize: MonthGridStyle.navArrowFontPx
            Behavior on color { ColorAnimation { duration: MonthGridStyle.animDurationMs } }
            Behavior on scale { NumberAnimation { duration: MonthGridStyle.animDurationMs; easing.type: Easing.OutCubic } }
            MouseArea {
                id: nextArrowMouse
                anchors.fill: parent
                anchors.margins: -MonthGridStyle.navHitPadding
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.monthOffset++
            }
        }
    }

    Row {
        y: MonthGridStyle.headerHeight
        Repeater {
            model: 7
            Text {
                required property int index
                width: root.cell
                height: MonthGridStyle.dowHeight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: root.dim
                font.pixelSize: MonthGridStyle.dowFontPx
                text: Qt.locale().dayName((root.weekStart + index) % 7, Locale.ShortFormat).slice(0, 3).toUpperCase()
            }
        }
    }

    Grid {
        y: MonthGridStyle.headerHeight + MonthGridStyle.dowHeight
        columns: 7
        Repeater {
            model: 42
            Item {
                id: day
                required property int index
                width: root.cell
                height: root.cell

                readonly property int dayNum: index - root.lead + 1
                readonly property bool inMonth: root.isDayInMonth(index)
                readonly property bool isToday: inMonth && root.monthOffset === 0 && dayNum === root.now.getDate()
                readonly property bool isSelected: inMonth && root.selectedDate !== null &&
                    root.first.getFullYear() === root.selectedDate.getFullYear() &&
                    root.first.getMonth() === root.selectedDate.getMonth() &&
                    dayNum === root.selectedDate.getDate()
                readonly property bool marked: inMonth && root.markers[root.first.getFullYear() + "-" + root.first.getMonth() + "-" + dayNum] === true

                Item {
                    id: dayInner
                    anchors.fill: parent
                    scale: (dayMouse.pressed && root.interactive && day.inMonth) ? MonthGridStyle.dayPressedScale :
                           ((dayMouse.containsMouse && root.interactive && day.inMonth) ?
                            (day.isToday ? MonthGridStyle.todayHoverScale : MonthGridStyle.dayHoverScale) : 1.0)
                    Behavior on scale { NumberAnimation { duration: MonthGridStyle.animDurationMs } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(day.width, day.height) - MonthGridStyle.todayPillInset
                        height: width
                        radius: width / 2
                        color: day.isSelected ? MonthGridStyle.selectedCircleColor : MonthGridStyle.hoverCircleColor
                        visible: day.inMonth && root.interactive && !day.isToday && (day.isSelected || dayMouse.containsMouse)
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(day.width, day.height) - MonthGridStyle.todayPillInset
                        height: width
                        radius: width / 2
                        color: root.accent
                        visible: day.isToday
                    }

                    Text {
                        anchors.centerIn: parent
                        text: day.inMonth ? day.dayNum : ""
                        color: day.isToday ? root.todayText :
                               (day.isSelected ? MonthGridStyle.textBright :
                               (dayMouse.containsMouse && root.interactive && day.inMonth ? MonthGridStyle.textBright : root.fg))
                        font.pixelSize: Math.round(root.cell * MonthGridStyle.dayFontRatio)
                        font.weight: (day.isToday || day.isSelected) ? Font.Bold : Font.Normal
                    }

                    Rectangle {
                        visible: day.marked
                        width: MonthGridStyle.eventDotSize
                        height: MonthGridStyle.eventDotSize
                        radius: MonthGridStyle.eventDotSize / 2
                        color: day.isToday ? root.todayText : root.accent
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: day.height - MonthGridStyle.eventDotBottomOffset
                    }
                }

                MouseArea {
                    id: dayMouse
                    anchors.fill: parent
                    enabled: root.interactive && day.inMonth
                    hoverEnabled: root.interactive && day.inMonth
                    cursorShape: root.dayCursorShape(day.index)
                    onClicked: {
                        if (!day.inMonth) return
                        var d = new Date(root.first.getFullYear(), root.first.getMonth(), day.dayNum)
                        if (root.selectedDate &&
                            root.selectedDate.getFullYear() === d.getFullYear() &&
                            root.selectedDate.getMonth() === d.getMonth() &&
                            root.selectedDate.getDate() === d.getDate()) {
                            root.selectedDate = null
                            root.daySelected(null)
                        } else {
                            root.selectedDate = d
                            root.daySelected(d)
                        }
                    }
                }
            }
        }
    }
}
