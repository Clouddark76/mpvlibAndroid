#!/bin/bash -e

# go to buildscripts root folder
cd "$( dirname "${BASH_SOURCE[0]}" )/.."

. ./include/depinfo.sh
. ./include/build_config.sh

build_arches=(armv7l arm64)
if [ "$ENABLE_X86_ARCH" = "true" ]; then
    build_arches+=(x86 x86_64)
fi

msg() {
	printf '==> %s\n' "$1"
}

fetch_prefix() {
	if [[ "$CACHE_MODE" == folder ]]; then
		local text=
		if [ -f "$CACHE_FOLDER/id.txt" ]; then
			text=$(cat "$CACHE_FOLDER/id.txt")
		else
			echo "Cache seems to be empty"
		fi
		printf 'Expecting "%s",\nfound     "%s".\n' "$ci_tarball" "$text"
		if [[ "$text" == "$ci_tarball" ]]; then
			if [ ! -f "$CACHE_FOLDER/data.tgz" ] || [ ! -f "$CACHE_FOLDER/python-assets.tgz" ]; then
				echo "Cache metadata matched, but cached payload is incomplete"
				return 1
			fi
			tar -xzf "$CACHE_FOLDER/data.tgz" -C prefix
			tar -xzf "$CACHE_FOLDER/python-assets.tgz" -C ..
			return 0
		fi
	fi
	return 1
}

fetch_ytdlp() {
	mkdir -p deps/yt-dlp
	if [ ! -f deps/yt-dlp/yt-dlp ] || [ "$(cat deps/yt-dlp/version.txt 2>/dev/null || true)" != "$v_ytdlp" ]; then
		msg "Fetching yt-dlp"
		$WGET "https://github.com/yt-dlp/yt-dlp/releases/download/$v_ytdlp/yt-dlp" -O deps/yt-dlp/yt-dlp
		chmod +x deps/yt-dlp/yt-dlp
		echo "$v_ytdlp" >deps/yt-dlp/version.txt
	fi
}

setup_ccache_wrappers() {
	if ! command -v ccache >/dev/null; then
		return 0
	fi

	mkdir -p ccache-wrappers
	local ccache_bin
	ccache_bin=$(command -v ccache)
	local compiler
	local compilers=(
		armv7a-linux-androideabi24-clang
		armv7a-linux-androideabi24-clang++
		aarch64-linux-android24-clang
		aarch64-linux-android24-clang++
	)
	if [ "$ENABLE_X86_ARCH" = "true" ]; then
		compilers+=(
			i686-linux-android24-clang
			i686-linux-android24-clang++
			x86_64-linux-android24-clang
			x86_64-linux-android24-clang++
		)
	fi
	for compiler in "${compilers[@]}"; do
		ln -sf "$ccache_bin" "ccache-wrappers/$compiler"
	done
}

compress_prefix() {
	if [[ "$CACHE_MODE" != folder ]]; then
		return 0
	fi

	mkdir -p "$CACHE_FOLDER"
	if [ ! -w "$CACHE_FOLDER" ]; then
		return 0
	fi

	msg "Compressing the prefix"
	tar -czf "$CACHE_FOLDER/data.tgz" -C prefix .

	local cache_folder_abs
	cache_folder_abs=$(cd "$CACHE_FOLDER" && pwd)
	local asset_paths=()
	local dir
	for dir in ../app/src/main/assets/py.*; do
		[ -d "$dir" ] || continue
		asset_paths+=("${dir#../}")
	done

	if [ ${#asset_paths[@]} -eq 0 ]; then
		echo "No Python assets were generated for cache"
		return 1
	fi

	(cd .. && tar -czf "$cache_folder_abs/python-assets.tgz" "${asset_paths[@]}")
	echo "$ci_tarball" >"$CACHE_FOLDER/id.txt"
}

build_prefix() {
	msg "Building the prefix ($ci_tarball)..."

	msg "Fetching deps"
	IN_CI=1 ./include/download-deps.sh

	# Build everything mpv depends on for every packaged ABI, but not mpv itself.
	for arch in "${build_arches[@]}"; do
		msg "Building dependency prefix for $arch"
		for x in ${dep_mpv[@]}; do
			msg "Building $x for $arch"
			./buildall.sh --arch "$arch" "$x"
		done

		msg "Building Python runtime for $arch"
		./buildall.sh --arch "$arch" python
	done

	compress_prefix
}

export WGET="wget --progress=bar:force"

if [ "$1" = "export" ]; then
	# export variable with unique cache identifier
	echo "CACHE_IDENTIFIER=$ci_tarball"
	exit 0
elif [ "$1" = "install" ]; then
	# install deps
	if [[ -n "$ANDROID_HOME" && -d "$ANDROID_HOME" ]]; then
		msg "Linking existing SDK"
		mkdir -p sdk
		if [ -L sdk/android-sdk-linux ] && [ ! -e sdk/android-sdk-linux ]; then
			rm sdk/android-sdk-linux
		fi
		if [ ! -e sdk/android-sdk-linux ]; then
			ln -sv "$ANDROID_HOME" sdk/android-sdk-linux
		fi
	fi

	msg "Fetching SDK + NDK"
	IN_CI=1 ./include/download-sdk.sh
	setup_ccache_wrappers

	msg "Fetching mpv"

 if [ ! -d deps/mpv/.git ]; then
	 git clone https://github.com/Clouddark75/mpv deps/mpv
 fi

 git -C deps/mpv fetch --tags
 git -C deps/mpv describe --tags --always > deps/mpv/VERSION

	fetch_ytdlp

	msg "Trying to fetch existing prefix"
	mkdir -p prefix
	fetch_prefix || build_prefix
	exit 0
elif [ "$1" = "build" ]; then
	# run build
	:
else
	exit 1
fi

for arch in "${build_arches[@]}"; do
	msg "Building mpv for $arch"
	./buildall.sh --arch "$arch" -n mpv || {
		# show logfile if configure failed
		[ ! -f deps/mpv/_build/config.h ] && cat deps/mpv/_build/meson-logs/meson-log.txt
		exit 1
	}
done

msg "Building mpv-android"
./buildall.sh -n mpv-android

exit 0
