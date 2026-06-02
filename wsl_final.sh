#!/bin/bash
set -e

cd /home/sagnik/mpvlibAndroid/buildscripts

echo "Step 5: Building arm64-v9a (SVE2 optimized) - CLEAN BUILD..."
./buildall.sh --clean --arch arm64-v9a

echo "Step 6: Packaging final mpv-android AAR..."
./buildall.sh mpv-android
cd ..

echo "Step 7: Copying generated AARs back to Windows host..."
mkdir -p /mnt/c/Users/sagni/StudioProjects/mpvlibAndroid/app/build/outputs/aar/
cp -r app/build/outputs/aar/* /mnt/c/Users/sagni/StudioProjects/mpvlibAndroid/app/build/outputs/aar/

echo "ALL DONE!"
