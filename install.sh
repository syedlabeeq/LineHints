#!/bin/sh
# Install script for koreader-linehints
# Applies the plugin and patches the required KOReader core files.

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Try to auto-detect a KOReader installation if no path is given.
if [ -n "$1" ]; then
    KOREADER_DIR="$1"
else
    for candidate in \
        "/media/$(whoami)/KINDLE/koreader" \
        "/media/KINDLE/koreader" \
        "/mnt/us/koreader" \
        "$HOME/KINDLE/koreader" \
        "$HOME/koreader" \
        "./koreader"
    do
        if [ -f "$candidate/reader.lua" ]; then
            KOREADER_DIR="$candidate"
            break
        fi
    done
fi

if [ -z "$KOREADER_DIR" ] || [ ! -f "$KOREADER_DIR/reader.lua" ]; then
    echo "Error: could not find a KOReader installation."
    echo "Usage: $0 /path/to/koreader"
    echo ""
    echo "Common examples:"
    echo "  $0 /media/$(whoami)/KINDLE/koreader"
    echo "  $0 /mnt/us/koreader"
    exit 1
fi

if ! command -v patch >/dev/null 2>&1; then
    echo "Error: 'patch' utility is required but not found."
    echo "Install it with your package manager, or apply the patches manually from the patches/ folder."
    exit 1
fi

echo "Installing koreader-linehints to: $KOREADER_DIR"

# Plugin
echo "  -> Installing plugin..."
mkdir -p "$KOREADER_DIR/plugins/linehints.koplugin"
cp -v "$REPO_DIR/linehints.koplugin/_meta.lua" "$KOREADER_DIR/plugins/linehints.koplugin/_meta.lua"
cp -v "$REPO_DIR/linehints.koplugin/main.lua" "$KOREADER_DIR/plugins/linehints.koplugin/main.lua"

# Back up the files we are about to patch
echo "  -> Backing up KOReader core files..."
BACKUP_DIR="$KOREADER_DIR/.linehints-backups-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR/frontend/apps/reader/modules"
cp -v "$KOREADER_DIR/frontend/apps/reader/modules/readerview.lua" "$BACKUP_DIR/frontend/apps/reader/modules/readerview.lua"
cp -v "$KOREADER_DIR/frontend/apps/reader/modules/readerhighlight.lua" "$BACKUP_DIR/frontend/apps/reader/modules/readerhighlight.lua"

# Apply patches
echo "  -> Patching KOReader core files..."
cd "$KOREADER_DIR"
if ! patch -p0 < "$REPO_DIR/patches/readerview.lua.patch"; then
    echo "Error: failed to patch readerview.lua"
    echo "Your KOReader version may differ from the one these patches were made for."
    exit 1
fi
if ! patch -p0 < "$REPO_DIR/patches/readerhighlight.lua.patch"; then
    echo "Error: failed to patch readerhighlight.lua"
    echo "Your KOReader version may differ from the one these patches were made for."
    exit 1
fi

echo ""
echo "Installation complete."
echo "Backups saved to: $BACKUP_DIR"
echo "Restart KOReader to use Line Hints."
