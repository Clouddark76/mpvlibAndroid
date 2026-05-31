#!/bin/bash -e

# mpeghdec — Fraunhofer MPEG-H 3D Audio decoder
# Cross-compile for Android ARM using CMake + NDK toolchain
# Source: https://github.com/Fraunhofer-IIS/mpeghdec

. ../../include/path.sh

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf _build$ndk_suffix
	exit 0
else
	exit 255
fi

mkdir -p _build$ndk_suffix
cd _build$ndk_suffix

cmake_args=(
	-G Ninja
	-DCMAKE_TOOLCHAIN_FILE="$DIR/sdk/android-ndk-${v_ndk}/build/cmake/android.toolchain.cmake"
	-DANDROID_ABI="$android_abi"
	-DANDROID_PLATFORM=android-24
	-DCMAKE_INSTALL_PREFIX="$prefix_dir"
	-DCMAKE_BUILD_TYPE=Release
	-DBUILD_SHARED_LIBS=OFF
	# mpeghdec specific options
	-DMPEGHDEC_BUILD_BINARIES=OFF
	-DMPEGHDEC_BUILD_DOC=OFF
)

# ARM NEON for DSP routines (critical for audio decode performance)
if [[ "$ndk_triple" == "aarch64"* ]]; then
	neon_flags="-DHAVE_NEON=1"
	if [ "${ARM_V9A:-0}" -eq 1 ]; then
		neon_flags="$neon_flags -march=armv9-a+sve2+crypto+i8mm"
	fi
	cmake_args+=(-DCMAKE_C_FLAGS="$neon_flags")
	cmake_args+=(-DCMAKE_CXX_FLAGS="$neon_flags")
fi

cmake "${cmake_args[@]}" ..

cmake --build . -j"$cores"
cmake --install .

# Create pkgconfig file for FFmpeg to find
if [ ! -f "$prefix_dir/lib/pkgconfig/libmpeghdec.pc" ]; then
	mkdir -p "$prefix_dir/lib/pkgconfig"
	cat >"$prefix_dir/lib/pkgconfig/libmpeghdec.pc" <<END
Name: libmpeghdec
Description: Fraunhofer MPEG-H 3D Audio Decoder
Version: ${v_mpeghdec}
Libs: -L/usr/local/lib -lmpeghdec
Cflags: -I/usr/local/include
END
fi

echo "mpeghdec installed to $prefix_dir"
