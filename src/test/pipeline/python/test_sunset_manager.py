"""
Unit and CLI tests for scripts/sunset/sunset-manager.py.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[4]
SUNSET_SCRIPT = REPO_ROOT / "src" / "app" / "scripts" / "sunset" / "sunset-manager.py"


def test_sunset_status_cli(tmp_path):
    cfg_file = tmp_path / "sunset.config.json"
    cfg_file.write_text(
        json.dumps(
            {
                "enabled": False,
                "latitude": 37.7749,
                "longitude": -122.4194,
                "dayTemperature": 6500,
                "nightTemperature": 3500,
            }
        ),
        encoding="utf-8",
    )

    env = os.environ.copy()
    env["QS_SUNSET_CONFIG"] = str(cfg_file)

    res = subprocess.run(
        [sys.executable, str(SUNSET_SCRIPT), "status"],
        capture_output=True,
        text=True,
        env=env,
        check=True,
    )
    assert res.returncode == 0
    data = json.loads(res.stdout)
    assert data["latitude"] == pytest.approx(37.7749)
    assert data["longitude"] == pytest.approx(-122.4194)
    assert data["dayTemperature"] == 6500
    assert data["nightTemperature"] == 3500


def test_sunset_apply_cli(tmp_path):
    cfg_file = tmp_path / "sunset.config.json"
    env = os.environ.copy()
    env["QS_SUNSET_CONFIG"] = str(cfg_file)

    res = subprocess.run(
        [
            sys.executable,
            str(SUNSET_SCRIPT),
            "apply",
            "--lat",
            "-22.9068",
            "--long",
            "-43.1729",
            "--day",
            "6000",
            "--night",
            "3800",
            "--enabled",
            "false",
        ],
        capture_output=True,
        text=True,
        env=env,
        check=True,
    )
    assert res.returncode == 0
    data = json.loads(res.stdout)
    assert data["latitude"] == pytest.approx(-22.9068)
    assert data["longitude"] == pytest.approx(-43.1729)
    assert data["dayTemperature"] == 6000
    assert data["nightTemperature"] == 3800
    assert data["enabled"] is False

    # Check persisted file
    saved = json.loads(cfg_file.read_text(encoding="utf-8"))
    assert saved["latitude"] == pytest.approx(-22.9068)
    assert saved["nightTemperature"] == 3800


def test_sunset_restore_cli_preserves_enabled_state(tmp_path):
    cfg_file = tmp_path / "sunset.config.json"
    cfg_file.write_text(
        json.dumps(
            {
                "enabled": False,
                "latitude": 0.0,
                "longitude": 0.0,
                "dayTemperature": 6500,
                "nightTemperature": 3500,
            }
        ),
        encoding="utf-8",
    )

    env = os.environ.copy()
    env["QS_SUNSET_CONFIG"] = str(cfg_file)

    res = subprocess.run(
        [sys.executable, str(SUNSET_SCRIPT), "restore"],
        capture_output=True,
        text=True,
        env=env,
        check=True,
    )
    assert res.returncode == 0
    data = json.loads(res.stdout)
    assert data["enabled"] is False
