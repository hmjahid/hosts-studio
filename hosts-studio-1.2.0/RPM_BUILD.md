# RPM Build Documentation

## Overview

This document describes how to build RPM packages for Hosts Studio, a GUI application for editing the `/etc/hosts` file on Linux systems.

## Prerequisites

### Required Packages

Before building RPM packages, ensure you have the following packages installed:

```bash
# Fedora/RHEL/CentOS
sudo dnf install rpm-build rpmdevtools

# Ubuntu/Debian
sudo apt install rpm rpmdevtools
```

### System Requirements

- Linux distribution with RPM support (Fedora, RHEL, CentOS, etc.)
- Python 3.6 or later
- tkinter (usually included with Python)
- polkit (for privilege escalation)

## Build Process

### 1. Automatic Build

The easiest way to build the RPM is using the provided build script:

```bash
# Make the script executable
chmod +x build_rpm.sh

# Run the build script
./build_rpm.sh
```

The build script will:
- Check for required dependencies
- Set up the RPM build tree
- Create a source tarball
- Build both binary and source RPMs
- Display package information and contents

### 2. Manual Build

If you prefer to build manually or need to customize the process:

```bash
# Set up RPM build tree
rpmdev-setuptree

# Create source tarball
tar -czf ~/rpmbuild/SOURCES/hosts-studio-1.0.0.tar.gz \
    hosts_studio.py README.md USAGE.md LICENSE hosts-studio.png

# Copy spec file
cp hosts-studio.spec ~/rpmbuild/SPECS/

# Build RPM
cd ~/rpmbuild
rpmbuild -ba SPECS/hosts-studio.spec
```

## Package Structure

### Files Included

The RPM package includes:

- **Main Application**: `hosts_studio.py` (installed to `/usr/share/hosts-studio/`)
- **Launcher Script**: `hosts-studio` (installed to `/usr/bin/`)
- **Desktop File**: `hosts-studio.desktop` (for application menu integration)
- **Icon**: `hosts-studio.svg` (fallback icon if PNG not available)
- **Documentation**: README.md, USAGE.md, LICENSE

### Dependencies

The package requires:
- `python3` - Python 3 runtime
- `python3-tkinter` - Tkinter GUI framework
- `polkit` - PolicyKit for privilege escalation

## Installation

### Installing the RPM

```bash
# Install the built RPM
sudo dnf install ~/rpmbuild/RPMS/noarch/hosts-studio-1.0.0-1.*.noarch.rpm

# Or if you have the RPM file locally
sudo dnf install hosts-studio-1.0.0-1.*.noarch.rpm
```

### Verification

After installation, verify the package:

```bash
# Check if package is installed
rpm -q hosts-studio

# List installed files
rpm -ql hosts-studio

# Check package information
rpm -qi hosts-studio
```

## Troubleshooting

### Common Issues

1. **Missing Dependencies**
   ```
   Error: Package requires python3-tkinter
   ```
   Solution: Install the required package:
   ```bash
   sudo dnf install python3-tkinter
   ```

2. **Build Tree Issues**
   ```
   Error: Directory /home/user/rpmbuild does not exist
   ```
   Solution: Run `rpmdev-setuptree` to create the build tree.

3. **Permission Issues**
   ```
   Error: Permission denied
   ```
   Solution: Ensure you have write permissions to the build directory.

### Build Verification

To verify the build process:

```bash
# Check RPM contents
rpm -qlp ~/rpmbuild/RPMS/noarch/hosts-studio-*.rpm

# Validate RPM structure
rpm -K ~/rpmbuild/RPMS/noarch/hosts-studio-*.rpm

# Test installation in a clean environment
sudo dnf install --test ~/rpmbuild/RPMS/noarch/hosts-studio-*.rpm
```

## Customization

### Modifying the Spec File

The `hosts-studio.spec` file contains all package metadata and build instructions. Key sections:

- **Header**: Package name, version, dependencies
- **%description**: Package description
- **%install**: Installation instructions
- **%files**: File list and permissions

### Version Updates

To update the package version:

1. Update version in `hosts-studio.spec`
2. Update version in `build_rpm.sh`
3. Rebuild the package

### Adding Files

To include additional files:

1. Add files to the source directory
2. Update the `%install` section in the spec file
3. Add files to the `%files` section

## Distribution

### Repository Integration

To integrate with a repository:

```bash
# Create repository structure
mkdir -p repo/RPMS/noarch
cp ~/rpmbuild/RPMS/noarch/hosts-studio-*.rpm repo/RPMS/noarch/

# Create repository metadata
createrepo repo/

# Serve repository (example with Python)
cd repo && python3 -m http.server 8000
```

### Signing Packages

For production distribution, sign your packages:

```bash
# Generate GPG key (if not exists)
gpg --gen-key

# Sign the RPM
rpm --addsign ~/rpmbuild/RPMS/noarch/hosts-studio-*.rpm

# Verify signature
rpm -K ~/rpmbuild/RPMS/noarch/hosts-studio-*.rpm
```

## Best Practices

1. **Always test builds** in a clean environment
2. **Use consistent versioning** across all files
3. **Include comprehensive documentation**
4. **Test installation and uninstallation**
5. **Verify all dependencies** are correctly specified
6. **Use meaningful package descriptions**
7. **Include proper licensing information**

## Support

For issues with the RPM build process:

1. Check the troubleshooting section above
2. Review RPM build logs in `~/rpmbuild/BUILD/`
3. Verify all dependencies are installed
4. Ensure proper file permissions

## References

- [RPM Packaging Guide](https://rpm-packaging-guide.github.io/)
- [Fedora Packaging Guidelines](https://docs.fedoraproject.org/en-US/packaging-guidelines/)
- [RPM Build Documentation](https://docs.fedoraproject.org/en-US/quick-docs/creating-rpm-packages/) 