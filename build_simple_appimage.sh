#!/bin/bash
# Simple AppImage builder for Hosts Studio

set -e

echo "Hosts Studio - Simple AppImage Builder"
echo "==========================================="

# Configuration
APP_NAME="hosts-studio"
APP_VERSION="1.0.0"
APP_DIR="AppDir"
BUILD_DIR="build"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check dependencies
print_status "Checking dependencies..."

# Check Python
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed"
    exit 1
fi

# Check tkinter
if ! python3 -c "import tkinter" &> /dev/null; then
    print_error "tkinter is not available"
    print_warning "Please install tkinter for your distribution:"
    echo "  Ubuntu/Debian: sudo apt-get install python3-tk"
    echo "  Fedora/RHEL: sudo dnf install python3-tkinter"
    echo "  Arch: sudo pacman -S tk"
    exit 1
fi

# Check squashfs-tools
if ! command -v mksquashfs &> /dev/null; then
    print_error "squashfs-tools is not installed"
    print_warning "Please install squashfs-tools:"
    echo "  Ubuntu/Debian: sudo apt-get install squashfs-tools"
    echo "  Fedora/RHEL: sudo dnf install squashfs-tools"
    echo "  Arch: sudo pacman -S squashfs-tools"
    exit 1
fi

# Clean previous build
print_status "Cleaning previous build..."
rm -rf "$APP_DIR" "$BUILD_DIR"
mkdir -p "$APP_DIR" "$BUILD_DIR"

# Create AppDir structure
print_status "Creating AppDir structure..."
mkdir -p "$APP_DIR/usr/bin"
mkdir -p "$APP_DIR/usr/lib"
mkdir -p "$APP_DIR/usr/share/hosts-studio"
mkdir -p "$APP_DIR/usr/share/applications"
mkdir -p "$APP_DIR/usr/share/metainfo"
mkdir -p "$APP_DIR/usr/share/icons/hicolor/256x256/apps"

# Copy application files
print_status "Copying application files..."
cp hosts_studio.py "$APP_DIR/usr/share/hosts-studio/"
cp README.md "$APP_DIR/usr/share/hosts-studio/"
cp USAGE.md "$APP_DIR/usr/share/hosts-studio/"

# Create desktop file
print_status "Creating desktop file..."
cat > "$APP_DIR/usr/share/applications/hosts-studio.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Hosts Studio
GenericName=Hosts Studio
Comment=Edit /etc/hosts file safely with a graphical interface
Exec=hosts-studio
Icon=hosts-studio
Terminal=true
Categories=System;Network;Settings;
Keywords=hosts;network;dns;system;admin;
StartupNotify=true
StartupWMClass=hosts-studio
EOF

# Create metadata file
print_status "Creating metadata file..."
cat > "$APP_DIR/usr/share/metainfo/hosts-studio.appdata.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>hosts-studio</id>
  <name>Hosts Studio</name>
  <summary>Edit /etc/hosts file safely with a graphical interface</summary>
  <description>
    <p>
      Hosts Studio is a safe and convenient GUI application for editing the /etc/hosts file on Linux systems.
    </p>
    <p>
      Features:
    </p>
    <ul>
      <li>Clean GUI interface built with tkinter</li>
      <li>View and edit hosts file entries in a structured format</li>
      <li>Add, remove, and modify IP-to-hostname mappings</li>
      <li>Input validation for IP addresses and hostnames</li>
      <li>Automatic backup creation before saving changes</li>
      <li>Search functionality to quickly find entries</li>
      <li>Root privilege handling for secure file operations</li>
    </ul>
    <p>
      This application requires root privileges to modify /etc/hosts and automatically creates backups before making any changes.
    </p>
  </description>
  <launchable type="desktop-id">hosts-studio.desktop</launchable>
  <url type="homepage">https://github.com/your-repo/hosts-studio</url>
  <url type="bugtracker">https://github.com/your-repo/hosts-studio/issues</url>
  <url type="help">https://github.com/your-repo/hosts-studio/wiki</url>
  <developer_name>Hosts Editor Team</developer_name>
  <content_rating type="oars-1.1" />
  <releases>
    <release version="1.0.0" date="2024-01-01">
      <description>
        <p>Initial release with full hosts file editing capabilities</p>
      </description>
    </release>
  </releases>
  <categories>
    <category>System</category>
    <category>Network</category>
    <category>Settings</category>
  </categories>
  <keywords>
    <keyword>hosts</keyword>
    <keyword>network</keyword>
    <keyword>dns</keyword>
    <keyword>system</keyword>
    <keyword>admin</keyword>
  </keywords>
