# Hosts Studio

A safe and convenient GUI application for adding, removing and editing the `/etc/hosts` file on Linux systems.

## Features

- **Clean GUI Interface**: Easy-to-use graphical interface built with tkinter
- **View Current Entries**: Display all hosts file entries in a structured table format
- **Add New Entries**: Simple form to add new IP-to-hostname mappings
- **Edit Existing Entries**: Modify IP addresses, hostnames, and comments
- **Remove/Disable Entries**: Remove entries or toggle them on/off (commenting)
- **Input Validation**: Validates IP addresses (IPv4, IPv6, localhost) and hostnames
- **Automatic Backups**: Creates timestamped backups before saving changes
- **Graphical Privilege Escalation**: Uses pkexec/gksudo/kdesudo for secure privilege requests
- **Search Functionality**: Real-time search to quickly find specific entries
- **Status Feedback**: Clear status messages and error handling
- **Multi-Format Packaging**: Support for RPM, DEB, AUR, and AppImage packages

## Requirements

- Python 3.6 or higher (for source code)
- tkinter (usually included with Python)
- polkit (for privilege escalation)
- Root privileges for modifying `/etc/hosts`

## Installation

### Option 1: AppImage (Recommended)
1. Download the `hosts-studio-1.0.0-x86_64.AppImage` file
2. Make it executable:
   ```bash
   chmod +x hosts-studio-1.0.0-x86_64.AppImage
   ```
3. Run the AppImage using one of these methods:

   **Method A: Using the wrapper script (Recommended)**
   ```bash
   ./run_hosts_studio.sh
   ```

   **Method B: Direct AppImage with extract-and-run**
   ```bash
   ./hosts-studio-1.0.0-x86_64.AppImage --appimage-extract-and-run
   ```

   **Method C: Traditional AppImage (may have mounting issues)**
   ```bash
   ./hosts-studio-1.0.0-x86_64.AppImage
   ```

### Option 2: Package Manager Installation

#### RPM Package (Fedora, RHEL, CentOS)
```bash
# Install the RPM package
sudo dnf install hosts-studio-1.0.0-1.*.noarch.rpm

# Or if you have the RPM file locally
sudo dnf install ./hosts-studio-1.0.0-1.*.noarch.rpm
```

#### DEB Package (Debian, Ubuntu, Linux Mint)
```bash
# Install the DEB package
sudo dpkg -i hosts-studio_1.0.0-1_all.deb

# Fix any dependency issues
sudo apt-get install -f

# Or install with apt
sudo apt install ./hosts-studio_1.0.0-1_all.deb
```

#### AUR Package (Arch Linux, Manjaro)
```bash
# Install from AUR (if published)
yay -S hosts-studio

# Or install locally built package
sudo pacman -U hosts-studio-1.0.0-1-any.pkg.tar.zst
```

### Option 3: Source Code
1. Clone or download the application files
2. Install dependencies:
   ```bash
   # Fedora/RHEL/CentOS
   sudo dnf install python3 python3-tkinter polkit
   
   # Debian/Ubuntu
   sudo apt install python3 python3-tk policykit-1
   
   # Arch Linux
   sudo pacman -S python tk polkit
   ```
3. Run the application:
   ```bash
   python3 hosts_studio.py
   ```

## Package Building

Hosts Studio supports multiple packaging formats for different Linux distributions. Each package includes comprehensive documentation and proper system integration.

### Available Build Scripts

- `build_rpm.sh` - Build RPM packages for Red Hat-based distributions
- `build_deb.sh` - Build DEB packages for Debian-based distributions  
- `build_aur.sh` - Build AUR packages for Arch Linux
- `build_appimage.sh` - Build AppImage for universal distribution

### Building RPM Packages (Fedora, RHEL, CentOS)

#### Prerequisites
```bash
# Install RPM build tools
sudo dnf install rpm-build rpmdevtools

# Set up build environment
rpmdev-setuptree
```

#### Build Process
```bash
# Make the script executable
chmod +x build_rpm.sh

# Run the build script
./build_rpm.sh
```

The script will:
- Check for required dependencies
- Set up the RPM build tree
- Create a source tarball
- Build both binary and source RPMs
- Display package information and contents

#### Installation
```bash
# Install the built RPM
sudo dnf install ~/rpmbuild/RPMS/noarch/hosts-studio-1.0.0-1.*.noarch.rpm
```

### Building DEB Packages (Debian, Ubuntu, Linux Mint)

#### Prerequisites
```bash
# Install DEB build tools
sudo apt update
sudo apt install build-essential devscripts debhelper dh-python python3-all python3-setuptools lintian
```

#### Build Process
```bash
# Make the script executable
chmod +x build_deb.sh

# Run the build script
./build_deb.sh
```

