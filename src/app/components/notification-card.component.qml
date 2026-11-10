// ============================================================================
// File: components/notification-card.component.qml
// Purpose: Individual notification toast card featuring hydrodynamic water-bubble rise physics, urgency borders, and hover pause.
// Public API:
//   - Properties: screenW, screenH, cardW, cardH, bubbleW, bubbleH, restingGlobalY, phase, isActive, notification, urgency, urgencyColor
//   - Signals:    dismissRequested()
//   - Functions:  startSpawn(restingY), startDismiss()
// Dependencies: QtQuick, "../styles", "../theme", QtQuick.Layouts, Quickshell, Quickshell.Widgets, Quickshell.Services.Notifications
// ============================================================================
import QtQuick
import "../styles"
import "../../../themes"
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

// Notification card designed for vertical stacking accumulation with water bubble
// emergence physics, fluid expansion, urgency border styling, and dismissal collapse.
Item {
    id: root

    property real screenW: 1920
    property real screenH: 1080

    // Dimensions matching right bottom bar (width 350, height 1.5x depth 36 = 54)
    readonly property real cardW: NotificationCardStyle.cardWidth
    readonly property real cardH: NotificationCardStyle.cardHeight
    readonly property real bubbleW: NotificationCardStyle.bubbleStartWidth
    readonly property real bubbleH: NotificationCardStyle.bubbleStartHeight
    property real bottomGap: 0

    property real restingGlobalY: 0
    property string phase: "closed" // "closed" | "rising" | "expanding" | "active" | "dismissing"
    readonly property bool isActive: phase !== "closed"

    property var notification: null
    property int defaultTimeoutMs: NotificationCardStyle.defaultTimeoutMs
    property int criticalTimeoutMs: NotificationCardStyle.criticalTimeoutMs

    function effectiveTimeout() {
        if (root.notification && root.notification.expireTimeout && root.notification.expireTimeout > 0) {
            return root.notification.expireTimeout
        }
        if (root.urgency === 2) {
            return root.criticalTimeoutMs > 0 ? root.criticalTimeoutMs : NotificationCardStyle.criticalTimeoutMs
        }
        return root.defaultTimeoutMs > 0 ? root.defaultTimeoutMs : NotificationCardStyle.defaultTimeoutMs
    }

    onDefaultTimeoutMsChanged: {
        if (root.phase === "active" && dismissTimer.running) {
            dismissTimer.interval = root.effectiveTimeout()
            dismissTimer.restart()
        }
    }
    onCriticalTimeoutMsChanged: {
        if (root.phase === "active" && dismissTimer.running) {
            dismissTimer.interval = root.effectiveTimeout()
            dismissTimer.restart()
        }
    }

    // Urgency Border Colors
    // 0 = Low (muted subtle gray), 1 = Normal (brand accent orange), 2 = Critical (urgent danger red)
    readonly property int urgency: notification ? (notification.urgency !== undefined ? notification.urgency : 1) : 1
    readonly property color urgencyColor: {
        if (urgency === 2) return NotificationCardStyle.urgencyCritical // Critical
        if (urgency === 1) return NotificationCardStyle.urgencyNormal // Normal
        return NotificationCardStyle.urgencyLow       // Low
    }

    signal activated()
    signal deleteRequested()
    signal dismissStarted()
    signal dismissRequested()

    width: cardW
    height: cardH + bottomGap

    // External close handling (e.g. dismissed from DBus or another screen)
    Connections {
        target: root.notification
        function onClosed(reason) {
            root.startDismiss()
        }
    }

    function startSpawn(restingY) {
        restingGlobalY = restingY
        phase = "rising"
        root.height = root.cardH + root.bottomGap

        // Calculate offset from bottom of screen up to this card's resting slot
        var startOffset = Math.max(0, screenH - restingGlobalY)

        bubbleContainer.y = startOffset
        bubbleContainer.width = bubbleW
        bubbleContainer.height = bubbleH
        bubbleContainer.x = (cardW - bubbleW) / 2
        bubbleContainer.opacity = 1.0
        bubbleScale.yScale = 1.0
        bubbleScale.xScale = 1.0
        contentArea.opacity = 0.0

        riseAnim.start()
    }

    function startDismiss() {
        if (phase === "dismissing" || phase === "closed") return
        phase = "dismissing"
        riseAnim.stop()
        expandAnim.stop()
        dismissTimer.stop()
        if (notification) {
            try {
                notification.dismiss()
            } catch (e) {}
        }
        root.dismissStarted()
        dismissAnim.start()
    }

    // ── Phase 1: Rising Water Bubble Animation ──
    SequentialAnimation {
        id: riseAnim
        ParallelAnimation {
            NumberAnimation {
                target: bubbleContainer
                property: "y"
                to: 0
                duration: NotificationCardStyle.riseDurationMs
                easing.type: Easing.OutCubic
            }
            SequentialAnimation {
                // Hydrodynamic elongation as the water bubble ascends rapidly
                ParallelAnimation {
                    NumberAnimation { target: bubbleScale; property: "yScale"; to: NotificationCardStyle.stretchScaleY; duration: NotificationCardStyle.stretchUpMs; easing.type: Easing.OutQuad }
                    NumberAnimation { target: bubbleScale; property: "xScale"; to: NotificationCardStyle.squashScaleX; duration: NotificationCardStyle.stretchUpMs; easing.type: Easing.OutQuad }
                }
                // Deceleration and organic relaxation back to sphere upon arrival
                ParallelAnimation {
                    NumberAnimation { target: bubbleScale; property: "yScale"; to: 1.0; duration: NotificationCardStyle.stretchDownMs; easing.type: Easing.OutBack }
                    NumberAnimation { target: bubbleScale; property: "xScale"; to: 1.0; duration: NotificationCardStyle.stretchDownMs; easing.type: Easing.OutBack }
                }
            }
        }
        ScriptAction {
            script: {
                root.phase = "expanding"
                expandAnim.start()
            }
        }
    }

    // ── Phase 2: Bubble Expansion into Notification Card ──
    ParallelAnimation {
        id: expandAnim
        NumberAnimation {
            target: bubbleContainer
            property: "width"
            to: root.cardW
            duration: NotificationCardStyle.expandDurationMs
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: bubbleContainer
            property: "x"
            to: 0
            duration: NotificationCardStyle.expandDurationMs
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: bubbleContainer
            property: "height"
            to: root.cardH
            duration: NotificationCardStyle.expandDurationMs
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: contentArea
            property: "opacity"
            to: 1.0
            duration: NotificationCardStyle.contentFadeInMs
            easing.type: Easing.OutQuad
        }
        ColorAnimation {
            target: bubbleContainer
            property: "border.color"
            to: root.urgencyColor
            duration: NotificationCardStyle.borderColorAnimMs
        }
        ScriptAction {
            script: {
                root.phase = "active"
                dismissTimer.interval = root.effectiveTimeout()
                dismissTimer.start()
            }
        }
    }

    // ── Phase 3: Dismissal Animation (fades and collapses height) ──
    SequentialAnimation {
        id: dismissAnim
        ParallelAnimation {
            NumberAnimation {
                target: contentArea
                property: "opacity"
                to: 0.0
                duration: NotificationCardStyle.dismissContentFadeMs
            }
            NumberAnimation {
                target: bubbleContainer
                property: "opacity"
                to: 0.0
                duration: NotificationCardStyle.dismissBubbleFadeMs
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: root
                property: "height"
                to: 0
                duration: NotificationCardStyle.dismissCollapseMs
                easing.type: Easing.OutCubic
            }
        }
        ScriptAction {
            script: {
                root.phase = "closed"
                root.dismissRequested()
            }
        }
    }

    Timer {
        id: dismissTimer
        repeat: false
        onTriggered: root.startDismiss()
    }

    // Visual Card Container
    Rectangle {
        id: bubbleContainer
        width: bubbleW
        height: bubbleH
        x: (root.cardW - bubbleW) / 2
        radius: NotificationCardStyle.cardRadius
        color: NotificationCardStyle.background
        border.width: NotificationCardStyle.cardBorderWidth
        border.color: (root.phase === "rising") ? NotificationCardStyle.risingBorder : root.urgencyColor

        transform: Scale {
            id: bubbleScale
            origin.x: bubbleContainer.width / 2
            origin.y: bubbleContainer.height / 2
            xScale: 1.0
            yScale: 1.0
        }

        // Liquid Glass multi-stop refractive sheen + caustic bottom reflection
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            gradient: Gradient {
                GradientStop { position: 0.0; color: NotificationCardStyle.glassSheenTop }
                GradientStop { position: 0.25; color: NotificationCardStyle.glassSheenMid }
                GradientStop { position: 0.72; color: NotificationCardStyle.glassSheenCore }
                GradientStop { position: 1.0; color: NotificationCardStyle.glassSheenBottom }
            }
        }

        // 3D inner refractive bevel ring
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: NotificationCardStyle.transparent
            border.width: 1.5
            border.color: NotificationCardStyle.glassInnerBevel
        }

        // Top specular crest highlight
        Rectangle {
            width: Math.max(0, parent.width - parent.radius * 1.6)
            height: 1.0
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 1.5
            color: NotificationCardStyle.glassRimHighlight
        }

        // Water droplet shine (visible during rising water bubble phase)
        Rectangle {
            width: Math.min(parent.width * NotificationCardStyle.shineWidthRatio, NotificationCardStyle.shineMaxWidth)
            height: NotificationCardStyle.shineHeight
            radius: NotificationCardStyle.shineRadius
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: NotificationCardStyle.shineTopMargin
            color: NotificationCardStyle.bubbleShine
            opacity: root.phase === "rising" ? NotificationCardStyle.shineRisingOpacity : 0.0
            Behavior on opacity { NumberAnimation { duration: NotificationCardStyle.shineFadeDurationMs } }
        }

        // Notification Content
        Item {
            id: contentArea
            anchors.fill: parent
            anchors.leftMargin: NotificationCardStyle.contentHorizontalMargin
            anchors.rightMargin: NotificationCardStyle.contentHorizontalMargin
            anchors.topMargin: NotificationCardStyle.contentVerticalMargin
            anchors.bottomMargin: NotificationCardStyle.contentVerticalMargin
            opacity: 0.0

            // ── Left Icon ──
            Item {
                id: iconBox
                width: NotificationCardStyle.iconSize
                height: NotificationCardStyle.iconSize
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

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

                // Direct image preview
                Image {
                    id: customImg
                    anchors.fill: parent
                    source: root.notification ? iconBox.resolveImageSource(root.notification.image) : ""
                    fillMode: Image.PreserveAspectFit
                    visible: source !== "" && status === Image.Ready
                    smooth: true
                }

                // Freedesktop App Icon
                IconImage {
                    id: appIconImg
                    anchors.fill: parent
                    source: (customImg.visible || !root.notification) ? "" : iconBox.resolveImageSource(root.notification.appIcon)
                    visible: source !== "" && status === Image.Ready && !customImg.visible
                }

                // Fallback question mark icon when notification has no valid icon
                Rectangle {
                    anchors.fill: parent
                    radius: NotificationCardStyle.iconRadius
                    color: NotificationCardStyle.iconBadgeBg
                    border.width: NotificationCardStyle.iconBorderWidth
                    border.color: NotificationCardStyle.iconBadgeBorder
                    visible: !customImg.visible && !appIconImg.visible

                    Text {
                        anchors.centerIn: parent
                        text: "?"
                        font.weight: Font.Bold
                        font.pixelSize: NotificationCardStyle.fallbackBellFontPx
                        color: root.urgencyColor
                    }
                }
            }

            // ── Middle Message (Title & Body) ──
            Column {
                anchors.left: iconBox.right
                anchors.leftMargin: NotificationCardStyle.contentLeftMargin
                anchors.right: closeBtn.left
                anchors.rightMargin: NotificationCardStyle.contentRightMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: NotificationCardStyle.contentTextSpacing

                Text {
                    width: parent.width
                    text: root.notification ? (root.notification.summary || "") : ""
                    color: NotificationCardStyle.summaryText
                    font.pixelSize: NotificationCardStyle.summaryFontPx
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    textFormat: Text.AutoText
                }

                Text {
                    width: parent.width
                    text: root.notification ? (root.notification.body || "") : ""
                    color: NotificationCardStyle.bodyText
                    font.pixelSize: NotificationCardStyle.bodyFontPx
                    elide: Text.ElideRight
                    visible: text.length > 0
                    textFormat: Text.AutoText
                }
            }

            // ── Right Close Button ──
            Item {
                id: closeBtn
                width: NotificationCardStyle.closeBtnSize + 10
                height: parent.height
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.centerIn: parent
                    width: NotificationCardStyle.closeBtnSize
                    height: NotificationCardStyle.closeBtnSize
                    radius: width / 2
                    color: closeMouse.containsMouse ? NotificationCardStyle.closeBtnHoverBg : NotificationCardStyle.closeBtnIdleBg
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: NotificationCardStyle.closeIconFontPx
                        color: closeMouse.containsMouse ? NotificationCardStyle.closeTextHover : NotificationCardStyle.closeTextIdle
                    }
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onEntered: {
                        if (dismissTimer.running) dismissTimer.stop()
                    }
                    onExited: {
                        if (root.phase === "active") dismissTimer.restart()
                    }
                    onClicked: {
                        root.deleteRequested()
                        root.startDismiss()
                    }
                }
            }
        }

        // ── Card MouseArea: hover pauses dismiss, right-click vanishes, left-click activates & dismisses ──
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            z: -1
            onEntered: {
                if (dismissTimer.running) dismissTimer.stop()
            }
            onExited: {
                if (root.phase === "active") dismissTimer.restart()
            }
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    root.deleteRequested()
                    root.startDismiss()
                } else if (mouse.button === Qt.LeftButton) {
                    root.activated()
                    root.startDismiss()
                }
            }
        }
    }
}
