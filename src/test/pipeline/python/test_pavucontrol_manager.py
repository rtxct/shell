"""
Unit and mocked-PATH CLI tests for scripts/audio/pavucontrol-manager.py.
"""

from __future__ import annotations

import importlib.util
from pathlib import Path
from unittest.mock import patch

REPO_ROOT = Path(__file__).resolve().parents[4]
PAVU_SCRIPT = REPO_ROOT / "src" / "app" / "scripts" / "audio" / "pavucontrol-manager.py"

spec = importlib.util.spec_from_file_location("pavucontrol_manager", PAVU_SCRIPT)
pavu_mod = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(pavu_mod)


def test_extract_volume_and_clamp():
    ratio, pct, db = pavu_mod.extract_volume(
        {
            "front-left": {"value_percent": "80%", "db": "-5.81 dB"},
            "front-right": {"value_percent": "80%", "db": "-5.81 dB"},
        }
    )
    assert ratio == 0.80
    assert pct == 80
    assert db == "-5.81 dB"
    assert pavu_mod.clamp_pct("165%") == 150
    assert pavu_mod.clamp_pct("-10") == 0


def test_get_status_with_mocked_pactl():
    def fake_pactl_json(args):
        if args == ["info"]:
            return {
                "default_sink_name": "sink_bt",
                "default_source_name": "src_mic",
            }
        if args == ["list", "sinks"]:
            return [
                {
                    "index": 10,
                    "name": "sink_bt",
                    "description": "BT Headphones",
                    "driver": "PipeWire",
                    "state": "RUNNING",
                    "mute": False,
                    "volume": {"front-left": {"value_percent": "75%", "db": "-7.5 dB"}},
                    "active_port": "headset-output",
                    "ports": [
                        {
                            "name": "headset-output",
                            "description": "Headphones",
                            "availability": "available",
                        }
                    ],
                    "properties": {"device.api": "bluez5"},
                }
            ]
        if args == ["list", "sources"]:
            return [
                {
                    "index": 20,
                    "name": "src_mic",
                    "description": "Internal Mic",
                    "driver": "PipeWire",
                    "state": "IDLE",
                    "mute": False,
                    "volume": {"front-left": {"value_percent": "90%", "db": "-2.0 dB"}},
                    "active_port": "mic-in",
                    "ports": [],
                    "properties": {"device.api": "alsa"},
                }
            ]
        if args == ["list", "sink-inputs"]:
            return [
                {
                    "index": 100,
                    "sink": 10,
                    "driver": "PipeWire",
                    "corked": False,
                    "mute": False,
                    "volume": {"front-left": {"value_percent": "100%", "db": "0.00 dB"}},
                    "properties": {
                        "application.name": "Spotify",
                        "media.name": "Song",
                    },
                }
            ]
        if args == ["list", "source-outputs"]:
            return [
                {
                    "index": 200,
                    "source": 20,
                    "driver": "PipeWire",
                    "corked": False,
                    "mute": False,
                    "volume": {"front-left": {"value_percent": "100%", "db": "0.00 dB"}},
                    "properties": {
                        "application.name": "Quickshell Peak Detect",
                        "media.name": "Peak detect",
                    },
                }
            ]
        if args == ["list", "cards"]:
            return [
                {
                    "index": 44,
                    "name": "alsa_card.0",
                    "driver": "alsa",
                    "active_profile": "duplex",
                    "properties": {"device.description": "Built-in Audio"},
                    "profiles": {
                        "duplex": {
                            "description": "Analog Stereo Duplex",
                            "sinks": 1,
                            "sources": 1,
                            "priority": 100,
                            "available": True,
                        },
                        "off": {
                            "description": "Off",
                            "sinks": 0,
                            "sources": 0,
                            "priority": 0,
                            "available": True,
                        },
                    },
                }
            ]
        return []

    with patch.object(pavu_mod, "run_pactl_json", side_effect=fake_pactl_json):
        st = pavu_mod.get_status()
        assert st["default_sink"] == "sink_bt"
        assert len(st["sinks"]) == 1
        assert st["sinks"][0]["is_default"] is True
        assert st["sinks"][0]["volume_pct"] == 75
        assert len(st["sink_inputs"]) == 1
        assert st["sink_inputs"][0]["sink_description"] == "BT Headphones"
        assert len(st["source_outputs"]) == 1
        assert st["source_outputs"][0]["is_virtual"] is True
        assert len(st["cards"]) == 1
        assert st["cards"][0]["active_profile_description"] == "Analog Stereo Duplex"


def test_cli_mutations_call_pactl():
    calls = []

    def fake_cmd(args):
        calls.append(args)
        return True

    with patch.object(pavu_mod, "run_pactl_cmd", side_effect=fake_cmd):
        assert pavu_mod.main(["set-default-sink", "sink_bt"]) == 0
        assert pavu_mod.main(["set-sink-volume", "sink_bt", "85"]) == 0
        assert pavu_mod.main(["set-card-profile", "alsa_card.0", "duplex"]) == 0
        assert pavu_mod.main(["move-sink-input", "100", "sink_bt"]) == 0

    assert ["set-default-sink", "sink_bt"] in calls
    assert ["set-sink-volume", "sink_bt", "85%"] in calls
    assert ["set-card-profile", "alsa_card.0", "duplex"] in calls
    assert ["move-sink-input", "100", "sink_bt"] in calls
