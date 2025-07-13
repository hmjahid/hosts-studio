# AUR Build Documentation

## Overview

This document describes how to build and maintain AUR (Arch User Repository) packages for Hosts Studio, a GUI application for editing the `/etc/hosts` file on Linux systems. AUR packages are the community-driven packaging system for Arch Linux and its derivatives.

## Prerequisites

### Required Packages

Before building AUR packages, ensure you have the following packages installed:

```bash
# Arch Linux
sudo pacman -S base-devel git

# Additional tools for better packaging
sudo pacman -S namcap pkgbuild-introspection
```

### System Requirements

- Arch Linux or Arch-based distribution (Manjaro, EndeavourOS, etc.)
- Python 3.6 or later
- tkinter (usually included with Python)
- polkit (for privilege escalation)

## Build Process

### 1. Automatic Build

The easiest way to build the AUR package is using the provided build script:

```bash
# Make the script executable
chmod +x build_aur.sh

# Run the build script
./build_aur.sh
```

The build script will:
- Check for required dependencies
- Set up the AUR build environment
- Create the PKGBUILD
- Build the package
- Display package information and contents

### 2. Manual Build

If you prefer to build manually or need to customize the process:

```bash
# Clone or create the package directory
mkdir hosts-studio
cd hosts-studio

# Create PKGBUILD
# (See PKGBUILD example below)

# Build the package
makepkg -si

# Or build without installing
makepkg
```

## Package Structure

### AUR Package Contents

The AUR package includes:

- **PKGBUILD**: Package build script and metadata
- **.SRCINFO**: Source information for AUR
- **Main Application**: `hosts_studio.py` (installed to `/usr/share/hosts-studio/`)
- **Launcher Script**: `hosts-studio` (installed to `/usr/bin/`)
- **Desktop File**: `hosts-studio.desktop` (for application menu integration)
- **Icon**: `hosts-studio.svg` (fallback icon if PNG not available)
- **Documentation**: README.md, USAGE.md, LICENSE

### PKGBUILD Structure

```bash
# Maintainer: Your Name <your.email@example.com>
# Contributor: Another Name <another.email@example.com>
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
    # Installation steps
}
```

### Dependencies

The package requires:
- `python` - Python 3 runtime
- `tk` - Tkinter GUI framework
- `polkit` - PolicyKit for privilege escalation

## Installation

### Installing the AUR Package

```bash
# Install from AUR (if published)
yay -S hosts-studio

# Or install locally built package
sudo pacman -U hosts-studio-1.0.0-1-any.pkg.tar.zst

# Or install with makepkg
makepkg -si
```

### Verification

After installation, verify the package:

```bash
# Check if package is installed
pacman -Q hosts-studio

# List installed files
pacman -Ql hosts-studio

# Check package information
pacman -Qi hosts-studio
```

## AUR Publishing

### Creating the AUR Package

1. **Create PKGBUILD**: Write the package build script
2. **Create .SRCINFO**: Generate source information
3. **Test locally**: Build and test the package
4. **Submit to AUR**: Upload to the Arch User Repository

### PKGBUILD Example

```bash
# Maintainer: Your Name <your.email@example.com>
pkgname=hosts-studio
pkgver=1.0.0
pkgrel=1
pkgdesc="A safe GUI application for editing /etc/hosts file"
arch=('any')
url="https://github.com/hosts-studio/hosts-studio"
license=('MIT')
depends=('python' 'tk' 'polkit')
makedepends=()
source=("$pkgname-$pkgver.tar.gz::https://github.com/hosts-studio/hosts-studio/archive/v$pkgver.tar.gz")
sha256sums=('SKIP')

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
```

### Creating .SRCINFO

Generate the .SRCINFO file for AUR:

```bash
# Generate .SRCINFO
makepkg --printsrcinfo > .SRCINFO
```

### Publishing to AUR

