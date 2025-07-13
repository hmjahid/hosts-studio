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
- **AppImage Support**: Portable single-file executable for easy distribution

## Requirements

- Python 3.6 or higher (for source code)
- tkinter (usually included with Python)
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

### Option 2: Source Code
1. Clone or download the application files
2. Make the script executable:
   ```bash
   chmod +x hosts_studio.py
   ```

## Usage

### Running the Application

#### AppImage (Recommended)
```bash
# Use the wrapper script (recommended)
./run_hosts_studio.sh

# Or run with extract-and-run option
./hosts-studio-1.0.0-x86_64.AppImage --appimage-extract-and-run

# Traditional method (may have mounting issues)
./hosts-studio-1.0.0-x86_64.AppImage
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

- `hosts_studio.py` - Main application file
- `hosts-studio-1.0.0-x86_64.AppImage` - Portable executable
- `build_appimage.sh` - AppImage build script
- `README.md` - This documentation file
- `USAGE.md` - Detailed usage guide
- `/tmp/hosts_backups/` - Directory where backups are stored

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

## Building from Source

### Prerequisites
- Python 3.6+
- tkinter
- wget (for downloading appimagetool)

### Build Steps
1. Clone the repository
2. Run the build script:
   ```bash
   chmod +x build_appimage.sh
   ./build_appimage.sh
   ```
3. The AppImage will be created in the `build/` directory

## Troubleshooting

### Permission Denied Errors
- The AppImage will automatically request privileges using a graphical dialog
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
./build/hosts-studio-1.0.0-x86_64.AppImage --appimage-extract-and-run
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

This application is provided as-is for educational and practical use.

## Contributing

Feel free to submit issues or pull requests to improve the application. 