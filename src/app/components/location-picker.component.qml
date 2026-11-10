// ============================================================================
// File: components/location-picker.component.qml
// Purpose: Interactive list of configured weather locations allowing runtime city switching.
// Public API:
//   - Properties: weather, fg, accent, rowHover, rowCurrent, rowHeight, fontSize
//   - Signals:    picked()
// Dependencies: QtQuick, "../styles", "../theme"
// ============================================================================
import QtQuick
import "../styles"
import "../../../themes"

// List of the locations in weather.json. Click one to switch the weather to it.
ListView {
    id: list

    // ── input ──
    property var weather: null
    signal picked()

    // ── style ──
    property color fg: LocationPickerStyle.textPrimary
    property color accent: LocationPickerStyle.accent
    property color rowHover: LocationPickerStyle.rowHover
    property color rowCurrent: LocationPickerStyle.rowCurrent
    property real rowHeight: LocationPickerStyle.rowHeight
    property real fontSize: LocationPickerStyle.fontSize

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    model: weather ? weather.locations : []

    delegate: Rectangle {
        id: row
        required property var modelData
        required property int index
        readonly property bool current: list.weather !== null && index === list.weather.index

        width: ListView.view ? ListView.view.width : 0
        height: list.rowHeight
        radius: LocationPickerStyle.rowRadius
        color: current ? list.rowCurrent : (rowMouse.containsMouse ? list.rowHover : LocationPickerStyle.transparent)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            x: LocationPickerStyle.rowTextX
            text: row.modelData.name
            color: row.current ? list.accent : list.fg
            font.pixelSize: list.fontSize
        }
        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                list.weather.select(row.index)
                list.picked()
            }
        }
    }
}
