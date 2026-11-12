// ============================================================================
// File: modules/notification-center-bar.module.qml
// Purpose: Bottom-center notification tab and history center drawer with Do-Not-Disturb mute toggle and clear-all support.
// Public API:
//   - Properties: notifications, floatManager, fg, dim, accent, fill, danger, isOpen, tabWidth, tabIdleDepth, tabHoverDepth, panelWidth ...
//   - Functions:  open(), close(), toggle()
// Dependencies: QtQuick, "../components", "../styles", "../theme", QtQuick.Layouts, Quickshell, Quickshell.Widgets
// ============================================================================
import QtQuick
import "../components"
import "../styles"
import "../../../themes"
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// Bottom-center Notification Center drawer button and panel
Item {
    id: root

    property var notifications: null
    property var floatManager: null

    property color fg: NotificationCenterBarStyle.textPrimary
    property color dim: NotificationCenterBarStyle.textDim
    property color accent: NotificationCenterBarStyle.accent
    property color fill: NotificationCenterBarStyle.fill
    property color danger: NotificationCenterBarStyle.danger

    property bool isOpen: false
    property var expandedGroups: ({})
    property real clearAllProgress: 0.0

    function open() { root.isOpen = true }
    function close() { root.isOpen = false }
    function toggle() { root.isOpen = !root.isOpen }

    function triggerClearAll() {
        if (!root.notifications || clearAllAnim.running) return
        clearAllAnim.start()
    }

    SequentialAnimation {
        id: clearAllAnim
        NumberAnimation {
            target: root
            property: "clearAllProgress"
            from: 0.0
            to: 1.0
            duration: NotificationCenterBarStyle.deleteAnimDurationMs
            easing.type: Easing.OutCubic
        }
        ScriptAction {
            script: {
                if (root.notifications) {
                    root.notifications.clearAll()
                }
                root.expandedGroups = ({})
                root.clearAllProgress = 0.0
            }
        }
    }

    function isGroupExpanded(originKey) {
        return !!(originKey && root.expandedGroups && root.expandedGroups[originKey])
    }

    function toggleGroupExpanded(originKey) {
        if (!originKey) return
        var next = {}
        var keys = Object.keys(root.expandedGroups || {})
        for (var i = 0; i < keys.length; i++) {
            next[keys[i]] = root.expandedGroups[keys[i]]
        }
        next[originKey] = !next[originKey]
        root.expandedGroups = next
    }

    function resolveImageSource(raw) {
        if (!raw) return ""
        var s = String(raw)
        if (s.startsWith("image://icon/")) {
            var iconName = decodeURIComponent(s.slice(13).split("?")[0])
            return iconName ? (Quickshell.iconPath(iconName, true) || "") : ""
        }
        if (s.startsWith("/")) return "file://" + s
        if (s.startsWith("file://") || s.startsWith("image://qsimage/") || s.startsWith("http://") || s.startsWith("https://")) return s
        return Quickshell.iconPath(s, true) || ""
    }

    onNotificationsChanged: {
        if (root.notifications) {
            root.notifications.suppressPopups = root.isOpen
        }
    }

    readonly property bool isFloating: root.floatManager ? root.floatManager.isNotifFloating : false
    readonly property bool isActivelyDetaching: notifDrop.isDetaching || headerDragArea.isDetaching
    property bool detachedFromOpen: false

    Connections {
        target: root.floatManager
        function onWindowDocked(id) {
            if (id === "notif-center") {
                if (root.detachedFromOpen) {
                    root.open()
                }
                root.detachedFromOpen = false
            }
        }
        function onWindowClosed(id) {
            if (id === "notif-center") {
                root.detachedFromOpen = false
            }
        }
    }

    // Dimensions
    readonly property real tabWidth: NotificationCenterBarStyle.idleWidth
    readonly property real tabIdleDepth: NotificationCenterBarStyle.idleHeight
    readonly property real tabHoverDepth: NotificationCenterBarStyle.hoverHeight

    readonly property real panelWidth: NotificationCenterBarStyle.openWidth
    readonly property real panelHeight: NotificationCenterBarStyle.openHeight

    property real openProgress: isOpen ? 1.0 : 0.0
    Behavior on openProgress {
        NumberAnimation {
            duration: root.isOpen ? NotificationCenterBarStyle.openDurationMs : NotificationCenterBarStyle.closeDurationMs
            easing.type: root.isOpen ? Easing.OutCubic : Easing.InOutCubic
        }
    }

    property bool frozenHover: false
    onIsOpenChanged: {
        if (root.notifications) {
            root.notifications.suppressPopups = root.isOpen
        }
        if (isOpen) {
            frozenHover = isHovered
        } else {
            root.expandedGroups = ({})
        }
    }
    onOpenProgressChanged: {
        if (!isOpen && openProgress <= 0.01) {
            frozenHover = false
        }
    }

    readonly property bool isHovered: tabHover.hovered || tabCloseTimer.running
    readonly property bool effectiveHovered: (isOpen || openProgress > 0.01) ? frozenHover : isHovered
    property real baseHeight: effectiveHovered ? tabHoverDepth : tabIdleDepth
    Behavior on baseHeight { NumberAnimation { duration: NotificationCenterBarStyle.tabHoverDurationMs; easing.type: Easing.OutCubic } }

    width: tabWidth + (panelWidth - tabWidth) * openProgress
    height: baseHeight + (panelHeight - baseHeight) * openProgress

    // ── Input Mask for Wayland LayerShell Registration ──
    readonly property Item maskItem: barMask
    Item {
        id: barMask
        x: notifDrop.x
        y: notifDrop.y
        width: notifDrop.width
        height: notifDrop.height
    }

    HoverHandler {
        id: tabHover
        target: notifDrop
        enabled: !root.isOpen && !root.isFloating
        onHoveredChanged: {
            if (hovered) {
                tabCloseTimer.stop()
            } else {
                tabCloseTimer.restart()
            }
        }
    }

    Timer {
        id: tabCloseTimer
        interval: NotificationCenterBarStyle.unhoverDelayMs
    }

    // ────────────────────────────────────────────────────────
    // UNIFIED BOTTOM-EDGE MORPHING DROP (Idle Pill -> Hover Pill -> Open Panel)
    // ────────────────────────────────────────────────────────
    Drop {
        id: notifDrop
        fromBottom: true
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.isFloating ? (-root.height - 2) : 0
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.width
        height: root.height
        visible: anchors.bottomMargin > (-root.height - 1) || isDetaching || headerDragArea.isDetaching
        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: NotificationCenterBarStyle.openDurationMs
                easing.type: Easing.OutCubic
            }
        }
        fill: root.fill
        slant: NotificationCenterBarStyle.tabSlant + (NotificationCenterBarStyle.openSlant - NotificationCenterBarStyle.tabSlant) * root.openProgress
        rad: NotificationCenterBarStyle.tabRadius + (NotificationCenterBarStyle.openRadius - NotificationCenterBarStyle.tabRadius) * root.openProgress
        flare: NotificationCenterBarStyle.tabFlare + (NotificationCenterBarStyle.openFlare - NotificationCenterBarStyle.tabFlare) * Math.min(1.0, root.openProgress * 3.0)
        tp: 0
        inset: NotificationCenterBarStyle.tabInset + (NotificationCenterBarStyle.openInset - NotificationCenterBarStyle.tabInset) * root.openProgress
        bottomInset: NotificationCenterBarStyle.tabInset + (NotificationCenterBarStyle.openBottomInset - NotificationCenterBarStyle.tabInset) * root.openProgress

        property real pressSceneX: 0
        property real pressSceneY: 0
        property bool isDetaching: false

        // ── 1. Hover Tab Content (Bell Icon & Count Badge when closed) ──
        Item {
            id: tabContent
            anchors.fill: parent
            property real hoverContentOpacity: root.effectiveHovered ? 1.0 : 0.0
            Behavior on hoverContentOpacity { NumberAnimation { duration: NotificationCenterBarStyle.tabFadeDurationMs; easing.type: Easing.OutCubic } }
            opacity: hoverContentOpacity * Math.max(0.0, 1.0 - root.openProgress * 2.5)
            visible: opacity > 0.01 || notifDrop.isDetaching
            enabled: !root.isOpen || notifDrop.isDetaching

            Row {
                anchors.centerIn: parent
                spacing: NotificationCenterBarStyle.tabRowSpacing

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: (root.notifications && root.notifications.muted) ? "󰂛" : "󰂚"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: NotificationCenterBarStyle.tabBellFontPx
                    color: {
                        if (root.notifications && root.notifications.muted) return root.danger
                        if (tabMouse.containsMouse) return root.accent
                        return root.fg
                    }
                    Behavior on color { ColorAnimation { duration: NotificationCenterBarStyle.colorAnimDurationMs } }
                }

                // Notification count badge
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(NotificationCenterBarStyle.badgeMinWidth, countText.implicitWidth + NotificationCenterBarStyle.badgePadding)
                    height: NotificationCenterBarStyle.badgeHeight
                    radius: NotificationCenterBarStyle.badgeRadius
                    color: root.accent
                    visible: root.notifications && root.notifications.history && root.notifications.history.length > 0

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: (root.notifications && root.notifications.history) ? root.notifications.history.length : ""
                        color: NotificationCenterBarStyle.textOnAccent
                        font.pixelSize: NotificationCenterBarStyle.badgeFontPx
                        font.bold: true
                    }
                }
            }

            MouseArea {
                id: tabMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onPressed: function(mouse) {
                    var pt = mapToItem(null, mouse.x, mouse.y)
                    notifDrop.pressSceneX = pt.x
                    notifDrop.pressSceneY = pt.y
                    notifDrop.isDetaching = false
                }

                onPositionChanged: function(mouse) {
                    if (!pressed) return
                    var pt = mapToItem(null, mouse.x, mouse.y)
                    var dy = notifDrop.pressSceneY - pt.y

                    if (!notifDrop.isDetaching && root.floatManager && (dy > NotificationCenterBarStyle.detachThresholdY || Math.hypot(pt.x - notifDrop.pressSceneX, dy) > NotificationCenterBarStyle.detachThresholdHypot)) {
                        notifDrop.isDetaching = true
                        root.detachedFromOpen = false
                        root.floatManager.startDrag({
                            id: "notif-center",
                            title: "Notifications",
                            icon: "󰂚",
                            originSide: "bottom",
                            originX: root.x,
                            originY: root.y,
                            width: NotificationCenterBarStyle.floatWidth,
                            height: NotificationCenterBarStyle.floatHeight,
                            notifications: root.notifications
                        }, pt.x, pt.y)
                    } else if (notifDrop.isDetaching && root.floatManager) {
                        root.floatManager.updateDrag(pt.x, pt.y)
                    }
                }

                onReleased: function(mouse) {
                    if (notifDrop.isDetaching) {
                        notifDrop.isDetaching = false
                        if (root.floatManager) root.floatManager.endDrag()
                    } else {
                        if (mouse.button === Qt.RightButton) {
                            if (root.notifications) {
                                root.notifications.toggleMute()
                            }
                        } else {
                            root.toggle()
                        }
                    }
                }

                onCanceled: {
                    if (notifDrop.isDetaching) {
                        notifDrop.isDetaching = false
                        if (root.floatManager) root.floatManager.endDrag()
                    }
                }
            }
        }

        // ── 2. Open Panel Content (Expanded from the bottom-center Drop) ──
        ColumnLayout {
            id: panelContent
            anchors.fill: parent
            anchors.margins: NotificationCenterBarStyle.panelPadding
            spacing: NotificationCenterBarStyle.panelSpacing
            opacity: Math.max(0.0, Math.min(1.0, (root.openProgress - 0.35) / 0.65))
            visible: opacity > 0.01 || headerDragArea.isDetaching
            enabled: root.isOpen || headerDragArea.isDetaching
            Item {
                id: headerContainer
                Layout.fillWidth: true
                implicitHeight: NotificationCenterBarStyle.headerHeight

                MouseArea {
                    id: headerDragArea
                    anchors.fill: parent
                    anchors.rightMargin: NotificationCenterBarStyle.headerDragRightMargin
                    cursorShape: Qt.SizeAllCursor
                    property real pressSceneX: 0
                    property real pressSceneY: 0
                    property bool isDetaching: false

                    onPressed: function(mouse) {
                        var pt = mapToItem(null, mouse.x, mouse.y)
                        pressSceneX = pt.x
                        pressSceneY = pt.y
                        isDetaching = false
                    }

                    onPositionChanged: function(mouse) {
                        if (!pressed) return
                        var pt = mapToItem(null, mouse.x, mouse.y)
                        var dy = pressSceneY - pt.y

                        if (!isDetaching && root.floatManager && (dy > NotificationCenterBarStyle.detachThresholdY || Math.hypot(pt.x - pressSceneX, dy) > NotificationCenterBarStyle.detachThresholdHypot)) {
                            isDetaching = true
                            root.detachedFromOpen = true
                            root.close()
                            root.floatManager.startDrag({
                                id: "notif-center",
                                title: "Notifications",
                                icon: "󰂚",
                                originSide: "bottom",
                                originX: root.x,
                                originY: root.y,
                                width: NotificationCenterBarStyle.floatWidth,
                                height: NotificationCenterBarStyle.floatHeight,
                                notifications: root.notifications
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

                RowLayout {
                    id: headerRow
                    anchors.fill: parent
                    spacing: NotificationCenterBarStyle.headerSpacing

                // Bell Icon & Title
                Text {
                    text: (root.notifications && root.notifications.muted) ? "󰂛" : "󰂚"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: NotificationCenterBarStyle.headerIconFontPx
                    color: (root.notifications && root.notifications.muted) ? root.danger : root.accent
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: "Notification Center"
                    font.pixelSize: NotificationCenterBarStyle.headerTitleFontPx
                    font.weight: Font.DemiBold
                    color: root.fg
                    Layout.alignment: Qt.AlignVCenter
                }

                // History count pill
                Rectangle {
                    implicitHeight: NotificationCenterBarStyle.headerCountBadgeHeight
                    implicitWidth: Math.max(NotificationCenterBarStyle.headerCountBadgeHeight, histCountTxt.implicitWidth + NotificationCenterBarStyle.headerCountBadgePadding)
                    radius: NotificationCenterBarStyle.headerCountBadgeRadius
                    color: NotificationCenterBarStyle.dividerColor
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        id: histCountTxt
                        anchors.centerIn: parent
                        text: (root.notifications && root.notifications.history) ? root.notifications.history.length : "0"
                        color: root.dim
                        font.pixelSize: NotificationCenterBarStyle.headerCountFontPx
                        font.weight: Font.Medium
                    }
                }

                Item { Layout.fillWidth: true } // Spacer

                // ── Mute Button ──
                Rectangle {
                    implicitHeight: NotificationCenterBarStyle.actionBtnHeight
                    implicitWidth: muteRow.implicitWidth + NotificationCenterBarStyle.actionBtnPadding
                    radius: NotificationCenterBarStyle.actionBtnRadius
                    color: (root.notifications && root.notifications.muted) ? NotificationCenterBarStyle.dangerClampedTint
                           : (muteMouse.containsMouse ? NotificationCenterBarStyle.buttonHoverBg : NotificationCenterBarStyle.buttonBg)
                    border.width: 1
                    border.color: (root.notifications && root.notifications.muted) ? root.danger : NotificationCenterBarStyle.buttonBorder
                    Layout.alignment: Qt.AlignVCenter

                    Row {
                        id: muteRow
                        anchors.centerIn: parent
                        spacing: NotificationCenterBarStyle.actionRowSpacing

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (root.notifications && root.notifications.muted) ? "󰂛" : "󰂚"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: NotificationCenterBarStyle.actionIconFontPx
                            color: (root.notifications && root.notifications.muted) ? root.danger : root.fg
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (root.notifications && root.notifications.muted) ? "Muted" : "Mute"
                            font.pixelSize: NotificationCenterBarStyle.actionLabelFontPx
                            font.weight: Font.Medium
                            color: (root.notifications && root.notifications.muted) ? root.danger : root.fg
                        }
                    }

                    MouseArea {
                        id: muteMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.notifications) root.notifications.toggleMute()
                    }
                }

                // ── Clear Button ──
                Rectangle {
                    implicitHeight: NotificationCenterBarStyle.actionBtnHeight
                    implicitWidth: clearRow.implicitWidth + NotificationCenterBarStyle.actionBtnPadding
                    radius: NotificationCenterBarStyle.actionBtnRadius
                    color: clearMouse.containsMouse ? NotificationCenterBarStyle.dangerClampedTint : NotificationCenterBarStyle.buttonBg
                    border.width: 1
                    border.color: clearMouse.containsMouse ? root.danger : NotificationCenterBarStyle.buttonBorder
                    opacity: (root.notifications && root.notifications.history && root.notifications.history.length > 0) ? 1.0 : NotificationCenterBarStyle.disabledOpacity
                    Layout.alignment: Qt.AlignVCenter

                    Row {
                        id: clearRow
                        anchors.centerIn: parent
                        spacing: NotificationCenterBarStyle.actionRowSpacing

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰆴"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: NotificationCenterBarStyle.actionIconFontPx
                            color: clearMouse.containsMouse ? root.danger : root.fg
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Clear"
                            font.pixelSize: NotificationCenterBarStyle.actionLabelFontPx
                            font.weight: Font.Medium
                            color: clearMouse.containsMouse ? root.danger : root.fg
                        }
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.notifications && root.notifications.history && root.notifications.history.length > 0
                        onClicked: root.triggerClearAll()
                    }
                }

                // ── Close '✕' Button ──
                Rectangle {
                    implicitWidth: NotificationCenterBarStyle.closeBtnSize
                    implicitHeight: NotificationCenterBarStyle.closeBtnSize
                    radius: NotificationCenterBarStyle.closeBtnRadius
                    color: closeMouse.containsMouse ? NotificationCenterBarStyle.buttonHoverBg : NotificationCenterBarStyle.transparent
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: NotificationCenterBarStyle.closeIconFontPx
                        color: closeMouse.containsMouse ? root.fg : root.dim
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
        }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: NotificationCenterBarStyle.dividerHeight
                color: NotificationCenterBarStyle.dividerColor
            }

            // ── Notifications Body / List ──
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Empty State
                Column {
                    anchors.centerIn: parent
                    spacing: NotificationCenterBarStyle.emptyColumnSpacing
                    visible: !root.notifications || !root.notifications.history || root.notifications.history.length === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰂚"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: NotificationCenterBarStyle.emptyBellFontPx
                        color: NotificationCenterBarStyle.emptyBellColor
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No notifications"
                        font.pixelSize: NotificationCenterBarStyle.emptyTitleFontPx
                        font.weight: Font.Medium
                        color: root.dim
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Received notifications will appear here"
                        font.pixelSize: NotificationCenterBarStyle.emptySubFontPx
                        color: NotificationCenterBarStyle.textSubtle
                    }
                }

                // Notifications ListView (grouped by origin like swaync)
                ListView {
                    id: historyList
                    anchors.fill: parent
                    clip: true
                    spacing: 0
                    boundsBehavior: Flickable.StopAtBounds
                    visible: root.notifications && root.notifications.history && root.notifications.history.length > 0
                    opacity: 1.0 - root.clearAllProgress
                    transform: Translate { x: NotificationCenterBarStyle.deleteSlideOffsetX * root.clearAllProgress }
                    model: (root.notifications && root.notifications.groupedHistory) ? root.notifications.groupedHistory : []

                    displaced: Transition {
                        NumberAnimation {
                            properties: "x,y"
                            duration: NotificationCenterBarStyle.groupExpandDurationMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    delegate: Item {
                        id: groupDelegate
                        required property var modelData
                        required property int index

                        readonly property var groupItems: modelData.items || []
                        readonly property int groupCount: groupItems.length
                        readonly property var leadItem: groupCount > 0 ? groupItems[0] : modelData
                        readonly property bool isExpanded: groupCount > 1 && root.isGroupExpanded(modelData.originKey)
                        readonly property bool isStacked: groupCount > 1 && !isExpanded
                        readonly property real stackExtraBottom: (groupCount > 1 ? (groupCount > 2 ? 10 : 6) : 0) * (1.0 - expandProgress)

                        property real expandProgress: isExpanded ? 1.0 : 0.0
                        Behavior on expandProgress {
                            NumberAnimation {
                                duration: NotificationCenterBarStyle.groupExpandDurationMs
                                easing.type: Easing.OutCubic
                            }
                        }

                        readonly property real collapsedTotalH: collapsedCardWrapper.height + stackExtraBottom + NotificationCenterBarStyle.listSpacing
                        readonly property real expandedTotalH: expandedGroupCol.implicitHeight + NotificationCenterBarStyle.listSpacing
                        readonly property real targetGroupH: collapsedTotalH + (expandedTotalH - collapsedTotalH) * expandProgress

                        property bool isDeletingGroup: false
                        property real deleteProgress: 0.0
                        property real deleteStartH: 0.0
                        property bool deleteIsOriginGroup: false
                        property string pendingDeleteOriginKey: ""
                        property int pendingDeleteId: -1

                        onModelDataChanged: {
                            if (groupDeleteAnim.running) groupDeleteAnim.stop()
                            isDeletingGroup = false
                            deleteProgress = 0.0
                        }

                        function triggerDeleteGroup(removeWholeGroup) {
                            if (!root.notifications || isDeletingGroup) return
                            deleteStartH = height
                            deleteIsOriginGroup = !!removeWholeGroup
                            pendingDeleteOriginKey = modelData.originKey || ""
                            pendingDeleteId = leadItem ? leadItem.id : -1
                            isDeletingGroup = true
                            groupDeleteAnim.start()
                        }

                        SequentialAnimation {
                            id: groupDeleteAnim
                            NumberAnimation {
                                target: groupDelegate
                                property: "deleteProgress"
                                from: 0.0
                                to: 1.0
                                duration: NotificationCenterBarStyle.deleteAnimDurationMs
                                easing.type: Easing.OutCubic
                            }
                            ScriptAction {
                                script: {
                                    var origKey = groupDelegate.pendingDeleteOriginKey
                                    var targetId = groupDelegate.pendingDeleteId
                                    var wholeGrp = groupDelegate.deleteIsOriginGroup
                                    groupDelegate.isDeletingGroup = false
                                    groupDelegate.deleteProgress = 0.0
                                    if (!root.notifications) return
                                    if (wholeGrp && origKey) {
                                        root.notifications.removeGroupByOrigin(origKey)
                                    } else if (targetId >= 0) {
                                        root.notifications.removeById(targetId)
                                    }
                                }
                            }
                        }

                        width: historyList.width
                        height: isDeletingGroup ? Math.max(0, deleteStartH * (1.0 - deleteProgress)) : targetGroupH
                        opacity: 1.0 - deleteProgress
                        scale: 1.0 - 0.05 * deleteProgress
                        transform: Translate { x: NotificationCenterBarStyle.deleteSlideOffsetX * groupDelegate.deleteProgress }
                        clip: true

                        // ── A. COLLAPSED STACK OR SINGLE NOTIFICATION ──
                        Item {
                            id: collapsedCardWrapper
                            width: parent.width
                            height: Math.max(NotificationCenterBarStyle.rowMinHeight, leadMsgCol.implicitHeight + NotificationCenterBarStyle.rowVerticalPadding)
                            visible: groupDelegate.expandProgress < 0.99
                            opacity: 1.0 - groupDelegate.expandProgress
                            scale: 1.0 - 0.03 * groupDelegate.expandProgress

                            // Stack layer 2 (back card peeking at bottom when 3+ notifications in group)
                            Rectangle {
                                visible: groupDelegate.groupCount > 2
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                y: parent.height - NotificationCenterBarStyle.rowRadius + 10 + 14 * groupDelegate.expandProgress
                                height: NotificationCenterBarStyle.rowRadius + 4
                                radius: NotificationCenterBarStyle.rowRadius
                                color: NotificationCenterBarStyle.rowBg
                                border.width: 1
                                border.color: NotificationCenterBarStyle.rowBorder
                                opacity: 0.55 * (1.0 - groupDelegate.expandProgress)
                            }

                            // Stack layer 1 (middle card peeking at bottom when 2+ notifications in group)
                            Rectangle {
                                visible: groupDelegate.groupCount > 1
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                y: parent.height - NotificationCenterBarStyle.rowRadius + 5 + 8 * groupDelegate.expandProgress
                                height: NotificationCenterBarStyle.rowRadius + 4
                                radius: NotificationCenterBarStyle.rowRadius
                                color: NotificationCenterBarStyle.rowBg
                                border.width: 1
                                border.color: NotificationCenterBarStyle.rowBorder
                                opacity: 0.8 * (1.0 - groupDelegate.expandProgress)
                            }

                            // Top / Main Card
                            Rectangle {
                                id: itemRow
                                anchors.fill: parent
                                radius: NotificationCenterBarStyle.rowRadius
                                color: rowMouse.containsMouse ? NotificationCenterBarStyle.rowHoverBg : NotificationCenterBarStyle.rowBg
                                border.width: 1
                                border.color: NotificationCenterBarStyle.rowBorder
                                Behavior on color { ColorAnimation { duration: NotificationCenterBarStyle.rowColorAnimDurationMs } }

                                // Left Urgency Strip
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.margins: NotificationCenterBarStyle.urgencyBarMargin
                                    width: NotificationCenterBarStyle.urgencyBarWidth
                                    radius: NotificationCenterBarStyle.urgencyBarRadius
                                    color: {
                                        var urg = groupDelegate.modelData.urgency
                                        if (urg === 2) return root.danger
                                        if (urg === 1) return root.accent
                                        return NotificationCenterBarStyle.urgencyLowBar
                                    }
                                }

                                // App Icon
                                Item {
                                    id: iconHolder
                                    anchors.left: parent.left
                                    anchors.leftMargin: NotificationCenterBarStyle.rowIconLeftMargin
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: NotificationCenterBarStyle.rowIconSize
                                    height: NotificationCenterBarStyle.rowIconSize

                                    Image {
                                        id: customImg
                                        anchors.fill: parent
                                        source: root.resolveImageSource(groupDelegate.leadItem.image)
                                        fillMode: Image.PreserveAspectFit
                                        visible: source !== "" && status === Image.Ready
                                    }

                                    IconImage {
                                        id: appIconImg
                                        anchors.fill: parent
                                        source: customImg.visible ? "" : root.resolveImageSource(groupDelegate.leadItem.appIcon)
                                        visible: source !== "" && status === Image.Ready && !customImg.visible
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: NotificationCenterBarStyle.rowIconRadius
                                        color: NotificationCenterBarStyle.dividerColor
                                        visible: !customImg.visible && !appIconImg.visible

                                        Text {
                                            anchors.centerIn: parent
                                            text: "?"
                                            font.weight: Font.Bold
                                            font.pixelSize: NotificationCenterBarStyle.rowFallbackIconFontPx
                                            color: (groupDelegate.modelData.urgency === 2) ? root.danger : root.accent
                                        }
                                    }
                                }

                                // Message Column
                                Column {
                                    id: leadMsgCol
                                    anchors.left: iconHolder.right
                                    anchors.leftMargin: NotificationCenterBarStyle.msgLeftMargin
                                    anchors.right: rightBadgesRow.left
                                    anchors.rightMargin: NotificationCenterBarStyle.msgRightMargin
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: NotificationCenterBarStyle.msgSpacing

                                    Row {
                                        width: parent.width
                                        spacing: NotificationCenterBarStyle.metaRowSpacing

                                        Text {
                                            text: groupDelegate.leadItem.appName || "Notification"
                                            font.pixelSize: NotificationCenterBarStyle.rowTimeFontPx
                                            color: root.dim
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                            width: Math.min(implicitWidth, parent.width - NotificationCenterBarStyle.appNameRightReserve)
                                        }

                                        Text {
                                            text: groupDelegate.leadItem.time ? ("• " + Qt.formatTime(groupDelegate.leadItem.time, "hh:mm")) : ""
                                            font.pixelSize: NotificationCenterBarStyle.rowTimeFontPx
                                            color: NotificationCenterBarStyle.textSubtle
                                        }
                                    }

                                    Text {
                                        width: parent.width
                                        text: groupDelegate.leadItem.summary || ""
                                        color: root.fg
                                        font.pixelSize: NotificationCenterBarStyle.rowTitleFontPx
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        visible: text.length > 0
                                    }

                                    Text {
                                        width: parent.width
                                        text: groupDelegate.leadItem.body || ""
                                        color: NotificationCenterBarStyle.textSecondary
                                        font.pixelSize: NotificationCenterBarStyle.rowBodyFontPx
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        visible: text.length > 0
                                    }
                                }

                                // Right Action / Stack Count Badge + Delete Button
                                Row {
                                    id: rightBadgesRow
                                    anchors.right: parent.right
                                    anchors.rightMargin: NotificationCenterBarStyle.deleteBtnRightMargin
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    // Stack count pill + chevron when stacked
                                    Rectangle {
                                        visible: groupDelegate.groupCount > 1
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: NotificationCenterBarStyle.headerCountBadgeHeight
                                        width: stackBadgeRow.implicitWidth + 10
                                        radius: NotificationCenterBarStyle.headerCountBadgeRadius
                                        color: NotificationCenterBarStyle.buttonBg
                                        border.width: 1
                                        border.color: root.accent

                                        Row {
                                            id: stackBadgeRow
                                            anchors.centerIn: parent
                                            spacing: 3

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: groupDelegate.groupCount
                                                color: root.accent
                                                font.pixelSize: NotificationCenterBarStyle.badgeFontPx
                                                font.bold: true
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "󰅀"
                                                font.family: "Symbols Nerd Font"
                                                font.pixelSize: NotificationCenterBarStyle.deleteIconFontPx
                                                color: root.accent
                                            }
                                        }
                                    }

                                    // Delete Individual or Stacked Group Button
                                    Rectangle {
                                        id: rowDeleteBtn
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: NotificationCenterBarStyle.deleteBtnSize
                                        height: NotificationCenterBarStyle.deleteBtnSize
                                        radius: NotificationCenterBarStyle.deleteBtnRadius
                                        color: delMouse.containsMouse ? NotificationCenterBarStyle.dangerClampedTint : NotificationCenterBarStyle.transparent
                                        opacity: rowMouse.containsMouse ? 1.0 : 0.0
                                        Behavior on opacity { NumberAnimation { duration: NotificationCenterBarStyle.colorAnimDurationMs } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✕"
                                            font.pixelSize: NotificationCenterBarStyle.deleteIconFontPx
                                            color: delMouse.containsMouse ? root.danger : root.dim
                                        }

                                        MouseArea {
                                            id: delMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                groupDelegate.triggerDeleteGroup(groupDelegate.isStacked)
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    z: -1
                                    onClicked: function(mouse) {
                                        if (!root.notifications) return
                                        if (mouse.button === Qt.RightButton) {
                                            groupDelegate.triggerDeleteGroup(groupDelegate.isStacked)
                                        } else if (mouse.button === Qt.LeftButton) {
                                            if (groupDelegate.isStacked) {
                                                root.toggleGroupExpanded(groupDelegate.modelData.originKey)
                                            } else if (groupDelegate.leadItem) {
                                                var targetItem = groupDelegate.leadItem
                                                root.notifications.activateNotification(targetItem)
                                                root.notifications.removeById(targetItem.id)
                                                root.close()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── B. EXPANDED ORIGIN ARRAY (when a stacked group is left-clicked) ──
                        Column {
                            id: expandedGroupCol
                            width: parent.width
                            spacing: 0
                            visible: groupDelegate.expandProgress > 0.01
                            opacity: groupDelegate.expandProgress

                            // Group Header Bar (click to collapse stack, right-click or ✕ to clear group)
                            Rectangle {
                                width: parent.width
                                height: NotificationCenterBarStyle.actionBtnHeight + 4
                                radius: NotificationCenterBarStyle.actionBtnRadius
                                color: grpHdrMouse.containsMouse ? NotificationCenterBarStyle.buttonHoverBg : NotificationCenterBarStyle.buttonBg
                                border.width: 1
                                border.color: root.accent

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 6

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰅃"
                                        font.family: "Symbols Nerd Font"
                                        font.pixelSize: NotificationCenterBarStyle.actionIconFontPx
                                        color: root.accent
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: groupDelegate.modelData.appName || "Notification"
                                        font.pixelSize: NotificationCenterBarStyle.rowTitleFontPx
                                        font.weight: Font.DemiBold
                                        color: root.fg
                                    }

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: NotificationCenterBarStyle.badgeHeight
                                        width: Math.max(NotificationCenterBarStyle.badgeMinWidth, expCountTxt.implicitWidth + NotificationCenterBarStyle.badgePadding)
                                        radius: NotificationCenterBarStyle.badgeRadius
                                        color: root.accent

                                        Text {
                                            id: expCountTxt
                                            anchors.centerIn: parent
                                            text: groupDelegate.groupCount
                                            color: NotificationCenterBarStyle.textOnAccent
                                            font.pixelSize: NotificationCenterBarStyle.badgeFontPx
                                            font.bold: true
                                        }
                                    }
                                }

                                // Clear Group Button
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: NotificationCenterBarStyle.deleteBtnSize
                                    height: NotificationCenterBarStyle.deleteBtnSize
                                    radius: NotificationCenterBarStyle.deleteBtnRadius
                                    color: grpDelMouse.containsMouse ? NotificationCenterBarStyle.dangerClampedTint : NotificationCenterBarStyle.transparent
                                    z: 2

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        font.pixelSize: NotificationCenterBarStyle.deleteIconFontPx
                                        color: grpDelMouse.containsMouse ? root.danger : root.dim
                                    }

                                    MouseArea {
                                        id: grpDelMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            groupDelegate.triggerDeleteGroup(true)
                                        }
                                    }
                                }

                                MouseArea {
                                    id: grpHdrMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.RightButton) {
                                            groupDelegate.triggerDeleteGroup(true)
                                        } else {
                                            root.toggleGroupExpanded(groupDelegate.modelData.originKey)
                                        }
                                    }
                                }
                            }

                            // Array of Individual Notifications in this Origin Group
                            Repeater {
                                model: groupDelegate.groupItems

                                delegate: Item {
                                    id: subRowWrapper
                                    required property var modelData
                                    required property int index

                                    readonly property real cardHeight: Math.max(NotificationCenterBarStyle.rowMinHeight, subMsgCol.implicitHeight + NotificationCenterBarStyle.rowVerticalPadding)
                                    readonly property real baseHeight: cardHeight + 6

                                    property bool isDeletingSub: false
                                    property real subDeleteProgress: 0.0
                                    property real subDeleteStartH: 0.0
                                    property int pendingSubDeleteId: -1

                                    onModelDataChanged: {
                                        if (subDeleteAnim.running) subDeleteAnim.stop()
                                        isDeletingSub = false
                                        subDeleteProgress = 0.0
                                    }

                                    function triggerDeleteSub() {
                                        if (!root.notifications || isDeletingSub) return
                                        subDeleteStartH = height
                                        pendingSubDeleteId = modelData ? modelData.id : -1
                                        isDeletingSub = true
                                        subDeleteAnim.start()
                                    }

                                    SequentialAnimation {
                                        id: subDeleteAnim
                                        NumberAnimation {
                                            target: subRowWrapper
                                            property: "subDeleteProgress"
                                            from: 0.0
                                            to: 1.0
                                            duration: NotificationCenterBarStyle.deleteAnimDurationMs
                                            easing.type: Easing.OutCubic
                                        }
                                        ScriptAction {
                                            script: {
                                                var targetId = subRowWrapper.pendingSubDeleteId
                                                subRowWrapper.isDeletingSub = false
                                                subRowWrapper.subDeleteProgress = 0.0
                                                if (root.notifications && targetId >= 0) {
                                                    root.notifications.removeById(targetId)
                                                }
                                            }
                                        }
                                    }

                                    width: expandedGroupCol.width
                                    height: isDeletingSub ? Math.max(0, subDeleteStartH * (1.0 - subDeleteProgress)) : baseHeight
                                    opacity: (1.0 - subDeleteProgress) * groupDelegate.expandProgress
                                    scale: (0.96 + 0.04 * groupDelegate.expandProgress) * (1.0 - 0.05 * subDeleteProgress)
                                    transform: Translate {
                                        x: NotificationCenterBarStyle.deleteSlideOffsetX * subRowWrapper.subDeleteProgress
                                        y: -(subRowWrapper.index + 1) * 12 * (1.0 - groupDelegate.expandProgress)
                                    }
                                    clip: true

                                    Rectangle {
                                        id: subRow
                                        y: 6
                                        width: parent.width
                                        height: subRowWrapper.cardHeight
                                        radius: NotificationCenterBarStyle.rowRadius
                                        color: subRowMouse.containsMouse ? NotificationCenterBarStyle.rowHoverBg : NotificationCenterBarStyle.rowBg
                                        border.width: 1
                                        border.color: NotificationCenterBarStyle.rowBorder
                                        Behavior on color { ColorAnimation { duration: NotificationCenterBarStyle.rowColorAnimDurationMs } }

                                        // Left Urgency Strip
                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            anchors.margins: NotificationCenterBarStyle.urgencyBarMargin
                                            width: NotificationCenterBarStyle.urgencyBarWidth
                                            radius: NotificationCenterBarStyle.urgencyBarRadius
                                            color: {
                                                var urg = subRowWrapper.modelData.urgency
                                                if (urg === 2) return root.danger
                                                if (urg === 1) return root.accent
                                                return NotificationCenterBarStyle.urgencyLowBar
                                            }
                                        }

                                        // App Icon
                                        Item {
                                            id: subIconHolder
                                            anchors.left: parent.left
                                            anchors.leftMargin: NotificationCenterBarStyle.rowIconLeftMargin
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: NotificationCenterBarStyle.rowIconSize
                                            height: NotificationCenterBarStyle.rowIconSize

                                            Image {
                                                id: subCustomImg
                                                anchors.fill: parent
                                                source: root.resolveImageSource(subRowWrapper.modelData.image)
                                                fillMode: Image.PreserveAspectFit
                                                visible: source !== "" && status === Image.Ready
                                            }

                                            IconImage {
                                                id: subAppIconImg
                                                anchors.fill: parent
                                                source: subCustomImg.visible ? "" : root.resolveImageSource(subRowWrapper.modelData.appIcon)
                                                visible: source !== "" && status === Image.Ready && !subCustomImg.visible
                                            }

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: NotificationCenterBarStyle.rowIconRadius
                                                color: NotificationCenterBarStyle.dividerColor
                                                visible: !subCustomImg.visible && !subAppIconImg.visible

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "?"
                                                    font.weight: Font.Bold
                                                    font.pixelSize: NotificationCenterBarStyle.rowFallbackIconFontPx
                                                    color: (subRowWrapper.modelData.urgency === 2) ? root.danger : root.accent
                                                }
                                            }
                                        }

                                        // Message Column
                                        Column {
                                            id: subMsgCol
                                            anchors.left: subIconHolder.right
                                            anchors.leftMargin: NotificationCenterBarStyle.msgLeftMargin
                                            anchors.right: subDeleteBtn.left
                                            anchors.rightMargin: NotificationCenterBarStyle.msgRightMargin
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: NotificationCenterBarStyle.msgSpacing

                                            Row {
                                                width: parent.width
                                                spacing: NotificationCenterBarStyle.metaRowSpacing

                                                Text {
                                                    text: subRowWrapper.modelData.appName || "Notification"
                                                    font.pixelSize: NotificationCenterBarStyle.rowTimeFontPx
                                                    color: root.dim
                                                    font.weight: Font.Medium
                                                    elide: Text.ElideRight
                                                    width: Math.min(implicitWidth, parent.width - NotificationCenterBarStyle.appNameRightReserve)
                                                }

                                                Text {
                                                    text: subRowWrapper.modelData.time ? ("• " + Qt.formatTime(subRowWrapper.modelData.time, "hh:mm")) : ""
                                                    font.pixelSize: NotificationCenterBarStyle.rowTimeFontPx
                                                    color: NotificationCenterBarStyle.textSubtle
                                                }
                                            }

                                            Text {
                                                width: parent.width
                                                text: subRowWrapper.modelData.summary || ""
                                                color: root.fg
                                                font.pixelSize: NotificationCenterBarStyle.rowTitleFontPx
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                                visible: text.length > 0
                                            }

                                            Text {
                                                width: parent.width
                                                text: subRowWrapper.modelData.body || ""
                                                color: NotificationCenterBarStyle.textSecondary
                                                font.pixelSize: NotificationCenterBarStyle.rowBodyFontPx
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                                visible: text.length > 0
                                            }
                                        }

                                        // Delete Individual Notification in Expanded Array
                                        Rectangle {
                                            id: subDeleteBtn
                                            anchors.right: parent.right
                                            anchors.rightMargin: NotificationCenterBarStyle.deleteBtnRightMargin
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: NotificationCenterBarStyle.deleteBtnSize
                                            height: NotificationCenterBarStyle.deleteBtnSize
                                            radius: NotificationCenterBarStyle.deleteBtnRadius
                                            color: subDelMouse.containsMouse ? NotificationCenterBarStyle.dangerClampedTint : NotificationCenterBarStyle.transparent
                                            opacity: subRowMouse.containsMouse ? 1.0 : 0.0
                                            Behavior on opacity { NumberAnimation { duration: NotificationCenterBarStyle.colorAnimDurationMs } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "✕"
                                                font.pixelSize: NotificationCenterBarStyle.deleteIconFontPx
                                                color: subDelMouse.containsMouse ? root.danger : root.dim
                                            }

                                            MouseArea {
                                                id: subDelMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    subRowWrapper.triggerDeleteSub()
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: subRowMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            z: -1
                                            onClicked: function(mouse) {
                                                if (!root.notifications) return
                                                if (mouse.button === Qt.RightButton) {
                                                    subRowWrapper.triggerDeleteSub()
                                                } else if (mouse.button === Qt.LeftButton) {
                                                    var targetItem = subRowWrapper.modelData
                                                    root.notifications.activateNotification(targetItem)
                                                    root.notifications.removeById(targetItem.id)
                                                    root.close()
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
        }
    }
}
