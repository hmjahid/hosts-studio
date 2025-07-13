# Hosts Studio - User Manual

## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Getting Started](#getting-started)
4. [Features](#features)
5. [Usage Guide](#usage-guide)
6. [Troubleshooting](#troubleshooting)
7. [Advanced Usage](#advanced-usage)
8. [Security Considerations](#security-considerations)
9. [FAQ](#faq)

## Introduction

Hosts Studio is a safe and user-friendly GUI application for editing the `/etc/hosts` file on Linux systems. It provides a clean, intuitive interface built with tkinter that allows users to view, add, remove, and modify IP-to-hostname mappings with automatic backup creation and input validation.

### What is the hosts file?

The `/etc/hosts` file is a system file that maps hostnames to IP addresses. It's used by the operating system to resolve hostnames before querying DNS servers. This file is commonly used for:

- Blocking websites by redirecting them to localhost
- Creating local development environments
- Overriding DNS resolution for specific domains
- Network testing and debugging

### Why use Hosts Studio?

- **Safety**: Automatic backup creation before any changes
- **Validation**: Input validation for IP addresses and hostnames
- **User-friendly**: Clean GUI interface instead of command-line editing
- **Search**: Quick search functionality to find entries
- **Privilege handling**: Automatic privilege escalation when needed

## Installation

### Prerequisites

- Linux distribution (Fedora, RHEL, CentOS, Ubuntu, etc.)
- Python 3.6 or later
- tkinter (usually included with Python)
- polkit (for privilege escalation)

### Installation Methods

#### 1. RPM Package (Recommended)

```bash
# Install the RPM package
sudo dnf install hosts-studio-1.0.0-1.*.noarch.rpm

# Or if you have the RPM file locally
sudo dnf install ./hosts-studio-1.0.0-1.*.noarch.rpm
```

#### 2. AppImage

```bash
# Make the AppImage executable
chmod +x hosts-studio-*.AppImage

# Run the AppImage
./hosts-studio-*.AppImage
```

#### 3. Manual Installation

```bash
# Clone or download the source
git clone <repository-url>
cd hosts-studio

# Install dependencies
sudo dnf install python3 python3-tkinter polkit

# Run directly
python3 hosts_studio.py
```

### Verification

After installation, verify that Hosts Studio is properly installed:

```bash
# Check if the command is available
which hosts-studio

# Check package information (RPM installation)
rpm -qi hosts-studio

# Test the application
hosts-studio --help
```

## Getting Started

### Launching the Application

#### From Application Menu
1. Open your application menu
2. Search for "Hosts Studio"
3. Click on the Hosts Studio icon

#### From Terminal
```bash
hosts-studio
```

#### Direct Python Execution
```bash
python3 /usr/share/hosts-studio/hosts_studio.py
```

### First Launch

When you first launch Hosts Studio:

1. **Privilege Prompt**: You'll be prompted for your password to gain root privileges
2. **File Loading**: The application will load the current `/etc/hosts` file
3. **Main Interface**: You'll see the main interface with all current entries

### Interface Overview

The main interface consists of:

- **Menu Bar**: File operations, help, and settings
- **Toolbar**: Quick access to common actions
- **Entry List**: Displays all hosts file entries
- **Search Bar**: Filter entries by IP or hostname
- **Status Bar**: Shows current status and file information

## Features

### Core Features

#### 1. View and Edit Entries
- Display all current hosts file entries in a structured format
- Edit existing entries directly in the interface
- Real-time validation of IP addresses and hostnames

#### 2. Add New Entries
- Add new IP-to-hostname mappings
- Support for multiple hostnames per IP address
- Automatic validation of input data

#### 3. Remove Entries
- Select and remove unwanted entries
- Confirmation dialog to prevent accidental deletions
- Bulk selection and removal

#### 4. Search and Filter
- Search entries by IP address or hostname
- Real-time filtering as you type
- Case-insensitive search

#### 5. Automatic Backup
- Creates backup before saving changes
- Timestamped backup files
- Easy restoration of previous versions

### Advanced Features

#### 1. Input Validation
- IP address format validation
- Hostname format validation
- Duplicate entry detection
- Reserved IP range warnings

#### 2. File Operations
- Load hosts file from custom location
- Export entries to different formats
- Import entries from text files
- Backup management

#### 3. Security Features
- Automatic privilege escalation
- Secure file operations
- Backup verification
- Change logging

## Usage Guide

### Basic Operations

#### Adding a New Entry

1. Click the "Add Entry" button or use Ctrl+N
2. Enter the IP address (e.g., `127.0.0.1`)
3. Enter the hostname (e.g., `localhost`)
4. Click "Add" to add the entry
5. Click "Save" to write changes to the hosts file

#### Editing an Existing Entry

1. Select the entry you want to edit
2. Double-click or press Enter
3. Modify the IP address or hostname
4. Press Enter or click outside to save changes
5. Click "Save" to write changes to the hosts file

#### Removing an Entry

1. Select the entry you want to remove
2. Click the "Remove" button or press Delete
3. Confirm the deletion in the dialog
4. Click "Save" to write changes to the hosts file

#### Searching for Entries

1. Use the search bar at the top of the interface
2. Type the IP address or hostname you're looking for
3. Results will be filtered in real-time
4. Clear the search to show all entries again

### Advanced Operations

#### Bulk Operations

1. **Select Multiple Entries**: Hold Ctrl and click multiple entries
2. **Select Range**: Hold Shift and click to select a range
3. **Select All**: Use Ctrl+A to select all entries
4. **Bulk Remove**: Select multiple entries and press Delete

#### File Operations

1. **Load Custom File**: File → Load Custom File
2. **Export Entries**: File → Export → Choose format
3. **Import Entries**: File → Import → Select file
4. **Backup Management**: File → Manage Backups

#### Keyboard Shortcuts

- `Ctrl+N`: Add new entry
- `Ctrl+S`: Save changes
- `Ctrl+F`: Focus search bar
- `Ctrl+A`: Select all entries
- `Delete`: Remove selected entries
- `F5`: Refresh entries
- `Ctrl+Z`: Undo last change (if supported)

### Common Use Cases

#### Blocking Websites

1. Add a new entry with IP `127.0.0.1`
2. Enter the domain you want to block (e.g., `ads.example.com`)
3. Save the changes
4. The website will now redirect to localhost

#### Local Development

1. Add entries for your local development domains
2. Use IP addresses like `192.168.1.100` for local servers
3. Add multiple hostnames for the same IP if needed

#### Network Testing

1. Add test entries with specific IP addresses
2. Use for testing DNS resolution
3. Verify network connectivity

## Troubleshooting

### Common Issues

#### 1. Permission Denied

**Problem**: Cannot access `/etc/hosts` file

**Solutions**:
- Ensure you're running with root privileges
- Check if the file has correct permissions
- Verify polkit is installed and working

```bash
# Check file permissions
ls -la /etc/hosts

# Fix permissions if needed
sudo chmod 644 /etc/hosts
```

#### 2. Application Won't Start

**Problem**: Hosts Studio fails to launch

**Solutions**:
- Check Python installation: `python3 --version`
- Verify tkinter: `python3 -c "import tkinter"`
- Check dependencies: `rpm -q python3-tkinter`

```bash
# Install missing dependencies
sudo dnf install python3-tkinter

# Test tkinter
python3 -c "import tkinter; tkinter._test()"
```

#### 3. Changes Not Taking Effect

**Problem**: Modified hosts file doesn't affect DNS resolution

**Solutions**:
- Clear DNS cache: `sudo dscacheutil -flushcache` (macOS) or `sudo systemctl restart systemd-resolved` (Linux)
- Restart network services
- Check if DNS is configured to use hosts file

#### 4. Backup Issues

**Problem**: Backup files not created or corrupted

**Solutions**:
- Check disk space: `df -h`
- Verify write permissions to backup directory
- Check backup directory path in settings

### Error Messages

#### "Invalid IP Address"
- Ensure IP address is in correct format (e.g., `192.168.1.1`)
- Check for extra spaces or characters
- Verify IP address is valid

#### "Invalid Hostname"
- Hostnames should contain only letters, numbers, hyphens, and dots
- Cannot start or end with hyphen
- Maximum length is 253 characters

#### "Duplicate Entry"
- Check if the IP-hostname combination already exists
- Remove duplicate entry before adding new one

### Performance Issues

#### Slow Loading
- Large hosts files may take time to load
- Consider using search to filter entries
- Close other applications to free memory

#### Interface Lag
- Reduce the number of visible entries
- Use search to filter results
- Restart the application if needed

## Advanced Usage

### Configuration

#### Custom Backup Location

You can configure a custom backup location by modifying the application settings or environment variables:

```bash
# Set custom backup directory
export HOSTS_STUDIO_BACKUP_DIR="/path/to/backups"
hosts-studio
```

#### Custom Hosts File Location

To work with a different hosts file:

1. Use File → Load Custom File
2. Select your custom hosts file
3. Make changes as needed
4. Save to the custom location

### Scripting and Automation

#### Command Line Interface

Hosts Studio supports basic command-line operations:

```bash
# Show help
hosts-studio --help

# Load specific file
hosts-studio --file /path/to/hosts

# Export entries
hosts-studio --export /path/to/output.txt
```

#### Integration with Other Tools

You can integrate Hosts Studio with other system administration tools:

```bash
# Create a script to manage hosts entries
#!/bin/bash
# Add entry for development
echo "192.168.1.100 dev.example.com" | sudo tee -a /etc/hosts

# Use Hosts Studio to verify
hosts-studio
```

### Backup and Recovery

#### Manual Backup

Create manual backups before major changes:

```bash
# Create timestamped backup
sudo cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d_%H%M%S)
```

#### Restore from Backup

To restore from a backup:

1. Use File → Load Custom File
2. Select your backup file
3. Review the contents
4. Save to `/etc/hosts`

#### Backup Rotation

Set up automatic backup rotation:

```bash
# Keep only last 10 backups
find /etc/hosts.backup.* -mtime +10 -delete
```

## Security Considerations

### File Permissions

The `/etc/hosts` file should have restricted permissions:

```bash
# Correct permissions
sudo chmod 644 /etc/hosts
sudo chown root:root /etc/hosts
```

### Privilege Escalation

Hosts Studio uses secure privilege escalation methods:

- **pkexec**: Modern, secure method (preferred)
- **gksudo**: GTK-based sudo dialog
- **kdesudo**: KDE-based sudo dialog
- **sudo**: Fallback method

### Backup Security

Backup files should be protected:

```bash
# Secure backup directory
sudo chmod 700 /etc/hosts.backup
sudo chown root:root /etc/hosts.backup
```

### Network Security

Be cautious when modifying hosts file:

- **DNS Spoofing**: Malicious hosts entries can redirect traffic
- **Phishing**: Fake entries can redirect to malicious sites
- **Data Theft**: Incorrect entries can leak data

### Best Practices

1. **Verify Changes**: Always review changes before saving
2. **Regular Backups**: Keep multiple backup versions
3. **Document Changes**: Note why changes were made
4. **Test Changes**: Verify DNS resolution after changes
5. **Monitor Logs**: Check system logs for issues

## FAQ

### General Questions

**Q: Is Hosts Studio safe to use?**
A: Yes, Hosts Studio includes multiple safety features including automatic backups, input validation, and secure privilege handling.

**Q: Can I use Hosts Studio on other operating systems?**
A: Hosts Studio is designed for Linux systems. For Windows, consider using the hosts file editor built into the system, or use WSL.

**Q: Does Hosts Studio require internet access?**
A: No, Hosts Studio works entirely offline. It only modifies the local hosts file.

### Technical Questions

**Q: Why do I need root privileges?**
A: The `/etc/hosts` file is a system file that requires root privileges to modify. This is a security feature of the operating system.

**Q: Can I edit the hosts file while other applications are using it?**
A: Yes, changes are immediately available to all applications. Some applications may need to be restarted to pick up changes.

**Q: How do I revert changes?**
A: Use the backup files created by Hosts Studio, or manually restore from a backup using File → Load Custom File.

**Q: Can I use Hosts Studio in a script?**
A: Yes, Hosts Studio supports command-line operations for scripting and automation.

### Troubleshooting Questions

**Q: The application won't start after installation**
A: Check that Python 3 and tkinter are installed. Run `python3 -c "import tkinter"` to test.

**Q: Changes aren't taking effect**
A: Clear your DNS cache and restart network services. Some applications cache DNS lookups.

**Q: I can't find my backup files**
A: Check the default backup location (`/etc/hosts.backup`) or look in the application settings for the configured location.

**Q: The interface looks wrong**
A: This may be a tkinter theme issue. Try running with a different theme or check your system's display settings.

### Support and Community

For additional support:

1. Check the troubleshooting section above
2. Review the application logs
3. Search for similar issues online
4. Contact the development team

### Contributing

If you'd like to contribute to Hosts Studio:

1. Report bugs and issues
2. Suggest new features
3. Submit code improvements
4. Help with documentation

---

*This manual covers Hosts Studio version 1.0.0. For the latest information, check the project documentation or repository.* 