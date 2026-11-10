// ============================================================================
// File: components/weather-view.component.qml
// Purpose: Full expanded weather forecast view with current metrics, 16-day scrollable forecast list,
//          interactive day details with hourly forecast timeline, and embedded LocationPicker.
// Public API:
//   - Properties: weather, fg, dim, accent, cardColor, iconFont, backGlyph, headerH,
//                 picking, ready, pickProgress, detailOpen, selectedDay, selectedDayIndex, detailProgress
//   - Signals:    backRequested()
//   - Functions:  openDetail(dayData, idx), closeDetail()
// Dependencies: QtQuick, "../styles"
// ============================================================================
import QtQuick
import "../styles"

Item {
    id: root

    property var weather: null
    signal backRequested()

    property color fg: WeatherViewStyle.textPrimary
    property color dim: WeatherViewStyle.textDim
    property color accent: WeatherViewStyle.accent
    property color cardColor: WeatherViewStyle.cardColor
    property string iconFont: WeatherViewStyle.iconFont
    property string backGlyph: "\uDB80\uDF0D"
    property real headerH: WeatherViewStyle.headerHeight

    property bool picking: false
    property bool detailOpen: false
    property var selectedDay: null
    property int selectedDayIndex: 0

    onVisibleChanged: if (!visible) { picking = false; detailOpen = false }

    property real pickProgress: root.picking ? 1.0 : 0.0
    Behavior on pickProgress {
        NumberAnimation {
            duration: WeatherViewStyle.pickerAnimDurationMs
            easing.type: root.picking ? Easing.OutCubic : Easing.InOutCubic
        }
    }

    property real detailProgress: root.detailOpen ? 1.0 : 0.0
    Behavior on detailProgress {
        NumberAnimation {
            duration: WeatherViewStyle.detailAnimDurationMs
            easing.type: root.detailOpen ? Easing.OutCubic : Easing.InOutCubic
        }
    }

    readonly property bool ready: weather !== null && weather.status === "ok"

    function openDetail(dayData, idx) {
        if (!dayData) return
        selectedDay = dayData
        selectedDayIndex = (idx !== undefined && idx !== null) ? idx : 0
        detailOpen = true
    }

    function closeDetail() {
        detailOpen = false
    }

    // ── header ──
    Item {
        id: header
        x: WeatherViewStyle.headerPaddingX
        y: 0
        width: root.width - 2 * WeatherViewStyle.headerPaddingX
        height: root.headerH

        // ── Detail mode header: [ ←  Go Back ] on the left ──
        Item {
            id: goBackButton
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: backArrow.width
            height: parent.height
            visible: root.detailOpen

            Text {
                id: backArrow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.backGlyph
                font.family: root.iconFont
                font.pixelSize: WeatherViewStyle.backIconFontPx
                color: goBackMouse.containsMouse ? root.accent : root.fg
                transformOrigin: Item.Center
                scale: goBackMouse.pressed ? WeatherViewStyle.arrowPressedScale : (goBackMouse.containsMouse ? WeatherViewStyle.arrowHoverScale : 1.0)
                Behavior on scale {
                    NumberAnimation {
                        duration: WeatherViewStyle.buttonAnimDurationMs
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: WeatherViewStyle.buttonAnimDurationMs
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                id: goBackMouse
                anchors.fill: parent
                anchors.leftMargin: -WeatherViewStyle.headerPaddingX
                anchors.rightMargin: -WeatherViewStyle.backHitPadding
                anchors.topMargin: -WeatherViewStyle.backHitPadding
                anchors.bottomMargin: -WeatherViewStyle.backHitPadding
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeDetail()
            }
        }

        // ── Overview mode header: [ ← ] and [ City Name ▾ ] ──
        Item {
            anchors.fill: parent
            visible: !root.detailOpen

            Text {
                id: back
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.backGlyph
                font.family: root.iconFont
                font.pixelSize: WeatherViewStyle.backIconFontPx
                color: backMouse.containsMouse ? root.accent : root.fg
                transformOrigin: Item.Center
                scale: backMouse.pressed ? WeatherViewStyle.arrowPressedScale : (backMouse.containsMouse ? WeatherViewStyle.arrowHoverScale : 1.0)
                Behavior on scale {
                    NumberAnimation {
                        duration: WeatherViewStyle.buttonAnimDurationMs
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: WeatherViewStyle.buttonAnimDurationMs
                        easing.type: Easing.OutCubic
                    }
                }
                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    anchors.leftMargin: -WeatherViewStyle.headerPaddingX
                    anchors.rightMargin: -WeatherViewStyle.backHitPadding
                    anchors.topMargin: -WeatherViewStyle.backHitPadding
                    anchors.bottomMargin: -WeatherViewStyle.backHitPadding
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }
            }

            Item {
                id: locButton
                anchors.left: back.right
                anchors.leftMargin: WeatherViewStyle.locLeftMargin
                anchors.verticalCenter: parent.verticalCenter
                width: locRow.width
                height: locRow.height
                transformOrigin: Item.Center
                scale: locMouse.pressed ? WeatherViewStyle.buttonPressedScale : (locMouse.containsMouse ? WeatherViewStyle.buttonHoverScale : 1.0)
                Behavior on scale {
                    NumberAnimation {
                        duration: WeatherViewStyle.buttonAnimDurationMs
                        easing.type: Easing.OutCubic
                    }
                }

                Row {
                    id: locRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Text {
                        text: root.weather ? root.weather.locName : ""
                        color: (locMouse.containsMouse || root.picking) ? root.accent : root.fg
                        font.pixelSize: WeatherViewStyle.locNameFontPx
                        font.weight: Font.DemiBold
                        Behavior on color {
                            ColorAnimation {
                                duration: WeatherViewStyle.buttonAnimDurationMs
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Text {
                        text: "▾"
                        color: (locMouse.containsMouse || root.picking) ? root.accent : root.fg
                        font.pixelSize: WeatherViewStyle.locNameFontPx
                        rotation: root.pickProgress * 180
                        transformOrigin: Item.Center
                        Behavior on rotation {
                            NumberAnimation {
                                duration: WeatherViewStyle.pickerAnimDurationMs
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: WeatherViewStyle.buttonAnimDurationMs
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                MouseArea {
                    id: locMouse
                    anchors.fill: parent
                    anchors.margins: -WeatherViewStyle.locHitPadding
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picking = !root.picking
                }
            }
        }
    }

    // ── body ──
    Item {
        id: body
        x: WeatherViewStyle.contentPaddingX
        y: root.headerH + WeatherViewStyle.bodyTopGap
        width: root.width - 2 * WeatherViewStyle.contentPaddingX
        height: root.height - y
        clip: true

        LocationPicker {
            id: locationPicker
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height
            y: -(1.0 - root.pickProgress) * (height + WeatherViewStyle.pickerSlideOffsetY)
            opacity: root.pickProgress
            visible: root.pickProgress > 0.01
            enabled: root.pickProgress > 0.5
            weather: root.weather
            onPicked: root.picking = false
        }

        Text {
            anchors.centerIn: parent
            visible: !root.ready && root.pickProgress < 0.05
            text: root.weather && root.weather.status === "error" ? "Weather unavailable" : "Loading weather…"
            color: root.dim
            font.pixelSize: WeatherViewStyle.statusFontPx
            opacity: 1.0 - root.pickProgress
        }

        Item {
            id: weatherContent
            anchors.fill: parent
            y: WeatherViewStyle.pickerSlideOffsetY * root.pickProgress
            opacity: root.ready ? (1.0 - root.pickProgress) : 0.0
            visible: opacity > 0.01
            enabled: root.pickProgress < 0.5

            // ───── Layer 1: Overview (Hero + 16-Day Scrollable Forecast) ─────
            Item {
                id: overviewLayer
                anchors.fill: parent
                x: -root.detailProgress * WeatherViewStyle.detailSlideOffsetX
                opacity: 1.0 - root.detailProgress
                visible: opacity > 0.01
                enabled: root.detailProgress < 0.5

                Item {
                    id: nowCard
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: WeatherViewStyle.heroWidth

                    Column {
                        id: now
                        anchors.left: parent.left
                        anchors.top: parent.top
                        width: parent.width
                        spacing: WeatherViewStyle.heroSpacing
                        transformOrigin: Item.TopLeft
                        scale: heroMouse.pressed ? WeatherViewStyle.heroPressedScale : (heroMouse.containsMouse ? WeatherViewStyle.heroHoverScale : 1.0)
                        Behavior on scale {
                            NumberAnimation {
                                duration: WeatherViewStyle.buttonAnimDurationMs
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            text: root.weather ? root.weather.icon : ""
                            font.pixelSize: WeatherViewStyle.heroIconFontPx
                        }
                        Text {
                            text: root.weather ? root.weather.temp + "°C" : ""
                            color: heroMouse.containsMouse ? root.accent : root.fg
                            font.pixelSize: WeatherViewStyle.heroTempFontPx
                            font.weight: Font.Bold
                            Behavior on color {
                                ColorAnimation {
                                    duration: WeatherViewStyle.buttonAnimDurationMs
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                        Text {
                            text: root.weather ? root.weather.desc : ""
                            color: root.dim
                            font.pixelSize: WeatherViewStyle.heroDescFontPx
                        }
                        Item { width: 1; height: WeatherViewStyle.heroStatsGap }
                        Text {
                            text: root.weather ? "Feels like  " + root.weather.feels + "°C" : ""
                            color: root.fg
                            font.pixelSize: WeatherViewStyle.statsFontPx
                        }
                        Text {
                            text: root.weather ? "Humidity  " + root.weather.humidity + "%" : ""
                            color: root.fg
                            font.pixelSize: WeatherViewStyle.statsFontPx
                        }
                        Text {
                            text: root.weather ? "Wind  " + root.weather.wind + " km/h" : ""
                            color: root.fg
                            font.pixelSize: WeatherViewStyle.statsFontPx
                        }
                    }

                    MouseArea {
                        id: heroMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.weather && root.weather.forecast && root.weather.forecast.length > 0) {
                                root.openDetail(root.weather.forecast[0], 0)
                            }
                        }
                    }
                }

                ListView {
                    id: forecastList
                    anchors.left: nowCard.right
                    anchors.leftMargin: WeatherViewStyle.forecastLeftMargin
                    anchors.right: parent.right
                    anchors.rightMargin: WeatherViewStyle.forecastRightMargin
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: WeatherViewStyle.forecastBottomMargin
                    clip: true
                    spacing: WeatherViewStyle.forecastSpacing
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.weather ? root.weather.forecast : []

                    delegate: Rectangle {
                        id: day
                        required property var modelData
                        required property int index
                        width: ListView.view ? ListView.view.width : 0
                        height: WeatherViewStyle.forecastRowHeight
                        radius: WeatherViewStyle.forecastCardRadius
                        color: dayMouse.containsMouse ? WeatherViewStyle.cardHoverColor : root.cardColor
                        transformOrigin: Item.Center
                        z: dayMouse.containsMouse ? 2 : 1
                        scale: dayMouse.pressed ? WeatherViewStyle.forecastItemPressedScale : (dayMouse.containsMouse ? WeatherViewStyle.forecastItemHoverScale : 1.0)
                        Behavior on scale {
                            NumberAnimation {
                                duration: WeatherViewStyle.buttonAnimDurationMs
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: WeatherViewStyle.buttonAnimDurationMs
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            x: WeatherViewStyle.forecastDayX
                            anchors.verticalCenter: parent.verticalCenter
                            width: WeatherViewStyle.forecastDayWidth
                            text: day.modelData.day
                            color: root.fg
                            font.pixelSize: WeatherViewStyle.forecastDayFontPx
                            font.weight: Font.Medium
                        }
                        Text {
                            x: WeatherViewStyle.forecastIconX
                            anchors.verticalCenter: parent.verticalCenter
                            text: day.modelData.icon
                            font.pixelSize: WeatherViewStyle.forecastIconFontPx
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: WeatherViewStyle.forecastTempRightMargin
                            anchors.verticalCenter: parent.verticalCenter
                            text: day.modelData.max + "°  /  " + day.modelData.min + "°"
                            color: root.fg
                            font.pixelSize: WeatherViewStyle.forecastTempFontPx
                        }

                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openDetail(day.modelData, day.index)
                        }
                    }
                }

                // ── Non-clickable visual scroll indicator ──
                Item {
                    id: scrollBarTrack
                    anchors.right: parent.right
                    anchors.rightMargin: WeatherViewStyle.scrollBarRightMargin
                    anchors.top: forecastList.top
                    anchors.bottom: forecastList.bottom
                    width: WeatherViewStyle.scrollBarWidth
                    visible: forecastList.visibleArea.heightRatio < 1.0

                    Rectangle {
                        id: scrollBarThumb
                        x: 0
                        y: Math.min(scrollBarTrack.height - height, Math.max(0, forecastList.visibleArea.yPosition * scrollBarTrack.height))
                        width: WeatherViewStyle.scrollBarWidth
                        height: Math.max(16, Math.min(scrollBarTrack.height, forecastList.visibleArea.heightRatio * scrollBarTrack.height))
                        radius: WeatherViewStyle.scrollBarRadius
                        color: WeatherViewStyle.scrollBarColor
                    }
                }
            }

            // ───── Layer 2: Day Detail View (Hourly Timeline & Day Estimates) ─────
            Item {
                id: detailLayer
                anchors.fill: parent
                x: (1.0 - root.detailProgress) * WeatherViewStyle.detailSlideOffsetX
                opacity: root.detailProgress
                visible: root.detailProgress > 0.01
                enabled: root.detailProgress > 0.5

                Column {
                    anchors.fill: parent
                    spacing: WeatherViewStyle.detailSectionGap

                    // Top Hero Row: Selected Day Summary (Transparent background)
                    Item {
                        width: parent.width
                        height: 64

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Text {
                                text: root.selectedDay ? root.selectedDay.icon : "☀️"
                                font.pixelSize: WeatherViewStyle.detailHeroIconFontPx
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: root.selectedDay
                                          ? (root.selectedDayIndex === 0
                                             ? "Today · " + root.selectedDay.day + ", " + (root.selectedDay.dateFormatted || "")
                                             : root.selectedDay.day + ", " + (root.selectedDay.dateFormatted || ""))
                                          : ""
                                    color: root.fg
                                    font.pixelSize: WeatherViewStyle.detailTitleFontPx
                                    font.weight: Font.Bold
                                }

                                Text {
                                    text: root.selectedDay
                                          ? root.selectedDay.desc + "  ·  High " + root.selectedDay.max + "°C  /  Low " + root.selectedDay.min + "°C"
                                          : ""
                                    color: root.dim
                                    font.pixelSize: WeatherViewStyle.detailSubtitleFontPx
                                }

                                Text {
                                    text: root.selectedDayIndex === 0 && root.weather
                                          ? "Current: " + root.weather.temp + "°C  (Feels like " + root.weather.feels + "°C)"
                                          : ""
                                    color: root.accent
                                    font.pixelSize: WeatherViewStyle.metricSubFontPx
                                    visible: root.selectedDayIndex === 0 && root.weather !== null
                                }
                            }
                        }
                    }

                    // Middle Section: Hourly Forecast Timeline
                    Column {
                        width: parent.width
                        spacing: 6

                        Text {
                            text: "FORECAST BY TIME"
                            color: WeatherViewStyle.textSubtle
                            font.pixelSize: WeatherViewStyle.detailSectionHeaderFontPx
                            font.weight: Font.Bold
                        }

                        Item {
                            width: parent.width
                            height: WeatherViewStyle.hourlyCardHeight

                            ListView {
                                anchors.fill: parent
                                orientation: ListView.Horizontal
                                spacing: WeatherViewStyle.hourlyCardSpacing
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                model: (root.selectedDay && root.selectedDay.hourly && root.selectedDay.hourly.length > 0)
                                       ? root.selectedDay.hourly
                                       : []

                                delegate: Rectangle {
                                    id: hourlyItem
                                    required property var modelData
                                    width: WeatherViewStyle.hourlyCardWidth
                                    height: WeatherViewStyle.hourlyCardHeight
                                    radius: WeatherViewStyle.hourlyCardRadius
                                    color: hourlyMouse.containsMouse ? WeatherViewStyle.cardHoverColor : root.cardColor
                                    transformOrigin: Item.Center
                                    z: hourlyMouse.containsMouse ? 2 : 1
                                    scale: hourlyMouse.containsMouse ? WeatherViewStyle.hourlyItemHoverScale : 1.0
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: WeatherViewStyle.buttonAnimDurationMs
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: WeatherViewStyle.buttonAnimDurationMs
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Item {
                                        anchors.fill: parent
                                        anchors.margins: 6

                                        Text {
                                            anchors.top: parent.top
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: hourlyItem.modelData.time
                                            color: WeatherViewStyle.textDim
                                            font.pixelSize: WeatherViewStyle.hourlyTimeFontPx
                                        }

                                        Item {
                                            anchors.top: parent.top
                                            anchors.topMargin: 16
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: parent.width
                                            height: 24

                                            Text {
                                                anchors.centerIn: parent
                                                text: hourlyItem.modelData.icon
                                                font.pixelSize: WeatherViewStyle.hourlyIconFontPx
                                            }
                                        }

                                        Text {
                                            anchors.top: parent.top
                                            anchors.topMargin: 42
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: hourlyItem.modelData.temp + "°"
                                            color: root.fg
                                            font.pixelSize: WeatherViewStyle.hourlyTempFontPx
                                            font.weight: Font.Bold
                                        }

                                        Text {
                                            anchors.bottom: parent.bottom
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: (hourlyItem.modelData.pop !== null && hourlyItem.modelData.pop !== undefined && !isNaN(hourlyItem.modelData.pop))
                                                  ? hourlyItem.modelData.pop + "%"
                                                  : "N/A"
                                            color: (hourlyItem.modelData.pop !== null && hourlyItem.modelData.pop !== undefined && !isNaN(hourlyItem.modelData.pop))
                                                   ? WeatherViewStyle.textSecondary
                                                   : WeatherViewStyle.textDim
                                            font.pixelSize: WeatherViewStyle.hourlyPopFontPx
                                        }
                                    }

                                    MouseArea {
                                        id: hourlyMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !root.selectedDay || !root.selectedDay.hourly || root.selectedDay.hourly.length === 0
                                    text: "Hourly forecast updates with live API feed"
                                    color: WeatherViewStyle.textDim
                                    font.pixelSize: WeatherViewStyle.hourlyTimeFontPx
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: WeatherViewStyle.dividerColor
                    }

                    // Bottom Section: Day Estimates & Metrics Grid
                    Column {
                        width: parent.width
                        spacing: 6

                        Text {
                            text: "ESTIMATE FORECAST & METRICS"
                            color: WeatherViewStyle.textSubtle
                            font.pixelSize: WeatherViewStyle.detailSectionHeaderFontPx
                            font.weight: Font.Bold
                        }

                        Grid {
                            width: parent.width
                            columns: 4
                            spacing: WeatherViewStyle.metricGridSpacing

                            // Metric 1: Precipitation
                            Rectangle {
                                width: Math.floor((parent.width - 3 * WeatherViewStyle.metricGridSpacing) / 4)
                                height: WeatherViewStyle.metricCardHeight
                                radius: WeatherViewStyle.metricCardRadius
                                color: root.cardColor
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Precipitation"
                                        color: WeatherViewStyle.textDim
                                        font.pixelSize: WeatherViewStyle.metricLabelFontPx
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.selectedDay ? (root.selectedDay.precipSum + " mm") : "0 mm"
                                        color: root.fg
                                        font.pixelSize: WeatherViewStyle.metricValueFontPx
                                        font.weight: Font.Bold
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.selectedDay
                                              ? ((root.selectedDay.precipProb !== null && root.selectedDay.precipProb !== undefined && !isNaN(root.selectedDay.precipProb))
                                                 ? root.selectedDay.precipProb + "% prob"
                                                 : "N/A")
                                              : "0%"
                                        color: (root.selectedDay && root.selectedDay.precipProb !== null && root.selectedDay.precipProb !== undefined && !isNaN(root.selectedDay.precipProb))
                                               ? WeatherViewStyle.textSecondary
                                               : WeatherViewStyle.textDim
                                        font.pixelSize: WeatherViewStyle.metricSubFontPx
                                    }
                                }
                            }

                            // Metric 2: Wind
                            Rectangle {
                                width: Math.floor((parent.width - 3 * WeatherViewStyle.metricGridSpacing) / 4)
                                height: WeatherViewStyle.metricCardHeight
                                radius: WeatherViewStyle.metricCardRadius
                                color: root.cardColor
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Wind Max"
                                        color: WeatherViewStyle.textDim
                                        font.pixelSize: WeatherViewStyle.metricLabelFontPx
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.selectedDay ? (root.selectedDay.windMax + " km/h") : "0 km/h"
                                        color: root.fg
                                        font.pixelSize: WeatherViewStyle.metricValueFontPx
                                        font.weight: Font.Bold
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Peak breeze"
                                        color: WeatherViewStyle.textSecondary
                                        font.pixelSize: WeatherViewStyle.metricSubFontPx
                                    }
                                }
                            }

                            // Metric 3: UV Index
                            Rectangle {
                                width: Math.floor((parent.width - 3 * WeatherViewStyle.metricGridSpacing) / 4)
                                height: WeatherViewStyle.metricCardHeight
                                radius: WeatherViewStyle.metricCardRadius
                                color: root.cardColor
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "UV Index"
                                        color: WeatherViewStyle.textDim
                                        font.pixelSize: WeatherViewStyle.metricLabelFontPx
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.selectedDay ? String(root.selectedDay.uvMax) : "0"
                                        color: root.fg
                                        font.pixelSize: WeatherViewStyle.metricValueFontPx
                                        font.weight: Font.Bold
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.selectedDay
                                              ? (root.selectedDay.uvMax >= 6 ? "Very High" : (root.selectedDay.uvMax >= 3 ? "Moderate" : "Low"))
                                              : "Low"
                                        color: WeatherViewStyle.textSecondary
                                        font.pixelSize: WeatherViewStyle.metricSubFontPx
                                    }
                                }
                            }

                            // Metric 4: Range & Variation
                            Rectangle {
                                width: Math.floor((parent.width - 3 * WeatherViewStyle.metricGridSpacing) / 4)
                                height: WeatherViewStyle.metricCardHeight
                                radius: WeatherViewStyle.metricCardRadius
                                color: root.cardColor
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Temp Range"
                                        color: WeatherViewStyle.textDim
                                        font.pixelSize: WeatherViewStyle.metricLabelFontPx
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.selectedDay ? (root.selectedDay.min + "° ➔ " + root.selectedDay.max + "°") : "—"
                                        color: root.fg
                                        font.pixelSize: WeatherViewStyle.metricValueFontPx
                                        font.weight: Font.Bold
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.selectedDay ? ("Spread " + (root.selectedDay.max - root.selectedDay.min) + "°C") : "—"
                                        color: WeatherViewStyle.textSecondary
                                        font.pixelSize: WeatherViewStyle.metricSubFontPx
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
