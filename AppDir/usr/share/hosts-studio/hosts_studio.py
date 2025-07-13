#!/usr/bin/env python3
"""
Hosts Studio - A safe and convenient GUI application for editing /etc/hosts file
"""

import tkinter as tk
from tkinter import ttk, messagebox, filedialog, scrolledtext
import subprocess
import shutil
import os
import re
import datetime
from typing import List, Tuple, Optional
import threading
import tempfile


class HostsEntry:
    """Represents a single hosts file entry"""
    
    def __init__(self, ip: str, hostnames: List[str], comment: str = "", enabled: bool = True):
        self.ip = ip.strip()
        self.hostnames = [h.strip() for h in hostnames]
        self.comment = comment.strip()
        self.enabled = enabled
    
    def __str__(self) -> str:
        if not self.enabled:
            return f"# {self.ip} {' '.join(self.hostnames)} {self.comment}".strip()
        return f"{self.ip} {' '.join(self.hostnames)} {self.comment}".strip()
    
    def is_valid(self) -> Tuple[bool, str]:
        """Validate the entry and return (is_valid, error_message)"""
        # Validate IP address
        if not self._is_valid_ip(self.ip):
            return False, f"Invalid IP address: {self.ip}"
        
        # Validate hostnames
        for hostname in self.hostnames:
            if not self._is_valid_hostname(hostname):
                return False, f"Invalid hostname: {hostname}"
        
        return True, ""
    
    def _is_valid_ip(self, ip: str) -> bool:
        """Check if IP address is valid"""
        if ip == "localhost":
            return True
        
        # IPv4 validation
        ipv4_pattern = r'^(\d{1,3}\.){3}\d{1,3}$'
        if re.match(ipv4_pattern, ip):
            parts = ip.split('.')
            return all(0 <= int(part) <= 255 for part in parts)
        
        # IPv6 validation (basic)
        ipv6_pattern = r'^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$'
        return bool(re.match(ipv6_pattern, ip))
    
    def _is_valid_hostname(self, hostname: str) -> bool:
        """Check if hostname is valid"""
        if not hostname:
            return False
        
        # Basic hostname validation
        pattern = r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$'
        return bool(re.match(pattern, hostname))


