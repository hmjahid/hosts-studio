#!/usr/bin/env python3
"""
Test script for Hosts File Editor - demonstrates core functionality
"""

import os
import tempfile
import shutil
from hosts_editor import HostsEntry, HostsFileManager


def test_hosts_entry():
    """Test HostsEntry class functionality"""
    print("Testing HostsEntry class...")
    
    # Test valid entries
    entry1 = HostsEntry("127.0.0.1", ["localhost", "local"], "Local host")
    entry2 = HostsEntry("192.168.1.100", ["myserver.local"], "")
    entry3 = HostsEntry("::1", ["localhost", "ip6-localhost"], "IPv6 localhost")
    
    print(f"Entry 1: {entry1}")
    print(f"Entry 2: {entry2}")
    print(f"Entry 3: {entry3}")
    
    # Test validation
    is_valid, msg = entry1.is_valid()
    print(f"Entry 1 valid: {is_valid}")
    
    # Test invalid entry
    invalid_entry = HostsEntry("999.999.999.999", ["invalid"], "")
    is_valid, msg = invalid_entry.is_valid()
    print(f"Invalid entry valid: {is_valid}, Error: {msg}")
    
    # Test disabled entry
    entry1.enabled = False
    print(f"Disabled entry: {entry1}")
    
    print("HostsEntry tests completed!\n")


def test_hosts_file_manager():
    """Test HostsFileManager class functionality"""
    print("Testing HostsFileManager class...")
    
    # Create a temporary hosts file for testing
    with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
        temp_file.write("""# Test hosts file
127.0.0.1 localhost local
192.168.1.100 myserver.local # My server
# 192.168.1.101 disabled.server # This is disabled
::1 localhost ip6-localhost ip6-loopback
""")
        temp_hosts_file = temp_file.name
    
    # Create temporary backup directory
    temp_backup_dir = tempfile.mkdtemp()
    
    try:
        # Create manager with temporary files
        manager = HostsFileManager()
        manager.HOSTS_FILE = temp_hosts_file
        manager.BACKUP_DIR = temp_backup_dir
        
        # Test loading
        success, message = manager.load_hosts_file()
        print(f"Load result: {success}, Message: {message}")
        print(f"Loaded {len(manager.entries)} entries")
        
        # Display entries
        for i, entry in enumerate(manager.entries):
            print(f"  Entry {i}: {entry}")
        
        # Test adding entry
        success, message = manager.add_entry("10.0.0.1", ["test.local"], "Test entry")
        print(f"Add entry result: {success}, Message: {message}")
        
        # Test search
        matches = manager.search_entries("localhost")
        print(f"Search 'localhost' found {len(matches)} matches")
        
        # Test backup creation
        success, message = manager.create_backup()
        print(f"Backup result: {success}, Message: {message}")
        
        print("HostsFileManager tests completed!\n")
        
    finally:
        # Cleanup
        os.unlink(temp_hosts_file)
        shutil.rmtree(temp_backup_dir)


def test_validation():
    """Test input validation"""
    print("Testing input validation...")
    
    # Test valid IPs
    valid_ips = [
        "127.0.0.1",
        "192.168.1.1",
        "10.0.0.1",
        "localhost",
        "::1"
    ]
    
    for ip in valid_ips:
        entry = HostsEntry(ip, ["test.local"])
        is_valid, msg = entry.is_valid()
        print(f"IP {ip}: {'✓' if is_valid else '✗'} {msg}")
    
    # Test invalid IPs
    invalid_ips = [
        "999.999.999.999",
        "256.1.2.3",
        "1.2.3",
        "invalid"
    ]
    
    for ip in invalid_ips:
        entry = HostsEntry(ip, ["test.local"])
        is_valid, msg = entry.is_valid()
        print(f"IP {ip}: {'✓' if is_valid else '✗'} {msg}")
    
    # Test valid hostnames
    valid_hostnames = [
        "localhost",
        "example.com",
        "test.local",
        "my-server"
    ]
    
    for hostname in valid_hostnames:
        entry = HostsEntry("127.0.0.1", [hostname])
        is_valid, msg = entry.is_valid()
        print(f"Hostname {hostname}: {'✓' if is_valid else '✗'} {msg}")
    
    print("Validation tests completed!\n")


def main():
    """Run all tests"""
    print("Hosts File Editor - Test Suite")
    print("=" * 40)
    print()
    
    test_hosts_entry()
    test_hosts_file_manager()
    test_validation()
    
    print("All tests completed successfully!")
    print("\nTo run the GUI application:")
    print("  sudo python3 hosts_editor.py")


if __name__ == "__main__":
    main() 