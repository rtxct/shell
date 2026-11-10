"""
Layer 2 (pipeline): Configuration JSON Schema validation, negative rejection tests,
and default value verification.
"""

import json
from pathlib import Path

import jsonschema
import pytest

REPO_ROOT = Path(__file__).resolve().parents[4]
CONFIG_DIR = REPO_ROOT / "config"
SCHEMAS_DIR = Path(__file__).resolve().parent / "schemas"

CONFIG_PAIRS = [
    ("weather.config.json", "weather.schema.json"),
    ("calendar.config.json", "calendar.schema.json"),
    ("workspaces.config.json", "workspaces.schema.json"),
    ("audio.config.json", "audio.schema.json"),
    ("notifications.config.json", "notifications.schema.json"),
    ("layout.config.json", "layout.schema.json"),
    ("sunset.config.json", "sunset.schema.json"),
    ("wallpaper.config.json", "wallpaper.schema.json"),
]


@pytest.mark.parametrize("config_name,schema_name", CONFIG_PAIRS)
def test_config_validates_against_schema(config_name, schema_name):
    """Every config/*.config.json file must exist and validate against its JSON Schema."""
    cfg_path = CONFIG_DIR / config_name
    schema_path = SCHEMAS_DIR / schema_name
    assert cfg_path.is_file(), f"Missing config file: {cfg_path}"
    assert schema_path.is_file(), f"Missing schema file: {schema_path}"

    instance = json.loads(cfg_path.read_text(encoding="utf-8"))
    schema = json.loads(schema_path.read_text(encoding="utf-8"))
    jsonschema.validate(instance=instance, schema=schema)


def test_all_config_files_have_schemas():
    """Verify no untracked config file exists in config/ without a corresponding test pair."""
    actual = sorted(p.name for p in CONFIG_DIR.glob("*.json"))
    expected = sorted(pair[0] for pair in CONFIG_PAIRS)
    assert actual == expected


@pytest.mark.parametrize(
    "schema_name,invalid_payload",
    [
        # Latitude out of [-90, 90] range
        (
            "weather.schema.json",
            {
                "refreshMinutes": 20,
                "defaultIndex": 0,
                "locations": [{"name": "Invalid", "latitude": 120.0, "longitude": 0.0}],
            },
        ),
        # Empty locations array
        (
            "weather.schema.json",
            {"refreshMinutes": 20, "defaultIndex": 0, "locations": []},
        ),
        # Negative refreshMinutes in calendar config
        (
            "calendar.schema.json",
            {
                "icsUrl": "",
                "refreshMinutes": 0,
                "listDays": 30,
                "windowStartDays": -40,
                "windowEndDays": 90,
                "maxUpcoming": 60,
                "curlMaxTimeSeconds": 20,
            },
        ),
        # Unknown compositor backend
        (
            "workspaces.schema.json",
            {"backend": "hyprland", "count": 10, "pollIntervalMs": 1000},
        ),
        # Negative maxVolume in audio config
        (
            "audio.schema.json",
            {
                "pollIntervalMs": 1000,
                "maxVolume": 0.0,
                "wheelStep": 0.03,
                "activePeakThreshold": 0.005,
            },
        ),
        # Zero maxVisibleCount in notifications config
        (
            "notifications.schema.json",
            {"defaultTimeoutMs": 5000, "criticalTimeoutMs": 8000, "maxVisibleCount": 0},
        ),
        # Unknown extra property in layout config
        (
            "layout.schema.json",
            {
                "windowGap": 16,
                "barMaxWidth": 720,
                "screenMargin": 40,
                "leftBarMaxLength": 620,
                "launcherX": 190,
                "bottomGap": 18,
                "rightGap": 18,
                "unexpectedKey": 123,
            },
        ),
        # Latitude out of [-90, 90] in sunset config
        (
            "sunset.schema.json",
            {
                "enabled": True,
                "latitude": 105.0,
                "longitude": 0.0,
                "dayTemperature": 6500,
                "nightTemperature": 4000,
            },
        ),
    ],
)
def test_negative_invalid_configs_are_rejected(schema_name, invalid_payload):
    """Prove that invalid config payloads are rejected by their respective JSON Schema."""
    schema = json.loads((SCHEMAS_DIR / schema_name).read_text(encoding="utf-8"))
    with pytest.raises(jsonschema.ValidationError):
        jsonschema.validate(instance=invalid_payload, schema=schema)


def test_config_defaults_match_pre_refactor_baseline():
    """
    Verify that the default values in config/*.config.json match the expected baseline values.
    """
    weather = json.loads((CONFIG_DIR / "weather.config.json").read_text(encoding="utf-8"))
    assert weather["refreshMinutes"] == 20
    assert weather["defaultIndex"] == 0
    assert weather["locations"] == [
        {"name": "Paris", "latitude": 48.8566, "longitude": 2.3522},
        {"name": "Tokyo", "latitude": 35.6762, "longitude": 139.6503},
        {"name": "Denver", "latitude": 39.7392, "longitude": -104.9903},
    ]

    calendar = json.loads((CONFIG_DIR / "calendar.config.json").read_text(encoding="utf-8"))
    assert isinstance(calendar.get("icsUrl"), str)
    assert calendar["refreshMinutes"] == 10
    assert calendar["listDays"] == 30
    assert calendar["windowStartDays"] == -40
    assert calendar["windowEndDays"] == 90
    assert calendar["maxUpcoming"] == 60
    assert calendar["curlMaxTimeSeconds"] == 20

    wallpaper = json.loads((CONFIG_DIR / "wallpaper.config.json").read_text(encoding="utf-8"))
    assert wallpaper == {"path": ""}

    workspaces = json.loads((CONFIG_DIR / "workspaces.config.json").read_text(encoding="utf-8"))
    assert workspaces == {"backend": "sway", "count": 10, "pollIntervalMs": 1000}

    audio = json.loads((CONFIG_DIR / "audio.config.json").read_text(encoding="utf-8"))
    assert audio == {
        "pollIntervalMs": 1000,
        "maxVolume": 1.5,
        "wheelStep": 0.03,
        "activePeakThreshold": 0.005,
        "spectrumEnabled": True,
        "spectrumBars": 20,
        "spectrumFramerate": 60,
        "spectrumNoiseReduction": 45,
    }

    notifications = json.loads((CONFIG_DIR / "notifications.config.json").read_text(encoding="utf-8"))
    assert notifications == {
        "defaultTimeoutMs": 5000,
        "criticalTimeoutMs": 8000,
        "maxVisibleCount": 4,
    }

    layout = json.loads((CONFIG_DIR / "layout.config.json").read_text(encoding="utf-8"))
    assert layout == {
        "windowGap": 16,
        "barMaxWidth": 720,
        "screenMargin": 40,
        "leftBarMaxLength": 620,
        "launcherX": 190,
        "bottomGap": 18,
        "rightGap": 18,
    }
