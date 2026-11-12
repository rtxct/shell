#!/usr/bin/env python3
"""File: tests/pipeline/python/test_command_manager.py
Purpose: Unit tests for command-manager.py script (discovering executables, bash aliases/builtins, and command execution).
Dependencies: pytest, unittest.mock, pathlib, importlib.util
"""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

REPO_ROOT = Path(__file__).resolve().parents[4]
CMD_MANAGER_SCRIPT = REPO_ROOT / "src" / "app" / "scripts" / "commands" / "command-manager.py"

spec = importlib.util.spec_from_file_location("command_manager", CMD_MANAGER_SCRIPT)
assert spec and spec.loader
cmd_mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cmd_mod)


@pytest.fixture
def isolated_env(tmp_path: Path):
    cache_dir = tmp_path / "quickshell"
    cache_file = cache_dir / "commands_cache.json"
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir(parents=True)

    # Create dummy executables
    exe1 = bin_dir / "my-tool"
    exe1.write_text("#!/bin/sh\necho hello\n")
    exe1.chmod(0o755)

    non_exe = bin_dir / "notes.txt"
    non_exe.write_text("not executable")

    with (
        patch.object(cmd_mod, "CACHE_DIR", cache_dir),
        patch.object(cmd_mod, "CACHE_FILE", cache_file),
        patch.dict("os.environ", {"PATH": str(bin_dir)}),
    ):
        yield {"cache_dir": cache_dir, "cache_file": cache_file, "bin_dir": bin_dir, "exe1": exe1}


def test_get_path_executables(isolated_env):
    execs = cmd_mod.get_path_executables()
    assert "my-tool" in execs
    assert execs["my-tool"] == str(isolated_env["exe1"])
    assert "notes.txt" not in execs


def test_get_bash_aliases():
    mock_proc = MagicMock(returncode=0, stdout="alias ll='ls -la'\nalias gs=\"git status\"\n")
    with patch("subprocess.run", return_value=mock_proc):
        aliases = cmd_mod.get_bash_aliases()
        assert aliases == {"ll": "ls -la", "gs": "git status"}


def test_get_bash_builtins():
    mock_proc = MagicMock(returncode=0, stdout="cd\necho\nexport\n")
    with patch("subprocess.run", return_value=mock_proc):
        builtins = cmd_mod.get_bash_builtins()
        assert builtins == {"cd", "echo", "export"}


def test_build_and_load_command_cache(isolated_env):
    with (
        patch.object(cmd_mod, "get_bash_aliases", return_value={"ll": "ls -l"}),
        patch.object(cmd_mod, "get_bash_builtins", return_value={"cd"}),
    ):
        items = cmd_mod.load_commands(force_refresh=True)

        names = [item["name"] for item in items]
        assert "ll" in names
        assert "cd" in names
        assert "my-tool" in names

        # Verify priority ordering: alias, builtin, path command
        alias_idx = names.index("ll")
        builtin_idx = names.index("cd")
        cmd_idx = names.index("my-tool")
        assert alias_idx < builtin_idx < cmd_idx

        # Verify cache file created
        assert isolated_env["cache_file"].is_file()
        cached_data = json.loads(isolated_env["cache_file"].read_text(encoding="utf-8"))
        assert len(cached_data) == len(items)

        # Verify cache read on second call without force_refresh
        with patch.object(cmd_mod, "build_command_cache") as mock_build:
            cached_items = cmd_mod.load_commands(force_refresh=False)
            assert len(cached_items) == len(items)
            mock_build.assert_not_called()


def test_execute_command():
    # Empty command returns False
    assert cmd_mod.execute_command("") is False
    assert cmd_mod.execute_command("   ") is False

    # Non-interactive CLI runs via bash background
    with patch("subprocess.Popen") as mock_popen:
        assert cmd_mod.execute_command("echo test") is True
        mock_popen.assert_called_once()
        args = mock_popen.call_args[0][0]
        assert args == ["bash", "-i", "-c", "echo test"]

    # Interactive CLI tools run in terminal wrapper
    with (
        patch.object(cmd_mod, "find_terminal", return_value="foot"),
        patch("subprocess.Popen") as mock_popen,
    ):
        assert cmd_mod.execute_command("htop") is True
        mock_popen.assert_called_once()
        args = mock_popen.call_args[0][0]
        assert args == ["foot", "bash", "-i", "-c", "htop; exec bash"]


def test_cli_main(isolated_env, capsys):
    with patch("sys.argv", ["command-manager.py", "list"]):
        cmd_mod.main()
    captured = capsys.readouterr()
    data = json.loads(captured.out)
    assert isinstance(data, list)

    with patch("sys.argv", ["command-manager.py", "run", "echo", "test"]):
        with patch.object(cmd_mod, "execute_command", return_value=True) as mock_exec:
            with pytest.raises(SystemExit) as exc:
                cmd_mod.main()
            assert exc.value.code == 0
            mock_exec.assert_called_once_with("echo test")
