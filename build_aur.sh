#!/bin/bash
# Build script for Hosts Studio AUR package

set -e

echo "Hosts Studio - AUR Builder"
echo "=========================="

# Configuration
PACKAGE_NAME="hosts-studio"
PACKAGE_VERSION="1.0.0"
PACKAGE_RELEASE="1"
BUILD_DIR="build_aur"
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

# Check if makepkg is available
if ! command -v makepkg &> /dev/null; then
    print_error "makepkg is not installed"
    print_warning "Please install base-devel package:"
    echo "  sudo pacman -S base-devel"
    exit 1
fi

# Check if namcap is available
if ! command -v namcap &> /dev/null; then
    print_warning "namcap not found. Installing..."
    sudo pacman -S namcap
fi

# Clean previous build
print_status "Cleaning previous build..."
rm -rf "$BUILD_DIR"
rm -rf "$SOURCE_DIR"
rm -f "${PACKAGE_NAME}-${PACKAGE_VERSION}-${PACKAGE_RELEASE}-any.pkg.tar.zst"

# Create build directory
print_status "Creating build directory..."
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Create source directory structure
print_status "Creating package structure..."
mkdir -p "$SOURCE_DIR"
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

# Create PKGBUILD
print_status "Creating PKGBUILD..."
cat > PKGBUILD << 'EOF'
# Maintainer: Hosts Studio Team <hosts-studio@example.com>
pkgname=hosts-studio
pkgver=1.0.0
pkgrel=1
pkgdesc="A safe GUI application for editing /etc/hosts file"
arch=('any')
url="https://github.com/hosts-studio/hosts-studio"
license=('MIT')
depends=('python' 'tk' 'polkit')
makedepends=()
optdepends=()
provides=()
conflicts=()
replaces=()
backup=()
options=()
install=
changelog=
source=("$pkgname-$pkgver.tar.gz")
noextract=()
md5sums=('SKIP')
validpgpkeys=()

prepare() {
    cd "$pkgname-$pkgver"
    # Preparation steps
}

build() {
    cd "$pkgname-$pkgver"
    # Build steps (if any)
}

check() {
    cd "$pkgname-$pkgver"
    # Test steps (if any)
}

package() {
    cd "$pkgname-$pkgver"
    
    # Create directory structure
    install -dm755 "$pkgdir/usr/share/$pkgname"
    install -dm755 "$pkgdir/usr/bin"
    install -dm755 "$pkgdir/usr/share/applications"
    install -dm755 "$pkgdir/usr/share/icons/hicolor/256x256/apps"
    
    # Install main application
    install -m755 hosts_studio.py "$pkgdir/usr/share/$pkgname/"
    install -m644 README.md "$pkgdir/usr/share/$pkgname/" 2>/dev/null || true
    install -m644 USAGE.md "$pkgdir/usr/share/$pkgname/" 2>/dev/null || true
    install -m644 LICENSE "$pkgdir/usr/share/$pkgname/"
    install -m644 RPM_BUILD.md "$pkgdir/usr/share/$pkgname/" 2>/dev/null || true
    install -m644 MANUAL.md "$pkgdir/usr/share/$pkgname/" 2>/dev/null || true
    install -m644 PACKAGING.md "$pkgdir/usr/share/$pkgname/" 2>/dev/null || true
    install -m644 DEB_BUILD.md "$pkgdir/usr/share/$pkgname/" 2>/dev/null || true
    install -m644 AUR_BUILD.md "$pkgdir/usr/share/$pkgname/" 2>/dev/null || true
    
    # Create launcher script
    cat > "$pkgdir/usr/bin/$pkgname" << 'EOF'
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
    chmod +x "$pkgdir/usr/bin/$pkgname"
    
    # Install desktop file
    cat > "$pkgdir/usr/share/applications/$pkgname.desktop" << 'EOF'
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
    
    # Install icon
    if [ -f hosts-studio.png ]; then
        install -m644 hosts-studio.png "$pkgdir/usr/share/icons/hicolor/256x256/apps/"
    else
        # Create a simple SVG icon as fallback
        cat > "$pkgdir/usr/share/icons/hicolor/256x256/apps/$pkgname.svg" << 'EOF'
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
}
EOF

# Create source tarball
print_status "Creating source tarball..."
tar -czf "${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.gz" "$SOURCE_DIR"

# Build AUR package
print_status "Building AUR package..."
makepkg -f

# Check if package was created
PACKAGE_FILE="${PACKAGE_NAME}-${PACKAGE_VERSION}-${PACKAGE_RELEASE}-any.pkg.tar.zst"
if [ -f "$PACKAGE_FILE" ]; then
    print_status "AUR package created successfully: $PACKAGE_FILE"
    
    # Show package info
    print_status "Package information:"
    pacman -Qip "$PACKAGE_FILE"
    
    # Show package contents
    print_status "Package contents:"
    pacman -Qlp "$PACKAGE_FILE"
    
    # Validate package
    print_status "Validating package with namcap..."
    namcap "$PACKAGE_FILE" || print_warning "Namcap found some issues (this is normal for initial packages)"
    
    # Generate .SRCINFO for AUR
    print_status "Generating .SRCINFO for AUR..."
    makepkg --printsrcinfo > .SRCINFO
    
    print_status "AUR build completed successfully!"
    echo ""
    echo "To install the AUR package:"
    echo "  sudo pacman -U $PACKAGE_FILE"
    echo ""
    echo "To publish to AUR:"
    echo "  1. Create AUR account at https://aur.archlinux.org"
    echo "  2. Add SSH key to your AUR account"
    echo "  3. Clone AUR repository: git clone ssh://aur@aur.archlinux.org/hosts-studio.git"
    echo "  4. Copy PKGBUILD and .SRCINFO to the repository"
    echo "  5. Commit and push: git add . && git commit -m 'Initial release' && git push origin master"
    echo ""
    echo "To test the installation:"
    echo "  hosts-studio"
else
    print_error "Failed to create AUR package"
    exit 1
fi

print_status "Build completed successfully!" 