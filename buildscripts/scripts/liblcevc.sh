#!/bin/bash -e

# liblcevc — V-Nova LCEVC (Low Complexity Enhancement Video Coding) decoder
# MPEG-5 Part 2 enhancement layer codec
# Source: https://github.com/v-novaltd/LCEVCdec (BSD-3-Clause)
# Fallback: FFmpeg native LCEVC metadata passthrough if build fails

. ../../include/path.sh

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf _build$ndk_suffix
	exit 0
else
	exit 255
fi

# Check if source was downloaded
if [ ! -f CMakeLists.txt ] && [ ! -f cmake/CMakeLists.txt ]; then
	echo "Warning: LCEVCdec source not found, skipping (FFmpeg native LCEVC passthrough will be used)"
	# Create a marker so FFmpeg knows to skip --enable-liblcevc-dec
	touch "$prefix_dir/.liblcevc_unavailable"
	exit 0
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
	-DVNOVA_LCEVC_DEC_BUILD_TOOLS=OFF
	-DVNOVA_LCEVC_DEC_BUILD_TESTS=OFF
	-DVNOVA_LCEVC_DEC_BUILD_EXAMPLES=OFF
)

# ARM NEON + SVE2 flags
if [[ "$ndk_triple" == "aarch64"* ]]; then
	if [ "${ARM_V9A:-0}" -eq 1 ]; then
		cmake_args+=(-DCMAKE_C_FLAGS="-march=armv9-a+sve2+crypto+i8mm")
		cmake_args+=(-DCMAKE_CXX_FLAGS="-march=armv9-a+sve2+crypto+i8mm")
	fi
fi

if cmake "${cmake_args[@]}" ..; then
	cmake --build . -j"$cores"
	cmake --install .

	# Create pkgconfig file for FFmpeg
	if [ ! -f "$prefix_dir/lib/pkgconfig/lcevc_dec.pc" ]; then
		mkdir -p "$prefix_dir/lib/pkgconfig"
		cat >"$prefix_dir/lib/pkgconfig/lcevc_dec.pc" <<END
Name: lcevc_dec
Description: V-Nova LCEVC Decoder (MPEG-5 Part 2)
Version: ${v_liblcevc}
Libs: -L/usr/local/lib -llcevc_dec
Cflags: -I/usr/local/include
END
	fi

	echo "liblcevc installed to $prefix_dir"
	rm -f "$prefix_dir/.liblcevc_unavailable"
else
	echo "Warning: LCEVCdec build failed, falling back to FFmpeg native LCEVC passthrough"
	touch "$prefix_dir/.liblcevc_unavailable"
fi
