#!/bin/bash -e

# libiamf — Immersive Audio Model and Formats (IAMF)
# Alliance for Open Media immersive audio codec
# Source: https://github.com/AOMediaCodec/libiamf

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
	-DBUILD_TESTS=OFF
	-DBUILD_EXAMPLES=OFF
)

# ARM NEON + SVE2 flags
if [[ "$ndk_triple" == "aarch64"* ]]; then
	if [ "${ARM_V9A:-0}" -eq 1 ]; then
		cmake_args+=(-DCMAKE_C_FLAGS="-march=armv9-a+sve2+crypto+i8mm")
		cmake_args+=(-DCMAKE_CXX_FLAGS="-march=armv9-a+sve2+crypto+i8mm")
	fi
fi

cmake "${cmake_args[@]}" ..

cmake --build . -j"$cores"
cmake --install .

# Create pkgconfig file for FFmpeg
if [ ! -f "$prefix_dir/lib/pkgconfig/libiamf.pc" ]; then
	mkdir -p "$prefix_dir/lib/pkgconfig"
	cat >"$prefix_dir/lib/pkgconfig/libiamf.pc" <<END
Name: libiamf
Description: Immersive Audio Model and Formats decoder
Version: ${v_libiamf}
Libs: -L/usr/local/lib -liamf
Cflags: -I/usr/local/include
END
fi

echo "libiamf installed to $prefix_dir"
