#!/bin/bash -e

. ./include/depinfo.sh

[ -z "$IN_CI" ] && IN_CI=0
[ -z "$WGET" ] && WGET=wget

mkdir -p deps && cd deps

# mbedtls - use git clone with correct directory structure
if [ ! -d mbedtls ]; then
	git clone --depth 1 --branch mbedtls-$v_mbedtls https://github.com/Mbed-TLS/mbedtls.git mbedtls-tmp
	mv mbedtls-tmp mbedtls
	# Initialize submodules (required for config.py and build scripts)
	git -C mbedtls submodule update --init --recursive
fi

# dav1d (canonical repo, GitHub is read-only mirror)
[ ! -d dav1d ] && git clone https://github.com/videolan/dav1d

# vvdec — Fraunhofer VVC (H.266) decoder
if [ ! -d vvdec ]; then
	git clone --depth 1 --branch v$v_vvdec https://github.com/fraunhoferhhi/vvdec.git
fi

# mpeghdec — Fraunhofer MPEG-H 3D Audio decoder
if [ ! -d mpeghdec ]; then
	git clone --depth 1 https://github.com/Fraunhofer-IIS/mpeghdec.git
fi

if [ ! -d libiamf ]; then
	git clone --depth 1 --branch v1.1.0 https://github.com/AOMediaCodec/libiamf.git
	GIT_TERMINAL_PROMPT=0 git -C libiamf submodule update --init --recursive || echo "Warning: some libiamf submodules could not be initialized (likely oar-private)"
fi

# liblcevc — V-Nova LCEVC decoder (BSD-3-Clause)
# Optional: falls back to FFmpeg native LCEVC metadata passthrough if unavailable
if [ ! -d liblcevc ]; then
	if git clone --depth 1 --branch v$v_liblcevc https://github.com/v-novaltd/LCEVCdec.git liblcevc 2>/dev/null; then
		echo "LCEVCdec source downloaded successfully"
	else
		echo "Warning: LCEVCdec source not available, will use FFmpeg native LCEVC passthrough"
		mkdir -p liblcevc
		echo "LCEVCdec not available - FFmpeg native LCEVC passthrough will be used" > liblcevc/README
	fi
fi

# ffmpeg — pinned to n8.1.1
if [ ! -d ffmpeg ]; then
	git clone https://github.com/FFmpeg/FFmpeg ffmpeg
	[ $IN_CI -eq 1 ] && git -C ffmpeg checkout $v_ci_ffmpeg
fi

# freetype2 - latest is 2.14.3
if [ ! -d freetype2 ]; then
	mkdir freetype2
	$WGET https://mirrors.ocf.berkeley.edu/nongnu/freetype/freetype-$v_freetype.tar.gz -O - | \
		tar -xz -C freetype2 --strip-components=1
fi

# fribidi - use vX.Y.Z tag format for releases
if [ ! -d fribidi ]; then
	mkdir fribidi
	$WGET https://github.com/fribidi/fribidi/releases/download/v$v_fribidi/fribidi-$v_fribidi.tar.xz -O - | \
		tar -xJ -C fribidi --strip-components=1
fi

# harfbuzz - latest is 14.2.0
if [ ! -d harfbuzz ]; then
	mkdir harfbuzz
	$WGET https://github.com/harfbuzz/harfbuzz/releases/download/$v_harfbuzz/harfbuzz-$v_harfbuzz.tar.xz -O - | \
		tar -xJ -C harfbuzz --strip-components=1
fi

# unibreak
if [ ! -d unibreak ]; then
	mkdir unibreak
	$WGET https://github.com/adah1972/libunibreak/releases/download/libunibreak_${v_unibreak//./_}/libunibreak-${v_unibreak}.tar.gz -O - | \
		tar -xz -C unibreak --strip-components=1
fi

# libass - use GitHub mirror
[ ! -d libass ] && git clone https://github.com/libass/libass

# lua - use 5.2.x (mpv requires < 5.3)
if [ ! -d lua ]; then
	mkdir lua
	$WGET https://www.lua.org/ftp/lua-$v_lua.tar.gz -O - | \
		tar -xz -C lua --strip-components=1
fi

# mujs
if [ ! -d mujs ]; then
	mkdir mujs
	$WGET https://mujs.com/downloads/mujs-$v_mujs.tar.gz -O - | \
		tar -xz -C mujs --strip-components=1
fi

# openssl
if [ ! -d openssl ]; then
	mkdir openssl
	$WGET https://github.com/openssl/openssl/releases/download/openssl-$v_openssl/openssl-$v_openssl.tar.gz -O - | \
		tar -xz -C openssl --strip-components=1
fi

# curl
if [ ! -d curl ]; then
	mkdir curl
	$WGET https://curl.se/download/curl-$v_curl.tar.gz -O - | \
		tar -xz -C curl --strip-components=1
fi

# shaderc
mkdir -p shaderc
cat >shaderc/README <<'HEREDOC'
shaderc sources are provided by the NDK
see <ndk>/sources/third_party/shaderc
HEREDOC

# libplacebo - use GitHub mirror (haasn/libplacebo)
[ ! -d libplacebo ] && git clone --recursive https://github.com/haasn/libplacebo

# mpv
[ ! -d mpv ] && git clone https://github.com/mpv-player/mpv

# python
if [ ! -d python ]; then
	mkdir python
	$WGET https://www.python.org/ftp/python/$v_python/Python-$v_python.tar.xz -O - | \
		tar -xJ -C python --strip-components=1

	cd python
	# Enables all modules except the explicitly excluded ones.
	python3 ../../include/py/uncomment.py Modules/Setup \
		'_bz2|_ctypes|_lzma|_uuid|_posixshmem|_multiprocessing|readline|_test|grp|termios|resource|_md5|_sha[123]|_tkinter|syslog|_curses|_g?dbm|_(multibyte)?codec|_hashlib|_ssl'
	# Prevent host paths from sneaking in.
	sed -re 's|-[IL]\$\(prefix\)/[^ ]+ | |' -i Modules/Setup
	sed -re 's|-[IL]\$\(exec_prefix\)/[^ ]+ | |' -i Modules/Setup
	printf '%s\n' "_hashlib _hashopenssl.c -lcrypto" "_ssl _ssl.c -lssl -lcrypto" >>Modules/Setup
	cd ..
fi

# yt-dlp
if [ ! -f yt-dlp/yt-dlp ] || [ "$(cat yt-dlp/version.txt 2>/dev/null || true)" != "$v_ytdlp" ]; then
	mkdir -p yt-dlp
	$WGET https://github.com/yt-dlp/yt-dlp/releases/download/$v_ytdlp/yt-dlp -O yt-dlp/yt-dlp
	chmod +x yt-dlp/yt-dlp
	echo "$v_ytdlp" >yt-dlp/version.txt
fi

cd ..
