#!/bin/bash
set -e

APP=hosts-studio
VERSION=1.0.0

# Clean previous build
rm -rf AppDir
mkdir -p AppDir/usr/bin

# Copy your app
cp hosts_studio.py AppDir/usr/bin/
cp hosts-studio.desktop AppDir/
cp hosts-studio.png AppDir/

# Make sure linuxdeploy is executable
chmod +x linuxdeploy-x86_64.AppImage

# Make the Python plugin executable
chmod +x linuxdeploy-plugin-python.sh

# Build AppImage using linuxdeploy with custom Python plugin
export VERSION
./linuxdeploy-x86_64.AppImage --appdir AppDir \
  --desktop-file AppDir/hosts-studio.desktop \
  --icon-file AppDir/hosts-studio.png \
  --output appimage \
  --plugin linuxdeploy-plugin-python.sh

echo "AppImage build complete!" 