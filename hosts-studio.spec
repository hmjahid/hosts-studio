Name:           hosts-studio
Version:        1.0.0
Release:        1%{?dist}
Summary:        A safe GUI application for editing /etc/hosts file

License:        MIT
URL:            https://github.com/hosts-studio/hosts-studio
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch

Requires:       python3
Requires:       python3-tkinter
Requires:       polkit

%description
Hosts Studio is a safe and convenient GUI application for editing the /etc/hosts 
file on Linux systems. It provides a clean interface built with tkinter for 
viewing, adding, removing, and modifying IP-to-hostname mappings with automatic 
backup creation and input validation.

Features:
- Clean GUI interface built with tkinter
- View and edit hosts file entries in a structured format
- Add, remove, and modify IP-to-hostname mappings
- Input validation for IP addresses and hostnames
- Automatic backup creation before saving changes
- Search functionality to quickly find entries
- Root privilege handling for secure file operations

%prep
%autosetup

%build
# No build step needed for Python application

%install
# Create directory structure
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir}/%{name}
mkdir -p %{buildroot}%{_datadir}/applications
mkdir -p %{buildroot}%{_datadir}/icons/hicolor/256x256/apps

# Install main application
install -m 755 hosts_studio.py %{buildroot}%{_datadir}/%{name}/
install -m 644 README.md %{buildroot}%{_datadir}/%{name}/ 2>/dev/null || true
install -m 644 USAGE.md %{buildroot}%{_datadir}/%{name}/ 2>/dev/null || true
install -m 644 RPM_BUILD.md %{buildroot}%{_datadir}/%{name}/ 2>/dev/null || true
install -m 644 MANUAL.md %{buildroot}%{_datadir}/%{name}/ 2>/dev/null || true
install -m 644 PACKAGING.md %{buildroot}%{_datadir}/%{name}/ 2>/dev/null || true
install -m 644 DEB_BUILD.md %{buildroot}%{_datadir}/%{name}/ 2>/dev/null || true
install -m 644 AUR_BUILD.md %{buildroot}%{_datadir}/%{name}/ 2>/dev/null || true

# Create launcher script
cat > %{buildroot}%{_bindir}/%{name} << 'EOF'
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

chmod +x %{buildroot}%{_bindir}/%{name}

# Install desktop file
cat > %{buildroot}%{_datadir}/applications/%{name}.desktop << 'EOF'
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
    install -m 644 hosts-studio.png %{buildroot}%{_datadir}/icons/hicolor/256x256/apps/
else
    # Create a simple SVG icon as fallback
    cat > %{buildroot}%{_datadir}/icons/hicolor/256x256/apps/%{name}.svg << 'EOF'
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

%files
%license LICENSE
%doc README.md USAGE.md RPM_BUILD.md MANUAL.md PACKAGING.md DEB_BUILD.md AUR_BUILD.md
%{_bindir}/%{name}
%{_datadir}/%{name}/
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/256x256/apps/%{name}.*

%changelog
* %(date '+%a %b %d %Y') %{packager} - %{version}-%{release}
- Initial RPM package for Hosts Studio 