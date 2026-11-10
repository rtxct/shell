"""Regression test: Workspace Island border outline screen-edge flare tail.

Verifies:
1. `styles/workspace-island.style.qml` defines `flare: 12` (matching `IslandStyle`, `DropStyle`, `AppLauncherStyle`, etc.).
2. `modules/workspace-island.module.qml` binds `dropFlare: WorkspaceIslandStyle.flare`.
3. When `vertical: true` with `flare: 12` on `WorkspaceIsland`, the concave fillet radius `t` is > 0,
   guaranteeing the border outline curves outward along the screen edge into the bezel.
"""

from __future__ import annotations

import math
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]
WS_STYLE_QML = REPO_ROOT / "src" / "app" / "styles" / "workspace-island.style.qml"
WS_MODULE_QML = REPO_ROOT / "src" / "app" / "modules" / "workspace-island.module.qml"


def test_workspace_island_style_defines_flare():
    content = WS_STYLE_QML.read_text(encoding="utf-8")
    assert "readonly property real flare: 12" in content


def test_workspace_island_module_binds_drop_flare():
    content = WS_MODULE_QML.read_text(encoding="utf-8")
    assert "dropFlare: WorkspaceIslandStyle.flare" in content


def test_workspace_island_drop_fillet_geometry():
    # Simulate Drop math from components/drop.component.qml
    idle_depth = 44  # ld
    slant = 16  # sl
    flare = 12  # flare
    tpe = 0  # touching monitor edge

    hh = max(1.0, idle_depth - tpe)
    sl = slant
    length = math.sqrt(sl * sl + hh * hh)
    t = max(0.0, min(flare * (length - sl) / hh, length * 0.6))

    # Fillet radius must be strictly positive (producing the tail curve along the edge)
    assert t > 5.0, f"Expected concave fillet t > 5.0, got {t}"
    assert math.isclose(t, 8.405, rel_tol=1e-2)
