#!/usr/bin/env python3
"""File: scripts/wifi/wifi-manager.py.

Purpose: Wi-Fi controller & telemetry provider interfacing with NetworkManager via nmcli.
         Supports querying radio state, active/connected network, saved networks,
         discovered networks with signal strength & security info, power ON/OFF toggling,
         rescan, connect (with or without password), and disconnect actions.

CLI Usage:
  - status                    -> Outputs JSON state: adapter, saved networks, scanned networks
  - power [on|off|toggle]     -> Controls Wi-Fi radio power
  - scan                      -> Triggers Wi-Fi rescan
  - connect <ssid> [password] -> Connects to Wi-Fi network
  - disconnect                -> Disconnects active Wi-Fi device
"""

from __future__ import annotations

import json
import os
import subprocess
import sys


def get_ethernet_status() -> dict:
    """Check if any ethernet (cabled) device is connected."""
    eth_info = {
        "connected": False,
        "device": "",
        "connection": "",
        "ip": "",
        "speed": "",
    }
    # Check nmcli device status
    try:
        dev_out = subprocess.check_output(
            ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"],
            text=True,
            errors="replace",
        )
        for line in dev_out.splitlines():
            parts = line.strip().split(":")
            if len(parts) >= 3:
                dev = parts[0].strip()
                dtype = parts[1].strip().lower()
                state = parts[2].strip().lower()
                conn = parts[3].strip() if len(parts) > 3 else ""
                if dtype in ("ethernet", "wired") and state.startswith("connected"):
                    eth_info["connected"] = True
                    eth_info["device"] = dev
                    eth_info["connection"] = conn or "Wired Connection"
                    try:
                        ip_out = subprocess.check_output(
                            ["nmcli", "-g", "IP4.ADDRESS", "device", "show", dev],
                            text=True,
                            errors="replace",
                        ).strip()
                        if ip_out:
                            eth_info["ip"] = ip_out.split("/")[0].splitlines()[0]
                    except Exception:
                        pass
                    try:
                        with open(f"/sys/class/net/{dev}/speed") as sf:
                            spd = sf.read().strip()
                            if spd.isdigit() and int(spd) > 0:
                                eth_info["speed"] = f"{spd} Mbps"
                    except Exception:
                        pass
                    return eth_info
    except Exception:
        pass

    # Fallback to sysfs carrier check if nmcli is unavailable or unmanaged
    try:
        net_dir = "/sys/class/net"
        if os.path.exists(net_dir):
            for iface in os.listdir(net_dir):
                if iface == "lo" or iface.startswith(("br-", "docker", "veth", "wlp", "wlan", "virbr")):
                    continue
                type_path = os.path.join(net_dir, iface, "type")
                carrier_path = os.path.join(net_dir, iface, "carrier")
                if os.path.exists(type_path):
                    with open(type_path) as f:
                        if f.read().strip() != "1":
                            continue
                if os.path.exists(os.path.join(net_dir, iface, "wireless")):
                    continue
                if os.path.exists(carrier_path):
                    with open(carrier_path) as f:
                        if f.read().strip() == "1":
                            eth_info["connected"] = True
                            eth_info["device"] = iface
                            eth_info["connection"] = "Wired Connection"
                            try:
                                with open(os.path.join(net_dir, iface, "speed")) as sf:
                                    spd = sf.read().strip()
                                    if spd.isdigit() and int(spd) > 0:
                                        eth_info["speed"] = f"{spd} Mbps"
                            except Exception:
                                pass
                            return eth_info
    except Exception:
        pass

    return eth_info


def get_airplane_mode() -> bool:
    """Check if all wireless radios are disabled (Airplane Mode)."""
    try:
        out = subprocess.check_output(["nmcli", "-t", "radio", "all"], text=True, errors="replace").strip()
        parts = out.split(":")
        wifi_enabled = len(parts) > 1 and parts[1].lower() == "enabled"
        wwan_enabled = len(parts) > 3 and parts[3].lower() == "enabled"
        return not (wifi_enabled or wwan_enabled)
    except Exception:
        return False


def set_airplane(action: str = "toggle") -> dict:
    """Turn Airplane Mode ON, OFF, or toggle via nmcli radio all off/on."""
    current = get_airplane_mode()
    target_airplane = not current if action == "toggle" else (action == "on")
    cmd = ["nmcli", "radio", "all", "off" if target_airplane else "on"]
    try:
        subprocess.run(cmd, check=True, capture_output=True)
        return {"status": "ok", "airplane": target_airplane}
    except Exception as e:
        return {"status": "error", "message": str(e)}


