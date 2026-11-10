#!/usr/bin/env python3
# ============================================================================
# File: scripts/sunset/sunset-manager.py
# Purpose: CLI and background process coordinator for wlsunset (Night Light).
#          Manages process lifecycle (start, stop, toggle, status) and
#          persists configuration to config/sunset.config.json.
# Dependencies: python3, wlsunset, pgrep, pkill
# ============================================================================

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]
DEFAULT_CONFIG_PATH = REPO_ROOT / "config" / "sunset.config.json"

DEFAULT_CONFIG = {
    "enabled": False,
    "latitude": 0.0,
    "longitude": 0.0,
    "dayTemperature": 6500,
    "nightTemperature": 4000,
}


def get_config_path() -> Path:
    env_path = os.environ.get("QS_SUNSET_CONFIG")
    if env_path:
        return Path(env_path).resolve()
    return DEFAULT_CONFIG_PATH


def load_config() -> dict:
    path = get_config_path()
    if not path.is_file():
        save_config(DEFAULT_CONFIG)
        return dict(DEFAULT_CONFIG)
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        cfg = dict(DEFAULT_CONFIG)
        cfg.update(data)
        return cfg
    except Exception:
        return dict(DEFAULT_CONFIG)


def save_config(cfg: dict) -> None:
    path = get_config_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    temp_path = path.with_suffix(".tmp")
    payload = {
        "enabled": bool(cfg.get("enabled", False)),
        "latitude": round(float(cfg.get("latitude", 0.0)), 4),
        "longitude": round(float(cfg.get("longitude", 0.0)), 4),
        "dayTemperature": int(cfg.get("dayTemperature", 6500)),
        "nightTemperature": int(cfg.get("nightTemperature", 4000)),
    }
    temp_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    temp_path.replace(path)


def get_wlsunset_pid() -> int | None:
    try:
        res = subprocess.run(
            ["pgrep", "-x", "wlsunset"],
            capture_output=True,
            text=True,
            check=False,
        )
        if res.returncode == 0 and res.stdout.strip():
            pids = res.stdout.strip().split()
            if pids:
                return int(pids[0])
    except Exception:
        pass
    return None


def is_running() -> bool:
    return get_wlsunset_pid() is not None


def stop_wlsunset() -> None:
    try:
        # Stop competing daemons that exclusively hold Wayland gamma control
        subprocess.run(["pkill", "-x", "gammastep"], capture_output=True, check=False)
        subprocess.run(["pkill", "-x", "wlsunset"], capture_output=True, check=False)
        for _ in range(10):
            if get_wlsunset_pid() is None:
                break
            time.sleep(0.05)
    except Exception:
        pass


def start_wlsunset(cfg: dict) -> bool:
    stop_wlsunset()
    time.sleep(0.1)  # allow Wayland compositor to cleanly release gamma control protocol
    binary = shutil.which("wlsunset")
    if not binary:
        return False

    lat = str(cfg.get("latitude", 0.0))
    lon = str(cfg.get("longitude", 0.0))
    day = str(cfg.get("dayTemperature", 6500))
    night = str(cfg.get("nightTemperature", 4000))

    cmd = [binary, "-l", lat, "-L", lon, "-T", day, "-t", night]
    try:
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL,
            start_new_session=True,
        )
        time.sleep(0.08)
        if proc.poll() is not None:
            return False
        return True
    except Exception:
        return False


def get_status() -> dict:
    cfg = load_config()
    pid = get_wlsunset_pid()
    running = pid is not None
    return {
        "running": running,
        "pid": pid,
        "enabled": cfg.get("enabled", False),
        "latitude": cfg.get("latitude", 0.0),
        "longitude": cfg.get("longitude", 0.0),
        "dayTemperature": cfg.get("dayTemperature", 6500),
        "nightTemperature": cfg.get("nightTemperature", 4000),
        "installed": shutil.which("wlsunset") is not None,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="wlsunset coordinator")
    subparsers = parser.add_subparsers(dest="action", required=True)

    subparsers.add_parser("status", help="Get current running and config status")
    subparsers.add_parser("start", help="Start wlsunset using current config")
    subparsers.add_parser("stop", help="Stop wlsunset process")
    subparsers.add_parser("toggle", help="Toggle wlsunset on/off")
    subparsers.add_parser("restore", help="Ensure wlsunset running state matches persisted enabled config")

    apply_p = subparsers.add_parser("apply", help="Update config and apply")
    apply_p.add_argument("--lat", type=float, help="Latitude")
    apply_p.add_argument("--long", type=float, help="Longitude")
    apply_p.add_argument("--day", type=int, help="Daytime temperature (Kelvin)")
    apply_p.add_argument("--night", type=int, help="Nighttime temperature (Kelvin)")
    apply_p.add_argument("--enabled", choices=["true", "false", "auto"], default="auto")

    args = parser.parse_args()
    cfg = load_config()

    if args.action == "status":
        print(json.dumps(get_status()))
        return 0

    if args.action == "start":
        cfg["enabled"] = True
        save_config(cfg)
        start_wlsunset(cfg)
        print(json.dumps(get_status()))
        return 0

    if args.action == "stop":
        cfg["enabled"] = False
        save_config(cfg)
        stop_wlsunset()
        print(json.dumps(get_status()))
        return 0

    if args.action == "toggle":
        if is_running() or cfg.get("enabled", False):
            cfg["enabled"] = False
            save_config(cfg)
            stop_wlsunset()
        else:
            cfg["enabled"] = True
            save_config(cfg)
            start_wlsunset(cfg)
        print(json.dumps(get_status()))
        return 0

    if args.action == "restore":
        if cfg.get("enabled", False):
            if not is_running():
                start_wlsunset(cfg)
        else:
            if is_running():
                stop_wlsunset()
        print(json.dumps(get_status()))
        return 0

    if args.action == "apply":
        if args.lat is not None:
            cfg["latitude"] = args.lat
        if args.long is not None:
            cfg["longitude"] = args.long
        if args.day is not None:
            cfg["dayTemperature"] = args.day
        if args.night is not None:
            cfg["nightTemperature"] = args.night

        if args.enabled == "true":
            cfg["enabled"] = True
        elif args.enabled == "false":
            cfg["enabled"] = False
        # if "auto", keep previous enabled state

        save_config(cfg)

        if cfg["enabled"] or (args.enabled != "false" and is_running()):
            cfg["enabled"] = True
            save_config(cfg)
            start_wlsunset(cfg)
        else:
            stop_wlsunset()

        print(json.dumps(get_status()))
        return 0

    return 1


if __name__ == "__main__":
    sys.exit(main())
