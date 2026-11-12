#!/usr/bin/env python3
"""File: scripts/commands/command-manager.py
Purpose: Discovers system executables in PATH, bash aliases, builtins, and functions,
and executes commands via bash with optional terminal emulator wrapper.
Public API:
  - list: Outputs JSON array of discovered commands, aliases, and builtins.
  - run <cmd>: Executes a command with bash or inside a detected terminal emulator.
  - refresh: Rebuilds the commands cache file.
Dependencies: json, os, pathlib, shutil, subprocess, sys, time
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

CACHE_DIR = Path.home() / ".cache" / "quickshell"
CACHE_FILE = CACHE_DIR / "commands_cache.json"
CACHE_TTL = 3600  # 1 hour

INTERACTIVE_CLI_TOOLS = {
    "htop",
    "top",
    "btop",
    "vim",
    "nvim",
    "vi",
    "nano",
    "less",
    "more",
    "man",
    "fzf",
    "ranger",
    "yazi",
    "ncdu",
    "lazygit",
    "gdb",
    "ssh",
    "tail",
    "watch",
    "journalctl",
    "dmesg",
}


def find_terminal() -> str | None:
    for term in [
        os.environ.get("TERMINAL"),
        "foot",
        "kitty",
        "alacritty",
        "wezterm",
        "xterm",
    ]:
        if term and shutil.which(term):
            return term
    return None


def get_path_executables() -> dict[str, str]:
    commands: dict[str, str] = {}
    path_dirs = os.environ.get("PATH", "").split(":")
    for d in path_dirs:
        if not d or not os.path.isdir(d):
            continue
        try:
            for entry in os.scandir(d):
                if entry.name not in commands and entry.is_file(follow_symlinks=True):
                    try:
                        if os.access(entry.path, os.X_OK):
                            commands[entry.name] = entry.path
                    except OSError:
                        pass
        except OSError:
            pass
    return commands


def get_bash_aliases() -> dict[str, str]:
    try:
        proc = subprocess.run(
            ["bash", "-i", "-c", "alias -p"],
            capture_output=True,
            text=True,
            timeout=3,
        )
        if proc.returncode != 0:
            return {}
        aliases: dict[str, str] = {}
        for line in proc.stdout.splitlines():
            line = line.strip()
            if line.startswith("alias "):
                line = line[6:]
            if "=" in line:
                name, val = line.split("=", 1)
                aliases[name.strip()] = val.strip().strip("'\"")
        return aliases
    except Exception:
        return {}


def get_bash_builtins() -> set[str]:
    try:
        proc = subprocess.run(
            ["bash", "-c", "compgen -b"],
            capture_output=True,
            text=True,
            timeout=1,
        )
        if proc.returncode == 0:
            return set(proc.stdout.splitlines())
    except Exception:
        pass
    return set()


def build_command_cache() -> list[dict[str, str]]:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    aliases = get_bash_aliases()
    builtins = get_bash_builtins()
    path_execs = get_path_executables()

    items: list[dict[str, str]] = []
    seen: set[str] = set()

    # Priority 1: Aliases
    for name, val in sorted(aliases.items()):
        items.append(
            {
                "name": name,
                "desc": f"alias: {val}",
                "type": "alias",
            }
        )
        seen.add(name)

    # Priority 2: Builtins
    for b in sorted(builtins):
        if b not in seen and not b.startswith("_"):
            items.append(
                {
                    "name": b,
                    "desc": "bash builtin command",
                    "type": "builtin",
                }
            )
            seen.add(b)

    # Priority 3: PATH executables
    for name, path in sorted(path_execs.items()):
        if name not in seen and not name.startswith("."):
            items.append(
                {
                    "name": name,
                    "desc": path,
                    "type": "command",
                }
            )
            seen.add(name)

    try:
        CACHE_FILE.write_text(json.dumps(items), encoding="utf-8")
    except OSError:
        pass

    return items


def load_commands(force_refresh: bool = False) -> list[dict[str, str]]:
    if not force_refresh and CACHE_FILE.exists():
        try:
            mtime = CACHE_FILE.stat().st_mtime
            if (time.time() - mtime) < CACHE_TTL:
                data = json.loads(CACHE_FILE.read_text(encoding="utf-8"))
                if isinstance(data, list):
                    return data
        except Exception:
            pass
    return build_command_cache()


def execute_command(cmd: str) -> bool:
    if not cmd or not cmd.strip():
        return False
    cmd = cmd.strip()

    tokens = cmd.split()
    first_token = tokens[0] if tokens else ""

    term = find_terminal()
    is_cli = first_token in INTERACTIVE_CLI_TOOLS

    if is_cli and term:
        if term == "foot":
            subprocess.Popen(
                ["foot", "bash", "-i", "-c", f"{cmd}; exec bash"],
                start_new_session=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        elif term == "kitty":
            subprocess.Popen(
                ["kitty", "bash", "-i", "-c", f"{cmd}; exec bash"],
                start_new_session=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        else:
            subprocess.Popen(
                [term, "-e", "bash", "-i", "-c", f"{cmd}; exec bash"],
                start_new_session=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
    else:
        subprocess.Popen(
            ["bash", "-i", "-c", cmd],
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    return True


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: command-manager.py [list|run <cmd>|refresh]")
        sys.exit(1)

    action = sys.argv[1]

    if action in ("list", "refresh"):
        commands = load_commands(force_refresh=(action == "refresh"))
        print(json.dumps(commands))
    elif action == "run":
        if len(sys.argv) < 3:
            print("Error: command string required for run")
            sys.exit(1)
        cmd_str = " ".join(sys.argv[2:])
        success = execute_command(cmd_str)
        sys.exit(0 if success else 1)
    else:
        print(f"Unknown action: {action}")
        sys.exit(1)


if __name__ == "__main__":
    main()
