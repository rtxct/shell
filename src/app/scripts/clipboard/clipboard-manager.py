#!/usr/bin/env python3
"""Clipboard Manager for Quickshell.

Interacts with cliphist and wl-copy:
- 'list': outputs JSON list of clipboard entries
- 'copy <raw_line>': decodes the cliphist entry and copies it to wl-copy
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys


def list_clipboard(limit: int = 150) -> list[dict[str, str]]:
    if not shutil.which("cliphist"):
        return []
    try:
        res = subprocess.run(
            ["cliphist", "list"],
            capture_output=True,
            text=True,
            errors="replace",
            check=False,
        )
    except Exception:
        return []

    if res.returncode != 0:
        return []

    items = []
    for line in res.stdout.splitlines()[:limit]:
        if not line.strip():
            continue
        parts = line.split("\t", 1)
        clip_id = parts[0].strip()
        clip_text = parts[1].strip() if len(parts) > 1 else ""
        if not clip_text:
            continue

        # Format preview name and description
        lines = [line_text.strip() for line_text in clip_text.splitlines() if line_text.strip()]
        first_line = lines[0] if lines else clip_text
        preview = first_line[:140]

        desc = f"Item #{clip_id}"
        if len(lines) > 1:
            desc += f" · {len(lines)} lines"
        else:
            desc += f" · {len(clip_text)} chars"

        items.append(
            {
                "name": preview,
                "desc": desc,
                "raw": line,
                "type": "clipboard",
            }
        )
    return items


def copy_entry(raw: str) -> bool:
    if not shutil.which("cliphist") or not shutil.which("wl-copy"):
        return False
    try:
        p1 = subprocess.Popen(
            ["cliphist", "decode"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
        )
        decoded, _ = p1.communicate(input=raw.encode("utf-8"))
        if p1.returncode != 0 or decoded is None:
            return False

        p2 = subprocess.Popen(["wl-copy"], stdin=subprocess.PIPE)
        p2.communicate(input=decoded)
        return p2.returncode == 0
    except Exception:
        return False


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: clipboard-manager.py [list|copy <raw>]", file=sys.stderr)
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "list":
        limit = 150
        if len(sys.argv) > 2:
            try:
                limit = int(sys.argv[2])
            except ValueError:
                pass
        items = list_clipboard(limit)
        print(json.dumps(items))
    elif cmd == "copy":
        raw = sys.argv[2] if len(sys.argv) > 2 else sys.stdin.read()
        success = copy_entry(raw)
        sys.exit(0 if success else 1)
    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
