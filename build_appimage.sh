#!/bin/bash
# Build script for Hosts Studio AppImage

set -e

echo "Hosts Studio - AppImage Builder"
echo "===================================="

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

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. It's recommended to run this script as a regular user."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

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
mkdir -p "$APP_DIR/usr/share/metainfo"
mkdir -p "$APP_DIR/usr/share/icons/hicolor/256x256/apps"

# Create .desktop file if missing
if [ ! -f "$APP_DIR/hosts-studio.desktop" ]; then
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
fi

# Create .appdata.xml file if missing
# if [ ! -f "$APP_DIR/hosts-studio.appdata.xml" ]; then
#     cat > "$APP_DIR/hosts-studio.appdata.xml" << 'EOF'
# <?xml version="1.0" encoding="UTF-8"?>
# <component type="desktop-application">
#   <id>com.github.hosts-studio</id>
#   <name>Hosts Studio</name>
#   <summary>Edit /etc/hosts file safely with a graphical interface</summary>
#   <metadata_license>CC0-1.0</metadata_license>
#   <description>
#     <p>
#       Hosts Studio is a safe and convenient GUI application for editing the /etc/hosts file on Linux systems.
#     </p>
#     <p>
#       Features:
#     </p>
#     <ul>
#       <li>Clean GUI interface built with tkinter</li>
#       <li>View and edit hosts file entries in a structured format</li>
#       <li>Add, remove, and modify IP-to-hostname mappings</li>
#       <li>Input validation for IP addresses and hostnames</li>
#       <li>Automatic backup creation before saving changes</li>
#       <li>Search functionality to quickly find entries</li>
#       <li>Root privilege handling for secure file operations</li>
#     </ul>
#     <p>
#       This application requires root privileges to modify /etc/hosts and automatically creates backups before making any changes.
#     </p>
#   </description>
#   <launchable type="desktop-id">hosts-studio.desktop</launchable>
#   <developer>
#     <name>Hosts Studio Team</name>
#   </developer>
#   <content_rating type="oars-1.1" />
#   <releases>
#     <release version="1.0.0" date="2024-01-01">
#       <description>
#         <p>Initial release with full hosts file editing capabilities</p>
#       </description>
#     </release>
#   </releases>
#   <categories>
#     <category>System</category>
#   </categories>
#   <keywords>
#     <keyword>hosts</keyword>
#     <keyword>network</keyword>
#     <keyword>dns</keyword>
#     <keyword>system</keyword>
#     <keyword>admin</keyword>
#   </keywords>
# </component>
# EOF
# fi

# Copy application files
print_status "Copying application files..."
cp hosts_studio.py "$APP_DIR/usr/share/hosts-studio/"
cp README.md "$APP_DIR/usr/share/hosts-studio/"
cp USAGE.md "$APP_DIR/usr/share/hosts-studio/"

# Copy desktop and metadata files
cp "$APP_DIR/hosts-studio.desktop" "$APP_DIR/usr/share/applications/"
# cp "$APP_DIR/hosts-studio.appdata.xml" "$APP_DIR/usr/share/metainfo/"

# Copy application icon
print_status "Copying application icon..."
if [ -f "hosts-studio.png" ]; then
    # Copy to AppDir root for AppImage compliance
    cp hosts-studio.png "$APP_DIR/hosts-studio.png"
    # Copy to standard icon location
    cp hosts-studio.png "$APP_DIR/usr/share/icons/hicolor/256x256/apps/hosts-studio.png"
    print_status "Icon copied successfully"
else
    print_warning "hosts-studio.png not found, creating default icon..."
    # Create a simple icon as fallback
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

    # Create PNG icon from SVG (requires rsvg-convert or similar)
    if command -v rsvg-convert &> /dev/null; then
        rsvg-convert -w 256 -h 256 "$APP_DIR/usr/share/icons/hicolor/256x256/apps/hosts-studio.svg" -o "$APP_DIR/usr/share/icons/hicolor/256x256/apps/hosts-studio.png"
    elif command -v inkscape &> /dev/null; then
        inkscape -w 256 -h 256 "$APP_DIR/usr/share/icons/hicolor/256x256/apps/hosts-studio.svg" -o "$APP_DIR/usr/share/icons/hicolor/256x256/apps/hosts-studio.png"
    else
        print_warning "Could not create PNG icon. Using SVG only."
    fi
fi

# Copy Python interpreter and libraries (optimized for size)
print_status "Copying Python interpreter and libraries..."

# Get Python path
PYTHON_PATH=$(which python3)
PYTHON_DIR=$(dirname "$PYTHON_PATH")

# Copy Python binary
cp "$PYTHON_PATH" "$APP_DIR/usr/bin/"

