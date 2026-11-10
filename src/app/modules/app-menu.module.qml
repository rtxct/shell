// ============================================================================
// File: modules/app-menu.module.qml
// Purpose: Docked desktop applications menu with type-to-search auto-reveal, keyboard navigation, and drag-to-detach handle.
// Public API:
//   - Properties: open, floatManager, fg, dim, accent, cardBg, searchQuery, isSearching, allApps, filteredApps, selectedIndex ...
//   - Signals:    closeRequested()
//   - Functions:  close(), resetSearch(), reloadApps(), filterApps(), launchCurrent(), applyTabCompletion()
// Dependencies: QtQuick, "../components", "../styles", "../theme", QtQuick.Layouts, Quickshell, Quickshell.Widgets
// ============================================================================
import QtQuick
import "../components"
import "../styles"
import "../../../themes"
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

// The applications menu card:
//   - Filtered desktop applications from DesktopEntries.applications
//   - Search input only shows at the top when the user starts typing, otherwise hidden
//   - Morphs directly from the bottom-left Applications Drop button, glued to the bottom edge of the screen
//   - Keyboard navigation (Up/Down arrows, Enter to launch, Escape to dismiss)
Item {
    id: root

    // ── configuration & wiring ──
    property bool open: false
    property var floatManager: null
    property color fg: AppMenuStyle.textPrimary
    property color dim: AppMenuStyle.textDim
    property color accent: AppMenuStyle.accent
    property color cardBg: AppMenuStyle.cardBg

    signal closeRequested()
    function close() { root.closeRequested() }

    // ── state ──
    property string searchQuery: ""
    property bool isSearching: false
    property bool isTabbing: false
    property var allApps: []
    property var filteredApps: []
    property int selectedIndex: -1

    // ── command execution mode (triggered by ">") ──
    readonly property bool isCommandMode: searchQuery.startsWith(">")
    property var allCommands: []
    property var filteredCommands: []

    // ── clipboard history mode (triggered by "\") ──
    readonly property bool isClipboardMode: searchQuery.startsWith("\\")
    property var allClipboards: []
    property var filteredClipboards: []

    readonly property var currentList: isClipboardMode ? filteredClipboards : (isCommandMode ? filteredCommands : filteredApps)

    Process {
        id: loadCommandsProc
        command: ["python3", Quickshell.shellPath("src/app/scripts/commands/command-manager.py"), "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.allCommands = JSON.parse(this.text)
                    if (root.isCommandMode) {
                        root.filterCommands(root.searchQuery.slice(1))
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: runCmdProc
        function execute(cmd) {
            command = ["python3", Quickshell.shellPath("src/app/scripts/commands/command-manager.py"), "run", cmd]
            running = true
        }
    }

    Process {
        id: loadClipboardProc
        command: ["python3", Quickshell.shellPath("src/app/scripts/clipboard/clipboard-manager.py"), "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.allClipboards = JSON.parse(this.text)
                    if (root.isClipboardMode) {
                        var prev = root.selectedIndex
                        root.filterClipboard(root.searchQuery.slice(1))
                        if (prev >= 0 && root.filteredClipboards.length > 0) {
                            root.selectedIndex = Math.min(prev, root.filteredClipboards.length - 1)
                        }
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: copyClipboardProc
        function execute(rawEntry) {
            command = ["python3", Quickshell.shellPath("src/app/scripts/clipboard/clipboard-manager.py"), "copy", rawEntry]
            running = true
        }
    }

    function loadClipboard() {
        if (!loadClipboardProc.running) {
            loadClipboardProc.running = true
        }
    }

    // ── 3-Phase Animation Choreography ──
    // Phase 1 (0.0 -> p1): "go down" (bar dips down to bottom edge, height reduces to dipHeight)
    // Phase 2 (p1 -> p2):  "stretch to the right" (bar stretches horizontally to openWidth along the bottom edge)
    // Phase 3 (p2 -> 1.0): "open it up" (bar expands vertically upward to openHeight, revealing menu content)
    // Closing plays these exact phases in reverse.
    readonly property real p1: AppMenuStyle.phase1End
    readonly property real p2: AppMenuStyle.phase2End
    readonly property real dipH: AppMenuStyle.dipHeight

    property real openProgress: open ? 1.0 : 0.0
    Behavior on openProgress {
        NumberAnimation {
            duration: root.open ? AppMenuStyle.openDurationMs : AppMenuStyle.closeDurationMs
            easing.type: Easing.Linear
        }
    }

    readonly property bool activeOrAnimating: open || openProgress > 0.001
    readonly property bool isActivelyDetaching: dragHandleMouse.isDetaching

    readonly property real closedWidth: AppLauncherStyle.barWidth
    readonly property real closedHeight: AppLauncherStyle.barHeight
    readonly property real openWidth: AppMenuStyle.menuWidth
    readonly property real openHeight: Math.min(AppMenuStyle.maxPopupHeight, parent ? parent.height - AppMenuStyle.screenHeightMargin : AppMenuStyle.maxPopupHeight)

    function calcCurrentWidth(p) {
        if (p <= p1) return closedWidth
        if (p >= p2) return openWidth
        var u = (p - p1) / (p2 - p1)
        var e = 1.0 - Math.pow(1.0 - u, 3)
        return closedWidth + (openWidth - closedWidth) * e
    }

    function calcCurrentHeight(p) {
        if (p <= p1) {
            var u1 = p1 > 0 ? p / p1 : 1.0
            var e1 = u1 < 0.5 ? 2.0 * u1 * u1 : 1.0 - Math.pow(-2.0 * u1 + 2.0, 2) / 2.0
            return closedHeight + (dipH - closedHeight) * e1
        }
        if (p <= p2) {
            return dipH
        }
        var u3 = (1.0 - p2) > 0 ? (p - p2) / (1.0 - p2) : 1.0
        var e3 = 1.0 - Math.pow(1.0 - u3, 3)
        return dipH + (openHeight - dipH) * e3
    }

    readonly property Item maskItem: maskArea
    Item {
        id: maskArea
        anchors.fill: parent
        width: (root.activeOrAnimating || root.isActivelyDetaching) ? root.width : 0
        height: (root.activeOrAnimating || root.isActivelyDetaching) ? root.height : 0
    }

    width: calcCurrentWidth(openProgress)
    height: calcCurrentHeight(openProgress)

    // Position: glued to the bottom edge of the screen
    y: parent ? parent.height - height : 0
    visible: open || activeOrAnimating || isActivelyDetaching

    onOpenChanged: {
        if (open) {
            selectedIndex = -1
            reloadApps()
            if (allCommands.length === 0 && !loadCommandsProc.running) {
                loadCommandsProc.running = true
            }
            if (isClipboardMode) {
                loadClipboard()
            }
            root.focusMenu()
            Qt.callLater(root.focusMenu)
        } else {
            resetSearch()
        }
    }

    // Give keyboard focus directly to searchInput immediately upon opening so fast typing
    // during the 3-phase open animation or search-bar reveal animation is never dropped.
    function focusMenu() {
        if (!root.open) return
        if (searchInput.enabled && searchInput.visible) {
            searchInput.forceActiveFocus()
            searchInput.cursorPosition = searchInput.text.length
        } else {
            root.forceActiveFocus()
        }
    }

    onVisibleChanged: if (visible && root.open) root.focusMenu()

    // The compositor grants keyboard focus to the layer surface asynchronously after it switches
    // to Exclusive; re-apply item focus when the window actually becomes active, and guard
    // across early frames until searchInput holds activeFocus on an active window.
    readonly property bool windowActive: Window.active
    onWindowActiveChanged: if (windowActive && root.open) root.focusMenu()

    Timer {
        id: focusGuardTimer
        interval: 16
        repeat: true
        running: root.open && (!searchInput.activeFocus || !root.windowActive)
        onTriggered: {
            if (!root.open) {
                stop()
                return
            }
            root.focusMenu()
        }
    }

    function openWithQuery(prefix) {
        root.isSearching = true
        searchInput.text = prefix
        root.searchQuery = prefix
        if (prefix.startsWith("\\")) {
            loadClipboard()
        } else if (prefix.startsWith(">")) {
            if (allCommands.length === 0 && !loadCommandsProc.running) {
                loadCommandsProc.running = true
            }
        }
        filterApps()
        root.focusMenu()
    }

    function resetSearch() {
        searchQuery = ""
        isSearching = false
        isTabbing = false
        searchInput.text = ""
        selectedIndex = -1
        filterApps()
    }

    function reloadApps() {
        var raw = (DesktopEntries && DesktopEntries.applications) ? DesktopEntries.applications.values : []
        var list = []
        for (var i = 0; i < raw.length; i++) {
            var app = raw[i]
            if (!app || app.noDisplay || !app.name) continue
            list.push(app)
        }
        list.sort(function(a, b) {
            return a.name.localeCompare(b.name)
        })
        allApps = list
        filterApps()
    }

    function filterApps() {
        if (isClipboardMode) {
            filterClipboard(searchQuery.slice(1))
            return
        }
        if (isCommandMode) {
            filterCommands(searchQuery.slice(1))
            return
        }
        var q = searchQuery.trim().toLowerCase()
        if (!q) {
            filteredApps = allApps
            selectedIndex = -1
            return
        }
        var list = []
        for (var i = 0; i < allApps.length; i++) {
            var app = allApps[i]
            var name = app.name.toLowerCase()
            var comment = (app.comment || "").toLowerCase()
            var gen = (app.genericName || "").toLowerCase()
            if (name.includes(q) || comment.includes(q) || gen.includes(q)) {
                list.push(app)
            }
        }
        list.sort(function(a, b) {
            var aStarts = a.name.toLowerCase().startsWith(q)
            var bStarts = b.name.toLowerCase().startsWith(q)
            if (aStarts && !bStarts) return -1
            if (!aStarts && bStarts) return 1
            return a.name.localeCompare(b.name)
        })
        filteredApps = list
        selectedIndex = -1
    }

    function filterClipboard(clipText) {
        var raw = clipText.trim()
        var q = raw.toLowerCase()
        if (allClipboards.length === 0) {
            loadClipboard()
            filteredClipboards = []
            return
        }
        if (!q) {
            filteredClipboards = allClipboards
            return
        }
        var list = []
        for (var i = 0; i < allClipboards.length; i++) {
            var item = allClipboards[i]
            var name = (item.name || "").toLowerCase()
            var desc = (item.desc || "").toLowerCase()
            var rawText = (item.raw || "").toLowerCase()
            if (name.includes(q) || desc.includes(q) || rawText.includes(q)) {
                list.push(item)
            }
        }
        filteredClipboards = list
    }

    function filterCommands(cmdText) {
        var raw = cmdText.trim()
        var q = raw.toLowerCase()
        var list = []

        if (raw.length > 0) {
            list.push({
                name: raw,
                desc: "Run with zsh: " + raw,
                type: "exec",
                isCustomExec: true
            })
        }

        if (allCommands.length === 0) {
            if (!loadCommandsProc.running) loadCommandsProc.running = true
            filteredCommands = list
            selectedIndex = -1
            return
        }

        if (!q) {
            for (var i = 0; i < allCommands.length && list.length < 50; i++) {
                list.push(allCommands[i])
            }
        } else {
            var exactMatches = []
            var prefixMatches = []
            var containsMatches = []
            for (var j = 0; j < allCommands.length; j++) {
                var c = allCommands[j]
                var cName = c.name.toLowerCase()
                if (cName === q) {
                    exactMatches.push(c)
                } else if (cName.startsWith(q)) {
                    prefixMatches.push(c)
                } else if (cName.indexOf(q) !== -1 || (c.desc && c.desc.toLowerCase().indexOf(q) !== -1)) {
                    containsMatches.push(c)
                }
            }
            var combined = exactMatches.concat(prefixMatches).concat(containsMatches)
            for (var k = 0; k < combined.length && list.length < 50; k++) {
                if (list.length > 0 && list[0].isCustomExec && list[0].name.toLowerCase() === combined[k].name.toLowerCase()) {
                    continue
                }
                list.push(combined[k])
            }
        }
        filteredCommands = list
        selectedIndex = -1
    }

    function applyTabCompletion() {
        if (selectedIndex < 0 || selectedIndex >= currentList.length) {
            return
        }
        var item = currentList[selectedIndex]
        if (!item) return
        var itemName = item.name || ""
        if (!itemName) return

        isSearching = true
        isTabbing = true
        var targetText = isClipboardMode ? ("\\ " + itemName) : (isCommandMode ? ("> " + itemName) : itemName)
        searchInput.text = targetText
        searchInput.forceActiveFocus()
        searchInput.cursorPosition = targetText.length
        isTabbing = false
    }

    function launchCurrent() {
        if (isClipboardMode) {
            if (selectedIndex >= 0 && selectedIndex < filteredClipboards.length) {
                copyClipboardProc.execute(filteredClipboards[selectedIndex].raw)
            } else if (filteredClipboards.length > 0) {
                copyClipboardProc.execute(filteredClipboards[0].raw)
            }
            root.close()
            return
        }

        if (isCommandMode) {
            var inputCmd = searchInput.text.startsWith(">") ? searchInput.text.slice(1).trim() : searchInput.text.trim()
            var cmdToRun = ""
            if (selectedIndex >= 0 && selectedIndex < filteredCommands.length) {
                cmdToRun = filteredCommands[selectedIndex].name
            } else if (inputCmd.length > 0) {
                cmdToRun = inputCmd
            } else if (filteredCommands.length > 0) {
                cmdToRun = filteredCommands[0].name
            }
            if (cmdToRun) {
                runCmdProc.execute(cmdToRun)
                root.close()
            }
            return
        }

        if (selectedIndex >= 0 && selectedIndex < filteredApps.length) {
            var app = filteredApps[selectedIndex]
            if (app && typeof app.execute === "function") {
                app.execute()
            }
            root.close()
        } else if (searchQuery.trim().length > 0 && filteredApps.length > 0) {
            var topApp = filteredApps[0]
            if (topApp && typeof topApp.execute === "function") {
                topApp.execute()
            }
            root.close()
        }
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root.reloadApps() }
    }

    Component.onCompleted: {
        reloadApps()
        loadCommandsProc.running = true
    }

    // Keyboard handling when search is not yet active
    focus: true
    Keys.onPressed: function(event) {
        if (!root.open) return

        if (event.key === Qt.Key_Escape) {
            root.close()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.launchCurrent()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            root.applyTabCompletion()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Down) {
            if (root.currentList.length > 0) {
                if (root.selectedIndex < 0) {
                    root.selectedIndex = 0
                } else {
                    root.selectedIndex = Math.min(root.currentList.length - 1, root.selectedIndex + 1)
                }
                appListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
            }
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Up) {
            if (root.currentList.length > 0) {
                if (root.selectedIndex < 0) {
                    root.selectedIndex = root.currentList.length - 1
                } else {
                    root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                }
                appListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
            }
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Right && !root.isSearching && searchInput.text.length === 0) {
            root.isSearching = true
            searchInput.text = ">"
            searchInput.forceActiveFocus()
            searchInput.cursorPosition = searchInput.text.length
            event.accepted = true
            return
        }

        // Backspace while the search box can't take focus yet (open animation still running)
        if (event.key === Qt.Key_Backspace && root.isSearching) {
            if (searchInput.text.length <= 1) {
                root.resetSearch()
            } else {
                searchInput.text = searchInput.text.slice(0, -1)
            }
            event.accepted = true
            return
        }

        // Printable key press: trigger the search bar and type into it.
        // If a search is already in progress (e.g. opened with "\" and the input isn't
        // focusable yet), append instead of replacing so no keystrokes are lost.
        if (event.text && event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
            searchInput.text = root.isSearching ? searchInput.text + event.text : event.text
            root.isSearching = true
            root.focusMenu()
            event.accepted = true
        }
    }

    // Main Morphing Drop Frame (glued to bottom edge of the screen)
    Drop {
        id: card
        fromBottom: true
        anchors.fill: parent
        fill: root.cardBg
        slant: {
            if (root.openProgress <= root.p2) {
                var u = root.p2 > 0 ? root.openProgress / root.p2 : 0
                return AppLauncherStyle.dropSlant + (2 - AppLauncherStyle.dropSlant) * u
            }
            var u3 = (1.0 - root.p2) > 0 ? (root.openProgress - root.p2) / (1.0 - root.p2) : 1
            return 2 + (AppMenuStyle.openSlant - 2) * u3
        }
        rad: {
            if (root.openProgress <= root.p2) {
                var u = root.p2 > 0 ? root.openProgress / root.p2 : 0
                return AppLauncherStyle.dropRadius + (3 - AppLauncherStyle.dropRadius) * u
            }
            var u3 = (1.0 - root.p2) > 0 ? (root.openProgress - root.p2) / (1.0 - root.p2) : 1
            return 3 + (AppMenuStyle.cardRadius - 3) * u3
        }
        flare: {
            if (root.openProgress <= root.p2) {
                var u = root.p2 > 0 ? root.openProgress / root.p2 : 0
                return AppLauncherStyle.dropFlare + (4 - AppLauncherStyle.dropFlare) * u
            }
            var u3 = (1.0 - root.p2) > 0 ? (root.openProgress - root.p2) / (1.0 - root.p2) : 1
            return 4 + (AppMenuStyle.openFlare - 4) * u3
        }
        tp: 0
        inset: {
            if (root.openProgress <= root.p2) return AppLauncherStyle.dropInset
            var u3 = (1.0 - root.p2) > 0 ? (root.openProgress - root.p2) / (1.0 - root.p2) : 1
            return AppLauncherStyle.dropInset + (AppMenuStyle.openInset - AppLauncherStyle.dropInset) * u3
        }
        bottomInset: {
            if (root.openProgress <= root.p2) return AppLauncherStyle.dropBottomInset
            var u3 = (1.0 - root.p2) > 0 ? (root.openProgress - root.p2) / (1.0 - root.p2) : 1
            return AppLauncherStyle.dropBottomInset + (AppMenuStyle.openBottomInset - AppLauncherStyle.dropBottomInset) * u3
        }

        // ── 1. COLLAPSED "APPLICATIONS" BUTTON CONTENT (fades out as Drop dips down) ──
        Item {
            parent: card.contentArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.closedHeight - AppLauncherStyle.dropInset - AppLauncherStyle.dropBottomInset
            opacity: (root.openProgress <= root.p1) ? Math.max(0.0, 1.0 - (root.openProgress / Math.max(0.001, root.p1)) * 1.5) : 0.0
            visible: opacity > 0.01

            Row {
                anchors.centerIn: parent
                spacing: AppLauncherStyle.contentRowSpacing

                Grid {
                    columns: 2
                    spacing: AppLauncherStyle.iconGridSpacing
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: 4
                        Rectangle {
                            width: AppLauncherStyle.iconDotSize
                            height: AppLauncherStyle.iconDotSize
                            radius: AppLauncherStyle.iconDotRadius
                            color: root.fg
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Menu"
                    color: root.fg
                    font.pixelSize: AppLauncherStyle.labelFontPx
                    font.weight: Font.DemiBold
                }
            }
        }

        // ── 2. EXPANDED MENU CONTENT (fades in as Drop opens up in Phase 3) ──
        Column {
            id: expandedContentCol
            parent: card.contentArea
            anchors.fill: parent
            anchors.margins: AppMenuStyle.cardPadding
            spacing: AppMenuStyle.cardSpacing
            opacity: (root.openProgress > root.p2) ? Math.max(0.0, (root.openProgress - root.p2) / Math.max(0.001, 1.0 - root.p2)) : 0.0
            visible: root.open || root.activeOrAnimating || root.isActivelyDetaching
            enabled: root.open || root.isActivelyDetaching
            onEnabledChanged: if (enabled && root.open) root.focusMenu()

            // Top Drag Handle Bar
            Item {
                id: dragHandleBar
                width: parent.width
                height: AppMenuStyle.dragHandleHeight
                enabled: (root.open && expandedContentCol.opacity > 0.8) || dragHandleMouse.isDetaching

                Rectangle {
                    anchors.centerIn: parent
                    width: AppMenuStyle.dragPillWidth
                    height: AppMenuStyle.dragPillHeight
                    radius: AppMenuStyle.dragPillRadius
                    color: AppMenuStyle.dragPillColor
                }

                MouseArea {
                    id: dragHandleMouse
                    anchors.fill: parent
                    anchors.margins: -AppMenuStyle.dragHitPadding
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.SizeAllCursor
                    property real pressSceneX: 0
                    property real pressSceneY: 0
                    property bool isDetaching: false

                    onPressed: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            root.close()
                            return
                        }
                        var pt = mapToItem(null, mouse.x, mouse.y)
                        pressSceneX = pt.x
                        pressSceneY = pt.y
                        isDetaching = false
                    }

                    onPositionChanged: function(mouse) {
                        if (!pressed) return
                        var pt = mapToItem(null, mouse.x, mouse.y)
                        var dy = pressSceneY - pt.y

                        if (!isDetaching && root.floatManager && (dy > AppMenuStyle.detachThresholdY || Math.hypot(pt.x - pressSceneX, dy) > AppMenuStyle.detachThresholdHypot)) {
                            isDetaching = true
                            root.close()
                            root.floatManager.startDrag({
                                id: "app-menu",
                                title: "Applications",
                                icon: "󰀻",
                                originSide: "bottom",
                                originX: root.x,
                                originY: root.y,
                                width: AppMenuStyle.floatWidth,
                                height: AppMenuStyle.floatHeight
                            }, pt.x, pt.y)
                        } else if (isDetaching && root.floatManager) {
                            root.floatManager.updateDrag(pt.x, pt.y)
                        }
                    }

                    onReleased: {
                        if (isDetaching) {
                            isDetaching = false
                            if (root.floatManager) root.floatManager.endDrag()
                        }
                    }

                    onCanceled: {
                        if (isDetaching) {
                            isDetaching = false
                            if (root.floatManager) root.floatManager.endDrag()
                        }
                    }
                }
            }

            // Search Bar: completely collapses to height 0 when not searching,
            // while remaining visible/enabled so searchInput holds activeFocus from t=0ms.
            Item {
                id: searchBarContainer
                width: parent.width
                height: (root.isSearching || searchInput.text.length > 0) ? AppMenuStyle.searchBarHeight : 0
                opacity: (root.isSearching || searchInput.text.length > 0) ? 1.0 : 0.0
                visible: true
                enabled: root.open
                clip: true

                Behavior on height {
                    NumberAnimation { duration: AppMenuStyle.searchRevealDurationMs; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: AppMenuStyle.searchFadeDurationMs; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    anchors.fill: parent
                    color: AppMenuStyle.searchBoxBg
                    radius: AppMenuStyle.searchBoxRadius
                    border.width: 1
                    border.color: searchInput.activeFocus ? root.accent : AppMenuStyle.searchBoxBorder
                    Behavior on border.color { ColorAnimation { duration: AppMenuStyle.borderColorAnimMs } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: AppMenuStyle.searchBoxLeftMargin
                        anchors.rightMargin: AppMenuStyle.searchBoxRightMargin
                        spacing: AppMenuStyle.searchRowSpacing

                        Text {
                            text: root.isClipboardMode ? "󰅍" : (root.isCommandMode ? "󰞷" : "")
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: AppMenuStyle.searchInputFontPx
                            color: (root.isClipboardMode || root.isCommandMode) ? root.accent : (searchInput.activeFocus ? root.accent : root.dim)
                            Layout.alignment: Qt.AlignVCenter
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            color: root.fg
                            font.pixelSize: AppMenuStyle.searchInputFontPx
                            font.weight: Font.Medium
                            selectByMouse: true
                            selectionColor: root.accent
                            selectedTextColor: AppMenuStyle.textOnAccent
                            clip: true

                            Text {
                                text: root.isClipboardMode ? "    Search clipboard history…" : (root.isCommandMode ? "    Type a command to execute with zsh…" : "Search applications…")
                                color: AppMenuStyle.textPlaceholder
                                font.pixelSize: AppMenuStyle.searchInputFontPx
                                visible: (!searchInput.text && !searchInput.activeFocus) || (root.isCommandMode && searchInput.text === ">") || (root.isClipboardMode && searchInput.text === "\\")
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            onTextChanged: {
                                if (text.length > 0 && !root.isSearching) {
                                    root.isSearching = true
                                } else if (text.length === 0 && root.isSearching && !root.isTabbing) {
                                    root.isSearching = false
                                }
                                if (!root.isTabbing) {
                                    root.selectedIndex = -1
                                    var wasClip = root.isClipboardMode
                                    root.searchQuery = text
                                    if (!wasClip && text.startsWith("\\")) {
                                        root.loadClipboard()
                                    }
                                    root.filterApps()
                                }
                            }

                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Escape) {
                                    root.close()
                                    event.accepted = true
                                    return
                                }
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.launchCurrent()
                                    event.accepted = true
                                    return
                                }
                                if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                    root.applyTabCompletion()
                                    event.accepted = true
                                    return
                                }
                                if (event.key === Qt.Key_Down) {
                                    if (root.currentList.length > 0) {
                                        if (root.selectedIndex < 0) {
                                            root.selectedIndex = 0
                                        } else {
                                            root.selectedIndex = Math.min(root.currentList.length - 1, root.selectedIndex + 1)
                                        }
                                        appListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                                    }
                                    event.accepted = true
                                    return
                                }
                                if (event.key === Qt.Key_Up) {
                                    if (root.currentList.length > 0) {
                                        if (root.selectedIndex < 0) {
                                            root.selectedIndex = root.currentList.length - 1
                                        } else {
                                            root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                                        }
                                        appListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                                    }
                                    event.accepted = true
                                    return
                                }
                                if (event.key === Qt.Key_Right && !root.isSearching && searchInput.text.length === 0) {
                                    root.isSearching = true
                                    searchInput.text = ">"
                                    searchInput.forceActiveFocus()
                                    searchInput.cursorPosition = searchInput.text.length
                                    event.accepted = true
                                    return
                                }
                                if (event.key === Qt.Key_Backspace && searchInput.text.length <= 1) {
                                    root.resetSearch()
                                    root.focusMenu()
                                    event.accepted = true
                                    return
                                }
                            }
                        }

                        // Clear button
                        Text {
                            text: "✕"
                            font.pixelSize: AppMenuStyle.clearIconFontPx
                            color: clearMouse.containsMouse ? root.fg : root.dim
                            visible: searchInput.text.length > 0
                            Layout.alignment: Qt.AlignVCenter

                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                anchors.margins: -AppMenuStyle.clearHitPadding
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.resetSearch()
                                    root.focusMenu()
                                }
                            }
                        }
                    }
                }
            }

            // Application / Command List
            ListView {
                id: appListView
                width: parent.width
                height: Math.max(0, parent.height - AppMenuStyle.listVerticalReserve - (searchBarContainer.height > 1 ? searchBarContainer.height + parent.spacing : 0))
                enabled: root.open && expandedContentCol.opacity > 0.8
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: root.selectedIndex
                model: root.currentList

                // Scroll indicator
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: AppMenuStyle.scrollBarRightMargin
                    y: appListView.visibleArea.yPosition * appListView.height
                    width: AppMenuStyle.scrollBarWidth
                    height: Math.max(AppMenuStyle.scrollBarMinHeight, appListView.visibleArea.heightRatio * appListView.height)
                    radius: AppMenuStyle.scrollBarRadius
                    color: AppMenuStyle.dragPillColor
                    visible: appListView.visibleArea.heightRatio < 1.0
                    opacity: (appListView.moving || appListView.flicking) ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: AppMenuStyle.scrollFadeDurationMs } }
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index

                    width: appListView.width
                    height: AppMenuStyle.itemRowHeight

                    Rectangle {
                        id: rowBg
                        anchors.fill: parent
                        radius: AppMenuStyle.rowRadius
                        color: (row.index === root.selectedIndex && root.selectedIndex >= 0) ? AppMenuStyle.rowSelectedBg
                               : (rowMouse.containsMouse ? AppMenuStyle.rowHoverBg : AppMenuStyle.transparent)
                        Behavior on color { ColorAnimation { duration: AppMenuStyle.rowColorAnimDurationMs } }
                    }

                    // App Title & Description / Command & Alias Details
                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: AppMenuStyle.textLeftMargin
                        anchors.right: parent.right
                        anchors.rightMargin: AppMenuStyle.textRightMargin
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: AppMenuStyle.textSpacing

                        Text {
                            width: parent.width
                            text: row.modelData.name || ""
                            color: root.fg
                            font.pixelSize: AppMenuStyle.appNameFontPx
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: row.modelData.desc || row.modelData.comment || row.modelData.genericName || ""
                            color: root.dim
                            font.pixelSize: AppMenuStyle.appDescFontPx
                            elide: Text.ElideRight
                            visible: text.length > 0
                        }
                    }

                    // Divider between rows
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.leftMargin: AppMenuStyle.dividerLeftMargin
                        anchors.right: parent.right
                        anchors.rightMargin: AppMenuStyle.dividerRightMargin
                        height: AppMenuStyle.dividerHeight
                        color: AppMenuStyle.rowDividerColor
                        visible: row.index < root.currentList.length - 1
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                root.close()
                                return
                            }
                            root.selectedIndex = row.index
                            if (root.isClipboardMode) {
                                if (row.modelData && row.modelData.raw) {
                                    copyClipboardProc.execute(row.modelData.raw)
                                    root.close()
                                }
                                return
                            }
                            if (root.isCommandMode) {
                                if (row.modelData && row.modelData.name) {
                                    runCmdProc.execute(row.modelData.name)
                                    root.close()
                                }
                                return
                            }
                            if (row.modelData && typeof row.modelData.execute === "function") {
                                row.modelData.execute()
                            }
                            root.close()
                        }
                    }
                }

                // Empty search result placeholder
                Text {
                    anchors.centerIn: parent
                    visible: root.currentList.length === 0
                    text: root.isClipboardMode
                        ? (loadClipboardProc.running ? "Loading clipboard history…" : "No matching clipboard items")
                        : (root.isCommandMode ? "No matching commands found" : (root.searchQuery ? "No applications found" : "No applications available"))
                    color: root.dim
                    font.pixelSize: AppMenuStyle.appNameFontPx
                }
            }
        }
    }
}
