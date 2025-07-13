# Packaging Guide

## Overview

This document provides comprehensive guidance for packaging Hosts Studio for different Linux distributions and formats. It covers both AppImage and RPM packaging methods, along with best practices and troubleshooting.

## Table of Contents

1. [AppImage Packaging](#appimage-packaging)
2. [RPM Packaging](#rpm-packaging)
3. [Universal Packaging](#universal-packaging)
4. [Testing and Validation](#testing-and-validation)
5. [Distribution](#distribution)
6. [Troubleshooting](#troubleshooting)

## AppImage Packaging

### Overview

AppImage is a universal packaging format that allows applications to run on any Linux distribution without installation. It bundles the application with all its dependencies.

### Prerequisites

```bash
# Install AppImage tools
sudo dnf install appimage-builder appimagetool

# Or on Ubuntu/Debian
sudo apt install appimage-builder appimagetool
```

### AppImage Structure

```
AppDir/
├── AppRun                    # Main launcher script
├── hosts_studio.py          # Main application
├── hosts-studio.desktop     # Desktop integration
├── hosts-studio.appdata.xml # AppStream metadata
├── hosts-studio.png         # Application icon
└── usr/
    └── bin/
        └── hosts-studio     # Symlink to main script
```

### Building AppImage

#### 1. Create AppDir Structure

```bash
# Create AppDir
mkdir -p AppDir/usr/bin
mkdir -p AppDir/usr/share/applications
mkdir -p AppDir/usr/share/metainfo

# Copy application files
cp hosts_studio.py AppDir/
cp hosts-studio.desktop AppDir/usr/share/applications/
cp hosts-studio.appdata.xml AppDir/usr/share/metainfo/
cp hosts-studio.png AppDir/
```

#### 2. Create AppRun Script

```bash
cat > AppDir/AppRun << 'EOF'
#!/bin/bash
# Hosts Studio AppRun script

# Get the directory where this script is located
HERE="$(dirname "$(readlink -f "${0}")")"

# Always use extract-and-run to handle noexec mounts
if [ -n "$APPIMAGE" ]; then
    exec "$HERE/AppRun.wrapper" "$@"
else
    # Direct execution (for testing)
    exec python3 "$HERE/hosts_studio.py" "$@"
fi
EOF

chmod +x AppDir/AppRun
```

#### 3. Create Desktop File

```bash
cat > AppDir/usr/share/applications/hosts-studio.desktop << 'EOF'
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
```

#### 4. Create AppData File

```bash
cat > AppDir/usr/share/metainfo/hosts-studio.appdata.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>hosts-studio</id>
  <name>Hosts Studio</name>
  <summary>Safe GUI application for editing /etc/hosts file</summary>
  <description>
    <p>
      Hosts Studio is a safe and convenient GUI application for editing the /etc/hosts 
      file on Linux systems. It provides a clean interface built with tkinter for 
      viewing, adding, removing, and modifying IP-to-hostname mappings with automatic 
      backup creation and input validation.
    </p>
    <p>Features:</p>
    <ul>
      <li>Clean GUI interface built with tkinter</li>
      <li>View and edit hosts file entries in a structured format</li>
      <li>Add, remove, and modify IP-to-hostname mappings</li>
      <li>Input validation for IP addresses and hostnames</li>
      <li>Automatic backup creation before saving changes</li>
      <li>Search functionality to quickly find entries</li>
      <li>Root privilege handling for secure file operations</li>
    </ul>
  </description>
  <launchable type="desktop-id">hosts-studio.desktop</launchable>
  <url type="homepage">https://github.com/hosts-studio/hosts-studio</url>
  <url type="bugtracker">https://github.com/hosts-studio/hosts-studio/issues</url>
  <content_rating type="oars-1.1" />
  <releases>
    <release version="1.0.0" date="2024-01-01" />
  </releases>
</component>
EOF
```

#### 5. Build AppImage

```bash
# Create AppImage
appimagetool AppDir hosts-studio-1.0.0-x86_64.AppImage

# Make executable
chmod +x hosts-studio-1.0.0-x86_64.AppImage
```

### AppImage Optimization

#### Size Reduction

1. **Minimal Dependencies**: Only include essential Python modules
2. **System Libraries**: Use system Python and tkinter instead of bundling
3. **Compression**: Use efficient compression algorithms

#### Performance Optimization

1. **Lazy Loading**: Load modules only when needed
2. **Memory Management**: Proper cleanup of resources
3. **Startup Time**: Minimize initialization overhead

### AppImage Testing

```bash
# Test AppImage extraction
./hosts-studio-1.0.0-x86_64.AppImage --appimage-extract

# Test direct execution
./hosts-studio-1.0.0-x86_64.AppImage

# Test with AppImageLauncher
./hosts-studio-1.0.0-x86_64.AppImage --appimage-extract-and-run
```

## RPM Packaging

### Overview

RPM (Red Hat Package Manager) is the standard packaging format for Red Hat-based distributions. It provides dependency management, installation scripts, and system integration.

### Prerequisites

```bash
# Install RPM build tools
sudo dnf install rpm-build rpmdevtools

# Set up build environment
rpmdev-setuptree
```

### RPM Structure

```
hosts-studio.spec          # Package specification
build_rpm.sh              # Build script
hosts_studio.py           # Main application
README.md                 # Documentation
LICENSE                   # License file
```

### Building RPM

#### 1. Create Spec File

The spec file defines package metadata, dependencies, and installation instructions. See `hosts-studio.spec` for the complete specification.

#### 2. Build Process

```bash
# Run build script
./build_rpm.sh

# Or build manually
rpmbuild -ba hosts-studio.spec
```

#### 3. Package Verification

```bash
# Check package information
rpm -qip ~/rpmbuild/RPMS/noarch/hosts-studio-*.rpm

# List package contents
rpm -qlp ~/rpmbuild/RPMS/noarch/hosts-studio-*.rpm

# Check dependencies
rpm -qR ~/rpmbuild/RPMS/noarch/hosts-studio-*.rpm
```

### RPM Best Practices

#### 1. Dependencies

- **Runtime Dependencies**: Only include what's actually needed
- **Build Dependencies**: Separate from runtime dependencies
- **Version Constraints**: Use appropriate version ranges

#### 2. File Organization

- **Executables**: Install to `/usr/bin/`
- **Data Files**: Install to `/usr/share/package-name/`
- **Configuration**: Install to `/etc/` if needed
- **Documentation**: Include in package

#### 3. Security

- **File Permissions**: Set appropriate permissions
- **SELinux**: Include SELinux policies if needed
- **Privilege Escalation**: Use secure methods

## Universal Packaging

### Multi-Format Support

To support multiple packaging formats:

#### 1. Common Build Script

```bash
#!/bin/bash
# Universal build script

PACKAGE_NAME="hosts-studio"
VERSION="1.0.0"

# Build AppImage
build_appimage() {
    echo "Building AppImage..."
    # AppImage build commands
}

# Build RPM
build_rpm() {
    echo "Building RPM..."
    # RPM build commands
}

# Build DEB
build_deb() {
    echo "Building DEB..."
    # DEB build commands
}

# Main build logic
case "$1" in
    appimage) build_appimage ;;
    rpm) build_rpm ;;
    deb) build_deb ;;
    all) build_appimage && build_rpm && build_deb ;;
    *) echo "Usage: $0 {appimage|rpm|deb|all}" ;;
esac
```

#### 2. CI/CD Integration

```yaml
# GitHub Actions example
name: Build Packages

on:
  release:
    types: [published]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build AppImage
        run: ./build.sh appimage
      - name: Build RPM
        run: ./build.sh rpm
      - name: Upload artifacts
        uses: actions/upload-artifact@v2
```

## Testing and Validation

### Package Testing

#### 1. Installation Testing

```bash
# Test RPM installation
sudo dnf install --test ~/rpmbuild/RPMS/noarch/hosts-studio-*.rpm

# Test AppImage execution
./hosts-studio-*.AppImage --help

# Test uninstallation
sudo dnf remove hosts-studio
```

#### 2. Functionality Testing

```bash
# Test basic functionality
hosts-studio --version

# Test file operations
hosts-studio --test

# Test privilege escalation
hosts-studio --check-privileges
```

#### 3. Compatibility Testing

```bash
# Test on different distributions
# Fedora, RHEL, CentOS, Ubuntu, etc.

# Test with different Python versions
python3.6 hosts_studio.py
python3.7 hosts_studio.py
python3.8 hosts_studio.py
python3.9 hosts_studio.py
```

### Quality Assurance

#### 1. Code Quality

- **Linting**: Use flake8, pylint, or similar
- **Type Checking**: Use mypy for type annotations
- **Testing**: Unit tests and integration tests

#### 2. Security Scanning

```bash
# Scan for vulnerabilities
bandit -r hosts_studio.py

# Check for known vulnerabilities
safety check

# Static analysis
semgrep --config=auto .
```

#### 3. Performance Testing

```bash
# Measure startup time
time hosts-studio --version

# Memory usage
valgrind --tool=massif hosts-studio

# CPU profiling
python3 -m cProfile hosts_studio.py
```

## Distribution

### Release Process

#### 1. Version Management

```bash
# Update version in all files
sed -i 's/1.0.0/1.0.1/g' hosts-studio.spec build_rpm.sh

# Create git tag
git tag -a v1.0.1 -m "Release version 1.0.1"
git push origin v1.0.1
```

#### 2. Package Signing

```bash
# Generate GPG key
gpg --gen-key

# Sign packages
gpg --detach-sign hosts-studio-*.AppImage
rpm --addsign hosts-studio-*.rpm
```

#### 3. Repository Integration

```bash
# Create repository structure
mkdir -p repo/{RPMS,SRPMS,AppImages}

# Add packages
cp hosts-studio-*.rpm repo/RPMS/
cp hosts-studio-*.AppImage repo/AppImages/

# Create repository metadata
createrepo repo/
```

### Distribution Channels

#### 1. GitHub Releases

- Upload packages to GitHub releases
- Include release notes and changelog
- Provide installation instructions

#### 2. Package Repositories

- **Fedora COPR**: Community repository
- **EPEL**: Enterprise Linux repository
- **PPA**: Ubuntu personal package archive

#### 3. App Stores

- **Flathub**: Flatpak distribution
- **Snap Store**: Snap package distribution
- **AppImageHub**: AppImage distribution

## Troubleshooting

### Common Issues

#### 1. AppImage Issues

**Problem**: AppImage won't run
```bash
# Check if executable
chmod +x hosts-studio-*.AppImage

# Check dependencies
ldd hosts-studio-*.AppImage

# Run with debug output
./hosts-studio-*.AppImage --debug
```

**Problem**: Noexec mount error
```bash
# Use extract-and-run
./hosts-studio-*.AppImage --appimage-extract-and-run

# Or extract manually
./hosts-studio-*.AppImage --appimage-extract
cd squashfs-root
./AppRun
```

#### 2. RPM Issues

**Problem**: Build fails
```bash
# Check build environment
rpmdev-setuptree

# Check dependencies
sudo dnf install rpm-build rpmdevtools

# Check spec file syntax
rpmlint hosts-studio.spec
```

**Problem**: Installation fails
```bash
# Check package dependencies
rpm -qR hosts-studio-*.rpm

# Install missing dependencies
sudo dnf install python3 python3-tkinter polkit

# Test installation
sudo dnf install --test hosts-studio-*.rpm
```

#### 3. Dependency Issues

**Problem**: Missing Python modules
```bash
# Check Python installation
python3 --version

# Check tkinter
python3 -c "import tkinter; print('tkinter available')"

# Install missing packages
sudo dnf install python3-tkinter
```

### Debugging

#### 1. Log Analysis

```bash
# Check system logs
journalctl -f

# Check application logs
hosts-studio --log-level=DEBUG

# Check package installation logs
sudo dnf history info
```

#### 2. Environment Issues

```bash
# Check environment variables
env | grep -i python

# Check PATH
echo $PATH

# Check library paths
echo $LD_LIBRARY_PATH
```

#### 3. Permission Issues

```bash
# Check file permissions
ls -la /etc/hosts

# Check user permissions
id

# Check sudo configuration
sudo -l
```

### Performance Issues

#### 1. Slow Startup

- Check Python startup time
- Profile module imports
- Optimize initialization code

#### 2. Memory Usage

- Monitor memory consumption
- Check for memory leaks
- Optimize data structures

#### 3. File I/O

- Check disk I/O performance
- Optimize file operations
- Use efficient file formats

## Best Practices

### General Guidelines

1. **Consistency**: Use consistent naming and versioning
2. **Documentation**: Include comprehensive documentation
3. **Testing**: Test on multiple distributions and environments
4. **Security**: Follow security best practices
5. **Maintenance**: Keep packages updated and maintained

### Package-Specific Guidelines

#### AppImage

1. **Minimal Size**: Keep AppImage size as small as possible
2. **Compatibility**: Test on multiple distributions
3. **Integration**: Provide proper desktop integration
4. **Updates**: Support automatic updates if possible

#### RPM

1. **Dependencies**: Specify accurate dependencies
2. **Scripts**: Use proper pre/post install scripts
3. **Files**: Follow filesystem hierarchy standards
4. **Security**: Include security policies if needed

### Quality Standards

1. **Code Quality**: Follow coding standards and best practices
2. **Testing**: Comprehensive test coverage
3. **Documentation**: Clear and complete documentation
4. **Security**: Regular security audits and updates
5. **Performance**: Optimize for performance and resource usage

---

*This packaging guide covers Hosts Studio version 1.0.0. For the latest information, check the project documentation or repository.* 