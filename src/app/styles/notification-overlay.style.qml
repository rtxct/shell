// ============================================================================
// File: styles/notification-overlay.style.qml
// Purpose: Stack viewport geometry, card spacing, and scroll animation metrics for NotificationOverlay.
// Dependencies: QtQuick
// ============================================================================
pragma Singleton
import QtQuick

QtObject {
    readonly property real cardWidth: 350
    readonly property real cardHeight: 54
    readonly property real cardGap: 10
    readonly property int maxVisibleCount: 4
    readonly property real viewportBottomAnchorRatio: 0.75
    readonly property int scrollAnimDurationMs: 250
    readonly property real clipBoxExtraWidth: 8
    readonly property real wheelScrollStepPx: 64
}
