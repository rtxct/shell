// ============================================================================
// File: modules/middle-bar.module.qml
// Purpose: Top-center clock island module displaying live time/date when idle, mini MonthGrid on hover, and full CalendarPanel on click.
// Public API:
//   - Properties: barW
// Dependencies: QtQuick, "../components", "../styles"
// ============================================================================
import QtQuick
import "../components"
import "../styles"

// The clock island in the middle of the TOP bar.
//   idle  -> time + date
//   hover -> small month calendar with the time under it (closes when the mouse leaves)
//   click -> big panel: calendar / weather / events
Island {
    id: root

    // ── input from the parent ──
    property real barW: 720               // the open panel is as wide as the bar

    panelId: "calendar"
    title: "Calendar"
    clickPanel: calendarPanel

    readonly property bool isFloating: root.floatManager ? !!root.floatManager.isCalendarFloating : false
    readonly property bool isLeftWingFloating: root.floatManager ? !!root.floatManager.isTopLeftFloating : false
    readonly property bool isRightWingFloating: root.floatManager ? !!root.floatManager.isTopRightFloating : false

    nearWingVisibility: isLeftWingFloating ? 0.0 : 1.0
    farWingVisibility: isRightWingFloating ? 0.0 : 1.0
    Behavior on nearWingVisibility { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    Behavior on farWingVisibility { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    opacity: isFloating ? 0.0 : 1.0
    visible: opacity > 0.01 || root.isDetachingIdle || root.isDetachingOpen
    transformOrigin: Item.Top
    scale: (isFloating && !root.isActivelyDetaching) ? 0.9 : 1.0

    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    // ── shape (this island's own numbers) ──
    idleLen: MiddleBarStyle.idleLen
    idleDepth: MiddleBarStyle.idleDepth
    idleSlant: MiddleBarStyle.idleSlant
    hoverLen: MiddleBarStyle.hoverLen
    hoverDepth: MiddleBarStyle.hoverDepth
    hoverSlant: MiddleBarStyle.hoverSlant
    openLen: barW
    openDepth: MiddleBarStyle.openDepth                        // keep equal to SideBar.expandedH
    openSlant: MiddleBarStyle.openSlant                         // keep equal to SideBar.expandedSlant
    integratedStripSpan: !isFloating ? barW : 0

    // what the clock opens when clicked
    Component {
        id: calendarPanel
        CalendarPanel {
            ctl: root.ctl
        }
    }

    // ── hover: mini calendar ──
    MonthGrid {
        anchors.horizontalCenter: parent.horizontalCenter
        y: MiddleBarStyle.hoverColumnTopMargin
        cell: MiddleBarStyle.hoverCellSize
        now: root.ctl.now
        markers: root.ctl.events ? root.ctl.events.daysWithEvents : ({})
        opacity: root.hoverOpacity
        visible: opacity > 0.01
    }

    // ── idle: time + date centred in the idle pill ──
    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: Math.max(0, root.idleDepth - root.stripH - DropStyle.bottomInset)
        opacity: root.idleOpacity * Math.max(0, 1 - root.hoverFade * 3)
        visible: opacity > 0.01

        Text {
            anchors.centerIn: parent
            text: Qt.formatDateTime(root.ctl.now, "hh:mm:ss · dd/MM/yy")
            color: MiddleBarStyle.textPrimary
            font.pixelSize: MiddleBarStyle.idleClockFontPx
            font.weight: Font.DemiBold
        }
    }
}
