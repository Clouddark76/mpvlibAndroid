#!/bin/bash -e

# vvdec — Fraunhofer VVC (H.266) decoder
# Cross-compile for Android ARM using CMake + NDK toolchain

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

# vvdec CMake build with NDK toolchain
cmake_args=(
	-G Ninja
	-DCMAKE_TOOLCHAIN_FILE="$DIR/sdk/android-ndk-${v_ndk}/build/cmake/android.toolchain.cmake"
	-DANDROID_ABI="$android_abi"
	-DANDROID_PLATFORM=android-24
	-DCMAKE_INSTALL_PREFIX="$prefix_dir"
	-DCMAKE_BUILD_TYPE=Release
	-DBUILD_SHARED_LIBS=OFF
	-DVVDEC_ENABLE_X86_SIMD=OFF
	# Override compiler check for cross-compilation
	-DVVDEC_OVERRIDE_COMPILER_CHECK=ON
)

# Enable ARM NEON optimizations
if [[ "$ndk_triple" == "aarch64"* ]]; then
	cmake_args+=(-DVVDEC_ENABLE_ARM_SIMD=ON)
fi

# v9a builds: pass SVE2 flags through
if [ "${ARM_V9A:-0}" -eq 1 ]; then
	cmake_args+=(-DCMAKE_C_FLAGS="-march=armv9-a+sve2+crypto+i8mm")
	cmake_args+=(-DCMAKE_CXX_FLAGS="-march=armv9-a+sve2+crypto+i8mm")
fi

# Fix broken SIMDe byte-swap on GitHub Actions / Ubuntu
if [ -f "../source/Lib/CommonLib/BitStream.h" ]; then
	sed -i 's/simde_bswap64/__builtin_bswap64/g' "../source/Lib/CommonLib/BitStream.h"
fi

cmake "${cmake_args[@]}" ..

cmake --build . -j"$cores"
cmake --install .

# Create pkgconfig file if not generated
if [ ! -f "$prefix_dir/lib/pkgconfig/libvvdec.pc" ]; then
	mkdir -p "$prefix_dir/lib/pkgconfig"
	cat >"$prefix_dir/lib/pkgconfig/libvvdec.pc" <<END
Name: libvvdec
Description: Fraunhofer Versatile Video Decoder (VVC/H.266)
Version: ${v_vvdec}
Libs: -L/usr/local/lib -lvvdec
Cflags: -I/usr/local/include
END
fi

echo "vvdec installed to $prefix_dir"
