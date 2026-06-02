#!/bin/bash
set -e

# WSL Compilation Script for MPV Android AAR
# This script compiles the optimized Vulkan/Adreno AAR library from WSL Ubuntu.

echo "=========================================================="
echo "  Vulkan-Optimized MPV Android AAR Compiler for WSL"
echo "=========================================================="

# 1. Sanity Checks
if ! grep -qis "microsoft" /proc/version && ! grep -qis "wsl" /proc/version; then
    echo "Warning: This script is designed to run inside WSL (Windows Subsystem for Linux)."
    echo "It seems you are running this elsewhere. Let's proceed, but make sure you are on Ubuntu/Debian."
    read -p "Press Enter to continue..."
fi

echo "Step 1: Installing Ubuntu dependencies (requires sudo)..."
sudo apt-get update
sudo apt-get install -y \
    autoconf \
    pkg-config \
    libtool \
    ninja-build \
    unzip \
    wget \
    meson \
    python3 \
    nasm \
    git \
    openjdk-17-jdk \
    clang \
    build-essential

# 2. Check Java Version
if ! javac -version &>/dev/null; then
    echo "Error: JDK 17 is required but could not be found. Please ensure openjdk-17-jdk is installed and configured."
    exit 1
fi

echo "Step 2: Checking out/downloading Android SDK and NDK dependencies..."
cd buildscripts
./download.sh

echo "Step 3: Compiling dependencies for standard arm64-v8a..."
./buildall.sh --arch arm64

echo "Step 4: Compiling dependencies for optimized arm64-v9a (Snapdragon 8s Gen 3 / Adreno 735)..."
./buildall.sh --arch arm64-v9a

echo "Step 5: Building final JNI wrappers and packaging AAR..."
./buildall.sh mpv-android

echo "=========================================================="
echo "  Build Completed Successfully!"
echo "=========================================================="
echo "Your optimized AAR file is located at:"
ls -lh ../app/build/outputs/aar/*.aar
echo "=========================================================="