The script will:
- Check for required dependencies
- Set up the DEB build environment
- Create the package structure
- Build the DEB package
- Validate with lintian

#### Installation
```bash
# Install the built DEB
sudo dpkg -i hosts-studio_1.0.0-1_all.deb
sudo apt-get install -f  # Fix any dependency issues
```

### Building AUR Packages (Arch Linux, Manjaro)

#### Prerequisites
```bash
# Install AUR build tools
sudo pacman -S base-devel namcap
```

#### Build Process
```bash
# Make the script executable
chmod +x build_aur.sh

# Run the build script
./build_aur.sh
```

The script will:
- Check for required dependencies
- Set up the AUR build environment
- Create the PKGBUILD
- Build the package
- Generate .SRCINFO for AUR publishing

#### Installation
```bash
# Install the built package
sudo pacman -U hosts-studio-1.0.0-1-any.pkg.tar.zst
```

#### Publishing to AUR
```bash
# Clone AUR repository (if it exists)
git clone ssh://aur@aur.archlinux.org/hosts-studio.git
cd hosts-studio

# Copy build files
cp ../build_aur/PKGBUILD .
cp ../build_aur/.SRCINFO .

# Commit and push
git add .
git commit -m "Initial release"
git push origin master
```

### Building AppImage (Universal)

#### Prerequisites
```bash
# Install AppImage tools
sudo dnf install appimage-builder appimagetool
# Or on Ubuntu/Debian
sudo apt install appimage-builder appimagetool
```

#### Build Process
```bash
# Make the script executable
chmod +x build_appimage.sh

# Run the build script
./build_appimage.sh
```

The script will:
- Create the AppDir structure
- Copy application files
- Create desktop integration
- Build the AppImage
- Make it executable

## Package Contents

All packages include:

### Core Application
- **Main Application**: `hosts_studio.py` (installed to `/usr/share/hosts-studio/`)
- **Launcher Script**: `hosts-studio` (installed to `/usr/bin/`)
- **Desktop File**: `hosts-studio.desktop` (for application menu integration)
- **Icon**: `hosts-studio.svg` (fallback icon if PNG not available)

### Documentation
- **README.md** - Project overview and basic usage
- **USAGE.md** - Detailed usage guide
- **MANUAL.md** - Comprehensive user manual
- **RPM_BUILD.md** - RPM packaging guide
- **DEB_BUILD.md** - DEB packaging guide
- **AUR_BUILD.md** - AUR packaging guide
- **PACKAGING.md** - Universal packaging guide
- **LICENSE** - MIT license

### Dependencies
- **python3** - Python 3 runtime
- **python3-tkinter/tk** - Tkinter GUI framework
- **polkit** - PolicyKit for privilege escalation

## Usage

### Running the Application

#### Package Installation
```bash
# After installing any package
hosts-studio
```

#### AppImage
```bash
# Use the wrapper script (recommended)
./run_hosts_studio.sh

# Or run with extract-and-run option
./hosts-studio-1.0.0-x86_64.AppImage --appimage-extract-and-run
```

#### Source Code
```bash
# Run with sudo for full functionality
sudo python3 hosts_studio.py

# Or run without sudo for viewing only
python3 hosts_studio.py
```

### Basic Operations

1. **Viewing Entries**: The application automatically loads and displays all current hosts file entries
2. **Adding Entries**: Click "Add Entry" and fill in the IP address and hostnames
3. **Editing Entries**: Select an entry and click "Edit Entry" to modify it
4. **Removing Entries**: Select an entry and click "Remove Entry" (with confirmation dialog)
5. **Toggling Entries**: Select an entry and click "Toggle Entry" to enable/disable it
6. **Searching**: Use the search box to filter entries by IP, hostname, or comment
7. **Saving Changes**: Click "Save Changes" to write modifications to `/etc/hosts` (with confirmation)

### Example Entries

```
127.0.0.1 localhost
127.0.0.1 mycustomdomain.test
192.168.1.100 myserver.local
::1 localhost ip6-localhost ip6-loopback
```

## File Structure

### Source Files
- `hosts_studio.py` - Main application file
- `README.md` - Project documentation
- `USAGE.md` - Detailed usage guide
- `MANUAL.md` - Comprehensive user manual
- `LICENSE` - MIT license

### Build Scripts
- `build_rpm.sh` - RPM package builder
- `build_deb.sh` - DEB package builder
- `build_aur.sh` - AUR package builder
- `build_appimage.sh` - AppImage builder

### Documentation
- `RPM_BUILD.md` - RPM packaging guide
- `DEB_BUILD.md` - DEB packaging guide
- `AUR_BUILD.md` - AUR packaging guide
- `PACKAGING.md` - Universal packaging guide

