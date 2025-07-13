# Quick Usage Guide

## Quick Start

### Option 1: AppImage (Recommended)
1. **Download and Run:**
   ```bash
   # Make executable
   chmod +x hosts-studio-1.0.0-x86_64.AppImage
   
   # Run - it will automatically request privileges
   ./hosts-studio-1.0.0-x86_64.AppImage
   ```

### Option 2: Source Code
1. **Install and Run:**
   ```bash
   # Make executable
   chmod +x hosts_studio.py
   
   # Run with sudo for full functionality
   sudo python3 hosts_studio.py
   ```

2. **Or use the installation script:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

## Basic Operations

### Viewing Entries
- The application automatically loads and displays all `/etc/hosts` entries
- Entries show: Status (✓ enabled, ✗ disabled), IP Address, Hostnames, Comments

### Adding New Entries
1. Click **"Add Entry"** button
2. Enter IP address (e.g., `127.0.0.1`)
3. Enter hostnames (space-separated, e.g., `mycustomdomain.test`)
4. Add optional comment
5. Click **"Add"**

### Editing Entries
1. Select an entry from the list
2. Click **"Edit Entry"** button
3. Modify IP, hostnames, comment, or enable/disable status
4. Click **"Save"**

### Removing Entries
1. Select an entry from the list
2. Click **"Remove Entry"** button
3. **Confirmation dialog** will show entry details and ask for confirmation
4. Click **"Yes"** to remove

### Disabling/Enabling Entries
1. Select an entry from the list
2. Click **"Toggle Entry"** button
3. Entry will be commented out (disabled) or uncommented (enabled)

### Searching
- Use the search box to filter entries
- Searches across IP addresses, hostnames, and comments
- Click **"Clear"** to show all entries

### Saving Changes
1. Make your desired changes
2. Click **"Save Changes"** button
3. **Confirmation dialog** will explain what will happen and ask for confirmation
4. Click **"Yes"** to save
5. A backup will be automatically created

### Reloading
1. Click **"Reload"** button
2. **Confirmation dialog** will warn about losing unsaved changes
3. Click **"Yes"** to reload from disk

## Example Entries

```
127.0.0.1 localhost
127.0.0.1 mycustomdomain.test
192.168.1.100 myserver.local
::1 localhost ip6-localhost ip6-loopback
```

## Security Features

- **Graphical Privilege Escalation**: Uses pkexec/gksudo/kdesudo for secure privilege requests
- **Automatic Backups**: Created before any file modifications
- **Input Validation**: All IPs and hostnames are validated
- **Confirmation Dialogs**: All destructive operations require explicit user confirmation
- **Safe Operations**: Uses temporary files for secure writing

## Privilege Handling

### AppImage
- Automatically requests privileges using graphical dialog (pkexec/gksudo/kdesudo)
- No need to manually use sudo
- Falls back to sudo if graphical methods are unavailable

### Source Code
- Requires manual sudo for full functionality
- Can run without sudo for view-only mode

## Troubleshooting

### Permission Errors
```bash
# AppImage - should work automatically
./hosts-studio-1.0.0-x86_64.AppImage

# Source code - run with sudo
sudo python3 hosts_studio.py
```

### GUI Not Working
```bash
# Install tkinter (if missing)
# Ubuntu/Debian:
sudo apt-get install python3-tk

# Fedora/RHEL:
sudo dnf install python3-tkinter

# Arch:
sudo pacman -S tk
```

### AppImage Issues
```bash
# Make sure it's executable
chmod +x hosts-studio-1.0.0-x86_64.AppImage

# If privilege escalation fails, try manual sudo
sudo ./hosts-studio-1.0.0-x86_64.AppImage
```

### Backup Location
Backups are stored in: `/tmp/hosts_backups/`

## Keyboard Shortcuts

- **Ctrl+F**: Focus search box
- **Enter**: In search box, apply filter
- **Escape**: Clear search
- **Delete**: Remove selected entry (when selected)

## Tips

1. **Always backup before major changes** (automatic with save)
2. **Test entries with ping before saving**
3. **Use comments to document your changes**
4. **Search is case-insensitive**
5. **Disabled entries are shown with ✗ status**
6. **Confirmation dialogs show exactly what will happen**
7. **AppImage is portable - works on any Linux distribution** 