#!/bin/bash
# Build script for Hosts Studio DEB package

set -e

echo "Hosts Studio - DEB Builder"
echo "=========================="

# Configuration
PACKAGE_NAME="hosts-studio"
PACKAGE_VERSION="1.0.0"
PACKAGE_RELEASE="1"
BUILD_DIR="build_deb"
SOURCE_DIR="${PACKAGE_NAME}-${PACKAGE_VERSION}"

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

# Check if dpkg-buildpackage is available
if ! command -v dpkg-buildpackage &> /dev/null; then
    print_error "dpkg-buildpackage is not installed"
    print_warning "Please install build-essential and devscripts packages:"
    echo "  sudo apt update"
    echo "  sudo apt install build-essential devscripts debhelper dh-python python3-all python3-setuptools"
    exit 1
fi

# Check if lintian is available
if ! command -v lintian &> /dev/null; then
    print_warning "lintian not found. Installing..."
    sudo apt install -y lintian
fi

# Clean previous build
print_status "Cleaning previous build..."
rm -rf "$BUILD_DIR"
rm -rf "$SOURCE_DIR"
rm -f "${PACKAGE_NAME}_${PACKAGE_VERSION}-${PACKAGE_RELEASE}_all.deb"

# Create build directory
print_status "Creating build directory..."
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Create source directory structure
print_status "Creating package structure..."
mkdir -p "$SOURCE_DIR/debian"
mkdir -p "$SOURCE_DIR/usr/share/$PACKAGE_NAME"
mkdir -p "$SOURCE_DIR/usr/bin"
mkdir -p "$SOURCE_DIR/usr/share/applications"
mkdir -p "$SOURCE_DIR/usr/share/icons/hicolor/256x256/apps"

# Copy source files
print_status "Copying source files..."
cp ../hosts_studio.py "$SOURCE_DIR/usr/share/$PACKAGE_NAME/"
cp ../README.md "$SOURCE_DIR/usr/share/$PACKAGE_NAME/" 2>/dev/null || true
cp ../USAGE.md "$SOURCE_DIR/usr/share/$PACKAGE_NAME/" 2>/dev/null || true
cp ../LICENSE "$SOURCE_DIR/usr/share/$PACKAGE_NAME/"
cp ../RPM_BUILD.md "$SOURCE_DIR/usr/share/$PACKAGE_NAME/" 2>/dev/null || true
cp ../MANUAL.md "$SOURCE_DIR/usr/share/$PACKAGE_NAME/" 2>/dev/null || true
cp ../PACKAGING.md "$SOURCE_DIR/usr/share/$PACKAGE_NAME/" 2>/dev/null || true
cp ../DEB_BUILD.md "$SOURCE_DIR/usr/share/$PACKAGE_NAME/" 2>/dev/null || true
cp ../AUR_BUILD.md "$SOURCE_DIR/usr/share/$PACKAGE_NAME/" 2>/dev/null || true

if [ -f ../hosts-studio.png ]; then
    cp ../hosts-studio.png "$SOURCE_DIR/usr/share/icons/hicolor/256x256/apps/"
fi

# Create debian control file
print_status "Creating debian/control..."
cat > "$SOURCE_DIR/debian/control" << 'EOF'
Source: hosts-studio
Section: admin
Priority: optional
Maintainer: Hosts Studio Team <hosts-studio@example.com>
Build-Depends: debhelper (>= 11), dh-python, python3-all, python3-setuptools
Standards-Version: 4.5.1
Homepage: https://github.com/hosts-studio/hosts-studio

Package: hosts-studio
Architecture: all
Depends: ${python3:Depends}, ${misc:Depends}, python3-tk, policykit-1
Description: Safe GUI application for editing /etc/hosts file
 Hosts Studio is a safe and convenient GUI application for editing the /etc/hosts 
 file on Linux systems. It provides a clean interface built with tkinter for 
 viewing, adding, removing, and modifying IP-to-hostname mappings with automatic 
 backup creation and input validation.
 .
 Features:
  * Clean GUI interface built with tkinter
  * View and edit hosts file entries in a structured format
  * Add, remove, and modify IP-to-hostname mappings
  * Input validation for IP addresses and hostnames
  * Automatic backup creation before saving changes
  * Search functionality to quickly find entries
  * Root privilege handling for secure file operations
EOF

# Create debian/changelog
print_status "Creating debian/changelog..."
cat > "$SOURCE_DIR/debian/changelog" << EOF
hosts-studio (${PACKAGE_VERSION}-${PACKAGE_RELEASE}) unstable; urgency=medium

  * Initial release of Hosts Studio
  * Safe GUI application for editing /etc/hosts file
  * Automatic backup creation and input validation
  * Support for multiple privilege escalation methods

 -- Hosts Studio Team <hosts-studio@example.com>  $(date -R)