class HostsFileManager:
    """Manages reading, writing, and backing up the hosts file"""
    
    HOSTS_FILE = "/etc/hosts"
    BACKUP_DIR = "/tmp/hosts_backups"
    
    def __init__(self):
        self.entries: List[HostsEntry] = []
        self.backup_path: Optional[str] = None
        self._ensure_backup_dir()
    
    def _ensure_backup_dir(self):
        """Ensure backup directory exists"""
        if not os.path.exists(self.BACKUP_DIR):
            try:
                os.makedirs(self.BACKUP_DIR, mode=0o755)
            except PermissionError:
                pass
    
    def load_hosts_file(self) -> Tuple[bool, str]:
        """Load and parse the hosts file"""
        try:
            if not os.path.exists(self.HOSTS_FILE):
                return False, f"Hosts file not found: {self.HOSTS_FILE}"
            
            with open(self.HOSTS_FILE, 'r') as f:
                lines = f.readlines()
            
            self.entries = []
            for line_num, line in enumerate(lines, 1):
                line = line.strip()
                
                # Skip empty lines
                if not line:
                    continue
                
                # Handle comments
                if line.startswith('#'):
                    # Check if it's a commented entry
                    uncommented = line[1:].strip()
                    if self._is_hosts_entry(uncommented):
                        entry = self._parse_hosts_line(uncommented)
                        entry.enabled = False
                        entry.comment = line
                    else:
                        # Regular comment
                        continue
                else:
                    entry = self._parse_hosts_line(line)
                
                self.entries.append(entry)
            
            return True, f"Loaded {len(self.entries)} entries"
            
        except PermissionError:
            return False, "Permission denied. Run with sudo privileges."
        except Exception as e:
            return False, f"Error loading hosts file: {str(e)}"
    
    def _is_hosts_entry(self, line: str) -> bool:
        """Check if a line looks like a hosts entry"""
        parts = line.split()
        if len(parts) < 2:
            return False
        
        # Check if first part looks like an IP
        ip = parts[0]
        return bool(re.match(r'^(\d{1,3}\.){3}\d{1,3}$|^localhost$|^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$', ip))
    
    def _parse_hosts_line(self, line: str) -> HostsEntry:
        """Parse a single hosts file line into a HostsEntry"""
        # Split by whitespace
        parts = line.split()
        
        if len(parts) < 2:
            return HostsEntry("", [], line)
        
        ip = parts[0]
        hostnames = parts[1:]
        comment = ""
        
        # Extract comment if present
        if '#' in line:
            comment_start = line.find('#')
            comment = line[comment_start:].strip()
            # Remove comment from hostnames
            hostnames = [h for h in hostnames if not h.startswith('#')]
        
        return HostsEntry(ip, hostnames, comment)
    
    def create_backup(self) -> Tuple[bool, str]:
        """Create a backup of the current hosts file"""
        try:
            if not os.path.exists(self.HOSTS_FILE):
                return False, "Hosts file does not exist"
            
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_filename = f"hosts_backup_{timestamp}"
            self.backup_path = os.path.join(self.BACKUP_DIR, backup_filename)
            
            shutil.copy2(self.HOSTS_FILE, self.backup_path)
            return True, f"Backup created: {self.backup_path}"
            
        except Exception as e:
            return False, f"Failed to create backup: {str(e)}"
    
    def save_hosts_file(self) -> Tuple[bool, str]:
        """Save the current entries to the hosts file"""
        try:
            # Create backup first
            backup_success, backup_msg = self.create_backup()
            if not backup_success:
                return False, f"Failed to create backup: {backup_msg}"
            
            # Validate all entries
            for entry in self.entries:
                is_valid, error_msg = entry.is_valid()
                if not is_valid and entry.enabled:
                    return False, f"Invalid entry: {error_msg}"
            
            # Create temporary file
            with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
                for entry in self.entries:
                    temp_file.write(str(entry) + '\n')
                temp_file_path = temp_file.name
            
            # Always copy directly (app runs as root)
            shutil.copy2(temp_file_path, self.HOSTS_FILE)
            
            # Clean up temp file
            os.unlink(temp_file_path)
            
            return True, f"Hosts file saved successfully. Backup: {self.backup_path}"
            
        except Exception as e:
            return False, f"Error saving hosts file: {str(e)}"
    
    def add_entry(self, ip: str, hostnames: List[str], comment: str = "") -> Tuple[bool, str]:
        """Add a new entry"""
        entry = HostsEntry(ip, hostnames, comment)
        is_valid, error_msg = entry.is_valid()
        
        if not is_valid:
            return False, error_msg
        
        self.entries.append(entry)
        return True, "Entry added successfully"
    
    def remove_entry(self, index: int) -> Tuple[bool, str]:
        """Remove an entry by index"""
        if 0 <= index < len(self.entries):
            del self.entries[index]
            return True, "Entry removed successfully"
        return False, "Invalid entry index"
    
    def toggle_entry(self, index: int) -> Tuple[bool, str]:
        """Toggle entry enabled/disabled state"""
        if 0 <= index < len(self.entries):
            self.entries[index].enabled = not self.entries[index].enabled
            return True, "Entry toggled successfully"
        return False, "Invalid entry index"
    
    def search_entries(self, query: str) -> List[int]:
        """Search for entries matching the query"""
        query = query.lower()
        matches = []
        
        for i, entry in enumerate(self.entries):
            if (query in entry.ip.lower() or 
                any(query in hostname.lower() for hostname in entry.hostnames) or
                query in entry.comment.lower()):
                matches.append(i)
        
        return matches


