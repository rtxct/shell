"""Unit tests for src/app/scripts/menu/menu-history.py."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from unittest.mock import patch

REPO_ROOT = Path(__file__).resolve().parents[4]
MENU_HIST_SCRIPT = REPO_ROOT / "src" / "app" / "scripts" / "menu" / "menu-history.py"

spec = importlib.util.spec_from_file_location("menu_history", MENU_HIST_SCRIPT)
assert spec and spec.loader
hist_mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(hist_mod)


def test_ensure_cache_files(tmp_path: Path):
    cache_dir = tmp_path / "quickshell-menu"
    app_hist = cache_dir / "app.hist"
    cmd_hist = cache_dir / "cmd.hist"

    with (
        patch.object(hist_mod, "CACHE_DIR", cache_dir),
        patch.object(hist_mod, "APP_HIST", app_hist),
        patch.object(hist_mod, "CMD_HIST", cmd_hist),
    ):
        hist_mod.ensure_cache_files()
        assert cache_dir.is_dir()
        assert app_hist.is_file()
        assert cmd_hist.is_file()


def test_record_and_load_usage(tmp_path: Path):
    cache_dir = tmp_path / "quickshell-menu"
    app_hist = cache_dir / "app.hist"
    cmd_hist = cache_dir / "cmd.hist"

    with (
        patch.object(hist_mod, "CACHE_DIR", cache_dir),
        patch.object(hist_mod, "APP_HIST", app_hist),
        patch.object(hist_mod, "CMD_HIST", cmd_hist),
    ):
        hist_mod.record_usage("app", "firefox")
        hist_mod.record_usage("app", "firefox")
        hist_mod.record_usage("app", "alacritty")

        counts = hist_mod.load_history("app")
        assert counts == {"firefox": 2, "alacritty": 1}

        # Check file contents
        content = app_hist.read_text(encoding="utf-8").strip().splitlines()
        assert content[0] == "firefox:2"
        assert content[1] == "alacritty:1"

        # Record command
        hist_mod.record_usage("cmd", "htop")
        cmd_counts = hist_mod.load_history("cmd")
        assert cmd_counts == {"htop": 1}
        assert cmd_hist.read_text(encoding="utf-8").strip() == "htop:1"


def test_get_file_size(tmp_path: Path):
    non_existent = tmp_path / "missing.hist"
    assert hist_mod.get_file_size(non_existent) == "0B"

    empty_file = tmp_path / "empty.hist"
    empty_file.touch()
    assert hist_mod.get_file_size(empty_file) == "0B"

    content_file = tmp_path / "content.hist"
    content_file.write_text("firefox:10\n", encoding="utf-8")
    size_str = hist_mod.get_file_size(content_file)
    assert size_str != "0B"


def test_prune_history(tmp_path: Path):
    cache_dir = tmp_path / "quickshell-menu"
    app_hist = cache_dir / "app.hist"
    cmd_hist = cache_dir / "cmd.hist"

    with (
        patch.object(hist_mod, "CACHE_DIR", cache_dir),
        patch.object(hist_mod, "APP_HIST", app_hist),
        patch.object(hist_mod, "CMD_HIST", cmd_hist),
    ):
        hist_mod.record_usage("app", "firefox")
        hist_mod.record_usage("cmd", "ls")

        assert app_hist.exists()
        assert cmd_hist.exists()

        # Prune only app history
        hist_mod.prune_history("app")
        assert not app_hist.exists()
        assert cmd_hist.exists()
        assert hist_mod.load_history("app") == {}
        assert hist_mod.load_history("cmd") == {"ls": 1}

        # Prune cmd history
        hist_mod.prune_history("cmd")
        assert not cmd_hist.exists()
        assert hist_mod.load_history("cmd") == {}


def test_cli_subcommands(tmp_path: Path, capsys):
    cache_dir = tmp_path / "quickshell-menu"
    app_hist = cache_dir / "app.hist"
    cmd_hist = cache_dir / "cmd.hist"

    with (
        patch.object(hist_mod, "CACHE_DIR", cache_dir),
        patch.object(hist_mod, "APP_HIST", app_hist),
        patch.object(hist_mod, "CMD_HIST", cmd_hist),
    ):
        with patch("sys.argv", ["menu-history.py", "init"]):
            hist_mod.main()
        assert app_hist.exists()
        assert cmd_hist.exists()

        with patch("sys.argv", ["menu-history.py", "record", "app", "code"]):
            hist_mod.main()

        with patch("sys.argv", ["menu-history.py", "record", "cmd", "neofetch"]):
            hist_mod.main()

        with patch("sys.argv", ["menu-history.py", "get", "app"]):
            hist_mod.main()
        captured = capsys.readouterr()
        data = json.loads(captured.out)
        assert data["counts"] == {"code": 1}
        assert "storage" in data

        with patch("sys.argv", ["menu-history.py", "list"]):
            hist_mod.main()
        captured_all = capsys.readouterr()
        all_data = json.loads(captured_all.out)
        assert all_data["app"] == {"code": 1}
        assert all_data["cmd"] == {"neofetch": 1}
        assert "app" in all_data["storage"]
        assert "cmd" in all_data["storage"]

        # Prune app CLI
        with patch("sys.argv", ["menu-history.py", "prune", "app"]):
            hist_mod.main()
        captured_prune = capsys.readouterr()
        prune_data = json.loads(captured_prune.out)
        assert prune_data["app"] == {}
        assert prune_data["cmd"] == {"neofetch": 1}
        assert prune_data["storage"]["app"] == "0B"
        assert not app_hist.exists()
        assert cmd_hist.exists()
