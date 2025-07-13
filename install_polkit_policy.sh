#!/bin/bash
# Install polkit policy for Hosts Studio

echo "Installing polkit policy for Hosts Studio..."

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script needs to be run as root to install the polkit policy."
    echo "Please run: sudo $0"
    exit 1
fi

# Copy the policy file
POLICY_DIR="/usr/share/polkit-1/actions"
POLICY_FILE="hosts-studio.policy"
TARGET_FILE="$POLICY_DIR/com.hosts-studio.policy"

if [ ! -f "$POLICY_FILE" ]; then
    echo "Error: Policy file $POLICY_FILE not found in current directory."
    exit 1
fi

echo "Installing policy to $TARGET_FILE..."
cp "$POLICY_FILE" "$TARGET_FILE"

if [ $? -eq 0 ]; then
    echo "Policy installed successfully!"
    echo "You may need to restart your session or log out/in for changes to take effect."
else
    echo "Error: Failed to install policy."
    exit 1
fi 