// ============================================================================
// File: modules/top-right-bar.module.qml
// Purpose: Right wing module of the top bar displaying the Caelestia Shell
//          Performance window (GPU on left, CPU in middle, Memory on right)
//          with click-to-expand btop-style detailed hardware views, hover
//          animations on every measure, and morphing transitions.
// Public API:
//   - Properties: gpuPerc, gpuTemp, cpuPerc, cpuTemp, memPerc, memTemp,
//                 selectedHardware, detailOpen, detailProgress,
//                 gpuGaugeRef, cpuGaugeRef, memGaugeRef
//   - Functions:  displayTemp(temp), formatGib(kib), openDetail(hw, item),
//                 closeDetail(), applyMetrics(text)
// Dependencies: Quickshell, Quickshell.Io, QtQuick, "../components", "../styles"
// ============================================================================
import Quickshell
import Quickshell.Io
import QtQuick
import "../components"
import "../styles"
import "../components/service-parsers.js" as ServiceParsers

SideBar {
    id: bar
    side: "right"
    trigger: "click"
    expandedH: SideBarStyle.perfOverviewHeight + (SideBarStyle.openHeight - SideBarStyle.perfOverviewHeight) * bar.detailProgress

    // ── Aggregate Metrics ──
    property real gpuPerc: 0.0
    property real gpuTemp: 0.0
    property string gpuName: "Graphics Processor"
    property string gpuType: "GPU"
    property real gpuCurMhz: 0
    property real gpuMaxMhz: 1000
    property real gpuMinMhz: 100

    property real cpuPerc: 0.0
    property real cpuTemp: 0.0
    property string cpuModel: "Processor"
    property real cpuFreqGhz: 0.0
    property real cpuMaxGhz: 0.0
    property string load1: "0.00"
    property string load5: "0.00"
    property string load15: "0.00"
    property string procs: "0/0"
    property var cores: []

    ListModel {
        id: coresListModel
    }

    function syncCoresModel(rawCores) {
        var list = (rawCores || []).slice()
        bar.cores = list

        var newLen = list.length
        var oldLen = coresListModel.count
        var commonLen = Math.min(oldLen, newLen)
        for (var i = 0; i < commonLen; i++) {
            coresListModel.set(i, list[i])
        }
        for (var j = commonLen; j < newLen; j++) {
            coresListModel.append(list[j])
        }
        if (oldLen > newLen) {
            coresListModel.remove(newLen, oldLen - newLen)
        }
    }

    property real memPerc: 0.0
    property real memUsedKib: 0.0
    property real memAvailKib: 0.0
    property real memFreeKib: 0.0
    property real memCachedKib: 0.0
    property real memBuffersKib: 0.0
    property real memTotalKib: 1.0
    property real swapTotalKib: 0.0
    property real swapFreeKib: 0.0
    property real swapUsedKib: 0.0
    property real swapPerc: 0.0
    property real memTemp: 0.0

    property var cpuHistory: []
    property var gpuHistory: []
    property var memHistory: []

    property var perfState: ({})
    property int bootstrapCount: 0

    // ── Detail View State & Morphing Geometry ──
    property string selectedHardware: "" // "" | "gpu" | "cpu" | "memory"
    property bool detailOpen: false
    property real detailProgress: 0.0
    property rect cardRect: Qt.rect(0, 0, 160, 160)

    readonly property alias gpuGaugeRef: gpuResource
    readonly property alias cpuGaugeRef: cpuResource
    readonly property alias memGaugeRef: memResource

    function displayTemp(temp) {
        return Math.ceil(temp || 0) + "°C"
    }

    function formatGib(kib) {
        var val = (kib || 0) / (1024.0 * 1024.0)
        return val.toFixed(1) + " GiB"
    }

    function openDetail(hw, itemRef) {
        if (itemRef) {
            var pt = itemRef.mapToItem(contentRoot, 0, 0)
            bar.cardRect = Qt.rect(pt.x, pt.y, itemRef.width, itemRef.height)
        }
        bar.selectedHardware = hw
        bar.detailOpen = true
        detailAnim.stop()
        detailAnim.to = 1.0
        detailAnim.easing.type = Easing.OutCubic
        detailAnim.restart()
    }

    function closeDetail() {
        bar.detailOpen = false
        detailAnim.stop()
        detailAnim.to = 0.0
        detailAnim.easing.type = Easing.InOutCubic
        detailAnim.restart()
    }

    NumberAnimation {
        id: detailAnim
        target: bar
        property: "detailProgress"
        duration: SideBarStyle.perfMorphDurationMs
        onFinished: {
            if (!bar.detailOpen && bar.detailProgress <= 0.01) {
                bar.selectedHardware = ""
            }
        }
    }

    Connections {
        target: (!bar.isFloatingWindow && bar.ctl) ? bar.ctl : null
        function onPhaseChanged() {
            if (!bar.isFloatingWindow && bar.ctl && bar.ctl.phase === "closed") {
                detailAnim.stop()
                bar.detailOpen = false
                bar.detailProgress = 0.0
                bar.selectedHardware = ""
            }
        }
    }

    function getDetachState() {
        return {
            selectedHardware: bar.selectedHardware,
            detailOpen: bar.detailOpen,
            detailProgress: bar.detailProgress
        }
    }

    onExtraDataChanged: {
        if (bar.isFloatingWindow && bar.extraData) {
            bar.selectedHardware = bar.extraData.selectedHardware || ""
            bar.detailOpen = !!bar.extraData.detailOpen
            bar.detailProgress = bar.extraData.detailOpen ? 1.0 : 0.0
            if (bar.floatingWindow) {
                bar.floatingWindow.winHeight = Math.round(bar.expandedH + 60)
            }
        }
    }

    onExpandedHChanged: {
        if (bar.isFloatingWindow && bar.floatingWindow) {
            bar.floatingWindow.winHeight = Math.round(bar.expandedH + 60)
        }
    }

    onFloatingWindowChanged: {
        if (bar.isFloatingWindow && bar.floatingWindow) {
            bar.floatingWindow.winHeight = Math.round(bar.expandedH + 60)
        }
    }

    function applyMetrics(text) {
        var parsed = ServiceParsers.parsePerformanceMetrics(text, bar.perfState)
        bar.perfState = parsed
        bar.gpuPerc = parsed.gpuPerc
        bar.gpuTemp = parsed.gpuTemp
        bar.gpuName = parsed.gpuName
        bar.gpuType = parsed.gpuType
        bar.gpuCurMhz = parsed.gpuCurMhz
        bar.gpuMaxMhz = parsed.gpuMaxMhz
        bar.gpuMinMhz = parsed.gpuMinMhz
        bar.cpuPerc = parsed.cpuPerc
        bar.cpuTemp = parsed.cpuTemp
        bar.cpuModel = parsed.cpuModel
        bar.cpuFreqGhz = parsed.cpuFreqGhz
        bar.cpuMaxGhz = parsed.cpuMaxGhz
        bar.load1 = parsed.load1
        bar.load5 = parsed.load5
        bar.load15 = parsed.load15
        bar.procs = parsed.procs
        bar.syncCoresModel(parsed.cores)
        bar.memPerc = parsed.memPerc
        bar.memUsedKib = parsed.memUsedKib
        bar.memAvailKib = parsed.memAvailKib
        bar.memFreeKib = parsed.memFreeKib
        bar.memCachedKib = parsed.memCachedKib
        bar.memBuffersKib = parsed.memBuffersKib
        bar.memTotalKib = parsed.memTotalKib
        bar.swapTotalKib = parsed.swapTotalKib
        bar.swapFreeKib = parsed.swapFreeKib
        bar.swapUsedKib = parsed.swapUsedKib
        bar.swapPerc = parsed.swapPerc
        bar.memTemp = parsed.memTemp
        bar.cpuHistory = parsed.cpuHistory
        bar.gpuHistory = parsed.gpuHistory
        bar.memHistory = parsed.memHistory
    }

    Process {
        id: perfProc
        command: ["sh", Quickshell.shellPath("src/app/scripts/system/poll-performance.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                bar.applyMetrics(this.text)
                if (bar.bootstrapCount < 1) {
                    bar.bootstrapCount++
                    bootstrapTimer.restart()
                }
            }
        }
    }

    Timer {
        id: bootstrapTimer
        interval: 350
        repeat: false
        onTriggered: {
            if (!perfProc.running)
                perfProc.running = true
        }
    }

    Timer {
        id: pollTimer
        interval: SideBarStyle.perfPollIntervalMs
        running: bar.isFloatingWindow || bar.mine || bar.expand > 0.01
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!perfProc.running)
                perfProc.running = true
        }
    }

    Component.onCompleted: {
        if (!perfProc.running)
            perfProc.running = true
    }

    Item {
        id: contentRoot
        anchors.fill: parent

        // ────────────────────────────────────────────────────────────────
        // LAYER 1: Caelestia 3-Circle Overview (GPU, CPU, Memory)
        // ────────────────────────────────────────────────────────────────
        Item {
            id: overviewLayer
            anchors.fill: parent
            opacity: 1.0 - bar.clamp01(bar.detailProgress * 1.6)
            scale: 1.0 - 0.06 * bar.detailProgress
            visible: opacity > 0.01
            enabled: bar.detailProgress < 0.35

            Row {
                id: perfRow
                anchors.centerIn: parent
                spacing: SideBarStyle.perfRowSpacing

                // 1. Left Resource: GPU (Temperature + Usage)
                PerfResource {
                    id: gpuResource
                    anchors.verticalCenter: parent.verticalCenter
                    primary: false
                    value1: Math.min(1.0, Math.max(0.0, bar.gpuTemp / SideBarStyle.perfMaxTemp))
                    value2: Math.min(1.0, Math.max(0.0, bar.gpuPerc))
                    label1: bar.displayTemp(bar.gpuTemp)
                    label2: Math.round(bar.gpuPerc * 100) + "%"
                    sublabel1: "GPU temp"
                    sublabel2: "Usage"
                    onClicked: bar.openDetail("gpu", gpuResource)
                }

                // 2. Middle Resource: CPU (Primary 1.2x scale, Temperature + Usage)
                PerfResource {
                    id: cpuResource
                    anchors.verticalCenter: parent.verticalCenter
                    primary: true
                    value1: Math.min(1.0, Math.max(0.0, bar.cpuTemp / SideBarStyle.perfMaxTemp))
                    value2: Math.min(1.0, Math.max(0.0, bar.cpuPerc))
                    label1: bar.displayTemp(bar.cpuTemp)
                    label2: Math.round(bar.cpuPerc * 100) + "%"
                    sublabel1: "CPU temp"
                    sublabel2: "Usage"
                    onClicked: bar.openDetail("cpu", cpuResource)
                }

                // 3. Right Resource: Memory (Temperature + Usage)
                PerfResource {
                    id: memResource
                    anchors.verticalCenter: parent.verticalCenter
                    primary: false
                    value1: Math.min(1.0, Math.max(0.0, bar.memTemp / SideBarStyle.perfMaxTemp))
                    value2: Math.min(1.0, Math.max(0.0, bar.memPerc))
                    label1: bar.displayTemp(bar.memTemp)
                    label2: Math.round(bar.memPerc * 100) + "%"
                    sublabel1: "Memory temp"
                    sublabel2: "Usage"
                    onClicked: bar.openDetail("memory", memResource)
                }
            }
        }

        // ────────────────────────────────────────────────────────────────
        // LAYER 2: Morphing btop-Style Hardware Detail View
        // ────────────────────────────────────────────────────────────────
        Rectangle {
            id: detailMorphCard
            x: bar.cardRect.x * (1.0 - bar.detailProgress)
            y: bar.cardRect.y * (1.0 - bar.detailProgress)
            width: bar.cardRect.width + (contentRoot.width - bar.cardRect.width) * bar.detailProgress
            height: bar.cardRect.height + (contentRoot.height - bar.cardRect.height) * bar.detailProgress
            radius: (bar.cardRect.width * 0.5) * (1.0 - bar.detailProgress) + SideBarStyle.dropRadius * bar.detailProgress
            color: SideBarStyle.transparent
            border.width: bar.detailProgress < 0.98 ? 1 : 0
            border.color: SideBarStyle.perfCardBorder
            clip: true
            opacity: bar.clamp01(bar.detailProgress * 2.5)
            visible: bar.detailProgress > 0.005

            Item {
                id: detailContent
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 10
                anchors.bottomMargin: 12
                opacity: bar.clamp01((bar.detailProgress - 0.20) / 0.80)
                enabled: bar.detailProgress > 0.65

                // ── Top Header: [ ← ] Back Arrow + Hardware Title & Live Subtitle ──
                Item {
                    id: detailHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 36

                    Rectangle {
                        id: backBtn
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34
                        height: 30
                        radius: 8
                        color: backMouse.containsMouse ? SideBarStyle.perfCardHoverBg : SideBarStyle.perfCardBg
                        border.width: 1
                        border.color: backMouse.containsMouse ? SideBarStyle.perfCardHoverBorder : SideBarStyle.perfCardBorder
                        scale: backMouse.pressed ? SideBarStyle.perfArrowPressedScale : (backMouse.containsMouse ? SideBarStyle.perfArrowHoverScale : 1.0)

                        Behavior on scale {
                            NumberAnimation { duration: SideBarStyle.perfHoverDurationMs; easing.type: Easing.OutCubic }
                        }
                        Behavior on color {
                            ColorAnimation { duration: SideBarStyle.perfHoverDurationMs }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: SideBarStyle.perfHoverDurationMs }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "\uDB80\uDF0D"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 16
                            color: backMouse.containsMouse ? SideBarStyle.perfArcPrimary : SideBarStyle.textPrimary
                        }

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: function(mouse) {
                                var pt = mapToItem(null, mouse.x, mouse.y)
                                bar.beginDragCheck(pt.x, pt.y)
                            }
                            onPositionChanged: function(mouse) {
                                if (!pressed) return
                                var pt = mapToItem(null, mouse.x, mouse.y)
                                bar.moveDragCheck(pt.x, pt.y)
                            }
                            onReleased: {
                                if (!bar.endDragCheck()) {
                                    bar.closeDetail()
                                }
                            }
                            onCanceled: bar.cancelDragCheck()
                        }
                    }

                    Column {
                        anchors.left: backBtn.right
                        anchors.leftMargin: 12
                        anchors.right: headerRightBadge.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            color: SideBarStyle.textPrimary
                            text: {
                                if (bar.selectedHardware === "cpu")
                                    return "CPU  ·  " + bar.cpuModel
                                if (bar.selectedHardware === "gpu")
                                    return "GPU  ·  " + bar.gpuName
                                return "MEMORY  ·  System RAM & Swap"
                            }
                        }

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            font.pixelSize: 11
                            color: SideBarStyle.perfTextDim
                            text: {
                                if (bar.selectedHardware === "cpu")
                                    return "Load Avg " + bar.load1 + " / " + bar.load5 + " / " + bar.load15 + "   ·   Tasks " + bar.procs + "   ·   " + bar.cores.length + " Logical Cores"
                                if (bar.selectedHardware === "gpu")
                                    return "Engine " + bar.gpuType + "   ·   Clock " + Math.round(bar.gpuCurMhz) + " / " + Math.round(bar.gpuMaxMhz) + " MHz"
                                return "Total RAM " + bar.formatGib(bar.memTotalKib) + "   ·   Available " + bar.formatGib(bar.memAvailKib) + "   ·   Swap " + bar.formatGib(bar.swapTotalKib)
                            }
                        }
                    }

                    // Live Temperature & Usage Pill Badge on top-right
                    Rectangle {
                        id: headerRightBadge
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 28
                        width: badgeRow.width + 18
                        radius: 8
                        color: badgeMouse.containsMouse ? SideBarStyle.perfCardHoverBg : SideBarStyle.perfCardBg
                        border.width: 1
                        border.color: badgeMouse.containsMouse ? SideBarStyle.perfCardHoverBorder : SideBarStyle.perfCardBorder
                        scale: badgeMouse.containsMouse ? SideBarStyle.perfCardHoverScale : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: SideBarStyle.perfHoverDurationMs; easing.type: Easing.OutCubic }
                        }

                        Row {
                            id: badgeRow
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: SideBarStyle.perfArcPrimary
                                text: {
                                    if (bar.selectedHardware === "cpu")
                                        return Math.round(bar.cpuPerc * 100) + "%  ·  " + bar.displayTemp(bar.cpuTemp)
                                    if (bar.selectedHardware === "gpu")
                                        return Math.round(bar.gpuPerc * 100) + "%  ·  " + bar.displayTemp(bar.gpuTemp)
                                    return Math.round(bar.memPerc * 100) + "%  ·  " + bar.displayTemp(bar.memTemp)
                                }
                            }
                        }

                        MouseArea {
                            id: badgeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onPressed: function(mouse) {
                                var pt = mapToItem(null, mouse.x, mouse.y)
                                bar.beginDragCheck(pt.x, pt.y)
                            }
                            onPositionChanged: function(mouse) {
                                if (!pressed) return
                                var pt = mapToItem(null, mouse.x, mouse.y)
                                bar.moveDragCheck(pt.x, pt.y)
                            }
                            onReleased: bar.endDragCheck()
                            onCanceled: bar.cancelDragCheck()
                        }
                    }
                }

                // ── Row of 4 Hoverable Summary Metric Cards ──
                Row {
                    id: metricCardsRow
                    anchors.top: detailHeader.bottom
                    anchors.topMargin: 10
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 74
                    spacing: 10

                    readonly property real cardW: (width - 3 * spacing) / 4.0

                    // Card 1: Usage / Used
                    PerfMetricCard {
                        width: metricCardsRow.cardW
                        height: parent.height
                        title: bar.selectedHardware === "memory" ? "USED RAM" : "TOTAL USAGE"
                        mainValue: {
                            if (bar.selectedHardware === "cpu")
                                return Math.round(bar.cpuPerc * 100) + "%"
                            if (bar.selectedHardware === "gpu")
                                return Math.round(bar.gpuPerc * 100) + "%"
                            return bar.formatGib(bar.memUsedKib)
                        }
                        subValue: {
                            if (bar.selectedHardware === "memory")
                                return Math.round(bar.memPerc * 100) + "% of " + bar.formatGib(bar.memTotalKib)
                            return "Active Utilization"
                        }
                        ratio: {
                            if (bar.selectedHardware === "cpu")
                                return bar.cpuPerc
                            if (bar.selectedHardware === "gpu")
                                return bar.gpuPerc
                            return bar.memPerc
                        }
                    }

                    // Card 2: Available / Headroom
                    PerfMetricCard {
                        width: metricCardsRow.cardW
                        height: parent.height
                        title: bar.selectedHardware === "memory" ? "AVAILABLE" : "AVAILABLE"
                        mainValue: {
                            if (bar.selectedHardware === "cpu")
                                return Math.round((1.0 - bar.cpuPerc) * 100) + "%"
                            if (bar.selectedHardware === "gpu")
                                return Math.round((1.0 - bar.gpuPerc) * 100) + "%"
                            return bar.formatGib(bar.memAvailKib)
                        }
                        subValue: {
                            if (bar.selectedHardware === "memory")
                                return Math.round((1.0 - bar.memPerc) * 100) + "% Free + Cache"
                            return "Idle Headroom"
                        }
                        ratio: {
                            if (bar.selectedHardware === "cpu")
                                return 1.0 - bar.cpuPerc
                            if (bar.selectedHardware === "gpu")
                                return 1.0 - bar.gpuPerc
                            return 1.0 - bar.memPerc
                        }
                    }

                    // Card 3: Temperature
                    PerfMetricCard {
                        width: metricCardsRow.cardW
                        height: parent.height
                        title: "TEMPERATURE"
                        mainValue: {
                            if (bar.selectedHardware === "cpu")
                                return bar.displayTemp(bar.cpuTemp)
                            if (bar.selectedHardware === "gpu")
                                return bar.displayTemp(bar.gpuTemp)
                            return bar.displayTemp(bar.memTemp)
                        }
                        subValue: "Crit 100°C  ·  High 90°C"
                        ratio: {
                            var t = bar.selectedHardware === "cpu" ? bar.cpuTemp : (bar.selectedHardware === "gpu" ? bar.gpuTemp : bar.memTemp)
                            return Math.min(1.0, Math.max(0.0, t / SideBarStyle.perfMaxTemp))
                        }
                        isTemp: true
                    }

                    // Card 4: Frequency / Cached
                    PerfMetricCard {
                        width: metricCardsRow.cardW
                        height: parent.height
                        title: {
                            if (bar.selectedHardware === "cpu")
                                return "CLOCK SPEED"
                            if (bar.selectedHardware === "gpu")
                                return "CORE CLOCK"
                            return "CACHED + SWAP"
                        }
                        mainValue: {
                            if (bar.selectedHardware === "cpu")
                                return bar.cpuFreqGhz.toFixed(2) + " GHz"
                            if (bar.selectedHardware === "gpu")
                                return Math.round(bar.gpuCurMhz) + " MHz"
                            return bar.formatGib(bar.memCachedKib + bar.memBuffersKib)
                        }
                        subValue: {
                            if (bar.selectedHardware === "cpu")
                                return "Max " + bar.cpuMaxGhz.toFixed(2) + " GHz"
                            if (bar.selectedHardware === "gpu")
                                return "Max " + Math.round(bar.gpuMaxMhz) + " MHz"
                            return "Swap " + bar.formatGib(bar.swapUsedKib) + " / " + bar.formatGib(bar.swapTotalKib)
                        }
                        ratio: {
                            if (bar.selectedHardware === "cpu")
                                return bar.cpuMaxGhz > 0 ? Math.min(1.0, bar.cpuFreqGhz / bar.cpuMaxGhz) : 0.0
                            if (bar.selectedHardware === "gpu")
                                return bar.gpuMaxMhz > 0 ? Math.min(1.0, bar.gpuCurMhz / bar.gpuMaxMhz) : 0.0
                            return bar.memTotalKib > 0 ? Math.min(1.0, (bar.memCachedKib + bar.memBuffersKib) / bar.memTotalKib) : 0.0
                        }
                    }
                }

                // ── Middle Section: btop-Style Per-Core Grid (CPU) or Breakdown Meters (GPU / Memory) ──
                Item {
                    id: middleSection
                    anchors.top: metricCardsRow.bottom
                    anchors.topMargin: 10
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 172

                    // A. CPU Per-Core Scrollable Grid (btop style: C0..CN with individual bars, % and GHz)
                    Item {
                        id: cpuCoresSection
                        anchors.fill: parent
                        visible: bar.selectedHardware === "cpu"

                        readonly property int columns: 4
                        readonly property real colSpacing: 8
                        readonly property real rowSpacing: 8
                        readonly property real hoverBleed: 4
                        readonly property int coreCount: Math.max(1, coresListModel.count)
                        readonly property int rowsCount: Math.max(1, Math.ceil(coreCount / columns))
                        readonly property bool isScrollable: rowsCount > 3
                        readonly property real availWidth: width - (isScrollable ? 10 : 0)
                        readonly property real cellW: (availWidth - (columns - 1) * colSpacing) / columns
                        readonly property real cellH: (height - 2 * rowSpacing) / 3.0

                        Flickable {
                            id: cpuCoresFlick
                            x: -cpuCoresSection.hoverBleed
                            y: -cpuCoresSection.hoverBleed
                            width: cpuCoresSection.availWidth + 2 * cpuCoresSection.hoverBleed
                            height: cpuCoresSection.height + 2 * cpuCoresSection.hoverBleed
                            contentWidth: width
                            contentHeight: cpuCoresGrid.height + 2 * cpuCoresSection.hoverBleed
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: cpuCoresSection.isScrollable

                            WheelHandler {
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                enabled: cpuCoresSection.isScrollable
                                onWheel: function(event) {
                                    var dy = 0
                                    if (event.angleDelta && event.angleDelta.y !== 0) {
                                        dy = (event.angleDelta.y / 120.0) * (cpuCoresSection.cellH + cpuCoresSection.rowSpacing)
                                    } else if (event.pixelDelta && event.pixelDelta.y !== 0) {
                                        dy = event.pixelDelta.y
                                    }
                                    if (dy !== 0) {
                                        var maxY = Math.max(0, cpuCoresFlick.contentHeight - cpuCoresFlick.height)
                                        cpuCoresFlick.contentY = Math.max(0, Math.min(maxY, cpuCoresFlick.contentY - dy))
                                    }
                                }
                            }

                            Grid {
                                id: cpuCoresGrid
                                x: cpuCoresSection.hoverBleed
                                y: cpuCoresSection.hoverBleed
                                width: cpuCoresSection.availWidth
                                columns: cpuCoresSection.columns
                                columnSpacing: cpuCoresSection.colSpacing
                                rowSpacing: cpuCoresSection.rowSpacing

                                Repeater {
                                    model: coresListModel

                                    PerfMeterTile {
                                        required property int index
                                        required property real usage
                                        required property real freqGhz
                                        width: cpuCoresSection.cellW
                                        height: cpuCoresSection.cellH
                                        label: "C" + index
                                        rightValue: Math.round((usage || 0) * 100) + "%"
                                        subText: (freqGhz || 0).toFixed(2) + " GHz"
                                        ratio: usage || 0.0
                                    }
                                }
                            }
                        }

                        // Minimalist Vertical Scrollbar Indicator (shown only when > 12 cores)
                        Rectangle {
                            id: coresScrollTrack
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.topMargin: 2
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            width: 4
                            radius: 2
                            color: SideBarStyle.perfTrackSecondary
                            visible: cpuCoresSection.isScrollable

                            Rectangle {
                                width: parent.width
                                radius: 2
                                color: SideBarStyle.perfArcSecondary
                                height: Math.max(
                                    24,
                                    parent.height * (cpuCoresFlick.height / Math.max(1, cpuCoresFlick.contentHeight))
                                )
                                y: {
                                    var maxScroll = Math.max(1, cpuCoresFlick.contentHeight - cpuCoresFlick.height)
                                    var maxY = Math.max(0, parent.height - height)
                                    return Math.max(0, Math.min(maxY, (cpuCoresFlick.contentY / maxScroll) * maxY))
                                }
                            }
                        }
                    }

                    // B. Memory Breakdown Grid (btop style: Used, Available, Cached, Free, Buffers, Swap)
                    Grid {
                        id: memBreakdownGrid
                        anchors.fill: parent
                        visible: bar.selectedHardware === "memory"
                        columns: 3
                        columnSpacing: 10
                        rowSpacing: 10

                        readonly property real cellW: (width - 2 * columnSpacing) / 3.0
                        readonly property real cellH: (height - rowSpacing) / 2.0

                        PerfMeterTile {
                            width: memBreakdownGrid.cellW
                            height: memBreakdownGrid.cellH
                            label: "Used RAM"
                            rightValue: Math.round(bar.memPerc * 100) + "%"
                            subText: bar.formatGib(bar.memUsedKib) + " / " + bar.formatGib(bar.memTotalKib)
                            ratio: bar.memPerc
                        }

                        PerfMeterTile {
                            width: memBreakdownGrid.cellW
                            height: memBreakdownGrid.cellH
                            label: "Available RAM"
                            rightValue: Math.round((1.0 - bar.memPerc) * 100) + "%"
                            subText: bar.formatGib(bar.memAvailKib) + " ready"
                            ratio: 1.0 - bar.memPerc
                        }

                        PerfMeterTile {
                            width: memBreakdownGrid.cellW
                            height: memBreakdownGrid.cellH
                            label: "Page Cache"
                            rightValue: bar.memTotalKib > 0 ? Math.round((bar.memCachedKib / bar.memTotalKib) * 100) + "%" : "0%"
                            subText: bar.formatGib(bar.memCachedKib) + " cached"
                            ratio: bar.memTotalKib > 0 ? (bar.memCachedKib / bar.memTotalKib) : 0.0
                        }

                        PerfMeterTile {
                            width: memBreakdownGrid.cellW
                            height: memBreakdownGrid.cellH
                            label: "Free RAM"
                            rightValue: bar.memTotalKib > 0 ? Math.round((bar.memFreeKib / bar.memTotalKib) * 100) + "%" : "0%"
                            subText: bar.formatGib(bar.memFreeKib) + " unallocated"
                            ratio: bar.memTotalKib > 0 ? (bar.memFreeKib / bar.memTotalKib) : 0.0
                        }

                        PerfMeterTile {
                            width: memBreakdownGrid.cellW
                            height: memBreakdownGrid.cellH
                            label: "Kernel Buffers"
                            rightValue: bar.memTotalKib > 0 ? Math.round((bar.memBuffersKib / bar.memTotalKib) * 100) + "%" : "0%"
                            subText: bar.formatGib(bar.memBuffersKib) + " buffers"
                            ratio: bar.memTotalKib > 0 ? (bar.memBuffersKib / bar.memTotalKib) : 0.0
                        }

                        PerfMeterTile {
                            width: memBreakdownGrid.cellW
                            height: memBreakdownGrid.cellH
                            label: "Swap Space"
                            rightValue: Math.round(bar.swapPerc * 100) + "%"
                            subText: bar.formatGib(bar.swapUsedKib) + " / " + bar.formatGib(bar.swapTotalKib)
                            ratio: bar.swapPerc
                        }
                    }

                    // C. GPU Engine & Telemetry Breakdown Grid (btop / nvtop style)
                    Grid {
                        id: gpuBreakdownGrid
                        anchors.fill: parent
                        visible: bar.selectedHardware === "gpu"
                        columns: 3
                        columnSpacing: 10
                        rowSpacing: 10

                        readonly property real cellW: (width - 2 * columnSpacing) / 3.0
                        readonly property real cellH: (height - rowSpacing) / 2.0

                        PerfMeterTile {
                            width: gpuBreakdownGrid.cellW
                            height: gpuBreakdownGrid.cellH
                            label: "Render / 3D Load"
                            rightValue: Math.round(bar.gpuPerc * 100) + "%"
                            subText: "Active Engine"
                            ratio: bar.gpuPerc
                        }

                        PerfMeterTile {
                            width: gpuBreakdownGrid.cellW
                            height: gpuBreakdownGrid.cellH
                            label: "Available Headroom"
                            rightValue: Math.round((1.0 - bar.gpuPerc) * 100) + "%"
                            subText: "Idle Capacity"
                            ratio: 1.0 - bar.gpuPerc
                        }

                        PerfMeterTile {
                            width: gpuBreakdownGrid.cellW
                            height: gpuBreakdownGrid.cellH
                            label: "Core Frequency"
                            rightValue: Math.round(bar.gpuCurMhz) + " MHz"
                            subText: "Max " + Math.round(bar.gpuMaxMhz) + " MHz"
                            ratio: bar.gpuMaxMhz > 0 ? Math.min(1.0, bar.gpuCurMhz / bar.gpuMaxMhz) : 0.0
                        }

                        PerfMeterTile {
                            width: gpuBreakdownGrid.cellW
                            height: gpuBreakdownGrid.cellH
                            label: "Thermal Load"
                            rightValue: bar.displayTemp(bar.gpuTemp)
                            subText: "Limit 90°C"
                            ratio: Math.min(1.0, Math.max(0.0, bar.gpuTemp / SideBarStyle.perfMaxTemp))
                        }

                        PerfMeterTile {
                            width: gpuBreakdownGrid.cellW
                            height: gpuBreakdownGrid.cellH
                            label: "Power Save (RC6)"
                            rightValue: Math.round((1.0 - bar.gpuPerc) * 100) + "%"
                            subText: "Sleep Residency"
                            ratio: 1.0 - bar.gpuPerc
                        }

                        PerfMeterTile {
                            width: gpuBreakdownGrid.cellW
                            height: gpuBreakdownGrid.cellH
                            label: "Dynamic Range"
                            rightValue: Math.round(bar.gpuMinMhz) + "–" + Math.round(bar.gpuMaxMhz)
                            subText: "MHz Scaling Window"
                            ratio: bar.gpuMaxMhz > bar.gpuMinMhz ? Math.max(0.0, Math.min(1.0, (bar.gpuCurMhz - bar.gpuMinMhz) / (bar.gpuMaxMhz - bar.gpuMinMhz))) : 0.0
                        }
                    }
                }

                // ── Bottom Section: Live Rolling btop History Sparkline Graph ──
                PerfHistoryGraph {
                    anchors.top: middleSection.bottom
                    anchors.topMargin: 10
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    title: {
                        if (bar.selectedHardware === "cpu")
                            return "LIVE CPU UTILIZATION HISTORY"
                        if (bar.selectedHardware === "gpu")
                            return "LIVE GPU UTILIZATION HISTORY"
                        return "LIVE MEMORY UTILIZATION HISTORY"
                    }
                    values: {
                        if (bar.selectedHardware === "cpu")
                            return bar.cpuHistory
                        if (bar.selectedHardware === "gpu")
                            return bar.gpuHistory
                        return bar.memHistory
                    }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // Embedded Reusable Components
    // ════════════════════════════════════════════════════════════════════════

    // 1. Caelestia Split-Arc Circular Gauge with Hover & Click Animations
    component PerfResource: Item {
        id: res

        required property real value1
        required property real value2
        required property string sublabel1
        required property string sublabel2
        required property string label1
        required property string label2
        signal clicked()

        property bool primary: false
        readonly property real primaryMult: primary ? SideBarStyle.perfPrimaryScale : 1.0
        readonly property real thickness: SideBarStyle.perfStrokeThickness * primaryMult

        property real animValue1: value1
        property real animValue2: value2

        property color fg1: SideBarStyle.perfArcPrimary
        property color fg2: SideBarStyle.perfArcSecondary
        property color bg1: SideBarStyle.perfTrackPrimary
        property color bg2: SideBarStyle.perfTrackSecondary

        width: SideBarStyle.perfResourceSize * primaryMult
        height: SideBarStyle.perfResourceSize * primaryMult
        implicitWidth: width
        implicitHeight: height

        scale: resMouse.pressed ? SideBarStyle.perfCirclePressedScale : (resMouse.containsMouse ? SideBarStyle.perfCircleHoverScale : 1.0)
        Behavior on scale {
            NumberAnimation {
                duration: SideBarStyle.perfHoverDurationMs
                easing.type: Easing.OutCubic
            }
        }

        Behavior on animValue1 {
            NumberAnimation {
                duration: SideBarStyle.perfAnimDurationMs
                easing.type: Easing.OutCubic
            }
        }
        Behavior on animValue2 {
            NumberAnimation {
                duration: SideBarStyle.perfAnimDurationMs
                easing.type: Easing.OutCubic
            }
        }

        onAnimValue1Changed: canvas.requestPaint()
        onAnimValue2Changed: canvas.requestPaint()
        onFg1Changed: canvas.requestPaint()
        onFg2Changed: canvas.requestPaint()
        onBg1Changed: canvas.requestPaint()
        onBg2Changed: canvas.requestPaint()

        function toCanvasCssColor(c) {
            if (!c)
                return ""
            var r = Math.round((c.r || 0) * 255)
            var g = Math.round((c.g || 0) * 255)
            var b = Math.round((c.b || 0) * 255)
            var a = (c.a !== undefined) ? c.a : 1.0
            return "rgb" + "a(" + r + "," + g + "," + b + "," + a.toFixed(3) + ")"
        }

        Column {
            anchors.centerIn: parent

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: res.label1
                color: SideBarStyle.textPrimary
                font.pixelSize: Math.round(SideBarStyle.perfLabel1FontPx * res.primaryMult)
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: res.sublabel1
                color: resMouse.containsMouse ? SideBarStyle.textPrimary : SideBarStyle.perfTextDim
                font.pixelSize: Math.round(SideBarStyle.perfSublabel1FontPx * res.primaryMult)
                Behavior on color {
                    ColorAnimation { duration: SideBarStyle.perfHoverDurationMs }
                }
            }
        }

        Column {
            anchors.horizontalCenter: parent.right
            anchors.top: parent.verticalCenter
            anchors.horizontalCenterOffset: -res.thickness / 2
            anchors.topMargin: res.thickness / 2 + SideBarStyle.perfGapLabelTopMargin

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: res.label2
                color: SideBarStyle.textPrimary
                font.pixelSize: Math.round(SideBarStyle.perfLabel2FontPx * res.primaryMult)
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: res.sublabel2
                color: SideBarStyle.perfTextDim
                font.pixelSize: Math.round(SideBarStyle.perfSublabel2FontPx * res.primaryMult)
            }
        }

        Canvas {
            id: canvas

            readonly property real centerX: width / 2
            readonly property real centerY: height / 2

            readonly property real arc1Start: degToRad(45)
            readonly property real arc1End: degToRad(220)
            readonly property real arc2Start: degToRad(230)
            readonly property real arc2End: degToRad(360)

            function degToRad(deg) {
                return deg * Math.PI / 180.0
            }

            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                ctx.lineWidth = res.thickness
                ctx.lineCap = "round"

                var radius = (Math.min(width, height) - ctx.lineWidth) / 2.0
                if (radius <= 0)
                    return
                var cx = centerX
                var cy = centerY
                var a1s = arc1Start
                var a1e = arc1End
                var a2s = arc2Start
                var a2e = arc2End

                ctx.beginPath()
                ctx.arc(cx, cy, radius, a1s, a1e, false)
                ctx.strokeStyle = res.toCanvasCssColor(res.bg1)
                ctx.stroke()

                if (res.animValue1 > 0.001) {
                    ctx.beginPath()
                    ctx.arc(cx, cy, radius, a1s, (a1e - a1s) * res.animValue1 + a1s, false)
                    ctx.strokeStyle = res.toCanvasCssColor(res.fg1)
                    ctx.stroke()
                }

                ctx.beginPath()
                ctx.arc(cx, cy, radius, a2s, a2e, false)
                ctx.strokeStyle = res.toCanvasCssColor(res.bg2)
                ctx.stroke()

                if (res.animValue2 > 0.001) {
                    ctx.beginPath()
                    ctx.arc(cx, cy, radius, a2s, (a2e - a2s) * res.animValue2 + a2s, false)
                    ctx.strokeStyle = res.toCanvasCssColor(res.fg2)
                    ctx.stroke()
                }
            }
        }

        MouseArea {
            id: resMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: function(mouse) {
                var pt = mapToItem(null, mouse.x, mouse.y)
                bar.beginDragCheck(pt.x, pt.y)
            }
            onPositionChanged: function(mouse) {
                if (!pressed) return
                var pt = mapToItem(null, mouse.x, mouse.y)
                bar.moveDragCheck(pt.x, pt.y)
            }
            onReleased: {
                if (!bar.endDragCheck()) {
                    res.clicked()
                }
            }
            onCanceled: bar.cancelDragCheck()
        }
    }

    // 2. Hoverable Summary Metric Card
    component PerfMetricCard: Rectangle {
        id: mCard

        required property string title
        required property string mainValue
        required property string subValue
        required property real ratio
        property bool isTemp: false

        property real animRatio: Math.max(0.0, Math.min(1.0, ratio))
        Behavior on animRatio {
            NumberAnimation { duration: SideBarStyle.perfAnimDurationMs; easing.type: Easing.OutCubic }
        }

        radius: 10
        color: cardMouse.containsMouse ? SideBarStyle.perfCardHoverBg : SideBarStyle.perfCardBg
        border.width: 1
        border.color: cardMouse.containsMouse ? SideBarStyle.perfCardHoverBorder : SideBarStyle.perfCardBorder
        scale: cardMouse.pressed ? SideBarStyle.perfCardPressedScale : (cardMouse.containsMouse ? SideBarStyle.perfCardHoverScale : 1.0)

        Behavior on scale {
            NumberAnimation { duration: SideBarStyle.perfHoverDurationMs; easing.type: Easing.OutCubic }
        }
        Behavior on color {
            ColorAnimation { duration: SideBarStyle.perfHoverDurationMs }
        }
        Behavior on border.color {
            ColorAnimation { duration: SideBarStyle.perfHoverDurationMs }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 9
            spacing: 2

            Text {
                text: mCard.title
                font.pixelSize: 10
                font.weight: Font.Bold
                color: cardMouse.containsMouse ? SideBarStyle.textPrimary : SideBarStyle.perfTextDim
            }

            Text {
                text: mCard.mainValue
                font.pixelSize: 18
                font.weight: Font.Bold
                color: (mCard.isTemp && mCard.animRatio > 0.88) ? SideBarStyle.perfDanger : SideBarStyle.textPrimary
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: mCard.subValue
                font.pixelSize: 10
                color: SideBarStyle.perfTextDim
            }

            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: SideBarStyle.perfTrackSecondary

                Rectangle {
                    width: parent.width * mCard.animRatio
                    height: parent.height
                    radius: 2
                    color: (mCard.isTemp && mCard.animRatio > 0.88) ? SideBarStyle.perfDanger : SideBarStyle.perfArcPrimary
                }
            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            onPressed: function(mouse) {
                var pt = mapToItem(null, mouse.x, mouse.y)
                bar.beginDragCheck(pt.x, pt.y)
            }
            onPositionChanged: function(mouse) {
                if (!pressed) return
                var pt = mapToItem(null, mouse.x, mouse.y)
                bar.moveDragCheck(pt.x, pt.y)
            }
            onReleased: bar.endDragCheck()
            onCanceled: bar.cancelDragCheck()
        }
    }

    // 3. Hoverable btop Meter Tile (used for Per-Core CPU cells, Memory Breakdown, and GPU Telemetry)
    component PerfMeterTile: Rectangle {
        id: tile

        required property string label
        required property string rightValue
        required property string subText
        required property real ratio

        property real animRatio: Math.max(0.0, Math.min(1.0, ratio))
        Behavior on animRatio {
            NumberAnimation { duration: SideBarStyle.perfAnimDurationMs; easing.type: Easing.OutCubic }
        }

        radius: 8
        z: tileMouse.containsMouse ? 2 : 0
        color: tileMouse.containsMouse ? SideBarStyle.perfCardHoverBg : SideBarStyle.perfCardBg
        border.width: 1
        border.color: tileMouse.containsMouse ? SideBarStyle.perfCardHoverBorder : SideBarStyle.perfCardBorder
        scale: tileMouse.pressed ? SideBarStyle.perfCardPressedScale : (tileMouse.containsMouse ? SideBarStyle.perfCardHoverScale : 1.0)

        Behavior on scale {
            NumberAnimation { duration: SideBarStyle.perfHoverDurationMs; easing.type: Easing.OutCubic }
        }
        Behavior on color {
            ColorAnimation { duration: SideBarStyle.perfHoverDurationMs }
        }
        Behavior on border.color {
            ColorAnimation { duration: SideBarStyle.perfHoverDurationMs }
        }

        Column {
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 9
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            spacing: 3

            Item {
                width: parent.width
                height: 15

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: tile.label
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: SideBarStyle.textPrimary
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: tile.rightValue
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: tile.animRatio > 0.85 ? SideBarStyle.perfDanger : SideBarStyle.perfArcPrimary
                }
            }

            // btop-style meter bar
            Rectangle {
                width: parent.width
                height: 6
                radius: 3
                color: SideBarStyle.perfTrackSecondary

                Rectangle {
                    width: parent.width * tile.animRatio
                    height: parent.height
                    radius: 3
                    color: tile.animRatio > 0.85 ? SideBarStyle.perfDanger : (tileMouse.containsMouse ? SideBarStyle.perfArcPrimary : SideBarStyle.perfArcSecondary)
                    Behavior on color {
                        ColorAnimation { duration: SideBarStyle.perfHoverDurationMs }
                    }
                }
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: tile.subText
                font.pixelSize: 10
                color: tileMouse.containsMouse ? SideBarStyle.textPrimary : SideBarStyle.perfTextDim
            }
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            onPressed: function(mouse) {
                var pt = mapToItem(null, mouse.x, mouse.y)
                bar.beginDragCheck(pt.x, pt.y)
            }
            onPositionChanged: function(mouse) {
                if (!pressed) return
                var pt = mapToItem(null, mouse.x, mouse.y)
                bar.moveDragCheck(pt.x, pt.y)
            }
            onReleased: bar.endDragCheck()
            onCanceled: bar.cancelDragCheck()
        }
    }

    // 4. Rolling btop-Style Telemetry Sparkline Graph with Interactive Hover Inspection
    component PerfHistoryGraph: Rectangle {
        id: graphRoot

        required property string title
        required property var values

        radius: 10
        color: graphMouse.containsMouse ? SideBarStyle.perfCardHoverBg : SideBarStyle.perfCardBg
        border.width: 1
        border.color: graphMouse.containsMouse ? SideBarStyle.perfCardHoverBorder : SideBarStyle.perfCardBorder

        Behavior on color {
            ColorAnimation { duration: SideBarStyle.perfHoverDurationMs }
        }
        Behavior on border.color {
            ColorAnimation { duration: SideBarStyle.perfHoverDurationMs }
        }

        onValuesChanged: graphCanvas.requestPaint()

        readonly property int hoveredIdx: {
            if (!graphMouse.containsMouse || !values || values.length === 0)
                return -1
            var relX = Math.max(0.0, Math.min(1.0, (graphMouse.mouseX - 10) / Math.max(1.0, width - 20)))
            return Math.min(values.length - 1, Math.max(0, Math.round(relX * (values.length - 1))))
        }

        Item {
            id: graphHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 6
            height: 16

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: graphRoot.title
                font.pixelSize: 10
                font.weight: Font.Bold
                color: SideBarStyle.perfTextDim
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: SideBarStyle.perfArcPrimary
                text: {
                    var arr = graphRoot.values || []
                    if (arr.length === 0)
                        return "0%"
                    var idx = graphRoot.hoveredIdx >= 0 ? graphRoot.hoveredIdx : (arr.length - 1)
                    var prefix = graphRoot.hoveredIdx >= 0 ? ("Sample -" + (arr.length - 1 - idx) + ": ") : "Now: "
                    return prefix + Math.round((arr[idx] || 0) * 100) + "%"
                }
            }
        }

        Canvas {
            id: graphCanvas
            anchors.top: graphHeader.bottom
            anchors.topMargin: 4
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 10

            function toCss(c) {
                if (!c)
                    return ""
                var r = Math.round((c.r || 0) * 255)
                var g = Math.round((c.g || 0) * 255)
                var b = Math.round((c.b || 0) * 255)
                var a = (c.a !== undefined) ? c.a : 1.0
                return "rgb" + "a(" + r + "," + g + "," + b + "," + a.toFixed(3) + ")"
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                if (width <= 2 || height <= 2)
                    return

                // Draw btop horizontal reference grid lines (25%, 50%, 75%)
                ctx.strokeStyle = toCss(SideBarStyle.perfTrackSecondary)
                ctx.lineWidth = 1
                for (var g = 1; g <= 3; g++) {
                    var gy = height * (g / 4.0)
                    ctx.beginPath()
                    ctx.moveTo(0, gy)
                    ctx.lineTo(width, gy)
                    ctx.stroke()
                }

                var arr = graphRoot.values || []
                if (arr.length === 0)
                    return

                var n = arr.length
                var pts = []
                for (var i = 0; i < n; i++) {
                    var px = n > 1 ? (width * (i / (n - 1))) : width
                    var py = height - Math.max(0.0, Math.min(1.0, arr[i] || 0)) * (height - 4) - 2
                    pts.push([px, py])
                }

                // Area fill under sparkline
                ctx.beginPath()
                ctx.moveTo(0, height)
                if (pts.length === 1) {
                    ctx.lineTo(0, pts[0][1])
                    ctx.lineTo(width, pts[0][1])
                } else {
                    for (var j = 0; j < pts.length; j++) {
                        ctx.lineTo(pts[j][0], pts[j][1])
                    }
                }
                ctx.lineTo(width, height)
                ctx.closePath()
                ctx.fillStyle = toCss(SideBarStyle.perfGraphFill)
                ctx.fill()

                // Top crest stroke
                ctx.beginPath()
                if (pts.length === 1) {
                    ctx.moveTo(0, pts[0][1])
                    ctx.lineTo(width, pts[0][1])
                } else {
                    ctx.moveTo(pts[0][0], pts[0][1])
                    for (var k = 1; k < pts.length; k++) {
                        ctx.lineTo(pts[k][0], pts[k][1])
                    }
                }
                ctx.strokeStyle = toCss(SideBarStyle.perfArcPrimary)
                ctx.lineWidth = 1.8
                ctx.lineJoin = "round"
                ctx.lineCap = "round"
                ctx.stroke()

                // Highlight hovered sample marker
                var hIdx = graphRoot.hoveredIdx
                if (hIdx >= 0 && hIdx < pts.length) {
                    var hx = pts[hIdx][0]
                    var hy = pts[hIdx][1]
                    ctx.beginPath()
                    ctx.moveTo(hx, 0)
                    ctx.lineTo(hx, height)
                    ctx.strokeStyle = toCss(SideBarStyle.perfTrackPrimary)
                    ctx.lineWidth = 1
                    ctx.stroke()

                    ctx.beginPath()
                    ctx.arc(hx, hy, 3.5, 0, Math.PI * 2, false)
                    ctx.fillStyle = toCss(SideBarStyle.perfArcPrimary)
                    ctx.fill()
                }
            }
        }

        MouseArea {
            id: graphMouse
            anchors.fill: parent
            hoverEnabled: true
            onPressed: function(mouse) {
                var pt = mapToItem(null, mouse.x, mouse.y)
                bar.beginDragCheck(pt.x, pt.y)
            }
            onPositionChanged: function(mouse) {
                graphCanvas.requestPaint()
                if (!pressed) return
                var pt = mapToItem(null, mouse.x, mouse.y)
                bar.moveDragCheck(pt.x, pt.y)
            }
            onReleased: bar.endDragCheck()
            onCanceled: bar.cancelDragCheck()
            onEntered: graphCanvas.requestPaint()
            onExited: graphCanvas.requestPaint()
        }
    }
}
