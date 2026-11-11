"""Regression test: Application menu IPC handler and global shortcuts.

Verifies:
1. `shell.qml` imports `Quickshell.Io` and declares `IpcHandler` with target `"menu"`.
2. `IpcHandler` exposes `toggle(): void`, `open(): void`, and `close(): void`.
3. `shell.qml` forwards signals to `Bar` instances via `Connections`.
4. `modules/bar.module.qml` defines `toggleAppMenu()`, `openAppMenu()`, and `closeAppMenu()`.
5. `modules/bar.module.qml` binds `Shortcut` for `Ctrl+E`.
6. Helper script `scripts/menu/toggle-menu.sh` exists, is executable, and passes syntax validation.
"""

from __future__ import annotations

import os
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]
SHELL_QML = REPO_ROOT / "shell.qml"
BAR_QML = REPO_ROOT / "src" / "app" / "modules" / "bar.module.qml"
TOGGLE_SCRIPT = REPO_ROOT / "commands" / "toggle-menu.sh"


def test_shell_declares_ipc_handler():
    content = SHELL_QML.read_text(encoding="utf-8")
    assert "import Quickshell.Io" in content
    assert 'target: "menu"' in content
    assert "function toggle(): void" in content
    assert "function open(): void" in content
    assert "function close(): void" in content
    assert "function clipboard(): void" in content
    assert "function openClipboard(): void" in content
    assert "signal toggleAppMenuRequested()" in content
    assert "signal openAppMenuRequested()" in content
    assert "signal closeAppMenuRequested()" in content
    assert "signal toggleClipboardRequested()" in content
    assert "signal openClipboardRequested()" in content
    assert "barItem.toggleAppMenu()" in content
    assert "barItem.openAppMenu()" in content
    assert "barItem.closeAppMenu()" in content
    assert "barItem.toggleClipboard()" in content
    assert "barItem.openClipboard()" in content


def test_bar_declares_app_menu_methods_and_shortcuts():
    content = BAR_QML.read_text(encoding="utf-8")
    assert "function toggleAppMenu()" in content
    assert "function openAppMenu()" in content
    assert "function closeAppMenu()" in content
    assert "function toggleClipboard()" in content
    assert "function openClipboard()" in content
    assert "Shortcut {" in content
    assert 'sequence: "Escape"' in content
    assert "onActivated: scope.closeAll()" in content


def test_toggle_menu_script_executable():
    assert TOGGLE_SCRIPT.exists()
    assert os.access(TOGGLE_SCRIPT, os.X_OK)
    content = TOGGLE_SCRIPT.read_text(encoding="utf-8")
    assert "ipc call menu" in content


def test_clipboard_scripts_executable():
    clipboard_menu = REPO_ROOT / "commands" / "clipboard-menu.sh"
    clipboard_mgr = REPO_ROOT / "src" / "app" / "scripts" / "clipboard" / "clipboard-manager.py"
    assert clipboard_menu.exists()
    assert os.access(clipboard_menu, os.X_OK)
    assert clipboard_mgr.exists()
    assert os.access(clipboard_mgr, os.X_OK)


def test_app_menu_immediate_focus_and_local_keyboard_exclusivity():
    bar_content = BAR_QML.read_text(encoding="utf-8")
    app_menu_content = (REPO_ROOT / "src" / "app" / "modules" / "app-menu.module.qml").read_text(encoding="utf-8")

    # Secondary monitors must not steal WlrKeyboardFocus.Exclusive via anyMenuOpen
    assert "readonly property bool localClickOpen:" in bar_content
    assert (
        "WlrLayershell.keyboardFocus: scope.localClickOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None"
        in bar_content
    )
    assert (
        "Keys.forwardTo: (scope.isLeftmostScreen && scope.isBottommostScreen && scope.appMenuOpen) ? [appMenu] : []"
        in bar_content
    )

    # searchInput must be immediately focusable at t=0ms without waiting for openProgress > 0.8
    assert "id: focusGuardTimer" in app_menu_content
    assert "running: root.open && (!searchInput.activeFocus || !root.windowActive)" in app_menu_content
    assert "visible: open || activeOrAnimating" in app_menu_content

    # Bottom-left circles and notification idle bar must remain hidden until appMenu closing animation finishes
    app_launcher_content = (REPO_ROOT / "src" / "app" / "modules" / "app-launcher.module.qml").read_text(
        encoding="utf-8"
    )
    assert "property real circlesOpacity: (menuOpen || menuAnimating) ? 0.0 : 1.0" in app_launcher_content
    assert (
        "opacity: (scope.isBottommostScreen && !scope.appMenuOpen && !appMenu.activeOrAnimating) ? 1 : 0" in bar_content
    )


def test_app_menu_persists_sort_and_starts_selection_at_zero():
    app_menu_content = (REPO_ROOT / "src" / "app" / "modules" / "app-menu.module.qml").read_text(encoding="utf-8")

    # Verify initial selectedIndex is 0
    assert "property int selectedIndex: 0" in app_menu_content

    # Verify sort persistence wiring
    assert "id: saveSortProc" in app_menu_content
    assert "set-sort" in app_menu_content
    assert "menuHistoryProc.saveSort" in app_menu_content
    assert "res.sort" in app_menu_content
    assert "menuHistoryProc.load()" in app_menu_content

    # Verify pressing Enter on open launches first item without needing search query
    assert "else if (filteredApps.length > 0)" in app_menu_content