# Get Python version and site-packages
PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")

# Create minimal Python environment
mkdir -p "$APP_DIR/usr/lib/python${PYTHON_VERSION}/site-packages"

# Copy only essential Python libraries
PYTHON_LIB_DIR=$(python3 -c "import sys; print(sys.prefix + '/lib')")
if [ -d "$PYTHON_LIB_DIR" ]; then
    # Copy only essential libraries
    for lib in libpython${PYTHON_VERSION}.so* libpython${PYTHON_VERSION}m.so*; do
        if [ -f "$PYTHON_LIB_DIR/$lib" ]; then
            cp "$PYTHON_LIB_DIR/$lib" "$APP_DIR/usr/lib/" 2>/dev/null || true
        fi
    done
fi

# Copy tkinter and required modules from system Python
if [ -d "$PYTHON_LIB_DIR/python${PYTHON_VERSION}/tkinter" ]; then
    cp -r "$PYTHON_LIB_DIR/python${PYTHON_VERSION}/tkinter" "$APP_DIR/usr/lib/python${PYTHON_VERSION}/site-packages/" 2>/dev/null || true
fi

# Copy _tkinter.so from system Python lib
TKINTER_SO_SYSTEM=$(find "$PYTHON_LIB_DIR" -name "_tkinter*.so" 2>/dev/null | head -1)
if [ -n "$TKINTER_SO_SYSTEM" ]; then
    cp "$TKINTER_SO_SYSTEM" "$APP_DIR/usr/lib/python${PYTHON_VERSION}/site-packages/" 2>/dev/null || true
fi

# Copy minimal system libraries (only what Python needs)
print_status "Copying minimal system libraries..."
ldd "$PYTHON_PATH" | grep "=>" | awk '{print $3}' | while read lib; do
    if [ -f "$lib" ]; then
        # Only copy essential libraries
        libname=$(basename "$lib")
        case "$libname" in
            libc.so*|libdl.so*|libm.so*|libpthread.so*|libutil.so*|libz.so*|libssl.so*|libcrypto.so*|libtcl*.so*|libtk*.so*|libX11.so*|libXext.so*|libXft.so*|libfontconfig.so*|libfreetype.so*)
                cp "$lib" "$APP_DIR/usr/lib/" 2>/dev/null || true
                ;;
        esac
    fi
done

# Create AppRun in AppDir if missing
if [ ! -f "$APP_DIR/AppRun" ]; then
    cat > "$APP_DIR/AppRun" << 'EOF'
#!/bin/bash
HERE="$(dirname \"$(readlink -f \"${0}\")\")"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"

if [ -z "$HOSTS_STUDIO_PRIV_ESC" ]; then
    export HOSTS_STUDIO_PRIV_ESC=1
    if command -v pkexec >/dev/null 2>&1; then
        exec pkexec env HOSTS_STUDIO_PRIV_ESC=1 "$0" "$@"
    elif command -v gksudo >/dev/null 2>&1; then
        exec gksudo -- "$0" "$@"
    elif command -v kdesudo >/dev/null 2>&1; then
        exec kdesudo -- "$0" "$@"
    else
        echo "This application requires root privileges to modify /etc/hosts."
        echo "Please run with: sudo $0"
        exit 1
    fi
fi

exec python3 "${HERE}/usr/share/hosts-studio/hosts_studio.py" "$@"
EOF
    chmod +x "$APP_DIR/AppRun"
fi

# Make AppRun executable
chmod +x "$APP_DIR/AppRun"

# Create AppImage
print_status "Creating AppImage..."
APPIMAGE_NAME="${APP_NAME}-${APP_VERSION}-x86_64.AppImage"

# Use appimagetool to create the AppImage
ARCH=x86_64 ./$APPIMAGE_TOOL "$APP_DIR" "$APPIMAGE_NAME" || true

# Check if AppImage was created (ignore AppStream validation warnings)
if [ -f "$APPIMAGE_NAME" ]; then
    print_status "AppImage created successfully: $APPIMAGE_NAME"
    
    # Make AppImage executable
    chmod +x "$APPIMAGE_NAME"
    
    # Move to build directory
    mv "$APPIMAGE_NAME" "$BUILD_DIR/"
    
    print_status "AppImage is ready: $BUILD_DIR/$APPIMAGE_NAME"
    echo ""
    echo "To test the AppImage:"
    echo "  $BUILD_DIR/$APPIMAGE_NAME"
    echo ""
    echo "To install the AppImage:"
    echo "  chmod +x $BUILD_DIR/$APPIMAGE_NAME"
    echo "  ./$BUILD_DIR/$APPIMAGE_NAME"
else
    print_error "Failed to create AppImage"
    exit 1
fi

print_status "Build completed successfully!" 