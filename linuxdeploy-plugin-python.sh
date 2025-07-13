#!/bin/bash
# linuxdeploy-plugin-python.sh
# Simple Python plugin for linuxdeploy

set -e

# Get the AppDir from environment
APPDIR="${APPDIR:-AppDir}"

echo "Python plugin: Setting up Python environment in $APPDIR"

# Create necessary directories
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPDIR/usr/share"

# Copy Python binary
PYTHON_PATH=$(which python3)
if [ -z "$PYTHON_PATH" ]; then
    echo "Error: python3 not found in PATH"
    exit 1
fi

echo "Python plugin: Copying Python from $PYTHON_PATH"
cp "$PYTHON_PATH" "$APPDIR/usr/bin/"

# Copy minimal Python libraries (only what's needed)
PYTHON_LIB_DIR=$(python3 -c "import sys; print(sys.prefix + '/lib')")
if [ -d "$PYTHON_LIB_DIR" ]; then
    echo "Python plugin: Copying Python libraries from $PYTHON_LIB_DIR"
    # Copy only essential libraries
    cp -r "$PYTHON_LIB_DIR"/python* "$APPDIR/usr/lib/" 2>/dev/null || true
fi

# Copy tkinter (required for GUI)
PYTHON_SITE_PACKAGES=$(python3 -c "import site; print(site.getsitepackages()[0])")
if [ -d "$PYTHON_SITE_PACKAGES" ]; then
    echo "Python plugin: Setting up site-packages"
    mkdir -p "$APPDIR/usr/lib/python3.9/site-packages"
    
    # Copy tkinter
    if [ -d "$PYTHON_SITE_PACKAGES/tkinter" ]; then
        cp -r "$PYTHON_SITE_PACKAGES/tkinter" "$APPDIR/usr/lib/python3.9/site-packages/"
    fi
    
    # Copy _tkinter.so
    TKINTER_SO=$(find "$PYTHON_SITE_PACKAGES" -name "_tkinter*.so" 2>/dev/null | head -1)
    if [ -n "$TKINTER_SO" ]; then
        cp "$TKINTER_SO" "$APPDIR/usr/lib/python3.9/site-packages/"
    fi
fi

# Copy minimal system libraries
echo "Python plugin: Copying system libraries"
ldd "$PYTHON_PATH" | grep "=>" | awk '{print $3}' | while read lib; do
    if [ -f "$lib" ]; then
        cp "$lib" "$APPDIR/usr/lib/" 2>/dev/null || true
    fi
done

# Create AppRun script
cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"

if [ "$EUID" -ne 0 ]; then
    if command -v pkexec >/dev/null 2>&1; then
        exec pkexec "$0" "$@"
    elif command -v gksudo >/dev/null 2>&1; then
        exec gksudo "$0" "$@"
    elif command -v kdesudo >/dev/null 2>&1; then
        exec kdesudo "$0" "$@"
    else
        echo "This application requires root privileges to modify /etc/hosts."
        echo "Please run with: sudo $0"
        exit 1
    fi
else
    exec python3 "${HERE}/usr/bin/hosts_studio.py" "$@"
fi
EOF

chmod +x "$APPDIR/AppRun"

echo "Python plugin: Setup complete" 