// ============================================================================
// File: modules/app-launcher.module.qml
// Purpose: Bottom-left application launcher button, circular quick-action triggers, and active background tray items.
// Public API:
//   - Properties: menuOpen, floatManager, fg, dim, accent, fill, btnWidth, btnDepth, circleSize, circleSpacing, trayCircleSize, traySpacing, maskItem
//   - Signals:    appButtonClicked(), circle1Clicked(), circle2Clicked()
// Dependencies: QtQuick, Quickshell, Quickshell.Io, Quickshell.Services.SystemTray, Quickshell.Widgets, "../components", "../styles", "../theme"
// ============================================================================
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../components"
import "../styles"
import "../../../themes"

// Application island button and 2 quick-action circles (screenshot & color picker) at the bottom of the screen.
// Styled in the exact format of the middle top and left islands (Drop shape hanging from the bottom edge).
Item {
    id: root

    property bool menuOpen: false
    property bool menuAnimating: false
    property var floatManager: null
    property color fg: AppLauncherStyle.textPrimary
    property color dim: AppLauncherStyle.textDim
    property color accent: AppLauncherStyle.accent
    property color fill: AppLauncherStyle.fill

    // ── Tray options popup state ──
    property var trayMenuItem: null           // SystemTrayItem whose options popup is open
    property real trayMenuAnchorX: 0          // horizontal centre of the clicked circle (local x)
    readonly property bool trayMenuOpen: trayMenuItem !== null
    readonly property Item menuMaskItem: trayMenuPopup

    function closeTrayMenu() { trayMenuItem = null }

    // Strip DBusMenu mnemonic underscores ("_Quit" -> "Quit", "__" -> "_")
    function cleanMenuLabel(str) {
        if (!str) return ""
        return String(str).replace(/__/g, "\u0000").replace(/_/g, "").replace(/\u0000/g, "_")
    }

    // Close the popup if its app disappears from the tray
    Connections {
        target: SystemTray.items
        function onObjectRemovedPre(object, index) {
            if (object === root.trayMenuItem) root.closeTrayMenu()
        }
    }

    QsMenuOpener {
        id: trayMenuOpener
        menu: (root.trayMenuItem && root.trayMenuItem.hasMenu) ? root.trayMenuItem.menu : null
    }

    onMenuOpenChanged: if (menuOpen) closeTrayMenu()
    signal appButtonClicked()
    signal circle1Clicked()
    signal circle2Clicked()

    Process {
        id: screenshotProc
        command: ["sh", "-c", "geom=$(slurp </dev/null) && [ -n \"$geom\" ] && grim -g \"$geom\" - | satty --filename - --copy-command wl-copy"]
    }

    Process {
        id: colorPickerProc
        command: ["sh", "-c", "hyprpicker -a </dev/null"]
    }

    Process {
        id: appFocusProc
        command: ["sh", "-c", ""]
    }

    function focusAppWindow(appId) {
        if (!appId) return
        var raw = String(appId).trim()
        var token = raw
        if (token.indexOf(".") !== -1) {
            var parts = token.split(".")
            token = parts[parts.length - 1]
        }
        var clean = token.replace(/[^a-zA-Z0-9_\-]/g, "")
        if (clean.length === 0) clean = raw.replace(/[^a-zA-Z0-9_\-]/g, "")
        if (clean.length === 0) return
        appFocusProc.command = [
            "sh",
            "-c",
            "swaymsg '[app_id=\"(?i)" + clean + "\"] focus' 2>/dev/null || swaymsg '[class=\"(?i)" + clean + "\"] focus' 2>/dev/null || true"
        ]
        appFocusProc.running = true
    }

    function getFallbackGlyph(item) {
        if (!item) return "•"
        var idStr = ((item.id || "") + " " + (item.title || "")).toLowerCase()
        if (idStr.indexOf("spotify") !== -1) return "󰓇"
        if (idStr.indexOf("discord") !== -1 || idStr.indexOf("vesktop") !== -1 || idStr.indexOf("webcord") !== -1) return "󰙯"
        if (idStr.indexOf("steam") !== -1) return "󰓓"
        if (idStr.indexOf("telegram") !== -1) return "󰵅"
        if (idStr.indexOf("slack") !== -1) return "󰒱"
        if (idStr.indexOf("obs") !== -1) return "󰕧"
        if (idStr.indexOf("chrome") !== -1 || idStr.indexOf("chromium") !== -1) return "󰊯"
        if (idStr.indexOf("firefox") !== -1) return "󰈹"
        if (idStr.indexOf("code") !== -1 || idStr.indexOf("vsc") !== -1) return "󰨞"
        var name = item.title || item.id || ""
        if (name.length > 0) return name.charAt(0).toUpperCase()
        return "•"
    }

    // ── Dimensions ──
    property real btnWidth: AppLauncherStyle.barWidth         // 3x wider than original ~88px
    property real btnDepth: AppLauncherStyle.barHeight          // slightly smaller than middle islands (44px)
    property real circleSize: AppLauncherStyle.circleDiameter
    property real circleSpacing: AppLauncherStyle.circleSpacing
    property real trayCircleSize: AppLauncherStyle.trayCircleDiameter
    property real traySpacing: AppLauncherStyle.trayCircleSpacing
    readonly property real trayItemsWidth: trayRepeater.count > 0 ? (trayRepeater.count * trayCircleSize + (trayRepeater.count - 1) * traySpacing) : 0
    readonly property bool isAppMenuFloating: root.floatManager ? root.floatManager.isAppMenuFloating : false
    readonly property real allCirclesWidth: circleSize + circleSpacing + circleSize + (trayItemsWidth > 0 ? (traySpacing + trayItemsWidth) : 0)
    readonly property real floatedCirclesStartX: Math.max(0, (btnWidth - allCirclesWidth) / 2)

    width: btnWidth + AppLauncherStyle.circleGap + circleSize + circleSpacing + circleSize + (trayItemsWidth > 0 ? (traySpacing + trayItemsWidth) : 0)
    height: btnDepth

    Behavior on width {
        NumberAnimation { duration: AppLauncherStyle.scaleAnimDurationMs; easing.type: Easing.OutCubic }
    }

    property real circlesOpacity: (menuOpen || menuAnimating) ? 0.0 : 1.0
    Behavior on circlesOpacity {
        NumberAnimation { duration: AppLauncherStyle.fadeDurationMs; easing.type: Easing.OutCubic }
    }

    readonly property Item maskItem: maskArea
    Item {
        id: maskArea
        x: (root.isAppMenuFloating && !dropBtn.isDetaching) ? c1.x : 0
        y: 0
        width: (root.menuOpen || root.menuAnimating) ? 0
               : ((root.isAppMenuFloating && !dropBtn.isDetaching) ? root.allCirclesWidth : root.width)
        height: (root.menuOpen || root.menuAnimating) ? 0 : root.height
    }

    // ── Main Applications Island (Drop format glued to bottom) ──
    Drop {
        id: dropBtn
        fromBottom: true
        x: 0
        y: root.isAppMenuFloating ? (root.btnDepth + 2) : 0
        width: root.btnWidth
        height: root.btnDepth
        visible: (!root.menuOpen && !root.menuAnimating) && (y < (root.btnDepth + 1) || dropBtn.isDetaching)
        enabled: !root.isAppMenuFloating || dropBtn.isDetaching
        Behavior on y { NumberAnimation { duration: AppLauncherStyle.fadeDurationMs * 2; easing.type: Easing.OutCubic } }
        fill: root.fill
        slant: AppLauncherStyle.dropSlant
        rad: AppLauncherStyle.dropRadius
        flare: AppLauncherStyle.dropFlare
        tp: 0
        inset: AppLauncherStyle.dropInset
        bottomInset: AppLauncherStyle.dropBottomInset

        // Hover effect: subtle scale and accent color
        scale: btnMouse.pressed ? AppLauncherStyle.btnPressedScale : (btnMouse.containsMouse ? AppLauncherStyle.btnHoverScale : 1.0)
        transformOrigin: Item.Bottom
        Behavior on scale { NumberAnimation { duration: AppLauncherStyle.scaleAnimDurationMs } }

        Row {
            anchors.centerIn: parent
            spacing: AppLauncherStyle.contentRowSpacing

            // 2x2 grid icon representing applications
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
                        color: btnMouse.containsMouse ? root.accent : root.fg
                        Behavior on color { ColorAnimation { duration: AppLauncherStyle.colorAnimDurationMs } }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Menu"
                color: btnMouse.containsMouse ? root.accent : root.fg
                font.pixelSize: AppLauncherStyle.labelFontPx
                font.weight: Font.DemiBold
                Behavior on color { ColorAnimation { duration: AppLauncherStyle.colorAnimDurationMs } }
            }
        }

        property real pressSceneX: 0
        property real pressSceneY: 0
        property bool isDetaching: false

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onPressed: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    if (root.menuOpen) root.appButtonClicked()
                    return
                }
                var pt = mapToItem(null, mouse.x, mouse.y)
                dropBtn.pressSceneX = pt.x
                dropBtn.pressSceneY = pt.y
                dropBtn.isDetaching = false
            }

            onPositionChanged: function(mouse) {
                if (!pressed) return
                var pt = mapToItem(null, mouse.x, mouse.y)
                var dy = dropBtn.pressSceneY - pt.y

                if (!dropBtn.isDetaching && root.floatManager && (dy > AppLauncherStyle.detachThresholdY || Math.hypot(pt.x - dropBtn.pressSceneX, dy) > AppLauncherStyle.detachThresholdHypot)) {
                    dropBtn.isDetaching = true
                    root.floatManager.startDrag({
                        id: "app-menu",
                        title: "Menu",
                        icon: "󰀻",
                        originSide: "bottom",
                        originX: root.x,
                        originY: root.y,
                        width: AppLauncherStyle.floatWidth,
                        height: AppLauncherStyle.floatHeight
                    }, pt.x, pt.y)
                } else if (dropBtn.isDetaching && root.floatManager) {
                    root.floatManager.updateDrag(pt.x, pt.y)
                }
            }

            onReleased: {
                if (dropBtn.isDetaching) {
                    dropBtn.isDetaching = false
                    if (root.floatManager) root.floatManager.endDrag()
                } else {
                    root.appButtonClicked()
                }
            }

            onCanceled: {
                if (dropBtn.isDetaching) {
                    dropBtn.isDetaching = false
                    if (root.floatManager) root.floatManager.endDrag()
                }
            }
        }
    }

    // ── Circle 1 (Screenshot via grim + slurp + satty) ──
    Rectangle {
        id: c1
        x: root.isAppMenuFloating ? root.floatedCirclesStartX : (root.btnWidth + AppLauncherStyle.circleGap)
        anchors.verticalCenter: parent.verticalCenter
        width: root.circleSize
        height: root.circleSize
        radius: width / 2
        color: c1Mouse.containsMouse ? AppLauncherStyle.circleHoverBg : root.fill
        border.width: 1.2
        border.color: c1Mouse.containsMouse ? root.accent : AppLauncherStyle.circleIdleBorder

        scale: c1Mouse.pressed ? AppLauncherStyle.circlePressedScale : 1.0
        opacity: root.circlesOpacity
        visible: opacity > 0.01

        Behavior on x { NumberAnimation { duration: AppLauncherStyle.fadeDurationMs * 2; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: AppLauncherStyle.colorAnimDurationMs } }
        Behavior on border.color { ColorAnimation { duration: AppLauncherStyle.colorAnimDurationMs } }
        Behavior on scale { NumberAnimation { duration: AppLauncherStyle.scaleAnimDurationMs } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: AppLauncherStyle.transparent
            gradient: Gradient {
                GradientStop { position: 0.0; color: AppLauncherStyle.glassSheenTop }
                GradientStop { position: 0.35; color: AppLauncherStyle.glassSheenMid }
                GradientStop { position: 0.70; color: AppLauncherStyle.glassSheenCore }
                GradientStop { position: 1.0; color: AppLauncherStyle.glassSheenBottom }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: AppLauncherStyle.transparent
            border.width: 1.5
            border.color: AppLauncherStyle.glassInnerBevel
        }

        Text {
            anchors.centerIn: parent
            text: ""
            font.family: "Symbols Nerd Font"
            font.pixelSize: AppLauncherStyle.circleIconFontPx
            color: c1Mouse.containsMouse ? root.accent : root.fg
            Behavior on color { ColorAnimation { duration: AppLauncherStyle.colorAnimDurationMs } }
        }

        MouseArea {
            id: c1Mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!screenshotProc.running) {
                    screenshotProc.running = true
                }
                root.circle1Clicked()
            }
        }
    }

    // ── Circle 2 (On-screen color picker via hyprpicker) ──
    Rectangle {
        id: c2
        x: c1.x + root.circleSize + root.circleSpacing
        anchors.verticalCenter: parent.verticalCenter
        width: root.circleSize
        height: root.circleSize
        radius: width / 2
        color: c2Mouse.containsMouse ? AppLauncherStyle.circleHoverBg : root.fill
        border.width: 1.2
        border.color: c2Mouse.containsMouse ? root.accent : AppLauncherStyle.circleIdleBorder

        scale: c2Mouse.pressed ? AppLauncherStyle.circlePressedScale : 1.0
        opacity: root.circlesOpacity
        visible: opacity > 0.01

        Behavior on color { ColorAnimation { duration: AppLauncherStyle.colorAnimDurationMs } }
        Behavior on border.color { ColorAnimation { duration: AppLauncherStyle.colorAnimDurationMs } }
        Behavior on scale { NumberAnimation { duration: AppLauncherStyle.scaleAnimDurationMs } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: AppLauncherStyle.transparent
            gradient: Gradient {
                GradientStop { position: 0.0; color: AppLauncherStyle.glassSheenTop }
                GradientStop { position: 0.35; color: AppLauncherStyle.glassSheenMid }
                GradientStop { position: 0.70; color: AppLauncherStyle.glassSheenCore }
                GradientStop { position: 1.0; color: AppLauncherStyle.glassSheenBottom }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: AppLauncherStyle.transparent
            border.width: 1.5
            border.color: AppLauncherStyle.glassInnerBevel
        }

        Text {
            anchors.centerIn: parent
            text: "󰍉"
            font.family: "Symbols Nerd Font"
            font.pixelSize: AppLauncherStyle.circleIconFontPx
            color: c2Mouse.containsMouse ? root.accent : root.fg
            Behavior on color { ColorAnimation { duration: AppLauncherStyle.colorAnimDurationMs } }
        }

        MouseArea {
            id: c2Mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!colorPickerProc.running) {
                    colorPickerProc.running = true
                }
                root.circle2Clicked()
            }
        }
    }

    // ── Active Background Items (System Tray) ──
    Row {
        id: trayRow
        x: c2.x + root.circleSize + root.traySpacing
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.traySpacing
        opacity: root.circlesOpacity
        visible: opacity > 0.01 && trayRepeater.count > 0

        Repeater {
            id: trayRepeater
            model: SystemTray.items

            Item {
                id: delegateRoot
                required property var modelData

                width: root.trayCircleSize
                height: root.trayCircleSize

                Rectangle {
                    id: trayCircle
                    anchors.fill: parent
                    radius: width / 2
                    color: trayMouse.containsMouse ? AppLauncherStyle.circleHoverBg : root.fill
                    border.width: 1.2
                    border.color: trayMouse.containsMouse ? root.accent : AppLauncherStyle.circleIdleBorder

                    scale: trayMouse.pressed ? AppLauncherStyle.circlePressedScale : (trayMouse.containsMouse ? 1.05 : 1.0)

                    Behavior on color { ColorAnimation { duration: AppLauncherStyle.colorAnimDurationMs } }
                    Behavior on border.color { ColorAnimation { duration: AppLauncherStyle.colorAnimDurationMs } }
                    Behavior on scale { NumberAnimation { duration: AppLauncherStyle.scaleAnimDurationMs } }

                    // Liquid glass sheen gradient
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: AppLauncherStyle.transparent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: AppLauncherStyle.glassSheenTop }
                            GradientStop { position: 0.35; color: AppLauncherStyle.glassSheenMid }
                            GradientStop { position: 0.70; color: AppLauncherStyle.glassSheenCore }
                            GradientStop { position: 1.0; color: AppLauncherStyle.glassSheenBottom }
                        }
                    }

                    // Glass inner bevel
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: Math.max(0, parent.radius - 1)
                        color: AppLauncherStyle.transparent
                        border.width: 1.5
                        border.color: AppLauncherStyle.glassInnerBevel
                    }

                    // App Icon
                    IconImage {
                        id: trayIcon
                        anchors.centerIn: parent
                        width: AppLauncherStyle.trayIconSize
                        height: AppLauncherStyle.trayIconSize
                        source: (delegateRoot.modelData && delegateRoot.modelData.icon) ? delegateRoot.modelData.icon : ""
                        visible: status === Image.Ready
                    }

                    // Fallback glyph/letter if icon image is unavailable or loading
                    Text {
                        anchors.centerIn: parent
                        visible: trayIcon.status !== Image.Ready
                        text: root.getFallbackGlyph(delegateRoot.modelData)
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: AppLauncherStyle.circleIconFontPx
                        font.weight: Font.Bold
                        color: trayMouse.containsMouse ? root.accent : root.fg
                        Behavior on color { ColorAnimation { duration: AppLauncherStyle.colorAnimDurationMs } }
                    }
                }

                // Hover tooltip displaying application title or description
                Rectangle {
                    id: trayTooltip
                    visible: trayMouse.containsMouse && tooltipText.text.length > 0 && !root.menuOpen && !root.trayMenuOpen
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: AppLauncherStyle.scaleAnimDurationMs } }
                    anchors.bottom: parent.top
                    anchors.bottomMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: tooltipText.implicitWidth + AppLauncherStyle.trayTooltipPaddingH * 2
                    height: tooltipText.implicitHeight + AppLauncherStyle.trayTooltipPaddingV * 2
                    radius: AppLauncherStyle.trayTooltipRadius
                    color: AppLauncherStyle.fill
                    border.width: 1.0
                    border.color: AppLauncherStyle.circleIdleBorder
                    z: 200

                    Text {
                        id: tooltipText
                        anchors.centerIn: parent
                        text: (delegateRoot.modelData && (delegateRoot.modelData.tooltipTitle || delegateRoot.modelData.title || delegateRoot.modelData.id)) || ""
                        font.pixelSize: AppLauncherStyle.trayTooltipFontPx
                        font.weight: Font.Medium
                        color: AppLauncherStyle.textPrimary
                    }
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            if (root.trayMenuItem === delegateRoot.modelData) {
                                root.closeTrayMenu()
                            } else {
                                root.trayMenuAnchorX = trayRow.x + delegateRoot.x + delegateRoot.width / 2
                                root.trayMenuItem = delegateRoot.modelData
                            }
                        } else if (mouse.button === Qt.LeftButton) {
                            root.closeTrayMenu()
                            if (delegateRoot.modelData) {
                                if (typeof delegateRoot.modelData.activate === "function") {
                                    delegateRoot.modelData.activate()
                                }
                                var appId = delegateRoot.modelData.id || delegateRoot.modelData.title || ""
                                if (appId.length > 0) {
                                    root.focusAppWindow(appId)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Tray options popup (opens above the right-clicked circle) ──
    // Fixed width + fixed-height rows: no implicitWidth feedback, so no polish loops.
    Rectangle {
        id: trayMenuPopup
        visible: root.trayMenuOpen && !root.menuOpen
        width: AppLauncherStyle.trayMenuWidth
        height: menuCol.implicitHeight + AppLauncherStyle.trayMenuPadding * 2
        x: Math.max(0, root.trayMenuAnchorX - width / 2)
        y: -height - AppLauncherStyle.trayMenuGap
        z: 300
        radius: AppLauncherStyle.trayMenuRadius
        color: root.fill
        border.width: 1.2
        border.color: AppLauncherStyle.circleIdleBorder

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: AppLauncherStyle.transparent
            gradient: Gradient {
                GradientStop { position: 0.0; color: AppLauncherStyle.glassSheenTop }
                GradientStop { position: 0.35; color: AppLauncherStyle.glassSheenMid }
                GradientStop { position: 0.70; color: AppLauncherStyle.glassSheenCore }
                GradientStop { position: 1.0; color: AppLauncherStyle.glassSheenBottom }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: AppLauncherStyle.transparent
            border.width: 1.5
            border.color: AppLauncherStyle.glassInnerBevel
        }

        Column {
            id: menuCol
            x: AppLauncherStyle.trayMenuPadding
            y: AppLauncherStyle.trayMenuPadding
            width: trayMenuPopup.width - AppLauncherStyle.trayMenuPadding * 2

            // Header: app name
            Text {
                width: menuCol.width
                height: AppLauncherStyle.trayMenuHeaderHeight
                leftPadding: 8
                rightPadding: 8
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                text: root.trayMenuItem ? (root.trayMenuItem.tooltipTitle || root.trayMenuItem.title || root.trayMenuItem.id || "") : ""
                color: root.accent
                font.pixelSize: AppLauncherStyle.trayTooltipFontPx
                font.weight: Font.DemiBold
            }

            // Options provided by the app (DBusMenu)
            Repeater {
                model: trayMenuOpener.children

                Item {
                    id: entry
                    required property var modelData
                    readonly property bool isSep: modelData ? modelData.isSeparator : false
                    readonly property bool isEnabled: modelData ? modelData.enabled : false

                    width: menuCol.width
                    height: isSep ? AppLauncherStyle.trayMenuSeparatorHeight : AppLauncherStyle.trayMenuItemHeight

                    Rectangle {
                        visible: entry.isSep
                        anchors.verticalCenter: parent.verticalCenter
                        x: 6
                        width: parent.width - 12
                        height: 1
                        color: AppLauncherStyle.circleIdleBorder
                        opacity: 0.25
                    }

                    Rectangle {
                        visible: !entry.isSep
                        anchors.fill: parent
                        radius: AppLauncherStyle.trayMenuItemRadius
                        color: (entryMouse.containsMouse && entry.isEnabled) ? AppLauncherStyle.circleHoverBg : AppLauncherStyle.transparent
                        Behavior on color { ColorAnimation { duration: AppLauncherStyle.colorAnimDurationMs } }
                    }

                    Text {
                        visible: !entry.isSep
                        anchors.fill: parent
                        leftPadding: 8
                        rightPadding: 8
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: {
                            if (!entry.modelData) return ""
                            var mark = entry.modelData.checkState === Qt.Checked ? "✓  " : ""
                            var arrow = entry.modelData.hasChildren ? "  ›" : ""
                            return mark + root.cleanMenuLabel(entry.modelData.text) + arrow
                        }
                        color: !entry.isEnabled ? root.dim : (entryMouse.containsMouse ? root.accent : root.fg)
                        font.pixelSize: AppLauncherStyle.trayTooltipFontPx
                    }

                    MouseArea {
                        id: entryMouse
                        anchors.fill: parent
                        enabled: !entry.isSep
                        hoverEnabled: true
                        cursorShape: entry.isEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (!entry.isEnabled || !entry.modelData) return
                            entry.modelData.triggered()
                            root.closeTrayMenu()
                        }
                    }
                }
            }

            // Apps without a menu: only offer to open them
            Item {
                visible: !(root.trayMenuItem && root.trayMenuItem.hasMenu)
                width: menuCol.width
                height: visible ? AppLauncherStyle.trayMenuItemHeight : 0

                Rectangle {
                    anchors.fill: parent
                    radius: AppLauncherStyle.trayMenuItemRadius
                    color: openMouse.containsMouse ? AppLauncherStyle.circleHoverBg : AppLauncherStyle.transparent
                }

                Text {
                    anchors.fill: parent
                    leftPadding: 8
                    verticalAlignment: Text.AlignVCenter
                    text: "Open"
                    color: openMouse.containsMouse ? root.accent : root.fg
                    font.pixelSize: AppLauncherStyle.trayTooltipFontPx
                }

                MouseArea {
                    id: openMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var item = root.trayMenuItem
                        root.closeTrayMenu()
                        if (!item) return
                        item.activate()
                        root.focusAppWindow(item.id || item.title || "")
                    }
                }
            }
        }
    }
}