def get_wifi_status() -> dict:
    """Parse NetworkManager telemetry via nmcli into structured JSON."""
    ethernet_info = get_ethernet_status()
    is_airplane = get_airplane_mode()

    try:
        radio_out = subprocess.check_output(["nmcli", "radio", "wifi"], text=True, errors="replace").strip()
        powered = radio_out.lower() == "enabled"
    except Exception:
        powered = False

    adapter_info = {
        "name": "Wi-Fi",
        "powered": powered,
        "connected": False,
        "ssid": "",
    }

    # When connected to a cabled network, don't query Wi-Fi scan results (as requested)
    if ethernet_info["connected"]:
        return {
            "adapter": adapter_info,
            "ethernet": ethernet_info,
            "airplane": is_airplane,
            "saved": [],
            "scanned": [],
        }

    if not powered:
        return {
            "adapter": adapter_info,
            "ethernet": ethernet_info,
            "airplane": is_airplane,
            "saved": [],
            "scanned": [],
        }

    # Query saved connections
    saved_connections: dict[str, dict] = {}  # ssid -> {"name": ..., "uuid": ...}
    saved_ssids: set[str] = set()
    try:
        conn_out = subprocess.check_output(
            [
                "nmcli",
                "-t",
                "-f",
                "NAME,TYPE,UUID",
                "connection",
                "show",
            ],
            text=True,
            errors="replace",
        )
        for line in conn_out.splitlines():
            line = line.strip()
            if not line:
                continue
            parts = line.split(":")
            if len(parts) >= 3:
                cname = parts[0].strip()
                ctype = parts[1].strip().lower()
                cuuid = parts[2].strip()
                if any(w in ctype for w in ("wireless", "wifi", "802-11")) and cname:
                    saved_ssids.add(cname)
                    saved_connections[cname] = {"name": cname, "uuid": cuuid}
    except Exception:
        pass

    # Query nearby / visible Wi-Fi access points
    raw_networks: list[dict] = []
    try:
        wifi_out = subprocess.check_output(
            [
                "nmcli",
                "-m",
                "multiline",
                "-f",
                "ACTIVE,SSID,BSSID,SIGNAL,SECURITY,FREQ",
                "dev",
                "wifi",
            ],
            text=True,
            errors="replace",
        )
        current: dict = {}
        for line in wifi_out.splitlines():
            line = line.strip()
            if not line:
                continue
            parts = line.split(":", 1)
            if len(parts) == 2:
                k = parts[0].strip().upper()
                v = parts[1].strip()
                if k == "ACTIVE":
                    if current and current.get("ssid"):
                        raw_networks.append(current)
                    current = {"active": (v.lower() == "yes")}
                elif k == "SSID":
                    current["ssid"] = v
                elif k == "BSSID":
                    current["bssid"] = v
                elif k == "SIGNAL":
                    current["signal"] = int(v) if v.isdigit() else 0
                elif k == "SECURITY":
                    current["security"] = v if v != "--" else ""
                elif k == "FREQ":
                    current["freq"] = v
        if current and current.get("ssid"):
            raw_networks.append(current)
    except Exception:
        pass

    # De-duplicate by SSID keeping active network or highest signal
    by_ssid: dict[str, dict] = {}
    for n in raw_networks:
        s = n["ssid"]
        if not s:
            continue
        if s not in by_ssid or n["active"]:
            by_ssid[s] = n
        elif not by_ssid[s]["active"] and n.get("signal", 0) > by_ssid[s].get("signal", 0):
            by_ssid[s] = n

    saved_list: list[dict] = []
    scanned_list: list[dict] = []

    for s, item in by_ssid.items():
        is_active = item.get("active", False)
        is_saved = s in saved_ssids or is_active
        entry = {
            "ssid": s,
            "uuid": saved_connections.get(s, {}).get("uuid", ""),
            "connected": is_active,
            "signal": item.get("signal", 0),
            "security": item.get("security", ""),
            "freq": item.get("freq", ""),
            "is_saved": is_saved,
        }
        if is_active:
            adapter_info["connected"] = True
            adapter_info["ssid"] = s
            saved_list.insert(0, entry)
        elif is_saved:
            saved_list.append(entry)
        else:
            scanned_list.append(entry)

    # Also add any saved networks that weren't visible in the current scan
    seen_in_saved = {x["ssid"] for x in saved_list}
    for s in sorted(saved_ssids):
        if s not in seen_in_saved and s not in by_ssid:
            saved_list.append(
                {
                    "ssid": s,
                    "uuid": saved_connections.get(s, {}).get("uuid", ""),
                    "connected": False,
                    "signal": 0,
                    "security": "",
                    "freq": "",
                    "is_saved": True,
                }
            )

    saved_list.sort(key=lambda x: (not x["connected"], -x["signal"], x["ssid"].lower()))
    scanned_list.sort(key=lambda x: (-x["signal"], x["ssid"].lower()))

    return {
        "adapter": adapter_info,
        "ethernet": ethernet_info,
        "airplane": is_airplane,
        "saved": saved_list,
        "scanned": scanned_list,
    }


