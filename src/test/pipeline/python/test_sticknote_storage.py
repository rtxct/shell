"""
Unit, edge-case, and golden-file tests for scripts/sticknotes/sticknote-storage.py.
"""

import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

SCRIPT_PATH = Path(__file__).resolve().parents[4] / "src" / "app" / "scripts" / "sticknotes" / "sticknote-storage.py"


def test_list_empty_directory(sticknote_module, temp_sticknote_dir):
    """Listing an empty sticknote directory returns an empty list."""
    assert sticknote_module.list_notes(str(temp_sticknote_dir)) == []
    assert sticknote_module.run_cli(["sticknote-storage.py", "list"], str(temp_sticknote_dir)) == "[]"


def test_create_and_list_golden_format(sticknote_module, temp_sticknote_dir, fixtures_dir):
    """
    Golden-file test locking the exact JSON schema and stdout format that
    modules/stick-notes-service.module.qml consumes (`JSON.parse(this.text)`).
    """
    n1 = sticknote_module.create_note(
        "Ideas",
        str(temp_sticknote_dir),
        uid_fn=lambda: "00000000-1111-2222-3333-444444444444",
    )
    os.utime(temp_sticknote_dir / f"{n1['id']}.json", (1000, 1000))

    n2 = sticknote_module.create_note(
        "  Sprint Tasks  ",
        str(temp_sticknote_dir),
        uid_fn=lambda: "11111111-2222-3333-4444-555555555555",
    )
    sticknote_module.add_item(n2["id"], "Review QML components", str(temp_sticknote_dir))
    sticknote_module.add_item(n2["id"], "Run pipeline tests", str(temp_sticknote_dir))
    os.utime(temp_sticknote_dir / f"{n2['id']}.json", (2000, 2000))

    raw_stdout = sticknote_module.run_cli(["sticknote-storage.py", "list"], str(temp_sticknote_dir))
    parsed = json.loads(raw_stdout)
    expected = json.loads((fixtures_dir / "sticknote_list.golden.json").read_text(encoding="utf-8"))
    assert parsed == expected


@pytest.mark.parametrize(
    "raw_name,expected_name",
    [
        ("Shopping List", "Shopping List"),
        ("   ", "Stick Note"),
        ("", "Stick Note"),
        ("  Trimmed Name  ", "Trimmed Name"),
    ],
)
def test_create_note_name_normalization(sticknote_module, temp_sticknote_dir, raw_name, expected_name):
    """Blank or whitespace-only names default to 'Stick Note'; valid names are stripped."""
    created = sticknote_module.create_note(raw_name, str(temp_sticknote_dir), uid_fn=lambda: "fixed-id")
    assert created == {"id": "fixed-id", "name": expected_name, "notes": []}


def test_crud_item_operations(sticknote_module, temp_sticknote_dir):
    """Verify rename, add_item, edit_item, delete_item, and delete_note."""
    note = sticknote_module.create_note("Initial", str(temp_sticknote_dir), uid_fn=lambda: "nid-1")
    nid = note["id"]

    # Add items (whitespace-only ignored)
    sticknote_module.add_item(nid, "  First item  ", str(temp_sticknote_dir))
    sticknote_module.add_item(nid, "   ", str(temp_sticknote_dir))
    res = sticknote_module.add_item(nid, "Second item", str(temp_sticknote_dir))
    assert res["notes"] == ["First item", "Second item"]

    # Edit item (in-bounds and out-of-bounds)
    res = sticknote_module.edit_item(nid, 0, "  Updated first  ", str(temp_sticknote_dir))
    assert res["notes"] == ["Updated first", "Second item"]
    res_oob = sticknote_module.edit_item(nid, 99, "Ignored", str(temp_sticknote_dir))
    assert res_oob["notes"] == ["Updated first", "Second item"]

    # Rename note
    renamed = sticknote_module.rename_note(nid, "Renamed Title", str(temp_sticknote_dir))
    assert renamed["name"] == "Renamed Title"
    renamed_blank = sticknote_module.rename_note(nid, "   ", str(temp_sticknote_dir))
    assert renamed_blank["name"] == "Stick Note"

    # Set color
    colored = sticknote_module.set_color(nid, "purple", str(temp_sticknote_dir))
    assert colored["color"] == "purple"
    assert sticknote_module.set_color("missing", "blue", str(temp_sticknote_dir)) is None

    # Delete item
    after_del = sticknote_module.delete_item(nid, 0, str(temp_sticknote_dir))
    assert after_del["notes"] == ["Second item"]

    # Delete note
    del_status = sticknote_module.delete_note(nid, str(temp_sticknote_dir))
    assert del_status == {"status": "ok", "id": nid}
    assert sticknote_module.load_note(nid, str(temp_sticknote_dir)) is None


