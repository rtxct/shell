// ============================================================================
// File: modules/notification-overlay.module.qml
// Purpose: Bottom-center notification toast stack coordinator managing up to 4 visible cards, auto-scroll, and wheel scrolling.
// Public API:
//   - Properties: notifications, screenW, screenH, cardW, cardH, cardSpacing, maxVisibleCount, maxViewportH, slot1Y, itemsList, maskItem
//   - Functions:  clearAllCards(), enqueue(notif), removeCard(card)
// Dependencies: QtQuick, "../components", "../styles"
// ============================================================================
import QtQuick
import "../components"
import "../styles"

// Notification overlay managing accumulation of notifications one under the other,
// smooth upward water bubble entry, auto-scrolling with a 4-notification visible limit,
// interactive mouse wheel scrolling, and dynamic Wayland input masking.
Item {
    id: root

    property var notifications: null
    property real screenW: parent ? parent.width : 1920
    property real screenH: parent ? parent.height : 1080

    readonly property real cardW: NotificationOverlayStyle.cardWidth
    readonly property real cardH: NotificationOverlayStyle.cardHeight
    readonly property real cardSpacing: NotificationOverlayStyle.cardGap

    // Maximum visible notification count (bound to notifications.maxVisibleCount, default 4)
    readonly property int maxVisibleCount: (root.notifications && root.notifications.maxVisibleCount > 0)
        ? root.notifications.maxVisibleCount
        : NotificationOverlayStyle.maxVisibleCount
    // Viewport height accommodating maxVisibleCount notifications
    readonly property real maxViewportH: maxVisibleCount * cardH + (maxVisibleCount - 1) * cardSpacing

    onMaxVisibleCountChanged: {
        var remTotalH = root.cardCount > 0 ? (root.cardCount * (root.cardH + root.cardSpacing) - root.cardSpacing) : 0
        if (remTotalH <= root.maxViewportH) {
            scrollAnim.stop()
            scrollAnim.to = 0
            scrollAnim.start()
        } else {
            var maxScroll = remTotalH - root.maxViewportH
            if (flickable.contentY > maxScroll) {
                scrollAnim.stop()
                scrollAnim.to = maxScroll
                scrollAnim.start()
            }
        }
    }

    // Initial starting anchor: 1/4 of the screen height up from the bottom
    readonly property real slot1Y: Math.round(screenH * NotificationOverlayStyle.viewportBottomAnchorRatio - cardH)

    property var itemsList: []
    property int cardCount: 0

    // ── Input Mask item for Wayland LayerShell registration ──
    readonly property Item maskItem: scrollMaskArea
    Item {
        id: scrollMaskArea
        x: clipBox.x
        y: clipBox.y
        width: (root.cardCount > 0) ? flickable.width : 0
        height: (root.cardCount > 0) ? Math.min(root.maxViewportH, flickable.contentHeight) : 0
    }

    Connections {
        target: root.notifications
        function onNotificationReceived(notif) {
            if (!root.notifications || !root.notifications.suppressPopups) {
                root.enqueue(notif)
            }
        }
        function onCleared() {
            root.clearAllCards()
        }
        function onPopupsSuppressed() {
            root.clearAllCards()
        }
    }

    function clearAllCards() {
        for (var i = 0; i < itemsList.length; i++) {
            if (itemsList[i]) {
                itemsList[i].startDismiss()
            }
        }
    }

    Component {
        id: cardComp
        NotificationCard {
            screenW: root.screenW
            screenH: root.screenH
            bottomGap: root.cardSpacing
            defaultTimeoutMs: root.notifications ? root.notifications.defaultTimeoutMs : NotificationCardStyle.defaultTimeoutMs
            criticalTimeoutMs: root.notifications ? root.notifications.criticalTimeoutMs : NotificationCardStyle.criticalTimeoutMs
        }
    }

    function activeCardCount() {
        var count = 0
        for (var i = 0; i < itemsList.length; i++) {
            var c = itemsList[i]
            if (c && c.phase !== "dismissing" && c.phase !== "closed") {
                count++
            }
        }
        return count
    }

    function syncScrollToActiveCards(durationMs) {
        var count = root.activeCardCount()
        var remTotalH = count > 0 ? (count * (root.cardH + root.cardSpacing) - root.cardSpacing) : 0
        var maxScroll = Math.max(0, remTotalH - root.maxViewportH)
        if (flickable.contentY > maxScroll) {
            scrollAnim.stop()
            scrollAnim.duration = durationMs
            scrollAnim.to = maxScroll
            scrollAnim.start()
        }
    }

    function enqueue(notif) {
        var card = cardComp.createObject(notifColumn, {
            notification: notif,
            screenW: root.screenW,
            screenH: root.screenH,
            bottomGap: root.cardSpacing
        })
        if (!card) return

        var K = root.activeCardCount()
        var nextTotalH = (K + 1) * (root.cardH + root.cardSpacing) - root.cardSpacing
        var targetContentY = Math.max(0, nextTotalH - root.maxViewportH)
        var cardRestingGlobalY = root.slot1Y + (K * (root.cardH + root.cardSpacing)) - targetContentY

        itemsList.push(card)
        root.itemsList = itemsList.slice(0)
        root.cardCount = itemsList.length

        card.activated.connect(function() {
            if (root.notifications) {
                root.notifications.activateNotification(notif)
            }
        })
        card.deleteRequested.connect(function() {
            if (root.notifications && notif) {
                root.notifications.removeById(notif.id)
            }
        })
        card.dismissStarted.connect(function() {
            root.syncScrollToActiveCards(NotificationCardStyle.dismissCollapseMs)
        })
        card.dismissRequested.connect(function() {
            root.removeCard(card)
        })

        // When exceeding the 4-notification limit (e.g. 5th message arrives),
        // scroll down so the 5th message arrives on the bottom and the 1st hides under the scroll
        if (nextTotalH > root.maxViewportH) {
            scrollAnim.stop()
            scrollAnim.duration = NotificationOverlayStyle.scrollAnimDurationMs
            scrollAnim.to = targetContentY
            scrollAnim.start()
        }

        card.startSpawn(cardRestingGlobalY)
    }

    function removeCard(card) {
        var idx = itemsList.indexOf(card)
        if (idx !== -1) {
            itemsList.splice(idx, 1)
        }
        root.itemsList = itemsList.slice(0)
        root.cardCount = itemsList.length
        card.destroy()
        root.syncScrollToActiveCards(NotificationOverlayStyle.scrollAnimDurationMs)
    }

    NumberAnimation {
        id: scrollAnim
        target: flickable
        property: "contentY"
        duration: NotificationOverlayStyle.scrollAnimDurationMs
        easing.type: Easing.OutCubic
    }

    // Top-clipping container: clips only at root.slot1Y, extending all the way to screen bottom
    Item {
        id: clipBox
        x: (root.screenW - root.cardW) / 2
        y: root.slot1Y
        width: root.cardW + NotificationOverlayStyle.clipBoxExtraWidth
        height: root.screenH - root.slot1Y
        clip: true

        Flickable {
            id: flickable
            x: 0
            y: 0
            width: parent.width
            height: Math.min(root.maxViewportH, contentHeight)
            contentWidth: root.cardW
            contentHeight: Math.max(0, notifColumn.height - (root.cardCount > 0 ? root.cardSpacing : 0))
            clip: false
            boundsBehavior: Flickable.StopAtBounds
            interactive: false

            // Interactive mouse wheel and touchpad scrolling
            WheelHandler {
                id: wheelH
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: (event) => {
                    var delta = event.angleDelta.y
                    if (delta !== 0) {
                        var maxScroll = Math.max(0, flickable.contentHeight - flickable.height)
                        var step = delta > 0 ? -NotificationOverlayStyle.wheelScrollStepPx : NotificationOverlayStyle.wheelScrollStepPx
                        var newY = Math.max(0, Math.min(maxScroll, flickable.contentY + step))
                        scrollAnim.stop()
                        scrollAnim.duration = NotificationOverlayStyle.scrollAnimDurationMs
                        scrollAnim.to = newY
                        scrollAnim.start()
                    }
                }
            }

            Column {
                id: notifColumn
                width: root.cardW
                spacing: 0
            }
        }
    }
}
