// ============================================================================
// File: styles/calendar-panel.style.qml
// Purpose: Layout margins, morph transition timing, and Theme tokens for CalendarPanel.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color dividerColor: Theme.surfaceWhite08
    readonly property color weatherBg: Theme.weatherPanelSurface

    readonly property real leftColumnWidth: 270
    readonly property real columnGap: 32
    readonly property real leftColumnSpacing: 14
    readonly property int monthCellSize: 38
    readonly property real dividerWidth: 1
    readonly property real weatherCardOpenRadius: 14
    readonly property int morphDurationMs: 280
}
