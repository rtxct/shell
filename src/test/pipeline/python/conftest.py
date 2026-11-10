import importlib.util
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[4]
SCRIPTS_DIR = REPO_ROOT / "src" / "app" / "scripts"
FIXTURES_DIR = Path(__file__).resolve().parent / "fixtures"


@pytest.fixture(autouse=True)
def fixed_timezone(monkeypatch):
    """Force deterministic UTC timezone and locale across all Python/script tests."""
    monkeypatch.setenv("TZ", "UTC")
    monkeypatch.setenv("LC_ALL", "C.UTF-8")


@pytest.fixture
def sticknote_module():
    """Dynamically load scripts/sticknotes/sticknote-storage.py as a Python module."""
    script_path = SCRIPTS_DIR / "sticknotes" / "sticknote-storage.py"
    spec = importlib.util.spec_from_file_location("sticknote_storage", script_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


@pytest.fixture
def temp_sticknote_dir(tmp_path, monkeypatch):
    """Provide an isolated temporary sticknote directory injected via STICKNOTE_DIR."""
    note_dir = tmp_path / "sticknote"
    note_dir.mkdir(parents=True, exist_ok=True)
    monkeypatch.setenv("STICKNOTE_DIR", str(note_dir))
    return note_dir


@pytest.fixture
def fixtures_dir():
    """Return path to tests/pipeline/python/fixtures/."""
    return FIXTURES_DIR
