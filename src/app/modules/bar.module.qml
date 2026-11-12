// ============================================================================
// File: modules/bar.module.qml
// Purpose: Per-monitor Wayland LayerShell window orchestrator managing space reservation surfaces, bar canvas, input masks, and floating window layer.
// Public API:
//   - Properties: modelData, weather, events, workspaces, audio, sticknotes, notifications, screenW, screenH, windowGap, screenMargin, barMaxWidth, isLeftmostScreen, isRightmostScreen, isTopmostScreen, isBottommostScreen ...
//   - Functions:  applyLayoutConfig(text), closeAll()
// Dependencies: Quickshell, "../components", "../theme", Quickshell.Io, Quickshell.Wayland, QtQuick
// ============================================================================
import Quickshell
import "../components"
import "../components/service-parsers.js" as ServiceParsers
import "../styles"
import "../../../themes"
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// One set of bars per monitor. This file only WIRES things together and holds the few LAYOUT
// values that several components share (like props a React parent passes down).
// Every component's own look (colours, sizes, springs) lives at the top of its own file.
//
//   TOP BAR   strip + clock island (+ two hover bars). Only the strip reserves space, the
//             island overlaps the window.
//   LEFT BAR  strip + workspaces island + six circles. Reserves its WHOLE width: nothing overlaps.
//
//   core/        BarController (shared state + open/close choreography)
//   components/  Strip, Island (base), MiddleBar, WorkspaceIsland, SideBar (base), TopLeftBar,
//                TopRightBar, Circle (base), Drop (the shape), AppLauncher
//   circles/     the six circles of the left bar, one file each
//   panels/      what opens inside the big panels, including AppMenu
//   services/    weather, calendar and workspace data
Scope {
    id: scope

    required property var modelData
    property var weather: null
    property var events: null
    property var workspaces: null
    property var audio: null
    property var sticknotes: null
    property var notifications: null
    property var screenLocker: null

    // ───── layout (configurable via config/layout.config.json) ─────
    readonly property real screenW: modelData.width
    readonly property real screenH: modelData.height
    property real windowGap: 16                    // space between the bars and tiled windows
    property real screenMargin: 40                 // min margin from screen edges
    // top bar
    property real barMaxWidth: 720                 // total width of the top bar
    readonly property real barW: Math.min(barMaxWidth, screenW - screenMargin)
    readonly property real barX: (screenW - barW) / 2
    // left bar
    property real leftBarMaxLength: 620            // total height of the left bar
    readonly property real leftLen: Math.min(leftBarMaxLength, screenH - screenMargin)
    readonly property real leftY: (screenH - leftLen) / 2
    // bottom / application launcher
    property real launcherX: 190                   // ~5cm from left of screen
    property real topGap: 16                       // space between top bar and tiled windows
    property real bottomGap: 18                    // space between bottom of monitor and tiled windows
    property real rightGap: 18                     // space between right of monitor and tiled windows
    property bool appMenuOpen: false

    // ───── multi-monitor perimeter & outer edge detection ─────
    readonly property bool isLeftmostScreen: {
        if (!scope.modelData || !Quickshell.screens || Quickshell.screens.length <= 1) return true
        var minX = scope.modelData.x
        for (var i = 0; i < Quickshell.screens.length; i++) {
            var s = Quickshell.screens[i]
            if (s && typeof s.x === "number" && s.x < minX) minX = s.x
        }
        return scope.modelData.x <= minX
    }

    readonly property bool isRightmostScreen: {
        if (!scope.modelData || !Quickshell.screens || Quickshell.screens.length <= 1) return true
        var myRight = scope.modelData.x + scope.modelData.width
        var maxRight = myRight
        for (var i = 0; i < Quickshell.screens.length; i++) {
            var s = Quickshell.screens[i]
            if (s && typeof s.x === "number" && typeof s.width === "number") {
                var r = s.x + s.width
                if (r > maxRight) maxRight = r
            }
        }
        return myRight >= maxRight
    }

    readonly property bool isTopmostScreen: {
        if (!scope.modelData || !Quickshell.screens || Quickshell.screens.length <= 1) return true
        var minY = scope.modelData.y
        for (var i = 0; i < Quickshell.screens.length; i++) {
            var s = Quickshell.screens[i]
            if (s && typeof s.y === "number" && s.y < minY) minY = s.y
        }
        return scope.modelData.y <= minY
    }

    readonly property bool isBottommostScreen: {
        if (!scope.modelData || !Quickshell.screens || Quickshell.screens.length <= 1) return true
        var myBottom = scope.modelData.y + scope.modelData.height
        var maxBottom = myBottom
        for (var i = 0; i < Quickshell.screens.length; i++) {
            var s = Quickshell.screens[i]
            if (s && typeof s.y === "number" && typeof s.height === "number") {
                var b = s.y + s.height
                if (b > maxBottom) maxBottom = b
            }
        }
        return myBottom >= maxBottom
    }

    function applyLayoutConfig(text) {
        var parsed = ServiceParsers.parseLayoutConfig(text, scope)
        scope.windowGap = parsed.windowGap
        scope.barMaxWidth = parsed.barMaxWidth
        scope.screenMargin = parsed.screenMargin
        scope.leftBarMaxLength = parsed.leftBarMaxLength
        scope.launcherX = parsed.launcherX
        scope.bottomGap = parsed.bottomGap
        scope.rightGap = parsed.rightGap
    }

    FileView {
        id: layoutConfigFile
        path: Quickshell.shellPath("config/layout.config.json")
        watchChanges: true
        onFileChanged: layoutConfigFile.reload()
        onLoaded: scope.applyLayoutConfig(layoutConfigFile.text())
    }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    BarController {
        id: ctlTop
        weather: scope.weather
        events: scope.events
        workspaces: scope.workspaces
        now: clock.date
    }
    BarController {
        id: ctlLeft
        weather: scope.weather
        events: scope.events
        workspaces: scope.workspaces
        now: clock.date
    }

    property bool anyMenuOpen: false
    signal closeAllRequested()

    // True ONLY when a click-opened panel owned by THIS monitor is open.
    // Used for WlrKeyboardFocus.Exclusive so secondary monitors never steal keyboard focus
    // from the monitor hosting AppMenu or another open panel.
    readonly property bool isDetachingFromOpen: (scope.isBottommostScreen && notifCenterBar && notifCenterBar.isActivelyDetaching)
        || (scope.isLeftmostScreen && scope.isBottommostScreen && appMenu && appMenu.isActivelyDetaching)
        || (scope.isTopmostScreen && ((topLeft && topLeft.isDetaching) || (topRight && topRight.isDetaching) || (middleBar && middleBar.isActivelyDetaching)))
        || (scope.isLeftmostScreen && ((wsIsland && wsIsland.isActivelyDetaching) || cu0.isDetaching || cu1.isDetaching || cu2.isDetaching || cd2.isDetaching || cd1.isDetaching || cd0.isDetaching))
        || (scope.isRightmostScreen && scope.isBottommostScreen && mediaControlBar && mediaControlBar.isActivelyDetaching)

    readonly property bool localClickOpen: (scope.isTopmostScreen && ctlTop.clickOpen)
        || (scope.isLeftmostScreen && ctlLeft.clickOpen)
        || (scope.isLeftmostScreen && scope.isBottommostScreen && appMenuOpen)
        || (scope.isLeftmostScreen && scope.isBottommostScreen && appLauncher.trayMenuOpen)
        || (scope.isRightmostScreen && stickNotesBar && stickNotesBar.isAnyOpen)
        || (scope.isBottommostScreen && notifCenterBar && notifCenterBar.isOpen)
        || scope.isDetachingFromOpen

    readonly property bool anyClickOpen: scope.localClickOpen || scope.anyMenuOpen

    function closeAll() {
        if (scope.isTopmostScreen) ctlTop.close()
        if (scope.isLeftmostScreen) ctlLeft.close()
        if (scope.isLeftmostScreen) appMenuOpen = false
        if (scope.anyMenuOpen) scope.closeAllRequested()
        appLauncher.closeTrayMenu()
        if (scope.isRightmostScreen && stickNotesBar) stickNotesBar.closeAll()
        if (scope.isBottommostScreen && notifCenterBar) notifCenterBar.close()
        if (scope.isRightmostScreen && mediaControlBar && mediaControlBar.isMerged) mediaControlBar.closeMerged()
    }

    function toggleAppMenu() {
        if (!scope.isLeftmostScreen || !scope.isBottommostScreen) return
        if (scope.appMenuOpen && !appMenu.isClipboardMode) {
            scope.closeAll()
        } else {
            scope.closeAll()
            appMenu.resetSearch()
            scope.appMenuOpen = true
            appMenu.focusMenu()
        }
    }

    function openAppMenu() {
        if (!scope.isLeftmostScreen || !scope.isBottommostScreen) return
        scope.closeAll()
        appMenu.resetSearch()
        scope.appMenuOpen = true
        appMenu.focusMenu()
    }

    function closeAppMenu() {
        if (!scope.isLeftmostScreen || !scope.isBottommostScreen) return
        if (scope.appMenuOpen) {
            scope.appMenuOpen = false
        }
    }

    function toggleClipboard() {
        if (!scope.isLeftmostScreen || !scope.isBottommostScreen) return
        if (scope.appMenuOpen && appMenu.isClipboardMode) {
            scope.closeAll()
        } else {
            scope.closeAll()
            scope.appMenuOpen = true
            appMenu.openWithQuery("\\")
        }
    }

    function openClipboard() {
        if (!scope.isLeftmostScreen || !scope.isBottommostScreen) return
        scope.closeAll()
        scope.appMenuOpen = true
        appMenu.openWithQuery("\\")
    }

    // Invisible window that reserves the top space: only the strip (+ gap), so the clock
    // island and its panels can overlap the window. On edges without a bar, reserves windowGap.
    PanelWindow {
        Component.onCompleted: if (scope.modelData) screen = scope.modelData
        anchors { top: true; left: true; right: true }
        implicitHeight: scope.isTopmostScreen ? scope.topGap : scope.windowGap
        color: Theme.transparent
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: scope.isTopmostScreen ? scope.topGap : scope.windowGap
        mask: Region {}
        WlrLayershell.namespace: "qs-topbar-reserve"
    }

    // Invisible window that reserves the left space: the WHOLE left bar (strip + circles +
    // island depth) + gap, so tiled windows never overlap it. On edges without a bar, reserves windowGap.
    PanelWindow {
        Component.onCompleted: if (scope.modelData) screen = scope.modelData
        anchors { left: true; top: true; bottom: true }
        implicitWidth: scope.isLeftmostScreen ? (wsIsland.idleDepth + scope.windowGap) : scope.windowGap
        color: Theme.transparent
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: scope.isLeftmostScreen ? (wsIsland.idleDepth + scope.windowGap) : scope.windowGap
        mask: Region {}
        WlrLayershell.namespace: "qs-leftbar-reserve"
    }

    // Invisible window that reserves space along the bottom: a small space between the bottom
    // and tiled windows, so the application button can overlap the window. On edges without a bar, reserves windowGap.
    PanelWindow {
        Component.onCompleted: if (scope.modelData) screen = scope.modelData
        anchors { bottom: true; left: true; right: true }
        implicitHeight: scope.isBottommostScreen ? scope.bottomGap : scope.windowGap
        color: Theme.transparent
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: scope.isBottommostScreen ? scope.bottomGap : scope.windowGap
        mask: Region {}
        WlrLayershell.namespace: "qs-bottom-reserve"
    }

    // Invisible window that reserves space along the right: a small space between the right edge
    // and tiled windows, so the stick notes drawer buttons can overlap the window. On edges without a bar, reserves windowGap.
    PanelWindow {
        Component.onCompleted: if (scope.modelData) screen = scope.modelData
        anchors { right: true; top: true; bottom: true }
        implicitWidth: scope.isRightmostScreen ? scope.rightGap : scope.windowGap
        color: Theme.transparent
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: scope.isRightmostScreen ? scope.rightGap : scope.windowGap
        mask: Region {}
        WlrLayershell.namespace: "qs-right-reserve"
    }

    // Full-screen transparent overlay. Only the shapes take input (see `mask`);
    // while a click-opened panel is open the whole screen does, so a click outside can close it.
    PanelWindow {
        id: win
        Component.onCompleted: if (scope.modelData) screen = scope.modelData
        anchors { top: true; bottom: true; left: true; right: true }
        color: Theme.transparent
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "qs-bars"
        WlrLayershell.keyboardFocus: scope.localClickOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        mask: Region {
            Region { item: scope.isTopmostScreen ? topStrip : null }
            Region { item: (scope.isTopmostScreen && (!floatManager || !floatManager.isTopLeftFloating || topLeft.isDetaching)) ? topLeft.maskItem : null }
            Region { item: (scope.isTopmostScreen && (!floatManager || !floatManager.isTopRightFloating || topRight.isDetaching)) ? topRight.maskItem : null }
            Region { item: (scope.isTopmostScreen && (!floatManager || !floatManager.isCalendarFloating || middleBar.isActivelyDetaching)) ? middleBar.maskItem : null }
            Region { item: (scope.isLeftmostScreen && (!floatManager || !floatManager.isWorkspacesFloating || wsIsland.isActivelyDetaching || ctlLeft.busy)) ? wsIsland.maskItem : null }
            Region { item: (scope.isLeftmostScreen && (!cu0.isFloatingNow || cu0.isDetaching)) ? cu0 : null }
            Region { item: (scope.isLeftmostScreen && (!cu1.isFloatingNow || cu1.isDetaching)) ? cu1 : null }
            Region { item: (scope.isLeftmostScreen && (!cu2.isFloatingNow || cu2.isDetaching)) ? cu2 : null }
            Region { item: (scope.isLeftmostScreen && (!cd2.isFloatingNow || cd2.isDetaching)) ? cd2 : null }
            Region { item: (scope.isLeftmostScreen && (!cd1.isFloatingNow || cd1.isDetaching)) ? cd1 : null }
            Region { item: (scope.isLeftmostScreen && (!cd0.isFloatingNow || cd0.isDetaching)) ? cd0 : null }
            Region { item: (scope.isLeftmostScreen && scope.isBottommostScreen) ? appLauncher.maskItem : null }
            Region { item: (scope.isLeftmostScreen && scope.isBottommostScreen && appLauncher.trayMenuOpen) ? appLauncher.menuMaskItem : null }
            Region { item: (scope.isLeftmostScreen && scope.isBottommostScreen) ? appMenu.maskItem : null }
            Region { item: (scope.isRightmostScreen && scope.isBottommostScreen) ? mediaControlBar.maskItem : null }
            Region { item: scope.isRightmostScreen ? stickNotesBar.maskItem : null }
            Region { item: scope.isBottommostScreen ? notifOverlay.maskItem : null }
            Region { item: (scope.isBottommostScreen && (!floatManager || !floatManager.isNotifFloating || notifCenterBar.isActivelyDetaching)) ? notifCenterBar.maskItem : null }
            Region { item: (scope.anyClickOpen || (floatManager && floatManager.isDraggingAny)) ? catcher : null }
        }

        Item {
            id: scene
            anchors.fill: parent
            focus: true
            Keys.forwardTo: (scope.isLeftmostScreen && scope.isBottommostScreen && scope.appMenuOpen) ? [appMenu] : []
            Keys.onEscapePressed: scope.closeAll()

            Shortcut {
                sequence: "Escape"
                enabled: scope.anyClickOpen
                onActivated: scope.closeAll()
            }

            Connections {
                target: ctlTop
                function onClickOpenChanged() { if (ctlTop.clickOpen) scene.forceActiveFocus() }
            }
            Connections {
                target: ctlLeft
                function onClickOpenChanged() { if (ctlLeft.clickOpen) scene.forceActiveFocus() }
            }

            // click outside an open panel closes it
            MouseArea {
                id: catcher
                anchors.fill: parent
                enabled: scope.anyClickOpen
                visible: scope.anyClickOpen || (floatManager && floatManager.isDraggingAny)
                z: -1
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onPressed: scope.closeAll()
            }

            // z-order: bottom -> top

            // Dynamic circle offset: tracks the workspace island's spring-animated length in real time,
            // and interpolates via wsIsland.floatRetractProgress to CircleStyle.spacing / 2 when the workspace island is floating.
            readonly property real dockedCircleInnerOffset: (wsIsland ? wsIsland.baseLen / 2 : (WorkspaceIslandStyle.idleLen / 2)) + CircleStyle.innerGap
            readonly property real floatedCircleInnerOffset: CircleStyle.spacing / 2
            readonly property real circleInnerOffset: dockedCircleInnerOffset + (floatedCircleInnerOffset - dockedCircleInnerOffset) * (wsIsland ? wsIsland.floatRetractProgress : 0)

            // ───── left bar ─────
            CircleUpOuter    { id: cu0; ctl: ctlLeft; stripH: 0; floatManager: floatManager; visible: scope.isLeftmostScreen; innerOffset: scene.circleInnerOffset; effectiveStep: (cu2.isFloatingNow ? 0 : 1) + (cu1.isFloatingNow ? 0 : 1) }
            CircleUpMiddle   { id: cu1; ctl: ctlLeft; stripH: 0; floatManager: floatManager; visible: scope.isLeftmostScreen; innerOffset: scene.circleInnerOffset; effectiveStep: cu2.isFloatingNow ? 0 : 1 }
            CircleUpInner    { id: cu2; ctl: ctlLeft; stripH: 0; floatManager: floatManager; visible: scope.isLeftmostScreen; innerOffset: scene.circleInnerOffset; effectiveStep: 0 }
            CircleDownInner  { id: cd2; ctl: ctlLeft; stripH: 0; floatManager: floatManager; visible: scope.isLeftmostScreen; innerOffset: scene.circleInnerOffset; effectiveStep: 0 }
            CircleDownMiddle { id: cd1; ctl: ctlLeft; stripH: 0; floatManager: floatManager; visible: scope.isLeftmostScreen; innerOffset: scene.circleInnerOffset; effectiveStep: cd2.isFloatingNow ? 0 : 1 }
            CircleDownOuter  { id: cd0; ctl: ctlLeft; stripH: 0; floatManager: floatManager; visible: scope.isLeftmostScreen; screenLocker: scope.screenLocker; innerOffset: scene.circleInnerOffset; effectiveStep: (cd2.isFloatingNow ? 0 : 1) + (cd1.isFloatingNow ? 0 : 1) }

            WorkspaceIsland {
                id: wsIsland
                anchors.fill: parent
                ctl: ctlLeft
                stripH: 0
                barLen: scope.leftLen
                floatManager: floatManager
                visible: scope.isLeftmostScreen
            }

            // ───── top bar ─────
            Strip {
                id: topStrip
                barStart: scope.barX
                barLen: scope.barW
                gapLen: (floatManager && floatManager.isCalendarFloating) ? middleBar.idleLen : middleBar.outerSpan
                splitGap: (floatManager && floatManager.isCalendarFloating) ? true : false
                nearVisibility: (floatManager && floatManager.isTopLeftFloating) ? 0.0 : 1.0
                farVisibility: (floatManager && floatManager.isTopRightFloating) ? 0.0 : 1.0
                Behavior on nearVisibility { NumberAnimation { duration: StripStyle.fadeDurationMs; easing.type: Easing.OutCubic } }
                Behavior on farVisibility { NumberAnimation { duration: StripStyle.fadeDurationMs; easing.type: Easing.OutCubic } }
                opacity: ((!ctlTop.busy || middleBar.isActivelyDetaching) && floatManager && floatManager.isCalendarFloating) ? 1 : 0
                visible: scope.isTopmostScreen && opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: StripStyle.fadeDurationMs; easing.type: Easing.OutCubic } }
            }

            MiddleBar {
                id: middleBar
                anchors.fill: parent
                ctl: ctlTop
                stripH: topStrip.thickness
                barW: scope.barW
                floatManager: floatManager
                visible: scope.isTopmostScreen
            }

            // hover bars on top of the strip
            TopLeftBar {
                id: topLeft
                anchors.fill: parent
                ctl: ctlTop
                barX: scope.barX
                barW: scope.barW
                stripH: topStrip.thickness
                floatManager: floatManager
                visible: scope.isTopmostScreen
            }
            TopRightBar {
                id: topRight
                anchors.fill: parent
                ctl: ctlTop
                barX: scope.barX
                barW: scope.barW
                stripH: topStrip.thickness
                floatManager: floatManager
                visible: scope.isTopmostScreen
            }

            // ───── bottom application launcher & menu ─────
            AppLauncher {
                id: appLauncher
                x: scope.launcherX
                anchors.bottom: parent.bottom
                menuOpen: scope.appMenuOpen
                menuAnimating: appMenu.activeOrAnimating
                floatManager: floatManager
                visible: scope.isLeftmostScreen && scope.isBottommostScreen
                onAppButtonClicked: scope.toggleAppMenu()
            }

            AppMenu {
                id: appMenu
                x: scope.launcherX
                open: scope.appMenuOpen
                floatManager: floatManager
                visible: scope.isLeftmostScreen && scope.isBottommostScreen && (scope.appMenuOpen || activeOrAnimating || isActivelyDetaching)
                onCloseRequested: scope.closeAll()
            }

            // ───── bottom right media & audio control bar ─────
            MediaControlBar {
                id: mediaControlBar
                x: parent.width - scope.launcherX - width
                anchors.bottom: parent.bottom
                audio: scope.audio
                floatManager: floatManager
                opacity: (scope.isRightmostScreen && scope.isBottommostScreen && !scope.appMenuOpen && !appMenu.activeOrAnimating) ? 1 : 0
                visible: scope.isRightmostScreen && scope.isBottommostScreen && opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }

            // ───── right stick notes drawer bar ─────
            StickNotesBar {
                id: stickNotesBar
                anchors.right: parent.right
                y: Math.round((scope.screenH - 520) / 2)
                sticknotes: scope.sticknotes
                floatManager: floatManager
                opacity: (scope.isRightmostScreen && !scope.appMenuOpen && !appMenu.activeOrAnimating) ? 1 : 0
                visible: scope.isRightmostScreen && opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }

            // ───── desktop notifications overlay ─────
            NotificationOverlay {
                id: notifOverlay
                anchors.fill: parent
                notifications: scope.notifications
                screenW: scope.screenW
                screenH: scope.screenH
                visible: scope.isBottommostScreen
            }

            // ───── bottom center notification center drawer ─────
            NotificationCenterBar {
                id: notifCenterBar
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                notifications: scope.notifications
                floatManager: floatManager
                opacity: (scope.isBottommostScreen && !scope.appMenuOpen && !appMenu.activeOrAnimating) ? 1 : 0
                visible: scope.isBottommostScreen && (opacity > 0.01 || isActivelyDetaching)
                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }
        }
    }

    // ───── dedicated floating windows layer surface (qs-floating) ─────
    PanelWindow {
        id: floatingWin
        Component.onCompleted: if (scope.modelData) screen = scope.modelData
        anchors { top: true; bottom: true; left: true; right: true }
        color: Theme.transparent
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "qs-floating"
        WlrLayershell.keyboardFocus: (scope.localClickOpen || (floatManager && floatManager.isDraggingAny)) ? WlrKeyboardFocus.None : WlrKeyboardFocus.OnDemand

        visible: floatManager ? floatManager.layerVisible : false

        mask: Region {
            Region { item: (floatManager && (!floatManager.isDraggingAny || floatManager.currentDragSlot !== floatManager.fw0) && floatManager.fw0 && floatManager.fw0.active) ? floatManager.fw0 : null }
            Region { item: (floatManager && (!floatManager.isDraggingAny || floatManager.currentDragSlot !== floatManager.fw1) && floatManager.fw1 && floatManager.fw1.active) ? floatManager.fw1 : null }
            Region { item: (floatManager && (!floatManager.isDraggingAny || floatManager.currentDragSlot !== floatManager.fw2) && floatManager.fw2 && floatManager.fw2.active) ? floatManager.fw2 : null }
            Region { item: (floatManager && (!floatManager.isDraggingAny || floatManager.currentDragSlot !== floatManager.fw3) && floatManager.fw3 && floatManager.fw3.active) ? floatManager.fw3 : null }
            Region { item: (floatManager && (!floatManager.isDraggingAny || floatManager.currentDragSlot !== floatManager.fw4) && floatManager.fw4 && floatManager.fw4.active) ? floatManager.fw4 : null }
            Region { item: (floatManager && (!floatManager.isDraggingAny || floatManager.currentDragSlot !== floatManager.fw5) && floatManager.fw5 && floatManager.fw5.active) ? floatManager.fw5 : null }
            Region { item: (floatManager && (!floatManager.isDraggingAny || floatManager.currentDragSlot !== floatManager.fw6) && floatManager.fw6 && floatManager.fw6.active) ? floatManager.fw6 : null }
            Region { item: (floatManager && (!floatManager.isDraggingAny || floatManager.currentDragSlot !== floatManager.fw7) && floatManager.fw7 && floatManager.fw7.active) ? floatManager.fw7 : null }
            Region { item: (floatManager && floatManager.enableDragOverlayMask) ? floatManager.dragOverlayMask : null }
        }

        FloatingWindowManager {
            id: floatManager
            anchors.fill: parent
            screenW: scope.screenW
            screenH: scope.screenH
            ctlTop: ctlTop
            ctlLeft: ctlLeft
            audio: scope.audio
            workspaces: scope.workspaces
            events: scope.events
            weather: scope.weather
            sticknotes: scope.sticknotes
            notifications: scope.notifications
        }
    }
}
