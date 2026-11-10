import QtQuick
import QtTest
import "../../../../themes"
import "../../../app/styles"
import "../../../app/components"

Item {
    width: 700
    height: 600

    QtObject {
        id: mockWeather
        property string status: "ok"
        property int index: 0
        property var locations: [
            { name: "London", latitude: 51.5074, longitude: -0.1278 },
            { name: "New York", latitude: 40.7128, longitude: -74.006 }
        ]
        property string locName: locations[index].name
        property int temp: 18
        property int feels: 17
        property int humidity: 65
        property int wind: 11
        property string desc: "Partly cloudy"
        property string icon: "⛅"
        property var forecast: [
            { day: "Sat", date: "17 Oct", icon: "⛅", desc: "Partly cloudy", max: 19, min: 11, rain: 20 }
        ]
        function select(i) {
            index = i
        }
    }

    WeatherCard {
        id: card
        width: 260
        height: 92
        weather: mockWeather
    }

    WeatherView {
        id: view
        y: 110
        width: 600
        height: 360
        weather: mockWeather
    }

    LocationPicker {
        id: picker
        x: 300
        y: 0
        width: 220
        height: 90
        weather: mockWeather
    }

    PanelPlaceholder {
        id: placeholder
        x: 540
        y: 0
        width: 120
        height: 80
        text: "Custom Widget"
    }

    SignalSpy {
        id: openSpy
        target: card
        signalName: "openRequested"
    }

    SignalSpy {
        id: backSpy
        target: view
        signalName: "backRequested"
    }

    SignalSpy {
        id: pickedSpy
        target: picker
        signalName: "picked"
    }

    TestCase {
        name: "WeatherAndLocationPickerTests"
        when: windowShown

        function init() {
            mockWeather.status = "ok"
            mockWeather.index = 0
            card.picking = false
            view.picking = false
            view.detailOpen = false
            openSpy.clear()
            backSpy.clear()
            pickedSpy.clear()
        }

        function test_weather_card_clicks_and_messages() {
            compare(card.ready, true)
            // Left click emits openRequested
            mouseClick(card, 40, 40, Qt.LeftButton)
            compare(openSpy.count, 1)

            // Right click toggles picking mode
            mouseClick(card, 40, 40, Qt.RightButton)
            compare(card.picking, true)

            // Left click while picking closes picking without emitting openRequested
            mouseClick(card, 40, 40, Qt.LeftButton)
            compare(card.picking, false)
            compare(openSpy.count, 1)

            // Status messages
            mockWeather.status = "no-locations"
            compare(card.ready, false)
            compare(card.message(), "Add coordinates to weather.json")
            mockWeather.status = "error"
            compare(card.message(), "Weather unavailable")
            mockWeather.status = "loading"
            compare(card.message(), "Loading weather…")
        }

        function test_location_picker_selection() {
            compare(mockWeather.index, 0)
            // Click the second row ("New York" at y = rowHeight + rowHeight/2 = 42)
            mouseClick(picker, 50, 42, Qt.LeftButton)
            compare(pickedSpy.count, 1)
            compare(mockWeather.index, 1)
            compare(mockWeather.locName, "New York")
        }

        function test_weather_view_back_signal() {
            compare(view.ready, true)
            // Click the back arrow on top-left of WeatherView
            mouseClick(view, 12, 20, Qt.LeftButton)
            compare(backSpy.count, 1)
        }

        function test_weather_view_detail_toggle_and_back() {
            compare(view.detailOpen, false)
            view.openDetail(mockWeather.forecast[0], 0)
            compare(view.detailOpen, true)
            compare(view.selectedDayIndex, 0)

            // Clicking back arrow while in detail mode closes detail without emitting backRequested
            mouseClick(view, 12, 20, Qt.LeftButton)
            compare(view.detailOpen, false)
            compare(backSpy.count, 0)

            // Clicking back arrow while in overview emits backRequested
            mouseClick(view, 12, 20, Qt.LeftButton)
            compare(backSpy.count, 1)
        }

        function test_panel_placeholder() {
            compare(placeholder.text, "Custom Widget")
        }

        function test_weather_animations_and_scrollbar() {
            compare(WeatherCardStyle.cardHoverScale > 1.0, true)
            compare(WeatherCardStyle.cardPressedScale < 1.0, true)
            compare(WeatherCardStyle.animDurationMs > 0, true)

            compare(WeatherViewStyle.arrowHoverScale, 1.04)
            compare(WeatherViewStyle.arrowPressedScale, 0.99)
            compare(WeatherViewStyle.buttonHoverScale, 1.03)
            compare(WeatherViewStyle.buttonPressedScale, 0.99)
            compare(WeatherViewStyle.heroHoverScale, 1.03)
            compare(WeatherViewStyle.heroPressedScale, 0.99)
            compare(WeatherViewStyle.forecastItemHoverScale, 1.02)
            compare(WeatherViewStyle.forecastItemPressedScale, 0.99)
            compare(WeatherViewStyle.hourlyItemHoverScale, 1.03)
            compare(WeatherViewStyle.forecastRightMargin, 14)
            compare(WeatherViewStyle.forecastBottomMargin, 50)
            compare(WeatherViewStyle.scrollBarWidth, 3)

            compare(card.scale, 1.0)
        }
    }
}
