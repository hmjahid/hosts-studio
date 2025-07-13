#!/bin/bash
# Wrapper script to run Hosts Studio AppImage with extract-and-run option
# This avoids issues with AppImageLauncher mounting

SCRIPT_DIR="$(dirname "$(readlink -f "${0}")")"
APPIMAGE="$SCRIPT_DIR/build/hosts-studio-1.0.0-x86_64.AppImage"

if [ ! -f "$APPIMAGE" ]; then
    echo "Error: AppImage not found at $APPIMAGE"
    echo "Please run ./build_optimized_appimage.sh first to build the AppImage"
    exit 1
fi

echo "Starting Hosts Studio..."
echo "Note: Using --appimage-extract-and-run to avoid mounting issues"
echo ""

exec "$APPIMAGE" --appimage-extract-and-run "$@" 