// ============================================================================
// File: modules/floating-window-manager.module.qml
// Purpose: Coordinator managing 8 pre-allocated FloatingWindow slots, drag-to-detach sessions, and dynamic panel component instantiation on qs-floating.
// Public API:
//   - Properties: screenW, screenH, ctlTop, ctlLeft, audio, workspaces, events, weather, sticknotes, notifications, isDraggingAny, currentDragSlot ...
//   - Signals:    windowDocked(string id), windowClosed(string id)
//   - Functions:  resolveComponent(winId, fallbackComp), findSlot(winId), getFreeSlot(), isFloating(winId), startDrag(config, mouseX, mouseY), updateDrag(mouseX, mouseY), endDrag(), openFloating(config), closeWindow(winId), dockWindow(winId), closeAll()
// Dependencies: QtQuick, "../components", "../styles"
// ============================================================================
import QtQuick
import "../components"
import "../styles"

// Coordinator that manages all floating, draggable Quickshell windows.
// Provides drag orchestration from docked widgets, boundary clamping, docking callbacks,
// and LayerShell input mask exposure.
Item {
    id: root

    property real screenW: parent ? parent.width : 1920
    property real screenH: parent ? parent.height : 1080

    property var ctlTop: null
    property var ctlLeft: null
    property var audio: null
    property var workspaces: null
    property var events: null
    property var weather: null
    property var sticknotes: null
    property var notifications: null

    property bool isDraggingAny: false
    property var currentDragSlot: null
    property point dragPressOffset: Qt.point(0, 0)
    property bool hasLeftDockZone: false

    signal windowDocked(string id)
    signal windowClosed(string id)

    // ── Visibility & Surface Mapping State (with 250ms hide delay for close animations) ──
    readonly property bool hasActiveSlots: {
        for (var i = 0; i < slots.length; i++) {
            if (slots[i].active) return true
        }
        return false
    }

    readonly property bool isDraggingAnySlot: {
        for (var i = 0; i < slots.length; i++) {
            if (slots[i].isDragging) return true
        }
        return isDraggingAny
    }

    readonly property bool shouldBeVisible: hasActiveSlots || isDraggingAnySlot
    property bool layerVisible: false

    Timer {
        id: hideTimer
        interval: FloatingWindowStyle.managerHideDelayMs
        repeat: false
        onTriggered: {
            if (!root.shouldBeVisible) {
                root.layerVisible = false
            }
        }
    }

    onShouldBeVisibleChanged: {
        if (shouldBeVisible) {
            hideTimer.stop()
            layerVisible = true
        } else {
            hideTimer.restart()
        }
    }

    // ── Pre-packaged Panel Components ──
    Component { id: compCalendar; CalendarPanel {} }
    Component { id: compWorkspaces; WorkspaceCentral {} }
    Component { id: compTopLeft; TopLeftBar { isFloatingWindow: true } }
    Component { id: compTopRight; TopRightBar { isFloatingWindow: true } }
    Component { id: compAudio; FloatingAudioPanel {} }
    Component { id: compVolumeBar; FloatingSliderBarPanel { mode: "output" } }
    Component { id: compMicBar; FloatingSliderBarPanel { mode: "input" } }
    Component { id: compNotif; FloatingNotifPanel {} }
    Component { id: compAppMenu; FloatingAppMenuPanel {} }
    Component { id: compStickNote; FloatingStickNotePanel {} }
    Component { id: compPlaceholder; PanelPlaceholder {} }

    function resolveComponent(winId, fallbackComp) {
        if (fallbackComp) return fallbackComp
        if (winId === "calendar") return compCalendar
        if (winId === "workspaces") return compWorkspaces
        if (winId === "top-left") return compTopLeft
        if (winId === "top-right") return compTopRight
        if (winId === "sound") return compAudio
        if (winId === "volume-bar") return compVolumeBar
        if (winId === "mic-bar") return compMicBar
        if (winId === "notif-center") return compNotif
        if (winId === "app-menu") return compAppMenu
        if (winId && winId.indexOf("sticknote-") === 0) return compStickNote
        return compPlaceholder
    }

    // ── Slot Allocation & Public Exposure ──
    readonly property var slots: [_fw0, _fw1, _fw2, _fw3, _fw4, _fw5, _fw6, _fw7]
    readonly property var fw0: _fw0
    readonly property var fw1: _fw1
    readonly property var fw2: _fw2
    readonly property var fw3: _fw3
    readonly property var fw4: _fw4
    readonly property var fw5: _fw5
    readonly property var fw6: _fw6
    readonly property var fw7: _fw7

    readonly property bool isCalendarFloating: (_fw0.active && _fw0.winId === "calendar")
                                            || (_fw1.active && _fw1.winId === "calendar")
                                            || (_fw2.active && _fw2.winId === "calendar")
                                            || (_fw3.active && _fw3.winId === "calendar")
                                            || (_fw4.active && _fw4.winId === "calendar")
                                            || (_fw5.active && _fw5.winId === "calendar")
                                            || (_fw6.active && _fw6.winId === "calendar")
                                            || (_fw7.active && _fw7.winId === "calendar")

    readonly property bool isWorkspacesFloating: (_fw0.active && _fw0.winId === "workspaces")
                                              || (_fw1.active && _fw1.winId === "workspaces")
                                              || (_fw2.active && _fw2.winId === "workspaces")
                                              || (_fw3.active && _fw3.winId === "workspaces")
                                              || (_fw4.active && _fw4.winId === "workspaces")
                                              || (_fw5.active && _fw5.winId === "workspaces")
                                              || (_fw6.active && _fw6.winId === "workspaces")
                                              || (_fw7.active && _fw7.winId === "workspaces")

    readonly property bool isNotifFloating: (_fw0.active && _fw0.winId === "notif-center")
                                         || (_fw1.active && _fw1.winId === "notif-center")
                                         || (_fw2.active && _fw2.winId === "notif-center")
                                         || (_fw3.active && _fw3.winId === "notif-center")
                                         || (_fw4.active && _fw4.winId === "notif-center")
                                         || (_fw5.active && _fw5.winId === "notif-center")
                                         || (_fw6.active && _fw6.winId === "notif-center")
                                         || (_fw7.active && _fw7.winId === "notif-center")

    readonly property bool isSoundFloating: (_fw0.active && _fw0.winId === "sound")
                                         || (_fw1.active && _fw1.winId === "sound")
                                         || (_fw2.active && _fw2.winId === "sound")
                                         || (_fw3.active && _fw3.winId === "sound")
                                         || (_fw4.active && _fw4.winId === "sound")
                                         || (_fw5.active && _fw5.winId === "sound")
                                         || (_fw6.active && _fw6.winId === "sound")
                                         || (_fw7.active && _fw7.winId === "sound")

    readonly property bool isAppMenuFloating: (_fw0.active && _fw0.winId === "app-menu")
                                           || (_fw1.active && _fw1.winId === "app-menu")
                                           || (_fw2.active && _fw2.winId === "app-menu")
                                           || (_fw3.active && _fw3.winId === "app-menu")
                                           || (_fw4.active && _fw4.winId === "app-menu")
                                           || (_fw5.active && _fw5.winId === "app-menu")
                                           || (_fw6.active && _fw6.winId === "app-menu")
                                           || (_fw7.active && _fw7.winId === "app-menu")

    readonly property bool isVolumeBarFloating: (_fw0.active && _fw0.winId === "volume-bar")
                                             || (_fw1.active && _fw1.winId === "volume-bar")
                                             || (_fw2.active && _fw2.winId === "volume-bar")
                                             || (_fw3.active && _fw3.winId === "volume-bar")
                                             || (_fw4.active && _fw4.winId === "volume-bar")
                                             || (_fw5.active && _fw5.winId === "volume-bar")
                                             || (_fw6.active && _fw6.winId === "volume-bar")
                                             || (_fw7.active && _fw7.winId === "volume-bar")

    readonly property bool isMicBarFloating: (_fw0.active && _fw0.winId === "mic-bar")
                                          || (_fw1.active && _fw1.winId === "mic-bar")
                                          || (_fw2.active && _fw2.winId === "mic-bar")
                                          || (_fw3.active && _fw3.winId === "mic-bar")
                                          || (_fw4.active && _fw4.winId === "mic-bar")
                                          || (_fw5.active && _fw5.winId === "mic-bar")
                                          || (_fw6.active && _fw6.winId === "mic-bar")
                                          || (_fw7.active && _fw7.winId === "mic-bar")

    readonly property bool isTopLeftFloating: (_fw0.active && _fw0.winId === "top-left")
                                           || (_fw1.active && _fw1.winId === "top-left")
                                           || (_fw2.active && _fw2.winId === "top-left")
                                           || (_fw3.active && _fw3.winId === "top-left")
                                           || (_fw4.active && _fw4.winId === "top-left")
                                           || (_fw5.active && _fw5.winId === "top-left")
                                           || (_fw6.active && _fw6.winId === "top-left")
                                           || (_fw7.active && _fw7.winId === "top-left")

    readonly property bool isTopRightFloating: (_fw0.active && _fw0.winId === "top-right")
                                            || (_fw1.active && _fw1.winId === "top-right")
                                            || (_fw2.active && _fw2.winId === "top-right")
                                            || (_fw3.active && _fw3.winId === "top-right")
                                            || (_fw4.active && _fw4.winId === "top-right")
                                            || (_fw5.active && _fw5.winId === "top-right")
                                            || (_fw6.active && _fw6.winId === "top-right")
                                            || (_fw7.active && _fw7.winId === "top-right")

    function findSlot(winId) {
        for (var i = 0; i < slots.length; i++) {
            if (slots[i].active && slots[i].winId === winId) return slots[i]
        }
        return null
    }

    function getFreeSlot() {
        for (var i = 0; i < slots.length; i++) {
            if (!slots[i].active) return slots[i]
        }
        return slots[0] // fallback reuse
    }

    function isFloating(winId) {
        if (!winId) return false
        if (winId === "calendar") return isCalendarFloating
        if (winId === "workspaces") return isWorkspacesFloating
        if (winId === "top-left") return isTopLeftFloating
        if (winId === "top-right") return isTopRightFloating
        if (winId === "notif-center") return isNotifFloating
        if (winId === "sound") return isSoundFloating
        if (winId === "app-menu") return isAppMenuFloating
        if (winId === "volume-bar") return isVolumeBarFloating
        if (winId === "mic-bar") return isMicBarFloating
        return (_fw0.active && _fw0.winId === winId)
            || (_fw1.active && _fw1.winId === winId)
            || (_fw2.active && _fw2.winId === winId)
            || (_fw3.active && _fw3.winId === winId)
            || (_fw4.active && _fw4.winId === winId)
            || (_fw5.active && _fw5.winId === winId)
            || (_fw6.active && _fw6.winId === winId)
            || (_fw7.active && _fw7.winId === winId)
    }

    // ── Drag Orchestration from Docked Widgets ──
    function startDrag(config, mouseX, mouseY) {
        var slot = findSlot(config.id)
        if (!slot) slot = getFreeSlot()

        var w = config.width || FloatingWindowStyle.managerDefaultWidth
        var h = config.height || FloatingWindowStyle.managerDefaultHeight

        slot.winId = config.id
        slot.title = config.title || "Window"
        slot.icon = config.icon || "󰄯"
        slot.originSide = config.originSide || "left"
        slot.originX = config.originX || 0
        slot.originY = config.originY || 0
        slot.winWidth = w
        slot.winHeight = h
        slot.ctl = config.ctl || (config.originSide === "top" ? root.ctlTop : root.ctlLeft)
        slot.audio = config.audio || root.audio
        slot.workspaces = config.workspaces || root.workspaces
        slot.events = config.events || root.events
        slot.weather = config.weather || root.weather
        slot.sticknotes = config.sticknotes || root.sticknotes
        slot.notifications = config.notifications || root.notifications
        slot.extraData = config.extraData || null
        slot.contentComponent = resolveComponent(config.id, config.panel || config.component)

        // Position window centered on cursor header
        var targetX = Math.max(0, Math.min(root.screenW - w, mouseX - w / 2))
        var targetY = Math.max(0, Math.min(root.screenH - h, mouseY - 20))
        slot.posX = targetX
        slot.posY = targetY

        slot.active = true
        slot.isDragging = true
        slot.nearDockZone = false
        currentDragSlot = slot
        dragPressOffset = Qt.point(mouseX - targetX, mouseY - targetY)
        hasLeftDockZone = !slot.checkDockZone()
        isDraggingAny = true
    }

    function updateDrag(mouseX, mouseY) {
        if (!currentDragSlot) return
        var targetX = Math.max(0, Math.min(root.screenW - currentDragSlot.winWidth, mouseX - dragPressOffset.x))
        var targetY = Math.max(0, Math.min(root.screenH - currentDragSlot.winHeight, mouseY - dragPressOffset.y))
        currentDragSlot.posX = targetX
        currentDragSlot.posY = targetY
        var inZone = currentDragSlot.checkDockZone()
        if (!inZone) {
            hasLeftDockZone = true
        }
        currentDragSlot.nearDockZone = hasLeftDockZone && inZone
    }

    function endDrag() {
        isDraggingAny = false
        if (!currentDragSlot) return
        currentDragSlot.isDragging = false
        if (currentDragSlot.nearDockZone) {
            currentDragSlot.dock()
        } else if (!hasLeftDockZone && currentDragSlot.checkDockZone()) {
            // If user released during initial pull-out before clearing the full window width,
            // nudge the window just outside the snap zone so it stays cleanly detached.
            if (currentDragSlot.originSide === "right") {
                currentDragSlot.posX = Math.max(0, Math.min(currentDragSlot.posX, root.screenW - currentDragSlot.winWidth - currentDragSlot.snapDistance - 4))
            } else if (currentDragSlot.originSide === "left") {
                currentDragSlot.posX = Math.min(root.screenW - currentDragSlot.winWidth, Math.max(currentDragSlot.posX, currentDragSlot.snapDistance + 4))
            } else if (currentDragSlot.originSide === "top") {
                currentDragSlot.posY = Math.min(root.screenH - currentDragSlot.winHeight, Math.max(currentDragSlot.posY, currentDragSlot.snapDistance + 4))
            } else if (currentDragSlot.originSide === "bottom") {
                currentDragSlot.posY = Math.max(0, Math.min(currentDragSlot.posY, root.screenH - currentDragSlot.winHeight - currentDragSlot.snapDistance - 4))
            }
        }
        currentDragSlot.nearDockZone = false
        currentDragSlot = null
        hasLeftDockZone = false
    }

    // ── Open directly as floating window ──
    function openFloating(config) {
        var slot = findSlot(config.id)
        if (!slot) slot = getFreeSlot()

        var w = config.width || FloatingWindowStyle.managerDefaultWidth
        var h = config.height || FloatingWindowStyle.managerDefaultHeight

        slot.winId = config.id
        slot.title = config.title || "Window"
        slot.icon = config.icon || "󰄯"
        slot.originSide = config.originSide || "left"
        slot.originX = config.originX || 0
        slot.originY = config.originY || 0
        slot.winWidth = w
        slot.winHeight = h
        slot.ctl = config.ctl || (config.originSide === "top" ? root.ctlTop : root.ctlLeft)
        slot.audio = config.audio || root.audio
        slot.workspaces = config.workspaces || root.workspaces
        slot.events = config.events || root.events
        slot.weather = config.weather || root.weather
        slot.sticknotes = config.sticknotes || root.sticknotes
        slot.notifications = config.notifications || root.notifications
        slot.extraData = config.extraData || null
        slot.contentComponent = resolveComponent(config.id, config.panel || config.component)

        // Position window at specified coords or centered on screen
        slot.posX = config.posX !== undefined ? config.posX : (root.screenW - w) / 2
        slot.posY = config.posY !== undefined ? config.posY : (root.screenH - h) / 2

        slot.active = true
        slot.isDragging = false
    }

    function closeWindow(winId) {
        if (currentDragSlot && currentDragSlot.winId === winId) {
            endDrag()
        }
        var slot = findSlot(winId)
        if (slot) {
            slot.active = false
            slot.isDragging = false
            root.windowClosed(winId)
        }
    }

    function dockWindow(winId) {
        if (currentDragSlot && currentDragSlot.winId === winId) {
            endDrag()
        }
        var slot = findSlot(winId)
        if (slot) {
            slot.active = false
            slot.isDragging = false
            root.windowDocked(winId)
        }
    }

    function closeAll() {
        endDrag()
        for (var i = 0; i < slots.length; i++) {
            if (slots[i].active) {
                slots[i].active = false
                slots[i].isDragging = false
                root.windowClosed(slots[i].winId)
            }
        }
    }

    // ── 8 Floating Window Slots ──
    FloatingWindow {
        id: _fw0
        screenW: root.screenW; screenH: root.screenH
        onDockRequested: function(id) { root.dockWindow(id) }
        onCloseRequested: function(id) { root.closeWindow(id) }
    }
    FloatingWindow {
        id: _fw1
        screenW: root.screenW; screenH: root.screenH
        onDockRequested: function(id) { root.dockWindow(id) }
        onCloseRequested: function(id) { root.closeWindow(id) }
    }
    FloatingWindow {
        id: _fw2
        screenW: root.screenW; screenH: root.screenH
        onDockRequested: function(id) { root.dockWindow(id) }
        onCloseRequested: function(id) { root.closeWindow(id) }
    }
    FloatingWindow {
        id: _fw3
        screenW: root.screenW; screenH: root.screenH
        onDockRequested: function(id) { root.dockWindow(id) }
        onCloseRequested: function(id) { root.closeWindow(id) }
    }
    FloatingWindow {
        id: _fw4
        screenW: root.screenW; screenH: root.screenH
        onDockRequested: function(id) { root.dockWindow(id) }
        onCloseRequested: function(id) { root.closeWindow(id) }
    }
    FloatingWindow {
        id: _fw5
        screenW: root.screenW; screenH: root.screenH
        onDockRequested: function(id) { root.dockWindow(id) }
        onCloseRequested: function(id) { root.closeWindow(id) }
    }
    FloatingWindow {
        id: _fw6
        screenW: root.screenW; screenH: root.screenH
        onDockRequested: function(id) { root.dockWindow(id) }
        onCloseRequested: function(id) { root.closeWindow(id) }
    }
    FloatingWindow {
        id: _fw7
        screenW: root.screenW; screenH: root.screenH
        onDockRequested: function(id) { root.dockWindow(id) }
        onCloseRequested: function(id) { root.closeWindow(id) }
    }

    // Flag for fullscreen drag overlay mask on qs-floating.
    // When any floating window slot is being dragged/moved, this ensures qs-floating
    // maintains a full-screen input region so cursor events are never clipped by Wayland.
    property bool enableDragOverlayMask: true

    readonly property Item dragOverlayMask: dragOverlay
    Item {
        id: dragOverlay
        x: 0; y: 0
        width: (root.enableDragOverlayMask && root.isDraggingAnySlot) ? root.screenW : 0
        height: (root.enableDragOverlayMask && root.isDraggingAnySlot) ? root.screenH : 0
    }
}
