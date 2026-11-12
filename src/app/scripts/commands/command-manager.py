#!/usr/bin/env python3
"""File: scripts/commands/command-manager.py
Purpose: Discovers system executables in PATH, shell aliases, builtins, and functions (Bash, Zsh, Fish),
and executes commands via the user's active $SHELL with terminal emulator support.
Public API:
  - list: Outputs JSON array of discovered commands, aliases, and builtins.
  - run <cmd>: Executes a command with active shell or inside a detected terminal emulator.
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


def get_user_shell() -> tuple[str, str]:
    """Detects user login shell from $SHELL, returning (shell_name, shell_path).

    Falls back to bash (or sh) if $SHELL is unset, invalid, or unsupported.
    """
    raw_shell = os.environ.get("SHELL", "").strip()
    if raw_shell:
        shell_path = shutil.which(raw_shell) or raw_shell
        shell_name = Path(raw_shell).name.lower()
        if shell_name in ("fish", "zsh", "bash") and shutil.which(shell_name):
            return shell_name, shell_path

    bash_path = shutil.which("bash") or "/bin/bash"
    if shutil.which("bash"):
        return "bash", bash_path
    sh_path = shutil.which("sh") or "/bin/sh"
    return "sh", sh_path


def get_cache_file(shell_name: str) -> Path:
    return CACHE_DIR / f"{shell_name}_commands_cache.json"


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


def get_shell_aliases_and_functions(shell_name: str, shell_path: str) -> list[dict[str, str]]:
    items: list[dict[str, str]] = []
    seen: set[str] = set()

    if shell_name == "bash":
        try:
            proc = subprocess.run(
                [shell_path, "-i", "-c", "alias -p"],
                capture_output=True,
                text=True,
                timeout=3,
            )
            if proc.returncode == 0:
                for line in proc.stdout.splitlines():
                    line = line.strip()
                    if line.startswith("alias "):
                        line = line[6:]
                    if "=" in line:
                        name, val = line.split("=", 1)
                        name = name.strip()
                        if name and name not in seen:
                            val_str = val.strip().strip("'\"")
                            items.append({"name": name, "desc": f"alias: {val_str}", "type": "alias"})
                            seen.add(name)
        except Exception:
            pass

    elif shell_name == "zsh":
        try:
            proc = subprocess.run(
                [shell_path, "-i", "-c", "alias"],
                capture_output=True,
                text=True,
                timeout=3,
            )
            if proc.returncode == 0:
                for line in proc.stdout.splitlines():
                    if "=" in line:
                        name, val = line.split("=", 1)
                        name = name.strip()
                        if name and name not in seen:
                            val_str = val.strip().strip("'\"")
                            items.append({"name": name, "desc": f"alias: {val_str}", "type": "alias"})
                            seen.add(name)
        except Exception:
            pass

    elif shell_name == "fish":
        # 1. Abbreviations (abbr --show: "abbr -a -- name 'expansion'")
        try:
            proc = subprocess.run(
                [shell_path, "-c", "abbr --show"],
                capture_output=True,
                text=True,
                timeout=3,
            )
            if proc.returncode == 0:
                for line in proc.stdout.splitlines():
                    parts = line.split()
                    if "--" in parts:
                        idx = parts.index("--")
                        if idx + 1 < len(parts):
                            name = parts[idx + 1]
                            expansion = " ".join(parts[idx + 2 :]).strip("'\"")
                            if name not in seen:
                                items.append({"name": name, "desc": f"abbr: {expansion}", "type": "alias"})
                                seen.add(name)
        except Exception:
            pass

        # 2. Functions (includes fish aliases which are defined as functions)
        try:
            proc = subprocess.run(
                [shell_path, "-c", "functions -n"],
                capture_output=True,
                text=True,
                timeout=3,
            )
            if proc.returncode == 0:
                for line in proc.stdout.splitlines():
                    fn = line.strip()
                    if fn and not fn.startswith("_") and fn not in seen:
                        items.append({"name": fn, "desc": "fish function", "type": "alias"})
                        seen.add(fn)
        except Exception:
            pass

    return items


def get_shell_builtins(shell_name: str, shell_path: str) -> set[str]:
    builtins: set[str] = set()
    try:
        if shell_name == "bash":
            proc = subprocess.run(
                [shell_path, "-c", "compgen -b"],
                capture_output=True,
                text=True,
                timeout=1,
            )
            if proc.returncode == 0:
                builtins = set(proc.stdout.splitlines())
        elif shell_name == "zsh":
            proc = subprocess.run(
                [shell_path, "-c", "print -l ${(k)builtins}"],
                capture_output=True,
                text=True,
                timeout=1,
            )
            if proc.returncode == 0:
                builtins = set(proc.stdout.splitlines())
        elif shell_name == "fish":
            proc = subprocess.run(
                [shell_path, "-c", "builtin -n"],
                capture_output=True,
                text=True,
                timeout=1,
            )
            if proc.returncode == 0:
                builtins = set(proc.stdout.splitlines())
    except Exception:
        pass
    return builtins


def build_command_cache() -> list[dict[str, str]]:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    shell_name, shell_path = get_user_shell()
    cache_file = get_cache_file(shell_name)

    aliases_and_funcs = get_shell_aliases_and_functions(shell_name, shell_path)
    builtins = get_shell_builtins(shell_name, shell_path)
    path_execs = get_path_executables()

    items: list[dict[str, str]] = []
    seen: set[str] = set()

    # Priority 1: Aliases / Functions / Abbreviations
    for entry in aliases_and_funcs:
        name = entry["name"]
        if name not in seen:
            items.append(entry)
            seen.add(name)

    # Priority 2: Builtins
    for b in sorted(builtins):
        if b not in seen and not b.startswith("_"):
            items.append(
                {
                    "name": b,
                    "desc": f"{shell_name} builtin command",
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
        cache_file.write_text(json.dumps(items), encoding="utf-8")
    except OSError:
        pass

    return items


def load_commands(force_refresh: bool = False) -> list[dict[str, str]]:
    shell_name, _ = get_user_shell()
    cache_file = get_cache_file(shell_name)

    if not force_refresh and cache_file.exists():
        try:
            mtime = cache_file.stat().st_mtime
            if (time.time() - mtime) < CACHE_TTL:
                data = json.loads(cache_file.read_text(encoding="utf-8"))
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
    shell_name, shell_path = get_user_shell()

    if shell_name == "fish":
        term_args = [shell_path, "-c", f"{cmd}; exec {shell_name}"]
        bg_args = [shell_path, "-c", cmd]
    else:
        term_args = [shell_path, "-i", "-c", f"{cmd}; exec {shell_name}"]
        bg_args = [shell_path, "-i", "-c", cmd]

    if is_cli and term:
        if term == "foot":
            subprocess.Popen(
                ["foot", *term_args],
                start_new_session=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        elif term == "kitty":
            subprocess.Popen(
                ["kitty", *term_args],
                start_new_session=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        else:
            subprocess.Popen(
                [term, "-e", *term_args],
                start_new_session=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
    else:
        subprocess.Popen(
            bg_args,
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
