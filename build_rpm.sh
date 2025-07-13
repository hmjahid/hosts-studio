#!/bin/bash
# Build script for Hosts Studio RPM package

set -e

echo "Hosts Studio - RPM Builder"
echo "=========================="

# Configuration
PACKAGE_NAME="hosts-studio"
PACKAGE_VERSION="1.0.0"
BUILD_DIR="$HOME/rpmbuild"
SOURCES_DIR="$BUILD_DIR/SOURCES"
SPECS_DIR="$BUILD_DIR/SPECS"
RPMS_DIR="$BUILD_DIR/RPMS"
SRPMS_DIR="$BUILD_DIR/SRPMS"

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

# Check if rpmbuild is available
if ! command -v rpmbuild &> /dev/null; then
    print_error "rpmbuild is not installed"
    print_warning "Please install rpm-build package:"
    echo "  Fedora/RHEL: sudo dnf install rpm-build"
    echo "  Ubuntu/Debian: sudo apt install rpm"
    exit 1
fi

# Check if rpmdevtools is available (for rpmdev-setuptree)
if ! command -v rpmdev-setuptree &> /dev/null; then
    print_warning "rpmdevtools not found. Installing..."
    sudo dnf install -y rpmdevtools
fi

# Setup RPM build tree
print_status "Setting up RPM build tree..."
rpmdev-setuptree

# Create source tarball
print_status "Creating source tarball..."
SOURCE_TARBALL="$SOURCES_DIR/${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.gz"

# Create temporary directory for source files
TEMP_SOURCE_DIR="/tmp/${PACKAGE_NAME}-${PACKAGE_VERSION}"
rm -rf "$TEMP_SOURCE_DIR"
mkdir -p "$TEMP_SOURCE_DIR"

# Copy source files
cp hosts_studio.py "$TEMP_SOURCE_DIR/"
cp README.md "$TEMP_SOURCE_DIR/" 2>/dev/null || true
cp USAGE.md "$TEMP_SOURCE_DIR/" 2>/dev/null || true
cp LICENSE "$TEMP_SOURCE_DIR/"
cp RPM_BUILD.md "$TEMP_SOURCE_DIR/" 2>/dev/null || true
cp MANUAL.md "$TEMP_SOURCE_DIR/" 2>/dev/null || true
cp PACKAGING.md "$TEMP_SOURCE_DIR/" 2>/dev/null || true
cp DEB_BUILD.md "$TEMP_SOURCE_DIR/" 2>/dev/null || true
cp AUR_BUILD.md "$TEMP_SOURCE_DIR/" 2>/dev/null || true
if [ -f hosts-studio.png ]; then
    cp hosts-studio.png "$TEMP_SOURCE_DIR/"
fi

# Create tarball
cd /tmp
tar -czf "$SOURCE_TARBALL" "${PACKAGE_NAME}-${PACKAGE_VERSION}"
cd - > /dev/null

# Clean up temp directory
rm -rf "$TEMP_SOURCE_DIR"

print_status "Source tarball created: $SOURCE_TARBALL"

# Copy spec file
print_status "Copying spec file..."
cp hosts-studio.spec "$SPECS_DIR/"

# Build RPM
print_status "Building RPM package..."
cd "$BUILD_DIR"

# Build both binary and source RPMs
rpmbuild -ba SPECS/hosts-studio.spec

cd - > /dev/null

# Check if RPM was created
RPM_FILE="$RPMS_DIR/noarch/${PACKAGE_NAME}-${PACKAGE_VERSION}-1.*.noarch.rpm"
if ls $RPM_FILE 1> /dev/null 2>&1; then
    RPM_FILE=$(ls $RPM_FILE | head -1)
    print_status "RPM package created successfully: $RPM_FILE"
    
    # Show package info
    print_status "Package information:"
    rpm -qip "$RPM_FILE"
    
    # Show package contents
    print_status "Package contents:"
    rpm -qlp "$RPM_FILE"
    
    print_status "RPM build completed successfully!"
    echo ""
    echo "To install the RPM package:"
    echo "  sudo dnf install $RPM_FILE"
    echo ""
    echo "To test the installation:"
    echo "  hosts-studio"
else
    print_error "Failed to create RPM package"
    exit 1
fi

print_status "Build completed successfully!" 