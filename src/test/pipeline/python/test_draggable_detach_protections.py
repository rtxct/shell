"""Regression test: Draggable windows detach and cancellation protections.

Verifies:
1. `floating-window-manager.module.qml`:
   - `endDrag()` resets `isDraggingAny` unconditionally at function entry.
   - `closeWindow`, `dockWindow`, and `closeAll` terminate drag if the slot was actively being dragged.
   - `enableDragOverlayMask` is enabled.
2. `media-control-bar.module.qml`:
   - Exposes `isActivelyDetaching`.
   - Exposes `beginMediaDetach`, `updateMediaDetach`, `endMediaDetach`, `cancelMediaDetach`.
   - `dropDragArea`, `volCircleMouse`, `micCircleMouse`, `prevMouse`, `playMouse`, `nextMouse`, and `trackMouse` handle `onCanceled`.
   - `dropMedia.y` does not animate off-screen while detaching.
3. `stick-notes-bar.module.qml`:
   - `drawerBgDragMouse`, `closedTabMouse`, `headerBgDragMouse`, `headerTitleMouse`, and `addMouse` handle `onCanceled`.
4. `app-launcher.module.qml`:
   - `btnMouse` handles `onCanceled`.
5. `notification-center-bar.module.qml`:
   - `tabMouse` and `headerDragArea` handle `onCanceled`.
"""

from __future__ import annotations

from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]
FLOAT_MGR_QML = REPO_ROOT / "src" / "app" / "modules" / "floating-window-manager.module.qml"
MEDIA_BAR_QML = REPO_ROOT / "src" / "app" / "modules" / "media-control-bar.module.qml"
STICK_NOTES_QML = REPO_ROOT / "src" / "app" / "modules" / "stick-notes-bar.module.qml"
APP_LAUNCHER_QML = REPO_ROOT / "src" / "app" / "modules" / "app-launcher.module.qml"
NOTIF_BAR_QML = REPO_ROOT / "src" / "app" / "modules" / "notification-center-bar.module.qml"


def test_floating_window_manager_drag_protections():
    content = FLOAT_MGR_QML.read_text(encoding="utf-8")
    assert "function endDrag() {\n        isDraggingAny = false" in content
    assert "if (currentDragSlot && currentDragSlot.winId === winId) {" in content
    assert "property bool enableDragOverlayMask: true" in content


def test_media_control_bar_detach_and_cancellation():
    content = MEDIA_BAR_QML.read_text(encoding="utf-8")
    assert "readonly property bool isActivelyDetaching:" in content
    assert "function beginMediaDetach(" in content
    assert "function updateMediaDetach(" in content
    assert "function endMediaDetach()" in content
    assert "function cancelMediaDetach()" in content
    assert "!root.isMediaDetaching) ? (root.btnDepth + 2) : 0" in content

    # All mouse areas must handle onCanceled
    for mouse_area in (
        "volCircleMouse",
        "micCircleMouse",
        "dropDragArea",
        "prevMouse",
        "playMouse",
        "nextMouse",
        "trackMouse",
    ):
        idx = content.find(f"id: {mouse_area}")
        assert idx != -1, f"Missing {mouse_area}"
        next_chunk = content[idx : idx + 3500]
        assert "onCanceled" in next_chunk, f"{mouse_area} must define onCanceled handler"


def test_stick_notes_bar_drag_cancellation():
    content = STICK_NOTES_QML.read_text(encoding="utf-8")
    for mouse_area in ("drawerBgDragMouse", "closedTabMouse", "headerBgDragMouse", "headerTitleMouse", "addMouse"):
        idx = content.find(f"id: {mouse_area}")
        assert idx != -1, f"Missing {mouse_area}"
        next_chunk = content[idx : idx + 3500]
        assert "onCanceled" in next_chunk, f"{mouse_area} must define onCanceled handler"


def test_app_launcher_drag_cancellation():
    content = APP_LAUNCHER_QML.read_text(encoding="utf-8")
    idx = content.find("id: btnMouse")
    assert idx != -1
    next_chunk = content[idx : idx + 3500]
    assert "onCanceled" in next_chunk


def test_notification_center_bar_drag_cancellation():
    content = NOTIF_BAR_QML.read_text(encoding="utf-8")
    for mouse_area in ("tabMouse", "headerDragArea"):
        idx = content.find(f"id: {mouse_area}")
        assert idx != -1, f"Missing {mouse_area}"
        next_chunk = content[idx : idx + 3500]
        assert "onCanceled" in next_chunk