1. **Create AUR account**: Register at https://aur.archlinux.org
2. **Add SSH key**: Add your SSH public key to your AUR account
3. **Clone AUR repository**: Clone the AUR repository for your package
4. **Add files**: Add PKGBUILD, .SRCINFO, and other necessary files
5. **Commit and push**: Commit changes and push to AUR

```bash
# Clone AUR repository (if it exists)
git clone ssh://aur@aur.archlinux.org/hosts-studio.git
cd hosts-studio

# Add your files
cp ../PKGBUILD .
cp ../.SRCINFO .

# Commit and push
git add .
git commit -m "Initial release"
git push origin master
```

## Troubleshooting

### Common Issues

1. **Missing Dependencies**
   ```
   Error: Package requires python
   ```
   Solution: Install the required package:
   ```bash
   sudo pacman -S python
   ```

2. **Build Environment Issues**
   ```
   Error: Cannot find PKGBUILD
   ```
   Solution: Ensure you're in the correct directory with PKGBUILD file.

3. **Permission Issues**
   ```
   Error: Permission denied
   ```
   Solution: Ensure you have write permissions to the build directory.

### Build Verification

To verify the build process:

```bash
# Check package contents
tar -tvf hosts-studio-*.pkg.tar.zst

# Validate package structure
namcap hosts-studio-*.pkg.tar.zst

# Test installation
sudo pacman -U hosts-studio-*.pkg.tar.zst
```

## Customization

### Modifying PKGBUILD

The PKGBUILD file contains all package metadata and build instructions:

- **Header**: Package metadata, dependencies, and descriptions
- **prepare()**: Preparation steps
- **build()**: Build instructions
- **check()**: Test instructions
- **package()**: Installation instructions

### Version Updates

To update the package version:

1. Update version in PKGBUILD
2. Update .SRCINFO
3. Rebuild the package
4. Update AUR repository

### Adding Files

To include additional files:

1. Add files to the appropriate directory in the package() function
2. Update dependencies if needed
3. Rebuild the package

## Distribution

### AUR Repository

Once published to AUR, users can install your package with:

```bash
# Using yay (recommended)
yay -S hosts-studio

# Using paru
paru -S hosts-studio

# Using pacaur (deprecated)
pacaur -S hosts-studio
```

### Local Repository

Create a local repository for testing:

```bash
# Create repository directory
mkdir -p repo

# Add packages
cp hosts-studio-*.pkg.tar.zst repo/

# Create repository database
repo-add repo/hosts-studio.db.tar.gz repo/hosts-studio-*.pkg.tar.zst

# Add to pacman.conf
echo "[hosts-studio]" >> /etc/pacman.conf
echo "SigLevel = Optional TrustAll" >> /etc/pacman.conf
echo "Server = file:///path/to/repo" >> /etc/pacman.conf
```

## Best Practices

1. **Always test builds** in a clean environment
2. **Use consistent versioning** across all files
3. **Include comprehensive documentation**
4. **Test installation and uninstallation**
5. **Verify all dependencies** are correctly specified
6. **Use meaningful package descriptions**
7. **Include proper licensing information**
8. **Follow AUR packaging guidelines**
9. **Use namcap** to check package quality
10. **Keep .SRCINFO updated**

## Support

For issues with the AUR build process:

1. Check the troubleshooting section above
2. Review build logs and error messages
3. Verify all dependencies are installed
4. Ensure proper file permissions
5. Check AUR packaging documentation
6. Consult the Arch Linux forums

## References

- [AUR User Guidelines](https://wiki.archlinux.org/title/AUR_user_guidelines)
- [PKGBUILD](https://wiki.archlinux.org/title/PKGBUILD)
- [Arch Packaging Standards](https://wiki.archlinux.org/title/Arch_packaging_standards)
- [Creating Packages](https://wiki.archlinux.org/title/Creating_packages)
- [AUR Submission Guidelines](https://wiki.archlinux.org/title/AUR_submission_guidelines) 