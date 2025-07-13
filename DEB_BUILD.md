# DEB Build Documentation

## Overview

This document describes how to build DEB packages for Hosts Studio, a GUI application for editing the `/etc/hosts` file on Linux systems. DEB packages are the standard packaging format for Debian-based distributions (Debian, Ubuntu, Linux Mint, etc.).

## Prerequisites

### Required Packages

Before building DEB packages, ensure you have the following packages installed:

```bash
# Debian/Ubuntu
sudo apt update
sudo apt install build-essential devscripts debhelper dh-python python3-all python3-setuptools

# Additional tools for better packaging
sudo apt install lintian pbuilder cowbuilder
```

### System Requirements

- Debian-based Linux distribution (Debian, Ubuntu, Linux Mint, etc.)
- Python 3.6 or later
- tkinter (usually included with Python)
- polkit (for privilege escalation)

## Build Process

### 1. Automatic Build

The easiest way to build the DEB is using the provided build script:

```bash
# Make the script executable
chmod +x build_deb.sh

# Run the build script
./build_deb.sh
```

The build script will:
- Check for required dependencies
- Set up the DEB build environment
- Create the package structure
- Build the DEB package
- Display package information and contents

### 2. Manual Build

If you prefer to build manually or need to customize the process:

```bash
# Create package directory structure
mkdir -p hosts-studio-1.0.0/debian
mkdir -p hosts-studio-1.0.0/usr/share/hosts-studio
mkdir -p hosts-studio-1.0.0/usr/bin
mkdir -p hosts-studio-1.0.0/usr/share/applications
mkdir -p hosts-studio-1.0.0/usr/share/icons/hicolor/256x256/apps

# Copy source files
cp hosts_studio.py hosts-studio-1.0.0/usr/share/hosts-studio/
cp README.md hosts-studio-1.0.0/usr/share/hosts-studio/ 2>/dev/null || true
cp USAGE.md hosts-studio-1.0.0/usr/share/hosts-studio/ 2>/dev/null || true
cp LICENSE hosts-studio-1.0.0/usr/share/hosts-studio/

# Create debian control files
# (See debian/ directory structure below)

# Build the package
cd hosts-studio-1.0.0
dpkg-buildpackage -b -us -uc
```

## Package Structure

### DEB Package Contents

The DEB package includes:

- **Main Application**: `hosts_studio.py` (installed to `/usr/share/hosts-studio/`)
- **Launcher Script**: `hosts-studio` (installed to `/usr/bin/`)
- **Desktop File**: `hosts-studio.desktop` (for application menu integration)
- **Icon**: `hosts-studio.svg` (fallback icon if PNG not available)
- **Documentation**: README.md, USAGE.md, LICENSE

### Debian Directory Structure

```
hosts-studio-1.0.0/
├── debian/
│   ├── changelog          # Package changelog
│   ├── control            # Package metadata and dependencies
│   ├── copyright          # Copyright information
│   ├── rules              # Build rules
│   ├── postinst           # Post-installation script
│   ├── postrm             # Post-removal script
│   ├── prerm              # Pre-removal script
│   └── hosts-studio.install # File installation list
├── usr/
│   ├── bin/
│   │   └── hosts-studio   # Launcher script
│   ├── share/
│   │   ├── hosts-studio/
│   │   │   ├── hosts_studio.py
│   │   │   ├── README.md
│   │   │   ├── USAGE.md
│   │   │   └── LICENSE
│   │   ├── applications/
│   │   │   └── hosts-studio.desktop
│   │   └── icons/
│   │       └── hicolor/
│   │           └── 256x256/
│   │               └── apps/
│   │                   └── hosts-studio.svg
└── hosts_studio.py        # Main application
```

### Dependencies

The package requires:
- `python3` - Python 3 runtime
- `python3-tk` - Tkinter GUI framework
- `policykit-1` - PolicyKit for privilege escalation

## Installation

### Installing the DEB

```bash
# Install the built DEB package
sudo dpkg -i hosts-studio_1.0.0-1_all.deb

# Fix any dependency issues
sudo apt-get install -f

# Or install with apt
sudo apt install ./hosts-studio_1.0.0-1_all.deb
```

### Verification

After installation, verify the package:

```bash
# Check if package is installed
dpkg -l | grep hosts-studio

# List installed files
dpkg -L hosts-studio

# Check package information
dpkg -s hosts-studio
```

## Troubleshooting

### Common Issues

1. **Missing Dependencies**
   ```
   Error: Package requires python3-tk
   ```
   Solution: Install the required package:
   ```bash
   sudo apt install python3-tk
   ```

2. **Build Environment Issues**
   ```
   Error: Cannot find debian/rules
   ```
   Solution: Ensure you're in the correct directory with debian/ subdirectory.

3. **Permission Issues**
   ```
   Error: Permission denied
   ```
   Solution: Ensure you have write permissions to the build directory.

### Build Verification

To verify the build process:

```bash
# Check DEB contents
dpkg -c hosts-studio_*.deb

# Validate DEB structure
lintian hosts-studio_*.deb

# Test installation in a clean environment
sudo pbuilder --build hosts-studio_*.dsc
```

## Customization

### Modifying Control Files

The debian/ directory contains all package metadata and build instructions:

- **control**: Package metadata, dependencies, and descriptions
- **rules**: Build instructions and customization
- **changelog**: Package version history
- **copyright**: License and copyright information

### Version Updates

To update the package version:

1. Update version in `debian/changelog`
2. Update version in `debian/control`
3. Rebuild the package

### Adding Files

To include additional files:

1. Add files to the appropriate directory in the package structure
2. Update `debian/hosts-studio.install` if needed
3. Rebuild the package

## Distribution

### Repository Integration

To integrate with a repository:

```bash
# Create repository structure
mkdir -p repo/conf repo/db repo/pool/main/h/hosts-studio

# Add packages
cp hosts-studio_*.deb repo/pool/main/h/hosts-studio/

# Create repository metadata
cd repo
dpkg-scanpackages . /dev/null > Packages
gzip -k -f Packages
```

### Signing Packages

For production distribution, sign your packages:

```bash
# Generate GPG key (if not exists)
gpg --gen-key

# Sign the DEB
dpkg-sig --sign builder hosts-studio_*.deb

# Verify signature
dpkg-sig --verify hosts-studio_*.deb
```

## Best Practices

1. **Always test builds** in a clean environment
2. **Use consistent versioning** across all files
3. **Include comprehensive documentation**
4. **Test installation and uninstallation**
5. **Verify all dependencies** are correctly specified
6. **Use meaningful package descriptions**
7. **Include proper licensing information**
8. **Follow Debian packaging guidelines**

## Support

For issues with the DEB build process:

1. Check the troubleshooting section above
2. Review build logs in the debian/ directory
3. Verify all dependencies are installed
4. Ensure proper file permissions
5. Check Debian packaging documentation

## References

- [Debian Packaging Guide](https://www.debian.org/doc/manuals/maint-guide/)
- [Ubuntu Packaging Guide](https://packaging.ubuntu.com/html/)
- [Debian Policy Manual](https://www.debian.org/doc/debian-policy/)
- [Python Packaging for Debian](https://wiki.debian.org/Python/Packaging) 