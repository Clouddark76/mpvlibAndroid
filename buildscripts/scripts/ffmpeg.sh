#!/bin/bash -e

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

cpu=armv7-a
[[ "$ndk_triple" == "aarch64"* ]] && cpu=armv8-a
[[ "$ndk_triple" == "x86_64"* ]] && cpu=generic
[[ "$ndk_triple" == "i686"* ]] && cpu="i686 --disable-asm"

# Override CPU for v9a optimized builds
if [ "${ARM_V9A:-0}" -eq 1 ]; then
	cpu=armv9-a
fi

cpuflags=
# ARM NEON intrinsics — always enabled for arm64
[[ "$ndk_triple" == "aarch64"* ]] && cpuflags="$cpuflags -DHAVE_NEON=1"
# v9a: explicit SVE2 instruction set
if [ "${ARM_V9A:-0}" -eq 1 ]; then
	cpuflags="$cpuflags -march=armv9-a+sve2+crypto+i8mm"
fi

args=(
	--target-os=android --enable-cross-compile
	--cross-prefix=$ndk_triple- --cc=$CC --pkg-config=pkg-config --nm=llvm-nm
	--arch=${ndk_triple%%-*} --cpu=$cpu
	--extra-cflags="-I$prefix_dir/include $cpuflags" --extra-ldflags="-L$prefix_dir/lib"

	--enable-{jni,mediacodec,mbedtls,libdav1d}

	# === NEW CODECS (FFmpeg n8.1.1) ===

	# VVC (H.266) — Versatile Video Coding via Fraunhofer vvdec
	--enable-libvvdec

	# xHE-AAC / USAC — native FFmpeg decoder (built-in to n8.1.1, no external lib needed)
	# Samsung APV — native decoder/encoder (built-in to n8.1.1, decoder auto-enabled)

	# MPEG-H 3D Audio — Fraunhofer decoder (immersive/object-based 3D audio, ATSC 3.0)
	--enable-libmpeghdec

	# IAMF — Immersive Audio Model and Formats (Alliance for Open Media)
	--enable-libiamf

	# === VULKAN ===
	# Enable Vulkan for compute codecs + video filters
	# Hardware acceleration on any Vulkan 1.3 device:
	#   Adreno 600+ (Snapdragon 845+), Mali-G77+ (Dimensity/Exynos), Xclipse (Exynos 2200+)
	# Vulkan video filters: deinterlace, crossfade, flip, scale
	--enable-vulkan

	# Vulkan Decoding Accelerators
	--enable-hwaccel=h264_vulkan
	--enable-hwaccel=hevc_vulkan
	--enable-hwaccel=av1_vulkan
	--enable-hwaccel=vp9_vulkan

	--disable-static --enable-shared --enable-{gpl,version3}

	# disable unneeded parts
	--disable-{stripping,doc,programs}
	# to keep the build lean we disable some features aggressively:
	# - muxers, encoders: mpv-android does not have any way to use these
	# - devices: no practical use on Android
	--disable-{muxers,encoders,devices}
	# useful for taking screenshots
	--enable-encoder=mjpeg,png
	# useful for the `dump-cache` command
	--enable-muxer=mov,matroska,mpegts

	# ARM NEON intrinsics optimizations (auto-enabled on arm64 but explicit is safer)
	--enable-neon
)

# LCEVC enhancement layer — try V-Nova's decoder, fall back to native metadata passthrough
if [ ! -f "$prefix_dir/.liblcevc_unavailable" ]; then
	args+=(--enable-liblcevc-dec)
	echo "LCEVC: Using V-Nova liblcevc_dec"
else
	# FFmpeg n8.1.1 has native LCEVC metadata parsing even without the external library
	echo "LCEVC: Using FFmpeg native metadata passthrough (liblcevc_dec unavailable)"
fi

../configure "${args[@]}"

make -j$cores
make DESTDIR="$prefix_dir" install
