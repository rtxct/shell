// ============================================================================
// File: modules/top-left-bar.module.qml
// Purpose: Left wing module of the top bar displaying a btop-style Active
//          Processes monitor with a scrollable process list, real-time filter
//          input, and interactive sorting by Name, CPU Usage, GPU Usage, or
//          Memory Usage.
// Public API:
//   - Properties: processes, filteredProcesses, filterText, sortBy,
//                 sortDescending, totalProcessCount
//   - Functions:  toggleSort(column), clearFilter(), formatMemory(rssKb),
//                 syncProcessModel(resetScroll), applyProcessOutput(text)
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
    side: "left"
    trigger: "click"
    expandedH: SideBarStyle.perfOverviewHeight

    // ── Process Telemetry & Interactive Sort/Filter State ──
    property var procState: ({})
    property var processes: []
    property var filteredProcesses: []
    property string filterText: ""
    property string sortBy: "cpu"          // "name" | "cpu" | "gpu" | "mem"
    property bool sortDescending: true
    property int bootstrapCount: 0

    readonly property int totalProcessCount: bar.processes ? bar.processes.length : 0

    ListModel {
        id: procListModel
    }

    function syncProcessModel(resetScroll) {
        var sorted = ServiceParsers.filterAndSortProcesses(
            bar.processes,
            bar.filterText,
            bar.sortBy,
            bar.sortDescending
        )
        bar.filteredProcesses = sorted

        var newLen = sorted.length
        var oldLen = procListModel.count
        var commonLen = Math.min(oldLen, newLen)

        for (var i = 0; i < commonLen; i++) {
            procListModel.set(i, sorted[i])
        }
        for (var j = commonLen; j < newLen; j++) {
            procListModel.append(sorted[j])
        }
        if (oldLen > newLen) {
            procListModel.remove(newLen, oldLen - newLen)
        }

        if (resetScroll) {
            procListView.positionViewAtBeginning()
        }
    }

    function toggleSort(column) {
        if (bar.sortBy === column) {
            bar.sortDescending = !bar.sortDescending
        } else {
            bar.sortBy = column
            bar.sortDescending = (column !== "name")
        }
        bar.syncProcessModel(true)
    }

    function clearFilter() {
        filterInput.text = ""
        bar.filterText = ""
        bar.syncProcessModel(true)
    }

    function formatMemory(rssKb) {
        var kb = rssKb || 0
        if (kb >= 1024 * 1024) {
            return (kb / (1024.0 * 1024.0)).toFixed(1) + "G"
        }
        return Math.round(kb / 1024.0) + "M"
    }

    function applyProcessOutput(text) {
        var parsed = ServiceParsers.parseProcessList(text, bar.procState)
        bar.procState = parsed
        bar.processes = parsed.processes
        bar.syncProcessModel(false)
    }

    property int lastCopiedPid: -1

    Timer {
        id: copiedResetTimer
        interval: 2000
        onTriggered: bar.lastCopiedPid = -1
    }

    Process {
        id: copyPidProc
        function execute(pid, procName) {
            command = [
                "sh",
                "-c",
                "wl-copy \"$1\" && notify-send -t 1500 -a \"Active Processes\" \"PID $1 was copied\" \"Process: $2\"",
                "--",
                String(pid),
                String(procName || "")
            ]
            running = true
        }
    }

    function copyProcessPid(pid, procName) {
        if (!pid) return
        bar.lastCopiedPid = pid
        copiedResetTimer.restart()
        copyPidProc.execute(pid, procName)
    }

    Process {
        id: procPoller
        command: ["python3", Quickshell.shellPath("src/app/scripts/system/poll-processes.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                bar.applyProcessOutput(this.text)
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
            if (!procPoller.running)
                procPoller.running = true
        }
    }

    function getDetachState() {
        return {
            filterText: bar.filterText,
            sortBy: bar.sortBy,
            sortDescending: bar.sortDescending
        }
    }

    onExtraDataChanged: {
        if (bar.isFloatingWindow && bar.extraData) {
            if (bar.extraData.sortBy) bar.sortBy = bar.extraData.sortBy
            if (bar.extraData.sortDescending !== undefined) bar.sortDescending = bar.extraData.sortDescending
            if (bar.extraData.filterText !== undefined) {
                bar.filterText = bar.extraData.filterText
                filterInput.text = bar.extraData.filterText
            }
            bar.syncProcessModel(true)
        }
    }

    Timer {
        id: pollTimer
        interval: SideBarStyle.perfPollIntervalMs
        running: bar.isFloatingWindow || bar.mine || bar.expand > 0.01
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!procPoller.running)
                procPoller.running = true
        }
    }

    Component.onCompleted: {
        if (!procPoller.running)
            procPoller.running = true
    }

    Item {
        id: contentRoot
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        anchors.topMargin: 8
        anchors.bottomMargin: 8

        // Shared column layout metrics guaranteed to fit inside contentRoot.width
        readonly property real leftPad: 8
        readonly property real rightPad: 4
        readonly property real innerRowW: Math.max(200, width - leftPad - rightPad)
        readonly property real pidColW: 48
        readonly property real userColW: 68
        readonly property real cpuColW: 88
        readonly property real gpuColW: 88
        readonly property real memColW: 108
        readonly property real nameColW: Math.max(
            60,
            innerRowW - pidColW - userColW - cpuColW - gpuColW - memColW
        )

        // ────────────────────────────────────────────────────────────────────
        // 1. Top Header Bar: btop Title, Process Count & Filter Input Box
        // ────────────────────────────────────────────────────────────────────
        Item {
            id: topHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 30

            Row {
                id: titleRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                // btop-style "proc" badge
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: procBadgeText.width + 14
                    height: 22
                    radius: 6
                    color: SideBarStyle.perfCardHoverBg
                    border.width: 1
                    border.color: SideBarStyle.perfCardHoverBorder

                    Text {
                        id: procBadgeText
                        anchors.centerIn: parent
                        text: "PROC"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: SideBarStyle.perfArcPrimary
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Active Processes"
                    font.pixelSize: SideBarStyle.panelFontPx
                    font.weight: Font.Bold
                    color: SideBarStyle.textPrimary
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "·  " + procListModel.count + " / " + bar.totalProcessCount + " tasks"
                    font.pixelSize: 11
                    color: SideBarStyle.perfTextDim
                }
            }

            // Interactive Filter Input Box (btop `/` filter bar)
            Rectangle {
                id: filterBox
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 230
                height: 26
                radius: 7
                color: filterInput.activeFocus || filterBoxMouse.containsMouse
                    ? SideBarStyle.perfCardHoverBg
                    : SideBarStyle.perfCardBg
                border.width: 1
                border.color: filterInput.activeFocus
                    ? SideBarStyle.perfArcPrimary
                    : (filterBoxMouse.containsMouse ? SideBarStyle.perfCardHoverBorder : SideBarStyle.perfCardBorder)

                Behavior on color {
                    ColorAnimation { duration: SideBarStyle.perfHoverDurationMs }
                }
                Behavior on border.color {
                    ColorAnimation { duration: SideBarStyle.perfHoverDurationMs }
                }

                Text {
                    id: filterIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 9
                    anchors.verticalCenter: parent.verticalCenter
                    text: "/"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: filterInput.activeFocus ? SideBarStyle.perfArcPrimary : SideBarStyle.perfTextDim
                }

                Item {
                    anchors.left: filterIcon.right
                    anchors.leftMargin: 6
                    anchors.right: clearFilterBtn.visible ? clearFilterBtn.left : parent.right
                    anchors.rightMargin: 6
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    clip: true

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: filterInput.text.length === 0
                        text: "Filter name, cmd, user, PID..."
                        font.pixelSize: 11
                        color: SideBarStyle.perfTextDim
                    }

                    TextInput {
                        id: filterInput
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: 11
                        color: SideBarStyle.textPrimary
                        selectionColor: SideBarStyle.perfTrackPrimary
                        selectedTextColor: SideBarStyle.textPrimary
                        onTextChanged: {
                            if (bar.filterText !== text) {
                                bar.filterText = text
                                bar.syncProcessModel(true)
                            }
                        }
                        Keys.onEscapePressed: function(event) {
                            if (text.length > 0) {
                                bar.clearFilter()
                                event.accepted = true
                            } else {
                                focus = false
                                event.accepted = false
                            }
                        }
                    }
                }

                MouseArea {
                    id: filterBoxMouse
                    anchors.fill: parent
                    anchors.rightMargin: clearFilterBtn.visible ? 24 : 0
                    hoverEnabled: true
                    cursorShape: Qt.IBeamCursor
                    onClicked: filterInput.forceActiveFocus()
                }

                // Clear Filter Button (only interactive when filter has text)
                Rectangle {
                    id: clearFilterBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    radius: 4
                    visible: filterInput.text.length > 0
                    color: clearMouse.containsMouse ? SideBarStyle.perfTrackPrimary : SideBarStyle.transparent

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: clearMouse.containsMouse ? SideBarStyle.textPrimary : SideBarStyle.perfTextDim
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bar.clearFilter()
                    }
                }
            }
        }

        // ────────────────────────────────────────────────────────────────────
        // 2. Interactive Sort Column Header Bar (Name, CPU, GPU, Memory)
        // ────────────────────────────────────────────────────────────────────
        Rectangle {
            id: tableHeaderBar
            anchors.top: topHeader.bottom
            anchors.topMargin: 6
            anchors.left: parent.left
            anchors.right: parent.right
            height: 28
            radius: 7
            color: SideBarStyle.perfCardBg
            border.width: 1
            border.color: SideBarStyle.perfCardBorder
            clip: true

            Row {
                x: contentRoot.leftPad
                width: contentRoot.innerRowW
                height: parent.height

                // Static PID Header
                Item {
                    width: contentRoot.pidColW
                    height: parent.height

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "PID"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: SideBarStyle.perfTextDim
                    }
                }

                // Interactive Sort Header 1: NAME
                SortColumnButton {
                    width: contentRoot.nameColW
                    height: parent.height
                    columnKey: "name"
                    title: "PROGRAM"
                    alignRight: false
                }

                // Static USER / THREADS Header
                Item {
                    width: contentRoot.userColW
                    height: parent.height

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        text: "USER"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: SideBarStyle.perfTextDim
                    }
                }

                // Interactive Sort Header 2: CPU USAGE
                SortColumnButton {
                    width: contentRoot.cpuColW
                    height: parent.height
                    columnKey: "cpu"
                    title: "CPU %"
                    alignRight: true
                }

                // Interactive Sort Header 3: GPU USAGE
                SortColumnButton {
                    width: contentRoot.gpuColW
                    height: parent.height
                    columnKey: "gpu"
                    title: "GPU %"
                    alignRight: true
                }

                // Interactive Sort Header 4: MEMORY USAGE
                SortColumnButton {
                    width: contentRoot.memColW
                    height: parent.height
                    columnKey: "mem"
                    title: "MEM %"
                    alignRight: true
                }
            }
        }

        // ────────────────────────────────────────────────────────────────────
        // 3. btop Scrollable Process List (Non-clickable display rows)
        // ────────────────────────────────────────────────────────────────────
        Rectangle {
            id: listContainer
            anchors.top: tableHeaderBar.bottom
            anchors.topMargin: 5
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            radius: 8
            color: SideBarStyle.perfCardBg
            border.width: 1
            border.color: SideBarStyle.perfCardBorder
            clip: true

            ListView {
                id: procListView
                anchors.fill: parent
                anchors.topMargin: 3
                anchors.bottomMargin: 3
                clip: true
                interactive: bar.isFloatingWindow
                boundsBehavior: Flickable.StopAtBounds
                model: procListModel
                spacing: 1

                WheelHandler {
                    onWheel: function(event) {
                        var delta = (event.angleDelta.y / 120.0) * 52
                        var maxY = Math.max(0, procListView.contentHeight - procListView.height)
                        procListView.contentY = Math.max(0, Math.min(maxY, procListView.contentY - delta))
                        event.accepted = true
                    }
                }

                delegate: Rectangle {
                    id: procRow
                    required property int index
                    required property int pid
                    required property string name
                    required property string user
                    required property int threads
                    required property real cpuPerc
                    required property real gpuPerc
                    required property real memPerc
                    required property real rssKb
                    required property string cmd

                    width: procListView.width
                    height: 25
                    radius: SideBarStyle.perfRowRadius
                    border.width: 1
                    border.color: rowMouse.containsMouse ? SideBarStyle.perfCardHoverBorder : SideBarStyle.transparent

                    Behavior on border.color {
                        ColorAnimation { duration: SideBarStyle.perfHoverDurationMs; easing.type: Easing.OutCubic }
                    }

                    color: rowMouse.pressed
                        ? SideBarStyle.perfCardPressedBg
                        : (rowMouse.containsMouse
                            ? SideBarStyle.perfRowHoverBg
                            : ((index % 2 === 1) ? SideBarStyle.perfTrackSecondary : SideBarStyle.transparent))

                    Behavior on color {
                        ColorAnimation { duration: SideBarStyle.perfHoverDurationMs; easing.type: Easing.OutCubic }
                    }

                    MouseArea {
                        id: rowMouse
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
                                bar.copyProcessPid(procRow.pid, procRow.name)
                            }
                        }
                        onCanceled: bar.cancelDragCheck()
                    }

                    Row {
                        x: contentRoot.leftPad
                        width: contentRoot.innerRowW
                        height: parent.height

                        // 1. PID
                        Item {
                            width: contentRoot.pidColW
                            height: parent.height
                            clip: true

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: String(procRow.pid)
                                font.pixelSize: 11
                                font.weight: (bar.lastCopiedPid === procRow.pid) ? Font.DemiBold : Font.Normal
                                color: (bar.lastCopiedPid === procRow.pid) ? SideBarStyle.perfArcPrimary : SideBarStyle.perfTextDim
                            }
                        }

                        // 2. Program Name & Command
                        Item {
                            width: contentRoot.nameColW
                            height: parent.height
                            clip: true

                            Row {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                Text {
                                    id: nameLabel
                                    width: Math.min(implicitWidth, parent.width)
                                    elide: Text.ElideRight
                                    text: procRow.name
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: SideBarStyle.textPrimary
                                }

                                Text {
                                    width: Math.max(0, parent.width - nameLabel.width - 6)
                                    elide: Text.ElideRight
                                    visible: width > 16 && procRow.cmd !== procRow.name
                                    text: procRow.cmd
                                    font.pixelSize: 10
                                    color: SideBarStyle.perfTextDim
                                    anchors.baseline: nameLabel.baseline
                                }
                            }
                        }

                        // 3. User
                        Item {
                            width: contentRoot.userColW
                            height: parent.height
                            clip: true

                            Text {
                                width: parent.width - 6
                                anchors.left: parent.left
                                anchors.leftMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                text: procRow.user
                                font.pixelSize: 10
                                color: SideBarStyle.perfTextDim
                            }
                        }

                        // 4. CPU Usage (btop mini bar + %)
                        ProcMetricCell {
                            width: contentRoot.cpuColW
                            height: parent.height
                            percent: procRow.cpuPerc
                            textValue: procRow.cpuPerc.toFixed(1) + "%"
                            highlighted: bar.sortBy === "cpu"
                        }

                        // 5. GPU Usage (btop mini bar + %)
                        ProcMetricCell {
                            width: contentRoot.gpuColW
                            height: parent.height
                            percent: procRow.gpuPerc
                            textValue: procRow.gpuPerc.toFixed(1) + "%"
                            highlighted: bar.sortBy === "gpu"
                        }

                        // 6. Memory Usage (btop mini bar + RSS + %)
                        ProcMetricCell {
                            width: contentRoot.memColW
                            height: parent.height
                            percent: procRow.memPerc
                            textValue: bar.formatMemory(procRow.rssKb) + " " + procRow.memPerc.toFixed(1) + "%"
                            highlighted: bar.sortBy === "mem"
                        }
                    }
                }
            }

            // Minimalist Vertical Scrollbar Indicator
            Rectangle {
                id: scrollTrack
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.top: parent.top
                anchors.topMargin: 5
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                width: 3
                radius: 1.5
                color: SideBarStyle.perfTrackSecondary
                visible: procListView.contentHeight > procListView.height

                Rectangle {
                    width: parent.width
                    radius: 2
                    color: SideBarStyle.perfArcSecondary
                    height: Math.max(
                        20,
                        parent.height * (procListView.height / Math.max(1, procListView.contentHeight))
                    )
                    y: {
                        var maxScroll = Math.max(1, procListView.contentHeight - procListView.height)
                        var maxY = Math.max(0, parent.height - height)
                        return Math.max(0, Math.min(maxY, (procListView.contentY / maxScroll) * maxY))
                    }
                }
            }

            // Empty Filter State
            Text {
                anchors.centerIn: parent
                visible: procListModel.count === 0
                text: bar.filterText.length > 0
                    ? "No processes matching \"" + bar.filterText + "\""
                    : "Scanning active processes..."
                font.pixelSize: 12
                color: SideBarStyle.perfTextDim
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // Embedded Components
    // ════════════════════════════════════════════════════════════════════════

    // Interactive Sortable Column Header Button
    component SortColumnButton: Item {
        id: colBtn

        required property string columnKey
        required property string title
        property bool alignRight: false

        readonly property bool isCurrentSort: bar.sortBy === columnKey

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 3
            anchors.bottomMargin: 3
            anchors.leftMargin: 2
            anchors.rightMargin: colBtn.columnKey === "mem" ? 0 : 2
            radius: 5
            color: colBtn.isCurrentSort
                ? SideBarStyle.perfCardHoverBg
                : (colMouse.containsMouse ? SideBarStyle.perfTrackSecondary : SideBarStyle.transparent)
            border.width: colBtn.isCurrentSort || colMouse.containsMouse ? 1 : 0
            border.color: colBtn.isCurrentSort ? SideBarStyle.perfCardHoverBorder : SideBarStyle.perfCardBorder
            scale: colMouse.pressed ? SideBarStyle.perfCardPressedScale : 1.0
            clip: true

            Behavior on scale {
                NumberAnimation { duration: SideBarStyle.perfHoverDurationMs; easing.type: Easing.OutCubic }
            }
            Behavior on color {
                ColorAnimation { duration: SideBarStyle.perfHoverDurationMs }
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: colBtn.alignRight ? undefined : parent.left
                anchors.leftMargin: colBtn.alignRight ? 0 : 6
                anchors.right: colBtn.alignRight ? parent.right : undefined
                anchors.rightMargin: colBtn.alignRight ? (colBtn.columnKey === "mem" ? 4 : 6) : 0
                spacing: 3

                Text {
                    text: colBtn.title
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: colBtn.isCurrentSort || colMouse.containsMouse
                        ? SideBarStyle.perfArcPrimary
                        : SideBarStyle.perfTextDim
                }

                Text {
                    visible: colBtn.isCurrentSort
                    text: bar.sortDescending ? "▼" : "▲"
                    font.pixelSize: 8
                    color: SideBarStyle.perfArcPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        MouseArea {
            id: colMouse
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
                    bar.toggleSort(colBtn.columnKey)
                }
            }
            onCanceled: bar.cancelDragCheck()
        }
    }

    // Non-interactive btop Metric Cell (Mini Progress Bar + Numeric Value)
    component ProcMetricCell: Item {
        id: cell

        required property real percent
        required property string textValue
        property bool highlighted: false

        readonly property real clampedRatio: Math.max(0.0, Math.min(1.0, (percent || 0.0) / 100.0))
        clip: true

        Rectangle {
            id: miniBar
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            height: 5
            radius: 2.5
            color: SideBarStyle.perfTrackSecondary

            Rectangle {
                width: parent.width * cell.clampedRatio
                height: parent.height
                radius: 2.5
                color: cell.clampedRatio > 0.80
                    ? SideBarStyle.perfDanger
                    : (cell.highlighted ? SideBarStyle.perfArcPrimary : SideBarStyle.perfArcSecondary)
            }
        }

        Text {
            anchors.left: miniBar.right
            anchors.leftMargin: 4
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            text: cell.textValue
            font.pixelSize: 10
            font.weight: cell.highlighted ? Font.DemiBold : Font.Normal
            color: cell.clampedRatio > 0.80
                ? SideBarStyle.perfDanger
                : (cell.highlighted ? SideBarStyle.textPrimary : SideBarStyle.perfTextDim)
        }
    }
}
