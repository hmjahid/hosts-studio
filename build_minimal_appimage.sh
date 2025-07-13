#!/bin/bash
# Minimal build script for Hosts Studio AppImage

set -e

echo "Hosts Studio - Minimal AppImage Builder"
echo "========================================"

# Configuration
APP_NAME="hosts-studio"
APP_VERSION="1.0.0"
APP_DIR="AppDir"
BUILD_DIR="build"
APPIMAGE_TOOL="appimagetool"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
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
    exit 1
fi

# Check if appimagetool is available
if ! command -v $APPIMAGE_TOOL &> /dev/null; then
    print_warning "appimagetool not found. Attempting to download..."
    
    # Download appimagetool
    APPIMAGE_TOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    wget -O $APPIMAGE_TOOL "$APPIMAGE_TOOL_URL"
    chmod +x $APPIMAGE_TOOL
    print_status "Downloaded appimagetool"
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
mkdir -p "$APP_DIR/usr/share/icons/hicolor/256x256/apps"

# Create .desktop file
cat > "$APP_DIR/hosts-studio.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Hosts Studio
GenericName=Hosts Studio
Comment=Edit /etc/hosts file safely with a graphical interface
Exec=hosts-studio
Icon=hosts-studio
Terminal=true
Categories=System;
Keywords=hosts;network;dns;system;admin;
StartupNotify=true
StartupWMClass=hosts-studio
EOF

# Copy application files
print_status "Copying application files..."
cp hosts_studio.py "$APP_DIR/usr/share/hosts-studio/"
cp README.md "$APP_DIR/usr/share/hosts-studio/" 2>/dev/null || true
cp USAGE.md "$APP_DIR/usr/share/hosts-studio/" 2>/dev/null || true

# Copy desktop file
cp "$APP_DIR/hosts-studio.desktop" "$APP_DIR/usr/share/applications/"

# Copy application icon
print_status "Copying application icon..."
if [ -f "hosts-studio.png" ]; then
    cp hosts-studio.png "$APP_DIR/hosts-studio.png"
    cp hosts-studio.png "$APP_DIR/usr/share/icons/hicolor/256x256/apps/hosts-studio.png"
    print_status "Icon copied successfully"
else
    print_warning "hosts-studio.png not found, creating default icon..."
    # Create a simple SVG icon
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
fi

# Create AppRun script
print_status "Creating AppRun script..."
cat > "$APP_DIR/AppRun" << 'EOF'
#!/bin/sh
# AppRun: Handle both mounted and extracted AppImage cases

# Get the directory where this script is located
HERE="$(dirname "$(readlink -f "$0")")"

# Check if we're running from a mounted AppImage (has APPIMAGE env var)
if [ -n "$APPIMAGE" ]; then
    # We're in a mounted AppImage, always extract and run
    exec "$APPIMAGE" --appimage-extract-and-run "$@"
fi

# We're running from an extracted AppImage
# Privilege escalation
if [ -z "$HOSTS_STUDIO_PRIV_ESC" ]; then
    export HOSTS_STUDIO_PRIV_ESC=1
    if command -v pkexec >/dev/null 2>&1; then
        exec pkexec env HOSTS_STUDIO_PRIV_ESC=1 DISPLAY="$DISPLAY" XAUTHORITY="$XAUTHORITY" "$0" "$@"
    elif command -v gksudo >/dev/null 2>&1; then
        exec gksudo -- "$0" "$@"
    elif command -v kdesudo >/dev/null 2>&1; then
        exec kdesudo -- "$0" "$@"
    else
        echo "This application requires root privileges to modify /etc/hosts."
        echo "Please run with: sudo DISPLAY=\$DISPLAY $0"
        exit 1
    fi
fi

# Use absolute path to the Python script and change to the correct directory
cd "$HERE"
exec python3 "${HERE}/usr/share/hosts-studio/hosts_studio.py" "$@"
EOF

chmod +x "$APP_DIR/AppRun"

# Create AppImage
print_status "Creating AppImage..."
APPIMAGE_NAME="${APP_NAME}-${APP_VERSION}-x86_64.AppImage"

# Use appimagetool to create the AppImage
ARCH=x86_64 ./$APPIMAGE_TOOL "$APP_DIR" "$APPIMAGE_NAME" || true

# Check if AppImage was created
if [ -f "$APPIMAGE_NAME" ]; then
    print_status "AppImage created successfully: $APPIMAGE_NAME"
    
    # Make AppImage executable
    chmod +x "$APPIMAGE_NAME"
    
    # Move to build directory
    mv "$APPIMAGE_NAME" "$BUILD_DIR/"
    
    print_status "AppImage is ready: $BUILD_DIR/$APPIMAGE_NAME"
    echo ""
    echo "To test the AppImage:"
    echo "  $BUILD_DIR/$APPIMAGE_NAME --appimage-extract-and-run"
    echo ""
    echo "To install the AppImage:"
    echo "  chmod +x $BUILD_DIR/$APPIMAGE_NAME"
    echo "  ./$BUILD_DIR/$APPIMAGE_NAME"
else
    print_error "Failed to create AppImage"
    exit 1
fi

print_status "Build completed successfully!" 