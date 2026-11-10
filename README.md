# Shell

**A fluid and practical [Quickshell](https://quickshell.outfoxxed.me/) configuration for Wayland.**

Calendar, weather, hardware, audio, notes, connectivity and power,<br>
all within mouse reach and tucked away when idle.

<br>

[Overview](#-overview) ·
[What's Inside](#-whats-inside) ·
[Install](#-installation) ·
[Keybindings](#-window-manager-keybindings) ·
[Configuration](#-configuration) ·
[Testing](#-testing)

<br>

---

<br>

## ✦ Overview

The idea behind this configuration is straightforward: keep daily essentials within mouse reach, without opening a browser tab or spawning separate desktop utility windows.

The interface stays **consistent**, **fluid**, and **tucked away when idle**. Everything is integrated directly into edge bars and floating panels:

| | | |
| :--- | :--- | :--- |
| 📅 Calendar | 🌤️ Weather | 📊 Hardware monitoring |
| 🔊 Audio devices | 📝 Notes | 📡 Connectivity |
| 🔋 Power actions | 🔔 Notifications | 🔒 Screen locking |

<br>

---

<br>

## ✦ What's Inside

The shell organizes its controls around the perimeter of the screen.

<br>

### 🔝 Top Bar

| Section | Description |
| :--- | :--- |
| **Center Island**<br>Clock, Calendar & Weather | Shows time and date. Expands on click into a monthly calendar synced with an `.ics` feed, alongside current weather and a 7-day forecast (via Open-Meteo). |
| **Left Wing**<br>Process Monitor | A btop-style active process list with real-time text filtering and column sorting by Name, CPU, GPU, or Memory usage. |
| **Right Wing**<br>Hardware Performance | Live CPU, GPU, and Memory gauges with temperatures and click-to-expand telemetry breakdowns. |

<br>

### ◀️ Left Bar & Circles

**Workspace Island**

Central workspace indicators (supports both `sway` and `niri`) that expand into a workspace navigation view.

<br>

**Top Circles: Connectivity & Comfort**

| Control | Powered by | Features |
| :--- | :--- | :--- |
| 📶 **Wi-Fi** | `nmcli` | Network scanner, signal strength, connection status, password prompts |
| 🔷 **Bluetooth** | `bluetoothctl` | Device discovery, pairing, battery indicators, connect/disconnect toggles |
| 🌙 **Night Light** | `wlsunset` | Gamma temperature controls, toggle, coordinate adjustments |

<br>

**Bottom Circles: Power & Battery**

| Control | Powered by | Features |
| :--- | :--- | :--- |
| ⚡ **Power Profiles** | `powerprofilesctl` | Quick toggle between Performance, Balanced, and Power Saver |
| 🔋 **Battery Diagnostics** | `UPower` | Real-time percentage, time to empty/full, health, cycle count |
| ⏻ **Session Actions** | n/a | Quick triggers for Reboot, Power Off, Sleep, and Lock |

<br>

**Bottom-Left Corner: App Menu & Clipboard**

| Feature | Powered by | Features |
| :--- | :--- | :--- |
| 🔍 **App Launcher** | n/a | Application search |
| 📋 **Clipboard** | `cliphist` | Clipboard history |
| 🧰 **Utilities** | `grim` · `slurp` · `satty` · `hyprpicker` | Screenshots and color picker |

<br>

### 🔽 Bottom Bars

| Section | Description |
| :--- | :--- |
| **Bottom Center**<br>Notification Center | A tab drawer that slides up into notification history, with Do-Not-Disturb and clear-all controls. |
| **Bottom Right**<br>Media & Audio | Music playback controls (`playerctl`), a Cava spectrum visualizer, volume/mic buttons that morph into unified sliders on click, and audio stream routing. |

<br>

### ▶️ Right Edge

**Stick Notes**

A perimeter drawer for quick scratchpad notes with swipe gestures, saved locally to `~/.cache/sticknote`.

<br>

### 🪟 Window Management & Locker

| Feature | Description |
| :--- | :--- |
| **Detachable Floating Windows** | Panels can be detached from the bar into floating, draggable windows. |
| **Screen Locker** | Wayland session lock (`ext-session-lock-v1`) with PAM authentication and wallpaper integration (`awww`). |

<br>

---

<br>

## ✦ Requirements

Targeted at **Arch Linux**. Runtime system packages are listed in [`requirements.txt`](./requirements.txt):

```bash
grep -vE '^\s*(#|$)' requirements.txt | sudo pacman -S --needed -
```

<br>

---

<br>

## ✦ Installation

**Run directly from the repo** inside an active Wayland session:

```bash
quickshell -p .
```

**Install into `~/.config/quickshell`** (backs up any existing configuration first):

```bash
./install.sh
qs
```

<br>

---

<br>

## ✦ Window Manager Keybindings

The shell exposes IPC handlers for window manager shortcuts or custom scripts.

**Application menu**

```bash
qs ipc call menu toggle
# or: ~/.config/quickshell/commands/toggle-menu.sh
```

**Clipboard history**

```bash
qs ipc call clipboard toggle
# or: ~/.config/quickshell/commands/clipboard-menu.sh
```

**Screen locker**

```bash
qs ipc call lock lock
# or: ~/.config/quickshell/commands/lock-screen.sh
```

<br>

---

<br>

## ✦ Configuration

Settings live in [`config/`](./config/) as JSON files and **hot-reload on save**.

| File | Purpose |
| :--- | :--- |
| [`workspaces.config.json`](./config/workspaces.config.json) | Compositor backend (`"sway"` or `"niri"`), workspace count, and poll interval. |
| [`weather.config.json`](./config/weather.config.json) | Location coordinates, default city, and refresh timer. |
| [`calendar.config.json`](./config/calendar.config.json) | Private `.ics` calendar URL (or `QS_ICS_URL` env variable) and fetch horizons. |
| [`sunset.config.json`](./config/sunset.config.json) | Night light coordinates and day/night color temperatures. |
| [`audio.config.json`](./config/audio.config.json) | Volume steps, limits, and Cava spectrum settings. |
| [`notifications.config.json`](./config/notifications.config.json) | Popup display timeouts and max visible toast count. |
| [`layout.config.json`](./config/layout.config.json) | Bar thickness, gaps, margins, and placement coordinates. |
| [`wallpaper.config.json`](./config/wallpaper.config.json) | Fallback wallpaper path for the screen locker. |

<br>

---

<br>

## ✦ Testing

Headless automated pipeline checks: Python tests, config schemas, QML component tests, and linters.

```bash
python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt
PATH=$PWD/.venv/bin:$PATH make test
```

<br>
