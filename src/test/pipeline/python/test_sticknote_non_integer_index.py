"""Regression test: edit_item and delete_item must handle non-integer index strings without crashing."""

from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]
SCRIPT_PATH = REPO_ROOT / "src" / "app" / "scripts" / "sticknotes" / "sticknote-storage.py"


def load_module():
    spec = importlib.util.spec_from_file_location("sticknote_storage_reg", SCRIPT_PATH)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    return mod


def test_edit_and_delete_item_non_integer_index_do_not_crash(tmp_path: Path):
    mod = load_module()
    note = mod.create_note("Work", storage_dir=tmp_path, uid_fn=lambda: "n1")
    mod.add_item(note["id"], "Task A", storage_dir=tmp_path)

    # Calling edit_item / delete_item with a non-integer index string must not raise ValueError
    after_edit = mod.edit_item("n1", "not-an-int", "Mutated", storage_dir=tmp_path)
    assert after_edit["notes"] == ["Task A"]

    after_del = mod.delete_item("n1", "", storage_dir=tmp_path)
    assert after_del["notes"] == ["Task A"]

    # Subprocess CLI invocation with malformed index must exit 0 and return valid JSON
    proc = subprocess.run(
        [sys.executable, str(SCRIPT_PATH), "delete_item", "n1", "NaN"],
        env={"STICKNOTE_DIR": str(tmp_path)},
        capture_output=True,
        text=True,
        check=False,
    )
    assert proc.returncode == 0
    assert json.loads(proc.stdout)["notes"] == ["Task A"]
