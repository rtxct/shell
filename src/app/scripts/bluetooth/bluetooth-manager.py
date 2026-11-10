#!/usr/bin/env python3
"""File: scripts/bluetooth/bluetooth-manager.py.

Purpose: Bluetooth controller & status provider interfacing with BlueZ DBus and bluetoothctl.
         Supports querying adapter state, paired & connected devices with RSSI and battery,
         scanned devices, Bluetooth power ON/OFF toggling, clean start/stop scanning daemon,
         connect/disconnect actions, and interactive pairing with PIN prompts.

CLI Usage:
  - status                 -> Outputs JSON state: adapter, paired devices, scanned devices
  - power [on|off|toggle]  -> Controls Bluetooth adapter power state
  - scan_daemon            -> Persistent discovery daemon with graceful StopDiscovery on exit
  - scan off               -> Stops bluetooth scanning
  - connect <address>      -> Connects to device
  - disconnect <address>   -> Disconnects from device
  - pair <address>         -> Interactively pairs and connects; prompts PIN on stdin if needed
"""

from __future__ import annotations

import json
import re
import signal
import subprocess
import sys
import time

try:
    import dbus
    import dbus.mainloop.glib
    from gi.repository import GLib

    HAS_DBUS = True
except ImportError:
    HAS_DBUS = False


def get_default_adapter_path(objects: dict) -> str:
    """Find the first Bluetooth adapter object path."""
    for path, ifaces in objects.items():
        if "org.bluez.Adapter1" in ifaces:
            return str(path)
    return "/org/bluez/hci0"


def get_status_dbus() -> dict:
    """Query BlueZ DBus ObjectManager for adapter and device states."""
    bus = dbus.SystemBus()
    manager = dbus.Interface(bus.get_object("org.bluez", "/"), "org.freedesktop.DBus.ObjectManager")
    objects = manager.GetManagedObjects()

    adapter_info = {
        "name": "Bluetooth",
        "powered": False,
        "discovering": False,
        "address": "",
    }
    paired = []
    scanned = []

    for _path, ifaces in objects.items():
        if "org.bluez.Adapter1" in ifaces:
            a = ifaces["org.bluez.Adapter1"]
            adapter_info = {
                "name": str(a.get("Alias", a.get("Name", "Bluetooth"))),
                "powered": bool(a.get("Powered", False)),
                "discovering": bool(a.get("Discovering", False)),
                "address": str(a.get("Address", "")),
            }
        if "org.bluez.Device1" in ifaces:
            d = ifaces["org.bluez.Device1"]
            addr = str(d.get("Address", ""))
            name = str(d.get("Alias", d.get("Name", addr)))
            is_paired = bool(d.get("Paired", False))
            is_connected = bool(d.get("Connected", False))
            icon = str(d.get("Icon", ""))
            rssi = int(d.get("RSSI")) if "RSSI" in d else None
            battery = None
            if "org.bluez.Battery1" in ifaces:
                battery = int(ifaces["org.bluez.Battery1"].get("Percentage", 0))

            item = {
                "address": addr,
                "name": name,
                "paired": is_paired,
                "connected": is_connected,
                "icon": icon,
                "rssi": rssi,
                "battery": battery,
            }
            if is_paired or is_connected:
                paired.append(item)
            else:
                scanned.append(item)

    paired.sort(key=lambda x: (not x["connected"], x["name"].lower()))
    scanned.sort(key=lambda x: (x["rssi"] is None, -(x["rssi"] or 0), x["name"].lower()))
    return {"adapter": adapter_info, "paired": paired, "scanned": scanned}


def get_status_fallback() -> dict:
    """Fallback using bluetoothctl CLI when DBus is unavailable."""
    out = subprocess.check_output(["bluetoothctl", "devices"], text=True, errors="replace")
    info_out = subprocess.check_output(["bluetoothctl", "show"], text=True, errors="replace")
    discovering = "Discovering: yes" in info_out
    powered = "Powered: yes" in info_out

    paired = []
    for line in out.splitlines():
        parts = line.strip().split(maxsplit=2)
        if len(parts) >= 3 and parts[0] == "Device":
            addr = parts[1]
            name = parts[2]
            dev_info = subprocess.check_output(["bluetoothctl", "info", addr], text=True, errors="replace")
            is_conn = "Connected: yes" in dev_info
            is_pair = "Paired: yes" in dev_info
            paired.append(
                {
                    "address": addr,
                    "name": name,
                    "paired": is_pair,
                    "connected": is_conn,
                    "icon": "",
                    "rssi": None,
                    "battery": None,
                }
            )

    return {
        "adapter": {
            "name": "Bluetooth",
            "powered": powered,
            "discovering": discovering,
        },
        "paired": paired,
        "scanned": [],
    }


def get_status() -> dict:
    if HAS_DBUS:
        try:
            return get_status_dbus()
        except Exception:
            pass
    return get_status_fallback()


