#!/usr/bin/env bash
# ============================================================================
# File: install.sh
# Purpose: Install the Quickshell runtime files directly into ~/.config/quickshell.
#          If ~/.config/quickshell already exists, prompts the user for confirmation
#          and backs up the existing configuration directly into ~/.config/
#          (outside ~/.config/quickshell/) so Quickshell only detects the active
#          configuration when invoking `qs` commands.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XDG_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
QS_DIR="${XDG_CONFIG_DIR}/quickshell"

REQUIRED_ITEMS=(
    "shell.qml"
    "config"
    "commands"
    "themes"
    "src/app"
)

for item in "${REQUIRED_ITEMS[@]}"; do
    if [ ! -e "${SCRIPT_DIR}/${item}" ]; then
        echo "ERROR: Required runtime path '${item}' is missing from ${SCRIPT_DIR}." >&2
        exit 1
    fi
done

# Stage runtime files into a temporary directory first (safe even if running from inside ~/.config/quickshell)
STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"' EXIT

mkdir -p "${STAGING_DIR}/src"
cp "${SCRIPT_DIR}/shell.qml" "${STAGING_DIR}/shell.qml"
cp -r "${SCRIPT_DIR}/config" "${STAGING_DIR}/config"
cp -r "${SCRIPT_DIR}/commands" "${STAGING_DIR}/commands"
cp -r "${SCRIPT_DIR}/themes" "${STAGING_DIR}/themes"
cp -r "${SCRIPT_DIR}/src/app" "${STAGING_DIR}/src/app"

# Strip any Python bytecode caches from staged runtime files
find "$STAGING_DIR" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

# Ensure all command and helper scripts are executable
find "${STAGING_DIR}/commands" "${STAGING_DIR}/src/app/scripts" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} +

# Check if an existing ~/.config/quickshell configuration is present
if [ -d "$QS_DIR" ] && [ -n "$(ls -A "$QS_DIR" 2>/dev/null)" ]; then
    echo "An existing Quickshell configuration was found at: ${QS_DIR}"
    read -r -p "Do you want to back up your existing configuration and apply this one? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
            BACKUP_DIR="${XDG_CONFIG_DIR}/quickshell-backup-${TIMESTAMP}"
            cp -a "$QS_DIR" "$BACKUP_DIR"
            echo "Backed up existing configuration to: ${BACKUP_DIR}"
            rm -rf "${QS_DIR:?}"/*
            ;;
        *)
            echo "Installation cancelled."
            exit 0
            ;;
    esac
fi

mkdir -p "$QS_DIR"
cp -a "${STAGING_DIR}/." "$QS_DIR/"

echo "Successfully installed Quickshell configuration to: ${QS_DIR}"
echo "Run 'qs' to start the shell."