def set_power(action: str = "toggle") -> dict:
    """Turn Wi-Fi radio ON, OFF, or toggle."""
    try:
        radio_out = subprocess.check_output(["nmcli", "radio", "wifi"], text=True).strip()
        current = radio_out.lower() == "enabled"
        target = not current if action == "toggle" else (action == "on")
        subprocess.run(
            ["nmcli", "radio", "wifi", "on" if target else "off"],
            check=True,
            capture_output=True,
        )
        return {"status": "ok", "powered": target}
    except Exception as e:
        return {"status": "error", "message": str(e)}


def trigger_scan() -> dict:
    """Rescan visible Wi-Fi access points."""
    try:
        subprocess.run(
            ["nmcli", "dev", "wifi", "rescan"],
            check=False,
            capture_output=True,
            timeout=5,
        )
        return {"status": "ok"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


def connect_network(ssid: str, password: str | None = None) -> dict:
    """Connect to a Wi-Fi network with optional password."""
    try:
        if password:
            cmd = ["nmcli", "dev", "wifi", "connect", ssid, "password", password]
        else:
            # Try bringing up saved connection profile first
            cmd = ["nmcli", "connection", "up", ssid]
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=25)
            if res.returncode == 0 or "successfully activated" in res.stdout.lower():
                return {"status": "ok"}
            # Fallback to dev wifi connect if profile name didn't match directly
            cmd = ["nmcli", "dev", "wifi", "connect", ssid]
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=25)
        if res.returncode == 0 or "successfully activated" in res.stdout.lower():
            return {"status": "ok"}
        return {
            "status": "error",
            "message": res.stderr.strip() or res.stdout.strip(),
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}


def forget_network(identifier: str) -> dict:
    """Delete a saved Wi-Fi connection profile by SSID, connection name, or UUID."""
    try:
        # First try direct delete by identifier
        res = subprocess.run(
            ["nmcli", "connection", "delete", identifier],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if res.returncode == 0 or "successfully deleted" in res.stdout.lower():
            return {"status": "ok"}

        # Search all Wi-Fi connection profiles matching identifier
        out = subprocess.check_output(
            ["nmcli", "-t", "-f", "NAME,TYPE,UUID", "connection", "show"],
            text=True,
            errors="replace",
        )
        deleted = False
        for line in out.splitlines():
            parts = line.strip().split(":")
            if len(parts) >= 3:
                name, ctype, uuid = parts[0], parts[1].lower(), parts[2]
                if any(w in ctype for w in ("wireless", "wifi", "802-11")):
                    if name == identifier or uuid == identifier:
                        del_res = subprocess.run(
                            ["nmcli", "connection", "delete", uuid],
                            capture_output=True,
                            text=True,
                            timeout=10,
                        )
                        if del_res.returncode == 0:
                            deleted = True
        if deleted:
            return {"status": "ok"}
        return {
            "status": "error",
            "message": res.stderr.strip() or res.stdout.strip() or "Connection not found",
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}


def disconnect_active() -> dict:
    """Disconnect active Wi-Fi interface."""
    try:
        out = subprocess.check_output(
            ["nmcli", "-m", "multiline", "-f", "DEVICE,TYPE,STATE", "device"],
            text=True,
        )
        dev = None
        for block in out.split("DEVICE:"):
            if "wifi" in block.lower() and "connected" in block.lower():
                lines = block.strip().splitlines()
                if lines:
                    dev = lines[0].strip()
                    break
        if dev:
            res = subprocess.run(
                ["nmcli", "dev", "disconnect", dev],
                capture_output=True,
                text=True,
                timeout=10,
            )
            return {
                "status": "ok" if res.returncode == 0 else "error",
                "message": res.stderr.strip(),
            }
        return {"status": "error", "message": "No active Wi-Fi connection"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


def main():
    if len(sys.argv) < 2:
        print(json.dumps(get_wifi_status()))
        return 0

    cmd = sys.argv[1]
    if cmd == "status":
        print(json.dumps(get_wifi_status()))
        return 0
    elif cmd == "power":
        sub = sys.argv[2] if len(sys.argv) >= 3 else "toggle"
        print(json.dumps(set_power(sub)))
        return 0
    elif cmd == "airplane":
        sub = sys.argv[2] if len(sys.argv) >= 3 else "toggle"
        print(json.dumps(set_airplane(sub)))
        return 0
    elif cmd == "scan":
        print(json.dumps(trigger_scan()))
        return 0
    elif cmd in ("forget", "delete", "remove") and len(sys.argv) >= 3:
        print(json.dumps(forget_network(sys.argv[2])))
        return 0
    elif cmd == "connect" and len(sys.argv) >= 3:
        pwd = sys.argv[3] if len(sys.argv) >= 4 else None
        print(json.dumps(connect_network(sys.argv[2], pwd)))
        return 0
    elif cmd == "disconnect":
        print(json.dumps(disconnect_active()))
        return 0
    else:
        print(json.dumps({"status": "error", "message": f"Unknown command {cmd}"}))
        return 1


if __name__ == "__main__":
    sys.exit(main())
