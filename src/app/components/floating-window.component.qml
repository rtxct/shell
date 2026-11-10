// ============================================================================
// File: components/floating-window.component.qml
// Purpose: Movable, draggable floating window frame with titlebar, dock-zone edge snapping, and smooth close/dock animations.
// Public API:
//   - Properties: winId, title, icon, originSide, originX, originY, posX, posY, winWidth, winHeight, screenW, screenH ...
//   - Signals:    dockRequested(string id), closeRequested(string id)
//   - Functions:  checkDockZone(), dock(), close()
// Dependencies: QtQuick, "../styles", QtQuick.Layouts
// ============================================================================
import QtQuick
import "../styles"
import QtQuick.Layouts

// A movable, draggable Quickshell floating window that can be dragged anywhere on screen.
// Dragging it back towards its origin edge or clicking the dock / close button docks it back.
Item {
    id: root

    // ── Configuration & State ──
    property string winId: ""
    property string title: ""
    property string icon: "󰄯"
    property string originSide: "left" // "top" | "left" | "bottom" | "right"
    property real originX: 0
    property real originY: 0

    property real posX: 200
    property real posY: 150
    property real winWidth: FloatingWindowStyle.defaultWidth
    property real winHeight: FloatingWindowStyle.defaultHeight

    property real screenW: parent ? parent.width : 1920
    property real screenH: parent ? parent.height : 1080

    property bool active: false
    property bool isDragging: false
    property bool nearDockZone: false

    readonly property bool isBarMode: winId === "volume-bar" || winId === "mic-bar"
    property bool showTitlebar: !isBarMode

    property var contentComponent: null
    property var ctl: null
    property var audio: null
    property var workspaces: null
    property var events: null
    property var weather: null
    property var sticknotes: null
    property var notifications: null
    property var extraData: null

    function syncLoadedItemProperties() {
        var item = contentLoader.item
        if (!item) return
        if ("isFloatingWindow" in item) item.isFloatingWindow = true
        if ("floatingWindow" in item) item.floatingWindow = root
        if ("ctl" in item) item.ctl = root.ctl
        if ("audio" in item) item.audio = root.audio
        if ("workspaces" in item) item.workspaces = root.workspaces
        if ("events" in item) item.events = root.events
        if ("weather" in item) item.weather = root.weather
        if ("sticknotes" in item) item.sticknotes = root.sticknotes
        if ("notifications" in item) item.notifications = root.notifications
        if ("extraData" in item) item.extraData = root.extraData
    }

    onCtlChanged: syncLoadedItemProperties()
    onAudioChanged: syncLoadedItemProperties()
    onWorkspacesChanged: syncLoadedItemProperties()
    onEventsChanged: syncLoadedItemProperties()
    onWeatherChanged: syncLoadedItemProperties()
    onSticknotesChanged: syncLoadedItemProperties()
    onNotificationsChanged: syncLoadedItemProperties()
    onExtraDataChanged: syncLoadedItemProperties()

    signal dockRequested(string id)
    signal closeRequested(string id)

    readonly property Item maskItem: root

    x: posX
    y: posY
    width: active ? winWidth : 0
    height: active ? winHeight : 0
    visible: active || opacity > 0.01
    opacity: active ? 1.0 : 0.0

    Behavior on opacity { NumberAnimation { duration: FloatingWindowStyle.opacityDurationMs; easing.type: Easing.OutCubic } }

    // Dock snap distance threshold
    readonly property real snapDistance: FloatingWindowStyle.snapDistance

    function checkDockZone() {
        if (originSide === "left") {
            return posX < snapDistance
        } else if (originSide === "top") {
            return posY < snapDistance
        } else if (originSide === "bottom") {
            return (posY + winHeight) > (screenH - snapDistance)
        } else if (originSide === "right") {
            return (posX + winWidth) > (screenW - snapDistance)
        }
        return false
    }

    function dock() {
        root.dockRequested(root.winId)
    }

    function close() {
        root.closeRequested(root.winId)
    }

    // ── Drag Orchestration Helpers (callable from titlebar or embedded panel) ──
    property real dragPressSceneX: 0
    property real dragPressSceneY: 0
    property real dragPressWinX: 0
    property real dragPressWinY: 0

    function dragStart(sceneX, sceneY) {
        dragPressSceneX = sceneX
        dragPressSceneY = sceneY
        dragPressWinX = root.posX
        dragPressWinY = root.posY
        root.isDragging = true
    }

    function dragMove(sceneX, sceneY) {
        if (!root.isDragging) return
        var dx = sceneX - dragPressSceneX
        var dy = sceneY - dragPressSceneY
        root.posX = Math.max(0, Math.min(root.screenW - root.winWidth, dragPressWinX + dx))
        root.posY = Math.max(0, Math.min(root.screenH - root.winHeight, dragPressWinY + dy))
        root.nearDockZone = root.checkDockZone()
    }

    function dragEnd() {
        root.isDragging = false
        if (root.nearDockZone) {
            root.dock()
        }
        root.nearDockZone = false
    }

    // ── Window Frame & Background ──
    Rectangle {
        id: cardBg
        width: root.winWidth
        height: root.winHeight
        scale: root.active ? 1.0 : FloatingWindowStyle.closedScale
        transformOrigin: Item.Center
        Behavior on scale { NumberAnimation { duration: FloatingWindowStyle.scaleDurationMs; easing.type: Easing.OutBack } }
        color: FloatingWindowStyle.background
        radius: root.isBarMode ? FloatingWindowStyle.barFrameRadius : FloatingWindowStyle.frameRadius
        border.width: root.nearDockZone ? FloatingWindowStyle.borderWidthNearDock : (root.isDragging ? FloatingWindowStyle.borderWidthDragging : FloatingWindowStyle.borderWidthIdle)
        border.color: root.nearDockZone ? FloatingWindowStyle.accent : (root.isDragging ? FloatingWindowStyle.borderDragging : FloatingWindowStyle.borderIdle)

        Behavior on border.color { ColorAnimation { duration: FloatingWindowStyle.borderAnimDurationMs } }
        Behavior on border.width { NumberAnimation { duration: FloatingWindowStyle.borderAnimDurationMs } }

        // Subtle glow / elevation highlight
        Rectangle {
            anchors.fill: parent
            anchors.margins: -FloatingWindowStyle.innerGlowMargin
            radius: root.isBarMode ? (FloatingWindowStyle.barFrameRadius + 1) : FloatingWindowStyle.innerGlowRadius
            color: FloatingWindowStyle.transparent
            border.width: FloatingWindowStyle.borderWidthIdle
            border.color: root.nearDockZone ? FloatingWindowStyle.innerGlowNearDock : FloatingWindowStyle.innerGlowIdle
        }

        // Liquid Glass multi-stop refractive sheen + caustic bottom reflection
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            gradient: Gradient {
                GradientStop { position: 0.0; color: FloatingWindowStyle.glassSheenTop }
                GradientStop { position: 0.18; color: FloatingWindowStyle.glassSheenMid }
                GradientStop { position: 0.78; color: FloatingWindowStyle.glassSheenCore }
                GradientStop { position: 1.0; color: FloatingWindowStyle.glassSheenBottom }
            }
        }

        // 3D inner refractive bevel ring
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: FloatingWindowStyle.transparent
            border.width: 1.5
            border.color: FloatingWindowStyle.glassInnerBevel
        }

        // Top specular crest highlight
        Rectangle {
            width: Math.max(0, parent.width - parent.radius * 1.6)
            height: 1.0
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 1.5
            color: FloatingWindowStyle.glassRimHighlight
        }

        // ── Titlebar (Header & Drag Handle) ──
        Item {
            id: titlebar
            visible: root.showTitlebar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.showTitlebar ? FloatingWindowStyle.titlebarHeight : 0

            // Header Background / separator
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: FloatingWindowStyle.titlebarDividerMarginX
                anchors.rightMargin: FloatingWindowStyle.titlebarDividerMarginX
                height: 1
                color: FloatingWindowStyle.titlebarDivider
            }

            // Left: Window Icon + Title
            Row {
                anchors.left: parent.left
                anchors.leftMargin: FloatingWindowStyle.titlebarPaddingX
                anchors.verticalCenter: parent.verticalCenter
                spacing: FloatingWindowStyle.titlebarRowSpacing

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.icon
                    font.family: FloatingWindowStyle.iconFont
                    font.pixelSize: FloatingWindowStyle.titleIconFontPx
                    color: FloatingWindowStyle.accent
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.title
                    color: FloatingWindowStyle.accent
                    font.pixelSize: FloatingWindowStyle.titleFontPx
                    font.weight: Font.DemiBold
                    font.letterSpacing: FloatingWindowStyle.titleLetterSpacing
                    font.capitalization: Font.AllUppercase
                }
            }

            // Center: Drag Handle visual indicator
            Row {
                anchors.centerIn: parent
                spacing: FloatingWindowStyle.dragDotsSpacing
                opacity: root.isDragging ? FloatingWindowStyle.dragDotsOpacityActive : FloatingWindowStyle.dragDotsOpacityIdle
                Behavior on opacity { NumberAnimation { duration: FloatingWindowStyle.borderAnimDurationMs } }

                Repeater {
                    model: 3
                    Rectangle {
                        width: FloatingWindowStyle.dragDotSize
                        height: FloatingWindowStyle.dragDotSize
                        radius: FloatingWindowStyle.dragDotRadius
                        color: FloatingWindowStyle.textPrimary
                    }
                }
            }

            // Right: Actions (Close)
            Row {
                anchors.right: parent.right
                anchors.rightMargin: FloatingWindowStyle.actionsRightMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: FloatingWindowStyle.actionsSpacing

                // Close Button ('✕')
                Rectangle {
                    width: FloatingWindowStyle.titleBtnSize
                    height: FloatingWindowStyle.titleBtnSize
                    radius: FloatingWindowStyle.titleBtnRadius
                    color: closeMouse.containsMouse ? FloatingWindowStyle.closeBtnHoverBg : FloatingWindowStyle.transparent
                    border.width: FloatingWindowStyle.borderWidthIdle
                    border.color: closeMouse.containsMouse ? FloatingWindowStyle.danger : FloatingWindowStyle.transparent

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: FloatingWindowStyle.closeIconFontPx
                        color: closeMouse.containsMouse ? FloatingWindowStyle.danger : FloatingWindowStyle.textDim
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            // Drag MouseArea covering the entire titlebar (except buttons)
            MouseArea {
                id: dragArea
                anchors.fill: parent
                anchors.rightMargin: FloatingWindowStyle.dragRightMargin // leave room for dock and close buttons
                cursorShape: Qt.SizeAllCursor

                onPressed: function(mouse) {
                    var pt = mapToItem(null, mouse.x, mouse.y)
                    root.dragStart(pt.x, pt.y)
                }

                onPositionChanged: function(mouse) {
                    if (!pressed) return
                    var pt = mapToItem(null, mouse.x, mouse.y)
                    root.dragMove(pt.x, pt.y)
                }

                onReleased: {
                    root.dragEnd()
                }

                onCanceled: {
                    root.dragEnd()
                }
            }
        }

        // ── Window Body / Content Area ──
        Item {
            id: bodyArea
            anchors.top: root.showTitlebar ? titlebar.bottom : parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.showTitlebar ? FloatingWindowStyle.bodyPadding : 0
            clip: true

            Loader {
                id: contentLoader
                anchors.fill: parent
                sourceComponent: root.contentComponent

                onLoaded: root.syncLoadedItemProperties()
            }
        }
    }
}
