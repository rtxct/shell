"""Regression test: notification popup right-click dismissal, close button click hitbox, and overlay input mask reactivity."""

from __future__ import annotations

import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]
CARD_COMPONENT = REPO_ROOT / "src" / "app" / "components" / "notification-card.component.qml"
CARD_STYLE = REPO_ROOT / "src" / "app" / "styles" / "notification-card.style.qml"
OVERLAY_MODULE = REPO_ROOT / "src" / "app" / "modules" / "notification-overlay.module.qml"
NOTIFICATIONS_SERVICE = REPO_ROOT / "src" / "app" / "modules" / "notifications-service.module.qml"


def test_notification_card_style_has_close_button_tokens():
    style_content = CARD_STYLE.read_text(encoding="utf-8")
    assert "property color closeBtnHoverBg" in style_content
    assert "property color closeBtnIdleBg" in style_content


def test_notification_card_right_click_dismiss_and_close_button():
    card_content = CARD_COMPONENT.read_text(encoding="utf-8")

    # Verify close button has generous hit area and accepts left + right buttons
    assert "NotificationCardStyle.closeBtnSize + 10" in card_content
    assert "height: parent.height" in card_content
    assert "acceptedButtons: Qt.LeftButton | Qt.RightButton" in card_content

    # Verify close button references NotificationCardStyle background tokens (no direct Theme refs)
    assert "NotificationCardStyle.closeBtnHoverBg" in card_content
    assert "NotificationCardStyle.closeBtnIdleBg" in card_content
    assert "Theme." not in card_content, "Components must not contain direct Theme references"

    # Verify card MouseArea accepts RightButton and dismisses on right-click
    assert "mouse.button === Qt.RightButton" in card_content
    assert "root.startDismiss()" in card_content


def test_notification_overlay_reactive_card_count_and_mask():
    overlay_content = OVERLAY_MODULE.read_text(encoding="utf-8")

    # Verify cardCount property exists and drives scrollMaskArea and flickable
    assert re.search(r"property int cardCount:\s*0", overlay_content)
    assert "width: (root.cardCount > 0) ? flickable.width : 0" in overlay_content
    assert "height: (root.cardCount > 0) ? Math.min(root.maxViewportH, flickable.contentHeight) : 0" in overlay_content

    # Verify root.cardCount is updated on enqueue and removeCard
    assert "root.cardCount = itemsList.length" in overlay_content

    # Verify flickable is non-interactive so child clicks are never intercepted
    assert "interactive: false" in overlay_content


def test_notification_overlay_has_no_phantom_scroll_thumb():
    overlay_content = OVERLAY_MODULE.read_text(encoding="utf-8")
    assert "id: scrollThumb" not in overlay_content
    assert "scrollThumb" not in overlay_content
    assert "overflowPillColor" not in overlay_content


def test_notification_card_text_sanitization_and_line_bounds():
    card_content = CARD_COMPONENT.read_text(encoding="utf-8")

    # Verify ServiceParsers import and usage for sanitizing summary and body
    assert 'import "./service-parsers.js" as ServiceParsers' in card_content
    assert "ServiceParsers.cleanNotificationText(root.notification ? (root.notification.summary ||" in card_content
    assert "ServiceParsers.cleanNotificationText(root.notification ? (root.notification.body ||" in card_content

    # Verify maximumLineCount: 1 is set to prevent multiline expansion
    assert card_content.count("maximumLineCount: 1") >= 2

    # Verify clipping is active on contentArea and Column to bound any overflow
    assert "clip: true" in card_content


def test_notification_service_activates_default_action_and_focus_window():
    service_content = NOTIFICATIONS_SERVICE.read_text(encoding="utf-8")

    # Verify activateNotification accesses notifObj.actions directly, not .values
    assert "notifObj.actions.values" not in service_content
    assert "if (notifObj && notifObj.actions)" in service_content

    # Verify action lookup finds 'default' identifier and invokes it
    assert 'act.identifier === "default"' in service_content
    assert "defAct.invoke()" in service_content

    # Verify focus-notification-app script is invoked
    assert "focus-notification-app.sh" in service_content


def test_notification_service_never_stores_dangling_qobject_refs():
    service_content = NOTIFICATIONS_SERVICE.read_text(encoding="utf-8")

    # Verify notificationRef is never stored in history items
    assert "notificationRef:" not in service_content
    assert "it.notificationRef" not in service_content
    assert "itemOrNotif.notificationRef" not in service_content

    # Verify findLiveNotification helper looks up from trackedNotifications safely
    assert "function findLiveNotification(id)" in service_content
    assert "root.server.trackedNotifications.values" in service_content
