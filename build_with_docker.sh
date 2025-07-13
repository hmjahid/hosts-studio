#!/bin/bash
# Docker-based AppImage builder for Hosts File Editor

set -e

echo "Hosts File Editor - Docker AppImage Builder"
echo "==========================================="

# Configuration
IMAGE_NAME="hosts-editor-builder"
CONTAINER_NAME="hosts-editor-build"
BUILD_DIR="build"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not available"
    echo "Please install Docker first:"
    echo "  https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running"
    echo "Please start Docker and try again"
    exit 1
fi

# Clean up previous build
print_status "Cleaning up previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Remove previous container if it exists
if docker ps -a --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
    print_status "Removing previous container..."
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
fi

# Build Docker image
print_status "Building Docker image..."
docker build -t "$IMAGE_NAME" .

if [ $? -ne 0 ]; then
    print_error "Failed to build Docker image"
    exit 1
fi

# Run the build in Docker container
print_status "Building AppImage in Docker container..."
docker run --name "$CONTAINER_NAME" \
    -v "$(pwd)/$BUILD_DIR:/app/build" \
    "$IMAGE_NAME"

if [ $? -ne 0 ]; then
    print_error "Failed to build AppImage in Docker container"
    exit 1
fi

# Check if AppImage was created
if [ -f "$BUILD_DIR"/*.AppImage ]; then
    APPIMAGE_FILE=$(ls "$BUILD_DIR"/*.AppImage | head -1)
    print_status "AppImage created successfully: $APPIMAGE_FILE"
    
    # Make AppImage executable
    chmod +x "$APPIMAGE_FILE"
    
    echo ""
    echo "AppImage is ready: $APPIMAGE_FILE"
    echo ""
    echo "To test the AppImage:"
    echo "  sudo $APPIMAGE_FILE"
    echo ""
    echo "To install the AppImage:"
    echo "  chmod +x $APPIMAGE_FILE"
    echo "  ./$APPIMAGE_FILE"
    echo ""
    echo "AppImage features:"
    echo "  - Self-contained application"
    echo "  - No installation required"
    echo "  - Works on any Linux distribution"
    echo "  - Includes Python and all dependencies"
    
else
    print_error "AppImage was not created"
    exit 1
fi

# Clean up container
print_status "Cleaning up Docker container..."
docker rm "$CONTAINER_NAME" 2>/dev/null || true

print_status "Build completed successfully!" 