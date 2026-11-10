#!/usr/bin/env python3
"""File: scripts/audio/pavucontrol-manager.py.

Purpose: Complete PulseAudio / PipeWire (pactl) audio controller & telemetry provider
         powering the pavucontrol-equivalent floating sound window.
         Queries and controls Output Devices (sinks & ports), Input Devices (sources & ports),
         Playback Streams (sink-inputs & device routing), Recording Streams (source-outputs &
         device routing), and Sound Card Configuration (drivers & profiles).

CLI Usage:
  - status
  - set-sink-volume <sink> <pct>
  - set-sink-mute <sink> <1|0|toggle>
  - set-default-sink <sink>
  - set-sink-port <sink> <port>
  - set-source-volume <source> <pct>
  - set-source-mute <source> <1|0|toggle>
  - set-default-source <source>
  - set-source-port <source> <port>
  - set-sink-input-volume <index> <pct>
  - set-sink-input-mute <index> <1|0|toggle>
  - move-sink-input <index> <sink>
  - set-source-output-volume <index> <pct>
  - set-source-output-mute <index> <1|0|toggle>
  - move-source-output <index> <source>
  - set-card-profile <card> <profile>
"""

from __future__ import annotations

import json
import subprocess
import sys
from typing import Any

VIRTUAL_RECORDER_NAMES = {
    "quickshell peak detect",
    "pulseaudio volume control",
    "cava",
    "quickshell",
}


def run_pactl_json(args: list[str]) -> Any:
    """Execute `pactl -f json ...` and return parsed JSON or None on failure."""
    try:
        out = subprocess.check_output(
            ["pactl", "-f", "json", *args],
            text=True,
            stderr=subprocess.DEVNULL,
            errors="replace",
        )
        return json.loads(out)
    except Exception:
        return None