def set_power(action: str = "toggle") -> dict:
    """Turn Bluetooth adapter power ON, OFF, or toggle."""
    if HAS_DBUS:
        try:
            bus = dbus.SystemBus()
            manager = dbus.Interface(
                bus.get_object("org.bluez", "/"),
                "org.freedesktop.DBus.ObjectManager",
            )
            adapter_path = get_default_adapter_path(manager.GetManagedObjects())
            props = dbus.Interface(
                bus.get_object("org.bluez", adapter_path),
                "org.freedesktop.DBus.Properties",
            )
            current = bool(props.Get("org.bluez.Adapter1", "Powered"))
            target = not current if action == "toggle" else (action == "on")
            props.Set("org.bluez.Adapter1", "Powered", dbus.Boolean(target))
            return {"status": "ok", "powered": target}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    # Fallback to bluetoothctl
    cmd = ["bluetoothctl", "power", "on" if action == "on" else "off"]
    res = subprocess.run(cmd, capture_output=True, text=True)
    return {"status": "ok" if res.returncode == 0 else "error"}


def run_scan_daemon():
    """Run persistent discovery session with graceful StopDiscovery on exit."""
    if not HAS_DBUS:
        subprocess.run(["bluetoothctl", "--", "scan", "on"])
        return

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    manager = dbus.Interface(bus.get_object("org.bluez", "/"), "org.freedesktop.DBus.ObjectManager")
    adapter_path = get_default_adapter_path(manager.GetManagedObjects())
    adapter = dbus.Interface(bus.get_object("org.bluez", adapter_path), "org.bluez.Adapter1")

    loop = GLib.MainLoop()

    def handle_exit(signum, frame):
        try:
            adapter.StopDiscovery()
        except Exception:
            pass
        loop.quit()

    signal.signal(signal.SIGTERM, handle_exit)
    signal.signal(signal.SIGINT, handle_exit)

    try:
        adapter.StartDiscovery()
        print("SCAN_ACTIVE", flush=True)
    except Exception as e:
        if "InProgress" in str(type(e)) or "InProgress" in str(e) or "already in progress" in str(e).lower():
            print("SCAN_ACTIVE", flush=True)
        else:
            print(f"SCAN_ERROR:{e}", flush=True)
            return

    loop.run()


