#!/bin/bash

set -e

INSTALL_PATH="/usr/local/bin/fsx"

echo "Uninstalling FSX..."

if [ ! -f "$INSTALL_PATH" ]; then
    echo "fsx is not installed at $INSTALL_PATH"
    exit 1
fi

sudo rm "$INSTALL_PATH"

echo "FSX successfully removed."

if command -v fsx >/dev/null 2>&1; then
    echo "fsx still exists in PATH (maybe installed elsewhere)"
else
    echo "fsx is no longer available globally."
fi