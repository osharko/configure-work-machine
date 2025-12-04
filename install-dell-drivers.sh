#!/bin/bash

# Standalone script to install Dell OEM drivers on Pop!_OS/Ubuntu
# Can be run directly with:
# curl -sfL https://raw.githubusercontent.com/osharko/configure-work-machine/develop/install-dell-drivers.sh | bash -

set -e

SCRIPT_URL="https://raw.githubusercontent.com/osharko/configure-work-machine/develop/popos/dell-oem-drivers.sh"
TEMP_SCRIPT=$(mktemp)

echo "Downloading Dell OEM driver installation script..."
if curl -fsSL "$SCRIPT_URL" -o "$TEMP_SCRIPT"; then
    chmod +x "$TEMP_SCRIPT"
    echo "✓ Script downloaded"
    echo ""
    bash "$TEMP_SCRIPT"
    rm -f "$TEMP_SCRIPT"
else
    echo "✗ Failed to download script"
    rm -f "$TEMP_SCRIPT"
    exit 1
fi