class HostsStudioGUI:
    """Main GUI application for Hosts Studio"""
    
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Hosts Studio")
        self.root.geometry("800x600")
        self.root.minsize(600, 400)
        
        # Make window more visible when running as root
        self.root.lift()  # Bring to front
        self.root.attributes('-topmost', True)  # Keep on top
        self.root.after(1000, lambda: self.root.attributes('-topmost', False))  # Remove topmost after 1 second
        
        # Center the window on screen
        self.root.update_idletasks()
        x = (self.root.winfo_screenwidth() // 2) - (800 // 2)
        y = (self.root.winfo_screenheight() // 2) - (600 // 2)
        self.root.geometry(f"800x600+{x}+{y}")
        
        # Add some visual feedback
        self.root.configure(bg='white')
        
        self.hosts_manager = HostsFileManager()
        self.search_results = []
        self.current_filter = None
        
        self._setup_ui()
        self._load_hosts_file()
    
    def _setup_ui(self):
        """Setup the user interface"""
        # Main frame
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(1, weight=1)
        
        # Search frame
        search_frame = ttk.LabelFrame(main_frame, text="Search", padding="5")
        search_frame.grid(row=0, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))
        search_frame.columnconfigure(0, weight=1)
        
        self.search_var = tk.StringVar()
        search_entry = ttk.Entry(search_frame, textvariable=self.search_var)
        search_entry.grid(row=0, column=0, sticky=(tk.W, tk.E), padx=(0, 5))
        search_entry.bind('<KeyRelease>', self._on_search)
        
        clear_search_btn = ttk.Button(search_frame, text="Clear", command=self._clear_search)
        clear_search_btn.grid(row=0, column=1)
        
        # Entries list
        entries_frame = ttk.LabelFrame(main_frame, text="Host Entries", padding="5")
        entries_frame.grid(row=1, column=0, columnspan=3, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 10))
        entries_frame.columnconfigure(0, weight=1)
        entries_frame.rowconfigure(0, weight=1)
        
        # Treeview for entries
        columns = ('Status', 'IP', 'Hostnames', 'Comment')
        self.tree = ttk.Treeview(entries_frame, columns=columns, show='headings', height=15)
        
        # Configure columns
        self.tree.heading('Status', text='Status')
        self.tree.heading('IP', text='IP Address')
        self.tree.heading('Hostnames', text='Hostnames')
        self.tree.heading('Comment', text='Comment')
        
        self.tree.column('Status', width=60)
        self.tree.column('IP', width=120)
        self.tree.column('Hostnames', width=200)
        self.tree.column('Comment', width=300)
        
        # Scrollbar
        scrollbar = ttk.Scrollbar(entries_frame, orient=tk.VERTICAL, command=self.tree.yview)
        self.tree.configure(yscrollcommand=scrollbar.set)
        
        self.tree.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        scrollbar.grid(row=0, column=1, sticky=(tk.N, tk.S))
        
        # Bind selection event
        self.tree.bind('<<TreeviewSelect>>', self._on_entry_select)
        
        # Buttons frame
        buttons_frame = ttk.Frame(main_frame)
        buttons_frame.grid(row=2, column=0, columnspan=3, pady=(10, 0))
        
        # Left buttons
        add_btn = ttk.Button(buttons_frame, text="Add Entry", command=self._show_add_dialog)
        add_btn.grid(row=0, column=0, padx=(0, 5))
        
        edit_btn = ttk.Button(buttons_frame, text="Edit Entry", command=self._show_edit_dialog)
        edit_btn.grid(row=0, column=1, padx=(0, 5))
        
        remove_btn = ttk.Button(buttons_frame, text="Remove Entry", command=self._remove_selected)
        remove_btn.grid(row=0, column=2, padx=(0, 5))
        
        toggle_btn = ttk.Button(buttons_frame, text="Toggle Entry", command=self._toggle_selected)
        toggle_btn.grid(row=0, column=3, padx=(0, 5))
        
        # Right buttons
        save_btn = ttk.Button(buttons_frame, text="Save Changes", command=self._save_changes)
        save_btn.grid(row=0, column=4, padx=(20, 5))
        
        reload_btn = ttk.Button(buttons_frame, text="Reload", command=self._reload_hosts)
        reload_btn.grid(row=0, column=5, padx=(0, 5))
        
        backup_btn = ttk.Button(buttons_frame, text="Create Backup", command=self._create_backup)
        backup_btn.grid(row=0, column=6, padx=(0, 5))
        
        # Status bar
        self.status_var = tk.StringVar()
        status_bar = ttk.Label(main_frame, textvariable=self.status_var, relief=tk.SUNKEN)
        status_bar.grid(row=3, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(10, 0))
        
        self.status_var.set("Ready")
    
    def _load_hosts_file(self):
        """Load the hosts file and update the display"""
        success, message = self.hosts_manager.load_hosts_file()
        if success:
            self._update_entries_display()
            self.status_var.set(message)
        else:
            messagebox.showerror("Error", message)
            self.status_var.set("Failed to load hosts file")
    
    def _update_entries_display(self):
        """Update the entries display"""
        # Clear current items
        for item in self.tree.get_children():
            self.tree.delete(item)
        
        # Get entries to display (filtered if search is active)
        entries_to_show = self.hosts_manager.entries
        if self.current_filter is not None:
            entries_to_show = [self.hosts_manager.entries[i] for i in self.current_filter]
        
        # Add entries to treeview
        for entry in entries_to_show:
            status = "✓" if entry.enabled else "✗"
            hostnames_str = " ".join(entry.hostnames)
            comment_str = entry.comment.replace("#", "").strip() if entry.comment.startswith("#") else entry.comment
            
            self.tree.insert('', tk.END, values=(status, entry.ip, hostnames_str, comment_str))
    
    def _on_search(self, event=None):
        """Handle search input"""
        query = self.search_var.get().strip()
        if query:
            self.search_results = self.hosts_manager.search_entries(query)
            self.current_filter = self.search_results
            self.status_var.set(f"Found {len(self.search_results)} matching entries")
        else:
            self.current_filter = None
            self.status_var.set("Ready")
        
        self._update_entries_display()
    
    def _clear_search(self):
        """Clear search and show all entries"""
        self.search_var.set("")
        self.current_filter = None
        self._update_entries_display()
        self.status_var.set("Ready")
    
    def _on_entry_select(self, event=None):
        """Handle entry selection"""
        selection = self.tree.selection()
        if selection:
            self.status_var.set("Entry selected")
        else:
            self.status_var.set("Ready")
    
    def _get_selected_index(self) -> Optional[int]:
        """Get the index of the selected entry"""
        selection = self.tree.selection()
        if not selection:
            return None
        
        # Get the item index
        item = selection[0]
        item_index = self.tree.index(item)
        
        # If filtered, map back to original index
        if self.current_filter is not None:
            if item_index < len(self.current_filter):
                return self.current_filter[item_index]
            return None
        
        return item_index
    
    def _show_add_dialog(self):
        """Show dialog to add a new entry"""
        dialog = AddEntryDialog(self.root, self.hosts_manager)
        self.root.wait_window(dialog.dialog)
        self._update_entries_display()
    
    def _show_edit_dialog(self):
        """Show dialog to edit selected entry"""
        index = self._get_selected_index()
        if index is None:
            messagebox.showwarning("Warning", "Please select an entry to edit")
            return
        
        entry = self.hosts_manager.entries[index]
        dialog = EditEntryDialog(self.root, self.hosts_manager, index, entry)
        self.root.wait_window(dialog.dialog)
        self._update_entries_display()
    
    def _remove_selected(self):
        """Remove the selected entry"""
        index = self._get_selected_index()
        if index is None:
            messagebox.showwarning("Warning", "Please select an entry to remove")
            return
        
        entry = self.hosts_manager.entries[index]
        hostnames_str = " ".join(entry.hostnames)
        message = f"Are you sure you want to remove this entry?\n\nIP: {entry.ip}\nHostnames: {hostnames_str}"
        
        if messagebox.askyesno("Confirm Removal", message):
            success, message = self.hosts_manager.remove_entry(index)
            if success:
                self._update_entries_display()
                self.status_var.set(message)
            else:
                messagebox.showerror("Error", message)
    
    def _toggle_selected(self):
        """Toggle the selected entry"""
        index = self._get_selected_index()
        if index is None:
            messagebox.showwarning("Warning", "Please select an entry to toggle")
            return
        
        success, message = self.hosts_manager.toggle_entry(index)
        if success:
            self._update_entries_display()
            self.status_var.set(message)
        else:
            messagebox.showerror("Error", message)
    
    def _save_changes(self):
        """Save changes to the hosts file"""
        message = ("This will save all changes to /etc/hosts.\n\n"
                  "A backup will be created automatically before saving.\n"
                  "Are you sure you want to proceed?")
        
        if messagebox.askyesno("Confirm Save", message):
            success, message = self.hosts_manager.save_hosts_file()
            if success:
                messagebox.showinfo("Success", message)
                self.status_var.set("Changes saved successfully")
            else:
                messagebox.showerror("Error", message)
    
    def _reload_hosts(self):
        """Reload the hosts file"""
        message = ("This will reload the hosts file from disk.\n\n"
                  "Any unsaved changes will be lost.\n"
                  "Are you sure you want to reload?")
        
        if messagebox.askyesno("Confirm Reload", message):
            self._load_hosts_file()
    
    def _create_backup(self):
        """Create a backup of the current hosts file"""
        success, message = self.hosts_manager.create_backup()
        if success:
            messagebox.showinfo("Success", message)
            self.status_var.set("Backup created successfully")
        else:
            messagebox.showerror("Error", message)
    
    def run(self):
        """Start the GUI application"""
        self.root.mainloop()