### Package Files
- `hosts-studio.spec` - RPM spec file
- `hosts-studio-1.0.0-x86_64.AppImage` - Portable executable
- `run_hosts_studio.sh` - AppImage wrapper script

## Backup System

The application automatically creates backups in `/tmp/hosts_backups/` with timestamps:
- Format: `hosts_backup_YYYYMMDD_HHMMSS`
- Backups are created before any file modifications
- Manual backups can be created using the "Create Backup" button

## Security Features

- **Graphical Privilege Escalation**: Uses pkexec/gksudo/kdesudo for secure privilege requests
- **Input Validation**: Validates all IP addresses and hostnames before saving
- **Safe File Operations**: Uses temporary files for secure file writing
- **Backup Protection**: Always creates backups before making changes
- **Confirmation Dialogs**: All destructive operations require user confirmation

## Troubleshooting

### Package Installation Issues

#### RPM Package
```bash
# Check dependencies
rpm -qR hosts-studio-*.rpm

# Install missing dependencies
sudo dnf install python3 python3-tkinter polkit

# Test installation
sudo dnf install --test hosts-studio-*.rpm
```

#### DEB Package
```bash
# Check dependencies
dpkg -I hosts-studio_*.deb

# Install missing dependencies
sudo apt install python3 python3-tk policykit-1

# Fix broken packages
sudo apt-get install -f
```

#### AUR Package
```bash
# Check dependencies
pacman -Qip hosts-studio-*.pkg.tar.zst

# Install missing dependencies
sudo pacman -S python tk polkit

# Validate package
namcap hosts-studio-*.pkg.tar.zst
```

### Permission Denied Errors
- The application will automatically request privileges using a graphical dialog
- For source code, ensure you're running with `sudo`

### File Not Found Errors
- Verify that `/etc/hosts` exists on your system
- Ensure you have read permissions for the file

### Validation Errors
- Check that IP addresses are in valid format (e.g., `192.168.1.1`)
- Ensure hostnames follow proper naming conventions
- IPv6 addresses are supported in basic format

### AppImage Issues
- Make sure the AppImage is executable: `chmod +x hosts-studio-1.0.0-x86_64.AppImage`
- If privilege escalation fails, try running with: `sudo ./hosts-studio-1.0.0-x86_64.AppImage`

## AppImageLauncher Integration

**Important Note:** Due to system security policies, AppImageLauncher may mount AppImages with `noexec` permissions, which prevents the application from running when double-clicked. This is a known limitation on some Linux distributions.

### ✅ **Working Methods:**

**Method 1: Use the wrapper script (Recommended)**
```bash
./run_hosts_studio.sh
```

**Method 2: Use extract-and-run option**
```bash
./hosts-studio-1.0.0-x86_64.AppImage --appimage-extract-and-run
```

**Method 3: Install polkit policy for better integration**
```bash
sudo ./install_polkit_policy.sh
```

### ❌ **What Doesn't Work:**
- Double-clicking the AppImage directly (due to AppImageLauncher mounting restrictions)
- Running `./hosts-studio-1.0.0-x86_64.AppImage` directly

### 🔧 **For Distribution:**
1. **Include the wrapper script** (`run_hosts_studio.sh`) with your AppImage
2. **Include the polkit policy** (`hosts-studio.policy`) for advanced users
3. **Document the working methods** in your distribution notes

### 🎯 **Current Status:**
- ✅ AppImage builds successfully (~179MB)
- ✅ App works correctly with wrapper script and extract-and-run
- ✅ GUI appears and functions properly
- ✅ Privilege escalation works
- ✅ All features are functional
- ⚠️ Direct double-click integration limited by system security policies

## Development

The application is built with:
- **Python 3** - Core language
- **tkinter** - GUI framework
- **subprocess** - For system operations
- **re** - For input validation
- **datetime** - For backup timestamps

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Feel free to submit issues or pull requests to improve the application. 

### Development Setup
1. Clone the repository
2. Install development dependencies
3. Run the application in development mode
4. Test with different packaging formats

### Testing Packages
```bash
# Test RPM package
./build_rpm.sh
sudo dnf install ~/rpmbuild/RPMS/noarch/hosts-studio-*.rpm

# Test DEB package
./build_deb.sh
sudo dpkg -i hosts-studio_*.deb

# Test AUR package
./build_aur.sh
sudo pacman -U hosts-studio-*.pkg.tar.zst

# Test AppImage
./build_appimage.sh
./run_hosts_studio.sh
```

## Support

For issues with specific packaging formats:
- **RPM**: Check `RPM_BUILD.md` for detailed troubleshooting
- **DEB**: Check `DEB_BUILD.md` for detailed troubleshooting  
- **AUR**: Check `AUR_BUILD.md` for detailed troubleshooting
- **AppImage**: Check the troubleshooting section above
- **General**: Check `MANUAL.md` for comprehensive user guide 