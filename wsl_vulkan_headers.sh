#!/bin/bash
set -e

echo "Downloading latest Vulkan-Headers..."
cd /home/sagnik/mpvlibAndroid/buildscripts/deps
if [ ! -d "Vulkan-Headers" ]; then
    git clone https://github.com/KhronosGroup/Vulkan-Headers.git
else
    cd Vulkan-Headers
    git pull
    cd ..
fi

echo "Installing Vulkan headers to prefix directories..."
for arch in arm64 arm64-v9a; do
    mkdir -p /home/sagnik/mpvlibAndroid/buildscripts/prefix/$arch/include/
    cp -r Vulkan-Headers/include/vulkan /home/sagnik/mpvlibAndroid/buildscripts/prefix/$arch/include/
    cp -r Vulkan-Headers/include/vk_video /home/sagnik/mpvlibAndroid/buildscripts/prefix/$arch/include/
done

echo "Headers installed successfully! Resuming build..."
cd /home/sagnik/mpvlibAndroid
bash wsl_continue.sh