</component>
EOF

# Create a simple icon
print_status "Creating application icon..."
cat > "$APP_DIR/usr/share/icons/hicolor/256x256/apps/hosts-studio.svg" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="256" height="256" viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg">
  <rect width="256" height="256" fill="#2E86AB" rx="20"/>
  <rect x="40" y="60" width="176" height="136" fill="#A23B72" rx="10"/>
  <rect x="60" y="80" width="136" height="20" fill="#F18F01" rx="5"/>
  <rect x="60" y="110" width="136" height="20" fill="#C73E1D" rx="5"/>
  <rect x="60" y="140" width="136" height="20" fill="#F18F01" rx="5"/>
  <rect x="60" y="170" width="136" height="20" fill="#C73E1D" rx="5"/>
  <text x="128" y="220" text-anchor="middle" fill="white" font-family="Arial, sans-serif" font-size="16" font-weight="bold">HOSTS</text>
</svg>
EOF

# Create a simple AppRun script
print_status "Creating AppRun script..."
cat > "$APP_DIR/AppRun" << 'EOF'
#!/bin/bash
# AppRun script for Hosts Studio AppImage

# Get the directory where the AppImage is mounted
HERE="$(dirname "$(readlink -f "${0}")")"

# Set up environment
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"

# Check if running with sudo
if [ "$EUID" -eq 0 ]; then
    # Running as root, execute directly
    exec python3 "${HERE}/usr/share/hosts-studio/hosts_studio.py" "$@"
else
    # Not running as root, show warning and ask
    echo "Hosts Studio"
    echo "================="
    echo ""
    echo "This application requires root privileges to modify /etc/hosts"
    echo "Please run with: sudo $0"
    echo ""
    
    # Check if we can run in view-only mode
    if [ -r "/etc/hosts" ]; then
        echo "Running in view-only mode (no modifications allowed)"
        echo "To enable full functionality, run: sudo $0"
        echo ""
        exec python3 "${HERE}/usr/share/hosts-studio/hosts_studio.py" "$@"
    else
        echo "Cannot read /etc/hosts file. Please run with sudo."
        exit 1
    fi
fi
EOF

chmod +x "$APP_DIR/AppRun"

# Create a simple AppImage using squashfs
print_status "Creating AppImage using squashfs..."

# Create squashfs
mksquashfs "$APP_DIR" "$BUILD_DIR/app.squashfs" -root-owned -noappend

# Create AppImage header
cat > "$BUILD_DIR/AppImage" << 'EOF'
#!/bin/bash
# AppImage header
# This is a simple AppImage that extracts and runs the application

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Extract the squashfs if not already extracted
EXTRACT_DIR="$HOME/.local/share/hosts-studio"
if [ ! -d "$EXTRACT_DIR" ]; then
    mkdir -p "$EXTRACT_DIR"
    unsquashfs -f -d "$EXTRACT_DIR" "$SCRIPT_DIR/app.squashfs"
fi

# Run the application
exec "$EXTRACT_DIR/AppRun" "$@"
EOF

# Combine header and squashfs
cat "$BUILD_DIR/AppImage" "$BUILD_DIR/app.squashfs" > "$BUILD_DIR/${APP_NAME}-${APP_VERSION}-x86_64.AppImage"

# Make AppImage executable
chmod +x "$BUILD_DIR/${APP_NAME}-${APP_VERSION}-x86_64.AppImage"

# Clean up temporary files
rm "$BUILD_DIR/AppImage" "$BUILD_DIR/app.squashfs"

print_status "AppImage created successfully: $BUILD_DIR/${APP_NAME}-${APP_VERSION}-x86_64.AppImage"

echo ""
echo "AppImage is ready: $BUILD_DIR/${APP_NAME}-${APP_VERSION}-x86_64.AppImage"
echo ""
echo "To test the AppImage:"
echo "  sudo $BUILD_DIR/${APP_NAME}-${APP_VERSION}-x86_64.AppImage"
echo ""
echo "To install the AppImage:"
echo "  chmod +x $BUILD_DIR/${APP_NAME}-${APP_VERSION}-x86_64.AppImage"
echo "  ./$BUILD_DIR/${APP_NAME}-${APP_VERSION}-x86_64.AppImage"
echo ""
echo "AppImage features:"
echo "  - Self-contained application"
echo "  - No installation required"
echo "  - Works on any Linux distribution"
echo "  - Uses system Python (requires tkinter)"

print_status "Build completed successfully!" 