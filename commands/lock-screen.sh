#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

qs ipc call lock lock 2>/dev/null \
    || qs -p "$CONFIG_DIR" ipc call lock lock
