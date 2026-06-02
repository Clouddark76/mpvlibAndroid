#!/bin/bash
set -e

# Fast rsync to avoid 9p filesystem overhead for excluded heavy folders
echo "Step 1: Synchronizing source code to WSL home directory..."
mkdir -p /home/sagnik/mpvlibAndroid
rsync -a --delete \
  --exclude='.git' \
  --exclude='build' \
  --exclude='.gradle' \
  --exclude='app/build' \
  --exclude='buildscripts/prefix' \
  --exclude='buildscripts/deps' \
  --exclude='buildscripts/sdk' \
  --exclude='buildscripts/_build*' \
  --exclude='wsl-source.tar' \
  /mnt/c/Users/sagni/StudioProjects/mpvlibAndroid/ /home/sagnik/mpvlibAndroid/

cd /home/sagnik/mpvlibAndroid

echo "Step 2: Cleaning any leftover build files just in case..."
rm -rf buildscripts/prefix buildscripts/deps buildscripts/sdk buildscripts/_build* app/build

echo "Step 3: Downloading SDK, NDK, and dependencies..."
cd buildscripts
echo 2007 | sudo -S ./download.sh
echo 2007 | sudo -S chown -R $USER:$USER /home/sagnik/mpvlibAndroid

echo "Step 4: Building arm64-v8a (base) - CLEAN BUILD..."
./buildall.sh --clean --arch arm64

echo "Step 5: Building arm64-v9a (SVE2 optimized) - CLEAN BUILD..."
./buildall.sh --clean --arch arm64-v9a

echo "Step 6: Packaging final mpv-android AAR..."
./buildall.sh mpv-android
cd ..

echo "Step 7: Copying generated AARs back to Windows host..."
mkdir -p /mnt/c/Users/sagni/StudioProjects/mpvlibAndroid/app/build/outputs/aar/
cp -r app/build/outputs/aar/* /mnt/c/Users/sagni/StudioProjects/mpvlibAndroid/app/build/outputs/aar/

echo "ALL DONE!"
