"""Regression test: notification-center-bar tabDrop detach properties must be declared on tabDrop, not a child Item."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[4]
TARGET_QML = REPO_ROOT / "src" / "app" / "modules" / "notification-center-bar.module.qml"


def find_qmllint() -> str | None:
    for candidate in (
        "/usr/lib/qt6/bin/qmllint",
        "/usr/lib64/qt6/bin/qmllint",
        shutil.which("qmllint6"),
    ):
        if candidate and Path(candidate).is_file():
            return str(candidate)
    return None


def test_notification_center_bar_has_no_missing_drop_detach_properties():
    qmllint = find_qmllint()
    if not qmllint:
        pytest.skip("Qt6 qmllint not installed")

    proc = subprocess.run(
        [
            qmllint,
            "-I",
            str(REPO_ROOT / "themes"),
            "-I",
            str(REPO_ROOT / "src" / "app" / "components"),
            "-I",
            str(REPO_ROOT / "src" / "app" / "styles"),
            "-I",
            str(REPO_ROOT / "src" / "app" / "modules"),
            str(TARGET_QML),
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    output = proc.stdout + proc.stderr
    missing_prop_lines = [line for line in output.splitlines() if "[missing-property]" in line]
    assert missing_prop_lines == [], "tabDrop detach properties missing on Drop:\n" + "\n".join(missing_prop_lines)
