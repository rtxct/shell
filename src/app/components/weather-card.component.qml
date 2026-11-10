// ============================================================================
// File: components/weather-card.component.qml
// Purpose: Compact weather summary card displaying current condition icon, temperature, city name, and description.
// Public API:
//   - Properties: weather, picking, fg, dim, ready
//   - Signals:    openRequested()
//   - Functions:  message()
// Dependencies: QtQuick, "../styles"
// ============================================================================
import QtQuick
import "../styles"

// Compact weather card.
//   left click  -> asks the panel to turn into the full weather view
//   right click -> choose another location from weather.json
Rectangle {
    id: card

    // ── input ──
    property var weather: null
    property bool picking: false
    signal openRequested()

    // ── style ──
    property color fg: WeatherCardStyle.textPrimary
    property color dim: WeatherCardStyle.textDim

    readonly property bool ready: weather !== null && weather.status === "ok"

    radius: WeatherCardStyle.cardRadius
    color: cardMouse.containsMouse ? WeatherCardStyle.cardHoverColor : WeatherCardStyle.cardColor
    border.width: 1
    border.color: WeatherCardStyle.cardBorderColor
    clip: true
    transformOrigin: Item.Center
    z: cardMouse.containsMouse ? 2 : 1
    scale: cardMouse.pressed ? WeatherCardStyle.cardPressedScale : (cardMouse.containsMouse ? WeatherCardStyle.cardHoverScale : 1.0)
    Behavior on scale {
        NumberAnimation {
            duration: WeatherCardStyle.animDurationMs
            easing.type: Easing.OutCubic
        }
    }
    Behavior on color {
        ColorAnimation {
            duration: WeatherCardStyle.animDurationMs
            easing.type: Easing.OutCubic
        }
    }

    property real pickProgress: card.picking ? 1.0 : 0.0
    Behavior on pickProgress {
        NumberAnimation {
            duration: WeatherCardStyle.pickerAnimDurationMs
            easing.type: card.picking ? Easing.OutCubic : Easing.InOutCubic
        }
    }

    onVisibleChanged: if (!visible) picking = false

    // Top specular highlight line
    Rectangle {
        width: Math.max(0, parent.width - parent.radius * 1.6)
        height: 1.0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 1.0
        color: WeatherCardStyle.glassRimHighlight
    }

    function message() {
        if (!weather) return ""
        if (weather.status === "no-locations") return "Add coordinates to weather.json"
        if (weather.status === "error") return "Weather unavailable"
        return "Loading weather…"
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                if (card.weather && card.weather.locations.length > 0) card.picking = !card.picking
            } else if (card.picking) {
                card.picking = false
            } else {
                card.openRequested()
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !card.ready && card.pickProgress < 0.05
        text: card.message()
        color: card.dim
        font.pixelSize: WeatherCardStyle.statusFontPx
        opacity: 1.0 - card.pickProgress
    }

    Column {
        id: weatherContent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: WeatherCardStyle.contentMargins
        y: WeatherCardStyle.contentMargins + WeatherCardStyle.pickerSlideOffsetY * card.pickProgress
        spacing: WeatherCardStyle.columnSpacing
        opacity: card.ready ? (1.0 - card.pickProgress) : 0.0
        visible: opacity > 0.01

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: WeatherCardStyle.headerRowSpacing
            Text {
                text: card.weather ? card.weather.icon : ""
                font.pixelSize: WeatherCardStyle.iconFontPx
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: card.weather ? card.weather.temp + "°C" : ""
                    color: card.fg
                    font.pixelSize: WeatherCardStyle.tempFontPx
                    font.weight: Font.Bold
                }
                Text {
                    width: WeatherCardStyle.descWidth
                    text: card.weather ? card.weather.locName + "  ·  " + card.weather.desc : ""
                    color: card.dim
                    font.pixelSize: WeatherCardStyle.descFontPx
                    elide: Text.ElideRight
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.weather ? "Feels " + card.weather.feels + "° · " + card.weather.humidity + "% · " + card.weather.wind + " km/h" : ""
            color: card.dim
            font.pixelSize: WeatherCardStyle.statsFontPx
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: WeatherCardStyle.forecastSpacing
            Repeater {
                model: card.weather ? card.weather.forecast.slice(0, WeatherCardStyle.forecastPreviewCount) : []
                Text {
                    required property var modelData
                    width: WeatherCardStyle.forecastItemWidth
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData.day + " " + modelData.icon + " " + modelData.max + "/" + modelData.min
                    color: card.fg
                    font.pixelSize: WeatherCardStyle.forecastFontPx
                }
            }
        }
    }

    LocationPicker {
        id: locationPicker
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: WeatherCardStyle.pickerMargins
        height: parent.height - 2 * WeatherCardStyle.pickerMargins
        y: WeatherCardStyle.pickerMargins - (1.0 - card.pickProgress) * (height + WeatherCardStyle.pickerMargins)
        opacity: card.pickProgress
        visible: card.pickProgress > 0.01
        enabled: card.pickProgress > 0.5
        weather: card.weather
        onPicked: card.picking = false
    }
}
