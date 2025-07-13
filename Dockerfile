FROM ubuntu:20.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-tk \
    python3-pip \
    wget \
    curl \
    git \
    build-essential \
    libfuse2 \
    fuse \
    squashfs-tools \
    && rm -rf /var/lib/apt/lists/*

# Install appimagetool
RUN wget -O /usr/local/bin/appimagetool \
    "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" \
    && chmod +x /usr/local/bin/appimagetool

# Set working directory
WORKDIR /app

# Copy application files
COPY hosts_editor.py .
COPY README.md .
COPY USAGE.md .
COPY build_appimage.sh .

# Copy AppDir files
COPY AppDir/ ./AppDir/

# Make build script executable
RUN chmod +x build_appimage.sh

# Build the AppImage
CMD ["./build_appimage.sh"] 