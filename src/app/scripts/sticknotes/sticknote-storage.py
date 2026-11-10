#!/usr/bin/env python3
"""
File: scripts/sticknotes/sticknote-storage.py
Purpose: Standalone CLI JSON database engine for the Right-Edge Stick Notes Drawer
         and Floating Stick Note panels. Persists note collections as individual
         JSON files inside ~/.cache/sticknote/.
Public CLI API:
  - list                             -> Prints JSON array of all stick notes sorted by mtime desc
  - create <name>                    -> Creates a new stick note and prints its JSON object
  - delete <id>                      -> Deletes the stick note file and prints {"status": "ok", "id": <id>}
  - rename <id> <new_name>           -> Updates the stick note title and prints updated JSON
  - add_item <id> <text>             -> Appends an item string to notes[] and prints updated JSON
  - edit_item <id> <index> <text>    -> Replaces notes[<index>] and prints updated JSON
  - delete_item <id> <index>         -> Removes notes[<index>] and prints updated JSON
Dependencies: Python 3 standard library (os, sys, json, uuid, glob)
"""

import glob
import json
import os
import sys
import uuid

DIR = os.environ.get("STICKNOTE_DIR") or os.path.expanduser("~/.cache/sticknote")


def ensure_storage_dir(storage_dir=None):
    """Ensure the target storage directory exists and return its path."""
    target = storage_dir if storage_dir is not None else DIR
    os.makedirs(target, exist_ok=True)
    return target


def list_notes(storage_dir=None):
    """Return all stick note dictionaries sorted newest-first by modification time."""
    target = ensure_storage_dir(storage_dir)
    files = sorted(glob.glob(os.path.join(target, "*.json")), key=os.path.getmtime, reverse=True)
    res = []
    for f in files:
        try:
            with open(f, "r", encoding="utf-8") as fp:
                data = json.load(fp)
                if not isinstance(data, dict):
                    continue
                if "id" not in data:
                    data["id"] = os.path.splitext(os.path.basename(f))[0]
                if "name" not in data:
                    data["name"] = "Stick Note"
                if "notes" not in data or not isinstance(data["notes"], list):
                    data["notes"] = []
                res.append(data)
        except Exception as e:
            sys.stderr.write(f"Error reading {f}: {e}\n")
    return res


def get_note_path(nid, storage_dir=None):
    """Resolve the absolute JSON file path for a given stick note UUID."""
    target = ensure_storage_dir(storage_dir)
    return os.path.join(target, f"{nid}.json")


def load_note(nid, storage_dir=None):
    """Read and parse a single stick note JSON file, or return None if missing."""
    path = get_note_path(nid, storage_dir)
    if not os.path.exists(path):
        return None
    with open(path, "r", encoding="utf-8") as fp:
        return json.load(fp)


def save_note(data, storage_dir=None):
    """Atomically write stick note data to disk via a temporary file replacement."""
    nid = data["id"]
    path = get_note_path(nid, storage_dir)
    temp_path = path + ".tmp"
    with open(temp_path, "w", encoding="utf-8") as fp:
        json.dump(data, fp, indent=2, ensure_ascii=False)
    os.replace(temp_path, path)
    return data


def create_note(name, storage_dir=None, uid_fn=None):
    """Create a new stick note with a generated UUID and empty notes list."""
    nid = str(uid_fn() if uid_fn is not None else uuid.uuid4())
    data = {"id": nid, "name": name.strip() or "Stick Note", "notes": []}
    return save_note(data, storage_dir)


def set_color(nid, color_key, storage_dir=None):
    """Set the color key of an existing stick note by UUID."""
    data = load_note(nid, storage_dir)
    if not data:
        return None
    data["color"] = str(color_key).strip()
    return save_note(data, storage_dir)


def delete_note(nid, storage_dir=None):
    """Delete a stick note JSON file by UUID."""
    path = get_note_path(nid, storage_dir)
    if os.path.exists(path):
        try:
            os.remove(path)
        except Exception as e:
            sys.stderr.write(f"Error removing {path}: {e}\n")
    return {"status": "ok", "id": nid}


def rename_note(nid, new_name, storage_dir=None):
    """Rename an existing stick note by UUID."""
    data = load_note(nid, storage_dir)
    if not data:
        return None
    data["name"] = new_name.strip() or "Stick Note"
    return save_note(data, storage_dir)


def add_item(nid, text, storage_dir=None):
    """Append a non-empty note item string to a stick note's list."""
    data = load_note(nid, storage_dir)
    if not data:
        return None
    if not isinstance(data.get("notes"), list):
        data["notes"] = []
    if text.strip():
        data["notes"].append(text.strip())
    return save_note(data, storage_dir)


def edit_item(nid, index, text, storage_dir=None):
    """Update the text of a note item at a specific zero-based index."""
    data = load_note(nid, storage_dir)
    if not data:
        return None
    if not isinstance(data.get("notes"), list):
        data["notes"] = []
    try:
        idx = int(index)
    except (ValueError, TypeError):
        return save_note(data, storage_dir)
    if 0 <= idx < len(data["notes"]):
        data["notes"][idx] = text.strip()
    return save_note(data, storage_dir)


def delete_item(nid, index, storage_dir=None):
    """Remove a note item at a specific zero-based index."""
    data = load_note(nid, storage_dir)
    if not data:
        return None
    if not isinstance(data.get("notes"), list):
        data["notes"] = []
    try:
        idx = int(index)
    except (ValueError, TypeError):
        return save_note(data, storage_dir)
    if 0 <= idx < len(data["notes"]):
        data["notes"].pop(idx)
    return save_note(data, storage_dir)


def run_cli(argv, storage_dir=None, uid_fn=None):
    """Execute a CLI command from argv and return the serialized JSON output string."""
    if len(argv) < 2:
        return json.dumps(list_notes(storage_dir))

    cmd = argv[1]
    if cmd == "list":
        return json.dumps(list_notes(storage_dir))
    if cmd == "create":
        name = " ".join(argv[2:]) if len(argv) > 2 else "Stick Note"
        return json.dumps(create_note(name, storage_dir, uid_fn=uid_fn))
    if cmd == "delete":
        if len(argv) > 2:
            return json.dumps(delete_note(argv[2], storage_dir))
        return None
    if cmd == "rename":
        if len(argv) > 3:
            nid = argv[2]
            name = " ".join(argv[3:])
            return json.dumps(rename_note(nid, name, storage_dir))
        return None
    if cmd == "set_color":
        if len(argv) > 3:
            nid = argv[2]
            color_key = argv[3]
            return json.dumps(set_color(nid, color_key, storage_dir))
        return None
    if cmd == "add_item":
        if len(argv) > 3:
            nid = argv[2]
            text = " ".join(argv[3:])
            return json.dumps(add_item(nid, text, storage_dir))
        return None
    if cmd == "edit_item":
        if len(argv) > 4:
            nid = argv[2]
            idx = argv[3]
            text = " ".join(argv[4:])
            return json.dumps(edit_item(nid, idx, text, storage_dir))
        return None
    if cmd == "delete_item":
        if len(argv) > 3:
            nid = argv[2]
            idx = argv[3]
            return json.dumps(delete_item(nid, idx, storage_dir))
        return None
    return json.dumps(list_notes(storage_dir))


def main(argv=None):
    """CLI entry point printing the JSON result to stdout."""
    args = argv if argv is not None else sys.argv
    out = run_cli(args)
    if out is not None:
        print(out)


if __name__ == "__main__":
    main()
