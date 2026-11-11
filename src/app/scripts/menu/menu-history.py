#!/usr/bin/env python3
"""File: scripts/menu/menu-history.py
Purpose: Tracks and manages application and command launch usage history and persisted sorting in ~/.cache/quickshell-menu.
Public API:
  - init: Ensures cache directory and history files (app.hist, cmd.hist, sort.state) exist.
  - list: Outputs JSON dictionary with {"app": {...}, "cmd": {...}, "storage": {"app": str, "cmd": str}, "sort": str}.
  - get <app|cmd>: Outputs JSON dictionary with counts and single file storage.
  - record <app|cmd> <name>: Increments usage count for <name> in the specified history file.
  - prune <app|cmd>: Deletes only the specified history file and resets its tracking.
  - set-sort <alphabetically|most used>: Persists the active sorting option in sort.state.
Dependencies: argparse, json, pathlib, subprocess, sys
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

CACHE_DIR = Path.home() / ".cache" / "quickshell-menu"
APP_HIST = CACHE_DIR / "app.hist"
CMD_HIST = CACHE_DIR / "cmd.hist"
SORT_FILE = CACHE_DIR / "sort.state"


def get_hist_file(hist_type: str) -> Path:
    if hist_type == "app":
        return APP_HIST
    if hist_type == "cmd":
        return CMD_HIST
    raise ValueError(f"Unknown history type: {hist_type} (expected 'app' or 'cmd')")


def load_sort_option() -> str:
    if not SORT_FILE.exists():
        return "alphabetically"
    try:
        opt = SORT_FILE.read_text(encoding="utf-8").strip()
        return opt if opt in ("alphabetically", "most used") else "alphabetically"
    except OSError:
        return "alphabetically"


def save_sort_option(opt: str) -> None:
    ensure_cache_files()
    val = opt if opt in ("alphabetically", "most used") else "alphabetically"
    try:
        SORT_FILE.write_text(val + "\n", encoding="utf-8")
    except OSError as err:
        sys.stderr.write(f"Error writing {SORT_FILE}: {err}\n")


def ensure_cache_files() -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    if not APP_HIST.exists():
        APP_HIST.touch()
    if not CMD_HIST.exists():
        CMD_HIST.touch()
    if not SORT_FILE.exists():
        try:
            SORT_FILE.write_text("alphabetically\n", encoding="utf-8")
        except OSError:
            pass


def get_file_size(path: Path) -> str:
    if not path.exists():
        return "0B"
    try:
        proc = subprocess.run(["du", "-h", str(path)], capture_output=True, text=True, timeout=2)
        if proc.returncode == 0 and proc.stdout:
            parts = proc.stdout.split()
            if parts:
                val = parts[0]
                return "0B" if val == "0" else val
    except Exception:
        pass

    try:
        size = path.stat().st_size
    except OSError:
        return "0B"

    if size == 0:
        return "0B"
    if size < 1024:
        return f"{size}B"
    if size < 1024 * 1024:
        return f"{size / 1024:.1f}K"
    return f"{size / (1024 * 1024):.1f}M"


def load_history(hist_type: str) -> dict[str, int]:
    path = get_hist_file(hist_type)
    if not path.exists():
        return {}
    counts: dict[str, int] = {}
    try:
        content = path.read_text(encoding="utf-8")
    except OSError:
        return {}

    for line in content.splitlines():
        trimmed = line.strip()
        if not trimmed:
            continue
        last_colon = trimmed.rfind(":")
        if last_colon > 0:
            key = trimmed[:last_colon].strip()
            count_str = trimmed[last_colon + 1 :].strip()
            try:
                cnt = int(count_str)
                if key:
                    counts[key] = cnt
            except ValueError:
                continue
    return counts


def save_history(hist_type: str, counts: dict[str, int]) -> None:
    ensure_cache_files()
    path = get_hist_file(hist_type)
    # Sort entries by count descending, then key alphabetically
    sorted_items = sorted(counts.items(), key=lambda item: (-item[1], item[0].lower()))
    lines = [f"{k}:{v}" for k, v in sorted_items]
    try:
        path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
    except OSError as err:
        sys.stderr.write(f"Error writing {path}: {err}\n")


def record_usage(hist_type: str, name: str) -> None:
    target = name.strip()
    if not target:
        return
    ensure_cache_files()
    counts = load_history(hist_type)

    # Check case-insensitively if target exists under a different casing
    matched_key = target
    for k in counts:
        if k.lower() == target.lower():
            matched_key = k
            break

    counts[matched_key] = counts.get(matched_key, 0) + 1
    save_history(hist_type, counts)


def prune_history(hist_type: str) -> None:
    path = get_hist_file(hist_type)
    if path.exists():
        try:
            path.unlink()
        except OSError as err:
            sys.stderr.write(f"Error removing {path}: {err}\n")


def main() -> None:
    parser = argparse.ArgumentParser(description="Application and command usage history manager")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Subcommand: init
    subparsers.add_parser("init", help="Ensure cache directory and history files exist")

    # Subcommand: list
    subparsers.add_parser("list", help="Return all history counts and storage sizes as JSON")

    # Subcommand: get <type>
    get_p = subparsers.add_parser("get", help="Return history counts and storage for a type as JSON")
    get_p.add_argument("type", choices=["app", "cmd"], help="History type ('app' or 'cmd')")

    # Subcommand: record <type> <name>
    rec_p = subparsers.add_parser("record", help="Increment usage count for an item")
    rec_p.add_argument("type", choices=["app", "cmd"], help="History type ('app' or 'cmd')")
    rec_p.add_argument("name", help="Name of application or command executed")

    # Subcommand: prune <type>
    prune_p = subparsers.add_parser("prune", help="Delete specific history file ('app' or 'cmd')")
    prune_p.add_argument("type", choices=["app", "cmd"], help="History type ('app' or 'cmd')")

    # Subcommand: set-sort <option>
    sort_p = subparsers.add_parser("set-sort", help="Save sorting option ('alphabetically' or 'most used')")
    sort_p.add_argument("option", choices=["alphabetically", "most used"], help="Sort option")

    args = parser.parse_args()

    if args.command == "init":
        ensure_cache_files()
    elif args.command == "list":
        data = {
            "app": load_history("app"),
            "cmd": load_history("cmd"),
            "storage": {
                "app": get_file_size(APP_HIST),
                "cmd": get_file_size(CMD_HIST),
            },
            "sort": load_sort_option(),
        }
        sys.stdout.write(json.dumps(data) + "\n")
    elif args.command == "get":
        counts = load_history(args.type)
        data = {
            "counts": counts,
            "storage": get_file_size(get_hist_file(args.type)),
        }
        sys.stdout.write(json.dumps(data) + "\n")
    elif args.command == "record":
        record_usage(args.type, args.name)
    elif args.command == "set-sort":
        save_sort_option(args.option)
    elif args.command == "prune":
        prune_history(args.type)
        data = {
            "app": load_history("app"),
            "cmd": load_history("cmd"),
            "storage": {
                "app": get_file_size(APP_HIST),
                "cmd": get_file_size(CMD_HIST),
            },
            "sort": load_sort_option(),
        }
        sys.stdout.write(json.dumps(data) + "\n")


if __name__ == "__main__":
    main()