def stop_scan() -> dict:
    """Explicitly stops any discovery running on the adapter."""
    # Kill any active scan_daemon processes started by this user
    try:
        subprocess.run(
            ["pkill", "-f", "bluetooth-manager.py scan_daemon"],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except Exception:
        pass

    if HAS_DBUS:
        try:
            bus = dbus.SystemBus()
            manager = dbus.Interface(
                bus.get_object("org.bluez", "/"),
                "org.freedesktop.DBus.ObjectManager",
            )
            adapter_path = get_default_adapter_path(manager.GetManagedObjects())
            adapter = dbus.Interface(bus.get_object("org.bluez", adapter_path), "org.bluez.Adapter1")
            adapter.StopDiscovery()
            return {"status": "ok", "discovering": False}
        except Exception:
            pass

    return {"status": "ok", "discovering": False}


def connect_device(address: str) -> dict:
    res = subprocess.run(
        ["bluetoothctl", "connect", address],
        capture_output=True,
        text=True,
        timeout=15,
    )
    if res.returncode == 0 or "successful" in res.stdout.lower():
        return {"status": "ok"}
    return {
        "status": "error",
        "message": res.stdout.strip() or res.stderr.strip(),
    }


def disconnect_device(address: str) -> dict:
    res = subprocess.run(
        ["bluetoothctl", "disconnect", address],
        capture_output=True,
        text=True,
        timeout=10,
    )
    if res.returncode == 0 or "successful" in res.stdout.lower():
        return {"status": "ok"}
    return {
        "status": "error",
        "message": res.stdout.strip() or res.stderr.strip(),
    }


def forget_device(address: str) -> dict:
    """Unpair and remove a Bluetooth device."""
    res = subprocess.run(
        ["bluetoothctl", "remove", address],
        capture_output=True,
        text=True,
        timeout=10,
    )
    if res.returncode == 0 or "successful" in res.stdout.lower() or "removed" in res.stdout.lower():
        return {"status": "ok"}
    return {
        "status": "error",
        "message": res.stdout.strip() or res.stderr.strip(),
    }


ANSI_ESCAPE = re.compile(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")


def clean_terminal_output(text: str) -> str:
    """Remove ANSI color/escape sequences and prompt artifacts."""
    clean = ANSI_ESCAPE.sub("", text).replace("\x08", "").strip()
    clean = re.sub(r"\[[^\]]+\]>\s*", "", clean).strip()
    clean = re.sub(r"\[agent\]\s*", "", clean).strip()
    return clean


def pair_device(address: str):
    """Interactive pair handler with PIN/passkey support."""
    p = subprocess.Popen(
        ["bluetoothctl"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )
    p.stdin.write("agent on\ndefault-agent\n")
    p.stdin.write(f"pair {address}\n")
    p.stdin.flush()

    is_paired = False
    start_time = time.time()

    while time.time() - start_time < 45:
        line = p.stdout.readline()
        if not line:
            break
        line_clean = line.strip()
        line_lower = line_clean.lower()

        if any(
            kw in line_lower
            for kw in [
                "pin code",
                "passkey",
                "confirm",
                "yes/no",
                "enter pin",
                "enter passkey",
                "request pin",
                "request passkey",
                "authorize service",
            ]
        ):
            clean = clean_terminal_output(line_clean)
            is_confirm = "(yes/no)" in clean.lower() or "confirm" in clean.lower()

            # Extract any explicit PIN/passkey digits (4 to 8 digits)
            pin_code = ""
            m = re.search(
                r"(?:confirm\s+passkey|passkey:?|pin(?:\s+code)?:?)\s*(\d{4,8})",
                clean,
                re.IGNORECASE,
            )
            if m:
                pin_code = m.group(1)

            if pin_code:
                prompt = "Confirm passkey on your device" if is_confirm else "Enter this PIN on your device"
            elif "enter pin" in clean.lower() or "request pin" in clean.lower():
                prompt = "Enter device PIN (e.g. 0000 or 1234)"
            elif "enter passkey" in clean.lower() or "request passkey" in clean.lower():
                prompt = "Enter passkey (number from 0 to 999999)"
            elif "authorize service" in clean.lower():
                prompt = "Authorize Bluetooth service"
            else:
                prompt = "Bluetooth authentication required"

            payload = {
                "pin": pin_code,
                "prompt": prompt,
                "is_confirm": is_confirm,
            }
            print(f"PIN_REQUIRED:{json.dumps(payload)}", flush=True)

            if is_confirm:
                p.stdin.write("yes\n")
                p.stdin.flush()
            elif pin_code:
                # Passkey is to be typed on the external hardware device.
                # BlueZ is waiting for device input, so do not block on stdin.
                pass
            else:
                pin = sys.stdin.readline().strip()
                p.stdin.write(f"{pin}\n")
                p.stdin.flush()
        elif "pairing successful" in line_lower or "paired: yes" in line_lower:
            is_paired = True
            p.stdin.write(f"trust {address}\n")
            p.stdin.write(f"connect {address}\n")
            p.stdin.flush()
        elif "already paired" in line_lower or "already exists" in line_lower:
            is_paired = True
            p.stdin.write(f"trust {address}\n")
            p.stdin.write(f"connect {address}\n")
            p.stdin.flush()
        elif is_paired and (
            "connection successful" in line_lower or "connected: yes" in line_lower or "already connected" in line_lower
        ):
            print("SUCCESS", flush=True)
            p.terminate()
            return 0
        elif any(
            kw in line_lower
            for kw in [
                "failed to pair",
                "authenticationfailed",
                "authenticationcanceled",
                "authenticationtimeout",
                "authenticationrejected",
                "not available",
                "failed to connect",
            ]
        ):
            err_msg = clean_terminal_output(line_clean)
            if any(k in line_lower for k in ["authenticationfailed", "authenticationrejected"]):
                err_msg = "Incorrect PIN or password. Authentication failed."
            elif "authenticationtimeout" in line_lower:
                err_msg = "Pairing timed out. Authentication took too long."
            elif "authenticationcanceled" in line_lower:
                err_msg = "Pairing was canceled by the device."
            print(f"ERROR:{err_msg}", flush=True)
            p.terminate()
            return 1

    if is_paired:
        print("SUCCESS", flush=True)
        p.terminate()
        return 0

    print("ERROR:Timeout waiting for Bluetooth pairing", flush=True)
    p.terminate()
    return 1


def main():
    if len(sys.argv) < 2:
        print(json.dumps(get_status()))
        return 0

    cmd = sys.argv[1]
    if cmd == "status":
        print(json.dumps(get_status()))
        return 0
    elif cmd == "power":
        sub = sys.argv[2] if len(sys.argv) >= 3 else "toggle"
        print(json.dumps(set_power(sub)))
        return 0
    elif cmd == "scan_daemon":
        run_scan_daemon()
        return 0
    elif cmd == "scan" and len(sys.argv) >= 3 and sys.argv[2] == "off":
        print(json.dumps(stop_scan()))
        return 0
    elif cmd == "connect" and len(sys.argv) >= 3:
        print(json.dumps(connect_device(sys.argv[2])))
        return 0
    elif cmd == "disconnect" and len(sys.argv) >= 3:
        print(json.dumps(disconnect_device(sys.argv[2])))
        return 0
    elif cmd in ("forget", "remove", "unpair") and len(sys.argv) >= 3:
        print(json.dumps(forget_device(sys.argv[2])))
        return 0
    elif cmd == "pair" and len(sys.argv) >= 3:
        return pair_device(sys.argv[2])
    else:
        print(json.dumps({"status": "error", "message": f"Unknown command {cmd}"}))
        return 1


if __name__ == "__main__":
    sys.exit(main())