EOF

# Create debian/copyright
print_status "Creating debian/copyright..."
cat > "$SOURCE_DIR/debian/copyright" << 'EOF'
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: hosts-studio
Source: https://github.com/hosts-studio/hosts-studio

Files: *
Copyright: 2024 Hosts Studio Team
License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
EOF

# Create debian/rules
print_status "Creating debian/rules..."
cat > "$SOURCE_DIR/debian/rules" << 'EOF'
#!/usr/bin/make -f

%:
	dh $@

override_dh_auto_install:
	# No build step needed for Python application
	# Files are already in place
EOF

chmod +x "$SOURCE_DIR/debian/rules"

# Create debian/hosts-studio.install
print_status "Creating debian/hosts-studio.install..."
cat > "$SOURCE_DIR/debian/hosts-studio.install" << 'EOF'
usr/share/hosts-studio/* usr/share/hosts-studio/
usr/bin/hosts-studio usr/bin/
usr/share/applications/hosts-studio.desktop usr/share/applications/
usr/share/icons/hicolor/256x256/apps/hosts-studio.* usr/share/icons/hicolor/256x256/apps/
EOF

# Create launcher script
print_status "Creating launcher script..."
cat > "$SOURCE_DIR/usr/bin/hosts-studio" << 'EOF'
#!/bin/bash
# Hosts Studio launcher script

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    exec python3 /usr/share/hosts-studio/hosts_studio.py "$@"
else
    # Use pkexec for privilege escalation
    if command -v pkexec >/dev/null 2>&1; then
        exec pkexec env DISPLAY="$DISPLAY" XAUTHORITY="$XAUTHORITY" python3 /usr/share/hosts-studio/hosts_studio.py "$@"
    elif command -v gksudo >/dev/null 2>&1; then
        exec gksudo -- python3 /usr/share/hosts-studio/hosts_studio.py "$@"
    elif command -v kdesudo >/dev/null 2>&1; then
        exec kdesudo -- python3 /usr/share/hosts-studio/hosts_studio.py "$@"
    else
        echo "This application requires root privileges to modify /etc/hosts."
        echo "Please run with: sudo DISPLAY=\$DISPLAY python3 /usr/share/hosts-studio/hosts_studio.py"
        exit 1
    fi
fi
EOF

chmod +x "$SOURCE_DIR/usr/bin/hosts-studio"

# Create desktop file
print_status "Creating desktop file..."
cat > "$SOURCE_DIR/usr/share/applications/hosts-studio.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Hosts Studio
GenericName=Hosts Studio
Comment=Edit /etc/hosts file safely with a graphical interface
Exec=hosts-studio
Icon=hosts-studio
Terminal=false
Categories=System;
Keywords=hosts;network;dns;system;admin;
StartupNotify=true
StartupWMClass=hosts-studio
EOF

# Create fallback icon if PNG not available
if [ ! -f "$SOURCE_DIR/usr/share/icons/hicolor/256x256/apps/hosts-studio.png" ]; then
    print_status "Creating fallback SVG icon..."
    cat > "$SOURCE_DIR/usr/share/icons/hicolor/256x256/apps/hosts-studio.svg" << 'EOF'
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

# Build DEB package
print_status "Building DEB package..."
cd "$SOURCE_DIR"

# Build the package
dpkg-buildpackage -b -us -uc

cd ..

# Check if DEB was created
DEB_FILE="${PACKAGE_NAME}_${PACKAGE_VERSION}-${PACKAGE_RELEASE}_all.deb"
if [ -f "$DEB_FILE" ]; then
    print_status "DEB package created successfully: $DEB_FILE"
    
    # Show package info
    print_status "Package information:"
    dpkg -I "$DEB_FILE"
    
    # Show package contents
    print_status "Package contents:"
    dpkg -c "$DEB_FILE"
    
    # Validate package
    print_status "Validating package with lintian..."
    lintian "$DEB_FILE" || print_warning "Lintian found some issues (this is normal for initial packages)"
    
    print_status "DEB build completed successfully!"
    echo ""
    echo "To install the DEB package:"
    echo "  sudo dpkg -i $DEB_FILE"
    echo "  sudo apt-get install -f  # Fix any dependency issues"
    echo ""
    echo "To test the installation:"
    echo "  hosts-studio"
else
    print_error "Failed to create DEB package"
    exit 1
fi

print_status "Build completed successfully!" 