class AddEntryDialog:
    """Dialog for adding a new hosts entry"""
    
    def __init__(self, parent, hosts_manager):
        self.hosts_manager = hosts_manager
        self.dialog = tk.Toplevel(parent)
        self.dialog.title("Add Host Entry")
        self.dialog.geometry("400x300")
        self.dialog.transient(parent)
        self.dialog.grab_set()
        
        self._setup_ui()
    
    def _setup_ui(self):
        """Setup the dialog UI"""
        main_frame = ttk.Frame(self.dialog, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # IP Address
        ttk.Label(main_frame, text="IP Address:").grid(row=0, column=0, sticky=tk.W, pady=(0, 5))
        self.ip_var = tk.StringVar()
        ip_entry = ttk.Entry(main_frame, textvariable=self.ip_var, width=40)
        ip_entry.grid(row=1, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        
        # Hostnames
        ttk.Label(main_frame, text="Hostnames (space-separated):").grid(row=2, column=0, sticky=tk.W, pady=(0, 5))
        self.hostnames_var = tk.StringVar()
        hostnames_entry = ttk.Entry(main_frame, textvariable=self.hostnames_var, width=40)
        hostnames_entry.grid(row=3, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        
        # Comment
        ttk.Label(main_frame, text="Comment (optional):").grid(row=4, column=0, sticky=tk.W, pady=(0, 5))
        self.comment_var = tk.StringVar()
        comment_entry = ttk.Entry(main_frame, textvariable=self.comment_var, width=40)
        comment_entry.grid(row=5, column=0, sticky=(tk.W, tk.E), pady=(0, 20))
        
        # Buttons
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=6, column=0, pady=(0, 10))
        
        add_btn = ttk.Button(button_frame, text="Add", command=self._add_entry)
        add_btn.grid(row=0, column=0, padx=(0, 10))
        
        cancel_btn = ttk.Button(button_frame, text="Cancel", command=self.dialog.destroy)
        cancel_btn.grid(row=0, column=1)
        
        # Focus on IP entry
        ip_entry.focus()
    
    def _add_entry(self):
        """Add the entry"""
        ip = self.ip_var.get().strip()
        hostnames_str = self.hostnames_var.get().strip()
        comment = self.comment_var.get().strip()
        
        if not ip:
            messagebox.showerror("Error", "IP address is required")
            return
        
        if not hostnames_str:
            messagebox.showerror("Error", "At least one hostname is required")
            return
        
        hostnames = [h.strip() for h in hostnames_str.split()]
        
        success, message = self.hosts_manager.add_entry(ip, hostnames, comment)
        if success:
            messagebox.showinfo("Success", message)
            self.dialog.destroy()
        else:
            messagebox.showerror("Error", message)


class EditEntryDialog:
    """Dialog for editing an existing hosts entry"""
    
    def __init__(self, parent, hosts_manager, index, entry):
        self.hosts_manager = hosts_manager
        self.index = index
        self.entry = entry
        self.dialog = tk.Toplevel(parent)
        self.dialog.title("Edit Host Entry")
        self.dialog.geometry("400x300")
        self.dialog.transient(parent)
        self.dialog.grab_set()
        
        self._setup_ui()
    
    def _setup_ui(self):
        """Setup the dialog UI"""
        main_frame = ttk.Frame(self.dialog, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # IP Address
        ttk.Label(main_frame, text="IP Address:").grid(row=0, column=0, sticky=tk.W, pady=(0, 5))
        self.ip_var = tk.StringVar(value=self.entry.ip)
        ip_entry = ttk.Entry(main_frame, textvariable=self.ip_var, width=40)
        ip_entry.grid(row=1, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        
        # Hostnames
        ttk.Label(main_frame, text="Hostnames (space-separated):").grid(row=2, column=0, sticky=tk.W, pady=(0, 5))
        self.hostnames_var = tk.StringVar(value=" ".join(self.entry.hostnames))
        hostnames_entry = ttk.Entry(main_frame, textvariable=self.hostnames_var, width=40)
        hostnames_entry.grid(row=3, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        
        # Comment
        ttk.Label(main_frame, text="Comment (optional):").grid(row=4, column=0, sticky=tk.W, pady=(0, 5))
        comment_text = self.entry.comment.replace("#", "").strip() if self.entry.comment.startswith("#") else self.entry.comment
        self.comment_var = tk.StringVar(value=comment_text)
        comment_entry = ttk.Entry(main_frame, textvariable=self.comment_var, width=40)
        comment_entry.grid(row=5, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        
        # Enabled checkbox
        self.enabled_var = tk.BooleanVar(value=self.entry.enabled)
        enabled_check = ttk.Checkbutton(main_frame, text="Entry enabled", variable=self.enabled_var)
        enabled_check.grid(row=6, column=0, sticky=tk.W, pady=(0, 20))
        
        # Buttons
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=7, column=0, pady=(0, 10))
        
        save_btn = ttk.Button(button_frame, text="Save", command=self._save_entry)
        save_btn.grid(row=0, column=0, padx=(0, 10))
        
        cancel_btn = ttk.Button(button_frame, text="Cancel", command=self.dialog.destroy)
        cancel_btn.grid(row=0, column=1)
        
        # Focus on IP entry
        ip_entry.focus()
    
    def _save_entry(self):
        """Save the edited entry"""
        ip = self.ip_var.get().strip()
        hostnames_str = self.hostnames_var.get().strip()
        comment = self.comment_var.get().strip()
        enabled = self.enabled_var.get()
        
        if not ip:
            messagebox.showerror("Error", "IP address is required")
            return
        
        if not hostnames_str:
            messagebox.showerror("Error", "At least one hostname is required")
            return
        
        hostnames = [h.strip() for h in hostnames_str.split()]
        
        # Create new entry
        new_entry = HostsEntry(ip, hostnames, comment, enabled)
        is_valid, error_msg = new_entry.is_valid()
        
        if not is_valid:
            messagebox.showerror("Error", error_msg)
            return
        
        # Replace the entry
        self.hosts_manager.entries[self.index] = new_entry
        
        messagebox.showinfo("Success", "Entry updated successfully")
        self.dialog.destroy()


def main():
    """Main entry point"""
    print("Hosts Studio")
    print("=" * 50)
    
    # Debug environment variables
    print(f"DISPLAY: {os.environ.get('DISPLAY', 'Not set')}")
    print(f"XAUTHORITY: {os.environ.get('XAUTHORITY', 'Not set')}")
    print(f"USER: {os.environ.get('USER', 'Not set')}")
    print(f"UID: {os.getuid()}")
    
    # Check if we can connect to X11
    try:
        import tkinter as tk
        test_root = tk.Tk()
        test_root.withdraw()  # Hide the test window
        print("X11 connection successful")
        test_root.destroy()
    except Exception as e:
        print(f"X11 connection failed: {e}")
        print("Trying to fix X11 environment...")
        
        # Try to set common X11 environment variables
        if not os.environ.get('DISPLAY'):
            os.environ['DISPLAY'] = ':0'
        if not os.environ.get('XAUTHORITY'):
            os.environ['XAUTHORITY'] = f'/home/{os.environ.get("SUDO_USER", "root")}/.Xauthority'
        
        print(f"Updated DISPLAY: {os.environ.get('DISPLAY')}")
        print(f"Updated XAUTHORITY: {os.environ.get('XAUTHORITY')}")
    
    # No privilege check; AppImage launcher handles privilege escalation
    try:
        app = HostsStudioGUI()
        print("GUI created successfully, starting mainloop...")
        app.run()
    except KeyboardInterrupt:
        print("\nApplication interrupted by user")
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main() 