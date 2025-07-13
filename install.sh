#!/bin/bash
# Installation script for Hosts File Editor

echo "Hosts File Editor - Installation Script"
echo "========================================"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Warning: Running as root. It's recommended to run this script as a regular user."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check Python version
echo "Checking Python version..."
python3 --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Python 3 is not installed or not available as 'python3'"
    echo "Please install Python 3.6 or higher"
    exit 1
fi

# Check tkinter availability
echo "Checking tkinter availability..."
python3 -c "import tkinter" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: tkinter is not available"
    echo "Please install tkinter for your distribution:"
    echo "  Ubuntu/Debian: sudo apt-get install python3-tk"
    echo "  Fedora/RHEL: sudo dnf install python3-tkinter"
    echo "  Arch: sudo pacman -S tk"
    exit 1
fi

# Make script executable
echo "Making hosts_editor.py executable..."
chmod +x hosts_editor.py

# Create desktop shortcut (optional)
read -p "Create desktop shortcut? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    DESKTOP_DIR="$HOME/Desktop"
    if [ ! -d "$DESKTOP_DIR" ]; then
        DESKTOP_DIR="$HOME/桌面"  # Chinese desktop
    fi
    if [ ! -d "$DESKTOP_DIR" ]; then
        DESKTOP_DIR="$HOME/Рабочий стол"  # Russian desktop
    fi
    
    if [ -d "$DESKTOP_DIR" ]; then
        cat > "$DESKTOP_DIR/hosts-editor.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Hosts File Editor
Comment=Edit /etc/hosts file safely
Exec=sudo python3 $(pwd)/hosts_editor.py
Icon=text-editor
Terminal=true
Categories=System;Network;
EOF
        chmod +x "$DESKTOP_DIR/hosts-editor.desktop"
        echo "Desktop shortcut created at: $DESKTOP_DIR/hosts-editor.desktop"
    else
        echo "Could not find desktop directory"
    fi
fi

# Create system-wide installation (optional)
read -p "Install system-wide? (requires sudo) (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ "$EUID" -ne 0 ]; then
        echo "Installing system-wide..."
        sudo cp hosts_editor.py /usr/local/bin/hosts-editor
        sudo chmod +x /usr/local/bin/hosts-editor
        echo "Installed to /usr/local/bin/hosts-editor"
        echo "You can now run: sudo hosts-editor"
    else
        cp hosts_editor.py /usr/local/bin/hosts-editor
        chmod +x /usr/local/bin/hosts-editor
        echo "Installed to /usr/local/bin/hosts-editor"
        echo "You can now run: sudo hosts-editor"
    fi
fi

echo ""
echo "Installation completed!"
echo ""
echo "Usage:"
echo "  sudo python3 hosts_editor.py"
echo ""
echo "Features:"
echo "  - View and edit /etc/hosts file"
echo "  - Add, remove, and modify entries"
echo "  - Automatic backup creation"
echo "  - Input validation"
echo "  - Search functionality"
echo ""
echo "For more information, see README.md" 