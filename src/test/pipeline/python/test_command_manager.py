#!/usr/bin/env python3
"""File: tests/pipeline/python/test_command_manager.py
Purpose: Unit tests for command-manager.py script (discovering executables, multi-shell aliases/builtins, and execution).
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
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir(parents=True)

    exe1 = bin_dir / "my-tool"
    exe1.write_text("#!/bin/sh\necho hello\n")
    exe1.chmod(0o755)

    non_exe = bin_dir / "notes.txt"
    non_exe.write_text("not executable")

    with (
        patch.object(cmd_mod, "CACHE_DIR", cache_dir),
        patch.dict("os.environ", {"PATH": str(bin_dir), "SHELL": "/bin/bash"}),
    ):
        yield {"cache_dir": cache_dir, "bin_dir": bin_dir, "exe1": exe1}


def test_get_user_shell_detection():
    def mock_which(cmd: str):
        if cmd.startswith("/"):
            return cmd
        if cmd in ("bash", "zsh", "fish"):
            return f"/usr/bin/{cmd}"
        return None

    # Detect bash
    with (
        patch.dict("os.environ", {"SHELL": "/usr/bin/bash"}),
        patch("shutil.which", side_effect=mock_which),
    ):
        name, path = cmd_mod.get_user_shell()
        assert name == "bash"
        assert path == "/usr/bin/bash"

    # Detect zsh
    with (
        patch.dict("os.environ", {"SHELL": "/usr/bin/zsh"}),
        patch("shutil.which", side_effect=mock_which),
    ):
        name, path = cmd_mod.get_user_shell()
        assert name == "zsh"
        assert path == "/usr/bin/zsh"

    # Detect fish
    with (
        patch.dict("os.environ", {"SHELL": "/usr/bin/fish"}),
        patch("shutil.which", side_effect=mock_which),
    ):
        name, path = cmd_mod.get_user_shell()
        assert name == "fish"
        assert path == "/usr/bin/fish"

    # Fallback to bash for unknown or unset shell
    with (
        patch.dict("os.environ", {"SHELL": "/usr/bin/unknown_shell"}),
        patch("shutil.which", side_effect=lambda x: "/bin/bash" if "bash" in x else None),
    ):
        name, path = cmd_mod.get_user_shell()
        assert name == "bash"
        assert path == "/bin/bash"


def test_get_path_executables(isolated_env):
    execs = cmd_mod.get_path_executables()
    assert "my-tool" in execs
    assert execs["my-tool"] == str(isolated_env["exe1"])
    assert "notes.txt" not in execs


def test_get_shell_aliases_and_functions_bash():
    mock_proc = MagicMock(returncode=0, stdout="alias ll='ls -la'\nalias gs=\"git status\"\n")
    with patch("subprocess.run", return_value=mock_proc):
        items = cmd_mod.get_shell_aliases_and_functions("bash", "/bin/bash")
        names = {it["name"]: it["desc"] for it in items}
        assert names == {"ll": "alias: ls -la", "gs": "alias: git status"}


def test_get_shell_aliases_and_functions_zsh():
    mock_proc = MagicMock(returncode=0, stdout="ll='ls -la'\ngs='git status'\n")
    with patch("subprocess.run", return_value=mock_proc):
        items = cmd_mod.get_shell_aliases_and_functions("zsh", "/usr/bin/zsh")
        names = {it["name"]: it["desc"] for it in items}
        assert names == {"ll": "alias: ls -la", "gs": "alias: git status"}


def test_get_shell_aliases_and_functions_fish():
    mock_abbr = MagicMock(returncode=0, stdout="abbr -a -- g git\nabbr -a -g -- gp 'git push'\n")
    mock_func = MagicMock(returncode=0, stdout="my_fn\n_private_fn\nother_fn\n")

    def mock_run(args, **kwargs):
        if any("abbr" in str(a) for a in args):
            return mock_abbr
        return mock_func

    with patch("subprocess.run", side_effect=mock_run):
        items = cmd_mod.get_shell_aliases_and_functions("fish", "/usr/bin/fish")
        names = {it["name"]: it["desc"] for it in items}
        assert "g" in names
        assert names["g"] == "abbr: git"
        assert "gp" in names
        assert names["gp"] == "abbr: git push"
        assert "my_fn" in names
        assert names["my_fn"] == "fish function"
        assert "_private_fn" not in names  # Filtered out private functions


def test_get_shell_builtins():
    mock_proc = MagicMock(returncode=0, stdout="cd\necho\nset\n")
    with patch("subprocess.run", return_value=mock_proc):
        for shell in ("bash", "zsh", "fish"):
            builtins = cmd_mod.get_shell_builtins(shell, f"/bin/{shell}")
            assert builtins == {"cd", "echo", "set"}


def test_build_and_load_command_cache(isolated_env):
    with (
        patch.object(cmd_mod, "get_user_shell", return_value=("bash", "/bin/bash")),
        patch.object(
            cmd_mod,
            "get_shell_aliases_and_functions",
            return_value=[{"name": "ll", "desc": "alias: ls -l", "type": "alias"}],
        ),
        patch.object(cmd_mod, "get_shell_builtins", return_value={"cd"}),
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

        # Verify per-shell cache file created
        cache_file = cmd_mod.get_cache_file("bash")
        assert cache_file.is_file()
        cached_data = json.loads(cache_file.read_text(encoding="utf-8"))
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

    # Bash execution
    with (
        patch.object(cmd_mod, "get_user_shell", return_value=("bash", "/bin/bash")),
        patch("subprocess.Popen") as mock_popen,
    ):
        assert cmd_mod.execute_command("echo test") is True
        mock_popen.assert_called_once()
        args = mock_popen.call_args[0][0]
        assert args == ["/bin/bash", "-i", "-c", "echo test"]

    # Fish execution
    with (
        patch.object(cmd_mod, "get_user_shell", return_value=("fish", "/usr/bin/fish")),
        patch("subprocess.Popen") as mock_popen,
    ):
        assert cmd_mod.execute_command("echo test") is True
        mock_popen.assert_called_once()
        args = mock_popen.call_args[0][0]
        assert args == ["/usr/bin/fish", "-c", "echo test"]

    # Interactive CLI tools in terminal
    with (
        patch.object(cmd_mod, "get_user_shell", return_value=("bash", "/bin/bash")),
        patch.object(cmd_mod, "find_terminal", return_value="foot"),
        patch("subprocess.Popen") as mock_popen,
    ):
        assert cmd_mod.execute_command("htop") is True
        mock_popen.assert_called_once()
        args = mock_popen.call_args[0][0]
        assert args == ["foot", "/bin/bash", "-i", "-c", "htop; exec bash"]


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
