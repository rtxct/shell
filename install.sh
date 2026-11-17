#!/usr/bin/env bash
# ============================================================================
# File: install.sh
# Purpose: Install the Quickshell runtime files directly into ~/.config/quickshell.
#          Supports merging with existing user configs (giving ~/.config priority)
#          or full overwrite, and automatically creates a timestamped backup.
#
# Usage:
#   ./install.sh             # Interactive prompt ([M]erge / [O]verwrite / [C]ancel)
#   ./install.sh --merge     # Non-interactive merge (preserves user configs with priority)
#   ./install.sh --overwrite # Non-interactive fresh overwrite with repo defaults
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XDG_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
QS_DIR="${XDG_CONFIG_DIR}/quickshell"

MODE=""
for arg in "$@"; do
    case "$arg" in
        -m|--merge)
            MODE="merge"
            ;;
        -o|--overwrite)
            MODE="overwrite"
            ;;
        -h|--help)
            echo "Usage: $0 [--merge | --overwrite]"
            echo "  --merge      Preserve existing user configs in ~/.config/quickshell/config (priority) and merge new files"
            echo "  --overwrite  Clean install (replaces all files with repository defaults after backup)"
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            echo "Usage: $0 [--merge | --overwrite]" >&2
            exit 1
            ;;
    esac
done

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

    if [ -z "$MODE" ]; then
        echo ""
        echo "Choose an installation option:"
        echo "  [M]erge     - Keep your existing ~/.config settings with priority, add new configs & update code (Recommended)"
        echo "  [O]verwrite - Replace all files with fresh repository defaults"
        echo "  [C]ancel    - Abort installation without changes"
        read -r -p "Select option [M/o/c] (default: M): " response
        case "$response" in
            [oO]|[oO][vV][eE][rR][wW][rR][iI][tT][eE])
                MODE="overwrite"
                ;;
            [cC]|[cC][aA][nN][cC][eE][lL])
                echo "Installation cancelled."
                exit 0
                ;;
            ""|[mM]|[mM][eE][rR][gG][eE]|[yY]|[yY][eE][sS])
                MODE="merge"
                ;;
            *)
                echo "Invalid selection. Installation cancelled."
                exit 0
                ;;
        esac
    fi

    # Always create a backup of the existing ~/.config/quickshell before modifying
    TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
    BACKUP_DIR="${XDG_CONFIG_DIR}/quickshell-backup-${TIMESTAMP}"
    cp -a "$QS_DIR" "$BACKUP_DIR"
    echo "Backed up existing configuration to: ${BACKUP_DIR}"

    if [ "$MODE" = "merge" ]; then
        echo "Merging configuration (existing ~/.config settings take priority)..."
        # If the existing installation has a config directory, overlay it on top of staging config
        # so user's existing settings override repo defaults, while any new repo configs remain
        if [ -d "${QS_DIR}/config" ]; then
            cp -a "${QS_DIR}/config/." "${STAGING_DIR}/config/"
        fi
        # Clear out old runtime code in target directory (configs in staging already include user priority)
        rm -rf "${QS_DIR:?}"/*
    elif [ "$MODE" = "overwrite" ]; then
        echo "Performing clean overwrite with repository defaults..."
        rm -rf "${QS_DIR:?}"/*
    fi
fi

mkdir -p "$QS_DIR"
cp -a "${STAGING_DIR}/." "$QS_DIR/"

echo "Successfully installed Quickshell configuration to: ${QS_DIR}"
echo "Run 'qs' to start the shell."