def test_missing_and_malformed_files(sticknote_module, temp_sticknote_dir, capsys):
    """
    Verify resilience against missing note IDs, corrupted JSON files, non-dict JSON,
    and partial dictionaries missing id/name/notes keys.
    """
    # Operations on non-existent note ID return None cleanly
    assert sticknote_module.load_note("missing", str(temp_sticknote_dir)) is None
    assert sticknote_module.rename_note("missing", "New", str(temp_sticknote_dir)) is None
    assert sticknote_module.add_item("missing", "Text", str(temp_sticknote_dir)) is None
    assert sticknote_module.edit_item("missing", 0, "Text", str(temp_sticknote_dir)) is None
    assert sticknote_module.delete_item("missing", 0, str(temp_sticknote_dir)) is None

    # Corrupted JSON file logs to stderr and is skipped
    (temp_sticknote_dir / "corrupt.json").write_text("{not valid json", encoding="utf-8")
    # Non-dict JSON is skipped
    (temp_sticknote_dir / "array.json").write_text("[1, 2, 3]", encoding="utf-8")
    # Partial dict gets default id, name, and notes list repaired
    (temp_sticknote_dir / "partial-id.json").write_text('{"notes": "not-a-list"}', encoding="utf-8")

    notes = sticknote_module.list_notes(str(temp_sticknote_dir))
    captured = capsys.readouterr()
    assert "Error reading" in captured.err
    assert notes == [{"id": "partial-id", "name": "Stick Note", "notes": []}]


def test_cli_subprocess_entrypoints(temp_sticknote_dir):
    """Test invoking sticknote-storage.py as a subprocess across all CLI subcommands."""
    env = os.environ.copy()
    env["STICKNOTE_DIR"] = str(temp_sticknote_dir)

    def run_sub(*args):
        proc = subprocess.run(
            [sys.executable, str(SCRIPT_PATH), *args],
            env=env,
            capture_output=True,
            text=True,
            check=True,
        )
        return json.loads(proc.stdout.strip())

    assert run_sub() == []
    created = run_sub("create", "My", "Note")
    nid = created["id"]
    assert created["name"] == "My Note"

    added = run_sub("add_item", nid, "Hello", "World")
    assert added["notes"] == ["Hello World"]

    edited = run_sub("edit_item", nid, "0", "Edited", "Item")
    assert edited["notes"] == ["Edited Item"]

    renamed = run_sub("rename", nid, "New", "Name")
    assert renamed["name"] == "New Name"

    deleted_item = run_sub("delete_item", nid, "0")
    assert deleted_item["notes"] == []

    deleted_note = run_sub("delete", nid)
    assert deleted_note == {"status": "ok", "id": nid}
    assert run_sub("unknown_cmd") == []


def test_run_cli_and_main_in_process(sticknote_module, temp_sticknote_dir, capsys):
    """Exercise run_cli and main() directly in-process for all subcommands and short-arg branches."""
    d = str(temp_sticknote_dir)
    assert sticknote_module.run_cli(["prog"], d) == "[]"
    created_json = sticknote_module.run_cli(["prog", "create", "CLI", "Note"], d, uid_fn=lambda: "cli-1")
    assert json.loads(created_json)["id"] == "cli-1"

    assert json.loads(sticknote_module.run_cli(["prog", "add_item", "cli-1", "Item", "One"], d))["notes"] == [
        "Item One"
    ]
    assert json.loads(sticknote_module.run_cli(["prog", "edit_item", "cli-1", "0", "Item", "Updated"], d))["notes"] == [
        "Item Updated"
    ]
    assert (
        json.loads(sticknote_module.run_cli(["prog", "rename", "cli-1", "Renamed", "CLI"], d))["name"] == "Renamed CLI"
    )
    assert json.loads(sticknote_module.run_cli(["prog", "set_color", "cli-1", "green"], d))["color"] == "green"
    assert sticknote_module.run_cli(["prog", "set_color", "cli-1"], d) is None
    assert json.loads(sticknote_module.run_cli(["prog", "delete_item", "cli-1", "0"], d))["notes"] == []
    assert json.loads(sticknote_module.run_cli(["prog", "delete", "cli-1"], d)) == {
        "status": "ok",
        "id": "cli-1",
    }
    assert sticknote_module.run_cli(["prog", "unknown"], d) == "[]"

    # Missing arguments return None cleanly
    assert sticknote_module.run_cli(["prog", "delete"], d) is None
    assert sticknote_module.run_cli(["prog", "rename", "cli-1"], d) is None
    assert sticknote_module.run_cli(["prog", "add_item", "cli-1"], d) is None
    assert sticknote_module.run_cli(["prog", "edit_item", "cli-1", "0"], d) is None
    assert sticknote_module.run_cli(["prog", "delete_item", "cli-1"], d) is None

    # main() prints JSON to stdout
    sticknote_module.DIR = d
    sticknote_module.main(["prog", "list"])
    assert capsys.readouterr().out.strip() == "[]"