def run_pactl_cmd(args: list[str]) -> bool:
    """Execute a mutating `pactl` command."""
    try:
        subprocess.run(
            ["pactl", *args],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return True
    except Exception:
        return False


def extract_volume(vol_dict: dict | None) -> tuple[float, int, str]:
    """Return (ratio 0..1.5, integer percent 0..150, dB label) from a pactl volume dict."""
    if not isinstance(vol_dict, dict) or not vol_dict:
        return 1.0, 100, "0.00 dB"
    pcts: list[int] = []
    db_str = ""
    for ch_data in vol_dict.values():
        if not isinstance(ch_data, dict):
            continue
        raw_pct = str(ch_data.get("value_percent", "100%")).strip().rstrip("%")
        try:
            pcts.append(int(float(raw_pct)))
        except ValueError:
            pass
        if not db_str and ch_data.get("db"):
            db_str = str(ch_data.get("db"))
    if not pcts:
        return 1.0, 100, db_str or "0.00 dB"
    avg_pct = int(round(sum(pcts) / len(pcts)))
    avg_pct = max(0, min(150, avg_pct))
    return round(avg_pct / 100.0, 2), avg_pct, db_str or "0.00 dB"


def get_status() -> dict[str, Any]:
    """Collect full pavucontrol state across info, sinks, sources, streams, and cards."""
    info = run_pactl_json(["info"]) or {}
    default_sink = str(info.get("default_sink_name") or "")
    default_source = str(info.get("default_source_name") or "")

    raw_sinks = run_pactl_json(["list", "sinks"]) or []
    raw_sources = run_pactl_json(["list", "sources"]) or []
    raw_sink_inputs = run_pactl_json(["list", "sink-inputs"]) or []
    raw_source_outputs = run_pactl_json(["list", "source-outputs"]) or []
    raw_cards = run_pactl_json(["list", "cards"]) or []

    sinks_by_index: dict[int, dict[str, Any]] = {}
    sinks: list[dict[str, Any]] = []
    for s in raw_sinks:
        if not isinstance(s, dict):
            continue
        idx = int(s.get("index", -1))
        name = str(s.get("name") or "")
        props = s.get("properties") if isinstance(s.get("properties"), dict) else {}
        desc = str(s.get("description") or props.get("device.description") or props.get("node.nick") or name)
        vol_ratio, vol_pct, db_str = extract_volume(s.get("volume"))
        ports = []
        for p in s.get("ports") or []:
            if isinstance(p, dict) and p.get("name"):
                ports.append(
                    {
                        "name": str(p.get("name")),
                        "description": str(p.get("description") or p.get("name")),
                        "available": str(p.get("availability") or "unknown"),
                    }
                )
        sink_obj = {
            "index": idx,
            "name": name,
            "description": desc,
            "driver": str(s.get("driver") or "PipeWire"),
            "api": str(props.get("device.api") or ""),
            "state": str(s.get("state") or "IDLE"),
            "mute": bool(s.get("mute", False)),
            "volume": vol_ratio,
            "volume_pct": vol_pct,
            "db": db_str,
            "is_default": (name == default_sink),
            "active_port": str(s.get("active_port") or ""),
            "ports": ports,
        }
        sinks.append(sink_obj)
        sinks_by_index[idx] = sink_obj

    sources_by_index: dict[int, dict[str, Any]] = {}
    sources: list[dict[str, Any]] = []
    for src in raw_sources:
        if not isinstance(src, dict):
            continue
        idx = int(src.get("index", -1))
        name = str(src.get("name") or "")
        props = src.get("properties") if isinstance(src.get("properties"), dict) else {}
        desc = str(src.get("description") or props.get("device.description") or props.get("node.nick") or name)
        vol_ratio, vol_pct, db_str = extract_volume(src.get("volume"))
        is_monitor = (
            bool(src.get("monitor_source"))
            or name.endswith(".monitor")
            or str(props.get("device.class") or "").lower() == "monitor"
        )
        ports = []
        for p in src.get("ports") or []:
            if isinstance(p, dict) and p.get("name"):
                ports.append(
                    {
                        "name": str(p.get("name")),
                        "description": str(p.get("description") or p.get("name")),
                        "available": str(p.get("availability") or "unknown"),
                    }
                )
        src_obj = {
            "index": idx,
            "name": name,
            "description": desc,
            "driver": str(src.get("driver") or "PipeWire"),
            "api": str(props.get("device.api") or ""),
            "state": str(src.get("state") or "IDLE"),
            "mute": bool(src.get("mute", False)),
            "volume": vol_ratio,
            "volume_pct": vol_pct,
            "db": db_str,
            "is_default": (name == default_source),
            "is_monitor": is_monitor,
            "active_port": str(src.get("active_port") or ""),
            "ports": ports,
        }
        sources.append(src_obj)
        sources_by_index[idx] = src_obj

    sink_inputs: list[dict[str, Any]] = []
    for si in raw_sink_inputs:
        if not isinstance(si, dict):
            continue
        idx = int(si.get("index", -1))
        sink_idx = int(si.get("sink", -1))
        props = si.get("properties") if isinstance(si.get("properties"), dict) else {}
        app_name = str(
            props.get("application.name") or props.get("node.name") or props.get("media.name") or "Playback Stream"
        )
        media_name = str(props.get("media.name") or "")
        vol_ratio, vol_pct, db_str = extract_volume(si.get("volume"))
        target_sink = sinks_by_index.get(sink_idx, {})
        sink_inputs.append(
            {
                "index": idx,
                "app_name": app_name,
                "media_name": media_name,
                "sink": sink_idx,
                "sink_name": str(target_sink.get("name") or ""),
                "sink_description": str(target_sink.get("description") or "Default Output"),
                "driver": str(si.get("driver") or "PipeWire"),
                "corked": bool(si.get("corked", False)),
                "mute": bool(si.get("mute", False)),
                "volume": vol_ratio,
                "volume_pct": vol_pct,
                "db": db_str,
            }
        )

    source_outputs: list[dict[str, Any]] = []
    for so in raw_source_outputs:
        if not isinstance(so, dict):
            continue
        idx = int(so.get("index", -1))
        src_idx = int(so.get("source", -1))
        props = so.get("properties") if isinstance(so.get("properties"), dict) else {}
        app_name = str(
            props.get("application.name") or props.get("node.name") or props.get("media.name") or "Recording Stream"
        )
        media_name = str(props.get("media.name") or "")
        node_name = str(props.get("node.name") or "")
        is_virtual = (
            app_name.strip().lower() in VIRTUAL_RECORDER_NAMES
            or node_name.strip().lower() in VIRTUAL_RECORDER_NAMES
            or media_name.strip().lower() == "peak detect"
        )
        vol_ratio, vol_pct, db_str = extract_volume(so.get("volume"))
        target_src = sources_by_index.get(src_idx, {})
        source_outputs.append(
            {
                "index": idx,
                "app_name": app_name,
                "media_name": media_name,
                "source": src_idx,
                "source_name": str(target_src.get("name") or ""),
                "source_description": str(target_src.get("description") or "Default Input"),
                "driver": str(so.get("driver") or "PipeWire"),
                "corked": bool(so.get("corked", False)),
                "mute": bool(so.get("mute", False)),
                "volume": vol_ratio,
                "volume_pct": vol_pct,
                "db": db_str,
                "is_virtual": is_virtual,
            }
        )

    cards: list[dict[str, Any]] = []
    for c in raw_cards:
        if not isinstance(c, dict):
            continue
        idx = int(c.get("index", -1))
        name = str(c.get("name") or "")
        props = c.get("properties") if isinstance(c.get("properties"), dict) else {}
        desc = str(
            props.get("device.description")
            or props.get("device.nick")
            or props.get("device.product.name")
            or props.get("api.alsa.card.name")
            or name
        )
        product_name = str(props.get("device.product.name") or props.get("api.alsa.card.longname") or "")
        active_prof = str(c.get("active_profile") or "")
        raw_profiles = c.get("profiles") or {}
        profiles: list[dict[str, Any]] = []
        active_prof_desc = active_prof
        if isinstance(raw_profiles, dict):
            for prof_name, prof_data in raw_profiles.items():
                if not isinstance(prof_data, dict):
                    continue
                p_desc = str(prof_data.get("description") or prof_name)
                if prof_name == active_prof:
                    active_prof_desc = p_desc
                profiles.append(
                    {
                        "name": str(prof_name),
                        "description": p_desc,
                        "sinks": int(prof_data.get("sinks", 0)),
                        "sources": int(prof_data.get("sources", 0)),
                        "priority": int(prof_data.get("priority", 0)),
                        "available": bool(prof_data.get("available", True)),
                    }
                )
        profiles.sort(key=lambda item: (item["name"] == "off", -item["priority"]))
        cards.append(
            {
                "index": idx,
                "name": name,
                "description": desc,
                "product_name": product_name,
                "driver": str(c.get("driver") or ""),
                "api": str(props.get("device.api") or ""),
                "bus": str(props.get("device.bus") or ""),
                "form_factor": str(props.get("device.form_factor") or ""),
                "active_profile": active_prof,
                "active_profile_description": active_prof_desc,
                "profiles": profiles,
            }
        )

    return {
        "default_sink": default_sink,
        "default_source": default_source,
        "sinks": sinks,
        "sources": sources,
        "sink_inputs": sink_inputs,
        "source_outputs": source_outputs,
        "cards": cards,
    }


def clamp_pct(val_str: str) -> int:
    """Parse and clamp a volume percentage string to 0..150."""
    try:
        pct = int(round(float(val_str.strip().rstrip("%"))))
    except ValueError:
        pct = 100
    return max(0, min(150, pct))


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    cmd = args[0] if args else "status"

    if cmd == "status":
        print(json.dumps(get_status()))
        return 0

    if cmd == "set-sink-volume" and len(args) >= 3:
        pct = clamp_pct(args[2])
        ok = run_pactl_cmd(["set-sink-volume", args[1], f"{pct}%"])
        return 0 if ok else 1

    if cmd == "set-sink-mute" and len(args) >= 3:
        ok = run_pactl_cmd(["set-sink-mute", args[1], args[2]])
        return 0 if ok else 1

    if cmd == "set-default-sink" and len(args) >= 2:
        ok = run_pactl_cmd(["set-default-sink", args[1]])
        return 0 if ok else 1

    if cmd == "set-sink-port" and len(args) >= 3:
        ok = run_pactl_cmd(["set-sink-port", args[1], args[2]])
        return 0 if ok else 1

    if cmd == "set-source-volume" and len(args) >= 3:
        pct = clamp_pct(args[2])
        ok = run_pactl_cmd(["set-source-volume", args[1], f"{pct}%"])
        return 0 if ok else 1

    if cmd == "set-source-mute" and len(args) >= 3:
        ok = run_pactl_cmd(["set-source-mute", args[1], args[2]])
        return 0 if ok else 1

    if cmd == "set-default-source" and len(args) >= 2:
        ok = run_pactl_cmd(["set-default-source", args[1]])
        return 0 if ok else 1

    if cmd == "set-source-port" and len(args) >= 3:
        ok = run_pactl_cmd(["set-source-port", args[1], args[2]])
        return 0 if ok else 1

    if cmd == "set-sink-input-volume" and len(args) >= 3:
        pct = clamp_pct(args[2])
        ok = run_pactl_cmd(["set-sink-input-volume", args[1], f"{pct}%"])
        return 0 if ok else 1

    if cmd == "set-sink-input-mute" and len(args) >= 3:
        ok = run_pactl_cmd(["set-sink-input-mute", args[1], args[2]])
        return 0 if ok else 1

    if cmd == "move-sink-input" and len(args) >= 3:
        ok = run_pactl_cmd(["move-sink-input", args[1], args[2]])
        return 0 if ok else 1

    if cmd == "set-source-output-volume" and len(args) >= 3:
        pct = clamp_pct(args[2])
        ok = run_pactl_cmd(["set-source-output-volume", args[1], f"{pct}%"])
        return 0 if ok else 1

    if cmd == "set-source-output-mute" and len(args) >= 3:
        ok = run_pactl_cmd(["set-source-output-mute", args[1], args[2]])
        return 0 if ok else 1

    if cmd == "move-source-output" and len(args) >= 3:
        ok = run_pactl_cmd(["move-source-output", args[1], args[2]])
        return 0 if ok else 1

    if cmd == "set-card-profile" and len(args) >= 3:
        ok = run_pactl_cmd(["set-card-profile", args[1], args[2]])
        return 0 if ok else 1

    print(json.dumps({"error": f"Unknown or incomplete command: {cmd}"}))
    return 1


if __name__ == "__main__":
    sys.exit(main())
