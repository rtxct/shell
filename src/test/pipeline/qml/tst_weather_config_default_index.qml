import QtQuick
import QtTest
import "../../../app/components/service-parsers.js" as ServiceParsers

TestCase {
    name: "WeatherConfigDefaultIndexTests"

    function test_parse_weather_config_extracts_and_clamps_default_index() {
        var jsonText = JSON.stringify({
            locations: [
                { name: "London", latitude: 51.5074, longitude: -0.1278 },
                { name: "New York", latitude: 40.7128, longitude: -74.006 },
                { name: "Tokyo", latitude: 35.6762, longitude: 139.6503 }
            ],
            defaultIndex: 2,
            refreshMinutes: 10
        })

        var parsed = ServiceParsers.parseWeatherConfig(jsonText)
        compare(parsed.locations.length, 3)
        compare(parsed.defaultIndex, 2)
        compare(parsed.locations[parsed.defaultIndex].name, "Tokyo")

        // Out-of-bounds defaultIndex clamps safely to 0
        var outOfBounds = ServiceParsers.parseWeatherConfig(JSON.stringify({
            locations: [
                { name: "London", latitude: 51.5074, longitude: -0.1278 }
            ],
            defaultIndex: 5
        }))
        compare(outOfBounds.defaultIndex, 0)
    }
}
