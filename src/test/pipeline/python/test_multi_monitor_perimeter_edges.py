"""Regression test: multi-monitor perimeter & outer edge detection.

Verifies:
1. `modules/bar.module.qml` declares `isLeftmostScreen`, `isRightmostScreen`, `isTopmostScreen`, and `isBottommostScreen`.
2. Reservations (top, left, bottom, right) dynamically collapse to 0 on non-edge monitor borders.
3. Left Bar is only active on the leftmost screen.
4. Right Bar (stick notes) is only active on the rightmost screen.
5. Bottom-left (app launcher) is only active on leftmost + bottommost screen.
6. Bottom-right (media/volume controller) is only active on rightmost + bottommost screen.
7. Unit simulation of multi-monitor topologies (single, dual horizontal, triple horizontal, vertical).
"""

from __future__ import annotations

from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]
BAR_QML = REPO_ROOT / "src" / "app" / "modules" / "bar.module.qml"


def test_bar_declares_perimeter_edge_properties():
    content = BAR_QML.read_text(encoding="utf-8")
    assert "readonly property bool isLeftmostScreen:" in content
    assert "readonly property bool isRightmostScreen:" in content
    assert "readonly property bool isTopmostScreen:" in content
    assert "readonly property bool isBottommostScreen:" in content


def test_bar_reserves_pad_barless_edges():
    content = BAR_QML.read_text(encoding="utf-8")
    # Left bar reserve:
    assert "implicitWidth: scope.isLeftmostScreen ? (wsIsland.idleDepth + scope.windowGap) : scope.windowGap" in content
    assert "exclusiveZone: scope.isLeftmostScreen ? (wsIsland.idleDepth + scope.windowGap) : scope.windowGap" in content
    # Right bar reserve:
    assert "implicitWidth: scope.isRightmostScreen ? scope.rightGap : scope.windowGap" in content
    assert "exclusiveZone: scope.isRightmostScreen ? scope.rightGap : scope.windowGap" in content
    # Top bar reserve:
    assert "implicitHeight: scope.isTopmostScreen ? scope.topGap : scope.windowGap" in content
    assert "exclusiveZone: scope.isTopmostScreen ? scope.topGap : scope.windowGap" in content
    # Bottom bar reserve:
    assert "implicitHeight: scope.isBottommostScreen ? scope.bottomGap : scope.windowGap" in content


def test_bar_components_gated_by_perimeter():
    content = BAR_QML.read_text(encoding="utf-8")
    # Left bar circles & island
    assert "visible: scope.isLeftmostScreen" in content
    # Right bar stick notes
    assert "visible: scope.isRightmostScreen && opacity > 0.01" in content
    # Bottom left launcher
    assert "visible: scope.isLeftmostScreen && scope.isBottommostScreen" in content
    # Bottom right media control bar
    assert "visible: scope.isRightmostScreen && scope.isBottommostScreen && opacity > 0.01" in content


def test_perimeter_edge_topology_simulation():
    class Screen:
        def __init__(self, name: str, x: int, y: int, width: int, height: int):
            self.name = name
            self.x = x
            self.y = y
            self.width = width
            self.height = height

    def compute_edges(screen: Screen, all_screens: list[Screen]):
        if not all_screens or len(all_screens) <= 1:
            return True, True, True, True

        min_x = min(s.x for s in all_screens)
        max_right = max(s.x + s.width for s in all_screens)
        min_y = min(s.y for s in all_screens)
        max_bottom = max(s.y + s.height for s in all_screens)

        is_leftmost = screen.x <= min_x
        is_rightmost = (screen.x + screen.width) >= max_right
        is_topmost = screen.y <= min_y
        is_bottommost = (screen.y + screen.height) >= max_bottom

        return is_leftmost, is_rightmost, is_topmost, is_bottommost

    # 1. Single monitor
    s1 = Screen("eDP-1", 0, 0, 1920, 1080)
    assert compute_edges(s1, [s1]) == (True, True, True, True)

    # 2. Dual horizontal monitors (user's setup: eDP-1 and HDMI-A-1)
    s2 = Screen("HDMI-A-1", 1920, 0, 1920, 1080)
    dual = [s1, s2]
    # Screen 1 (left): leftmost=True, rightmost=False, top=True, bottom=True
    assert compute_edges(s1, dual) == (True, False, True, True)
    # Screen 2 (right): leftmost=False, rightmost=True, top=True, bottom=True
    assert compute_edges(s2, dual) == (False, True, True, True)

    # 3. Triple horizontal monitors
    s3 = Screen("DP-1", 3840, 0, 1920, 1080)
    triple = [s1, s2, s3]
    assert compute_edges(s1, triple) == (True, False, True, True)
    # Center screen has no left or right bars
    assert compute_edges(s2, triple) == (False, False, True, True)
    assert compute_edges(s3, triple) == (False, True, True, True)

    # 4. Vertical stacked monitors
    v1 = Screen("top", 0, 0, 1920, 1080)
    v2 = Screen("bottom", 0, 1080, 1920, 1080)
    vert = [v1, v2]
    assert compute_edges(v1, vert) == (True, True, True, False)
    assert compute_edges(v2, vert) == (True, True, False, True)


def test_left_bar_circles_match_bottom_bar_circles_diameter():
    circle_style = (REPO_ROOT / "src" / "app" / "styles" / "circle.style.qml").read_text(encoding="utf-8")
    app_launcher_style = (REPO_ROOT / "src" / "app" / "styles" / "app-launcher.style.qml").read_text(encoding="utf-8")
    media_bar_style = (REPO_ROOT / "src" / "app" / "styles" / "media-control-bar.style.qml").read_text(encoding="utf-8")

    import re

    diam_left = re.search(r"readonly\s+property\s+real\s+diameter:\s*(\d+)", circle_style)
    diam_app = re.search(r"readonly\s+property\s+real\s+circleDiameter:\s*(\d+)", app_launcher_style)
    diam_media = re.search(r"readonly\s+property\s+real\s+circleDiameter:\s*(\d+)", media_bar_style)

    assert diam_left and diam_app and diam_media
    assert diam_left.group(1) == diam_app.group(1) == diam_media.group(1) == "26"
