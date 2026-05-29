#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

. "$DIR/include/depinfo.sh"

os=linux
[[ "$OSTYPE" == "darwin"* ]] && os=mac
export os

if [ "$os" == "mac" ]; then
	[ -z "$cores" ] && cores=$(sysctl -n hw.ncpu)
	# various things rely on GNU behaviour
	export INSTALL=`which ginstall`
	export SED=gsed
else
	[ -z "$cores" ] && cores=$(grep -c ^processor /proc/cpuinfo)
fi
cores=${cores:-4}

# configure pkg-config paths if inside buildscripts
if [ -n "$ndk_triple" ]; then
	export PKG_CONFIG_SYSROOT_DIR="$prefix_dir"
	export PKG_CONFIG_LIBDIR="$PKG_CONFIG_SYSROOT_DIR/lib/pkgconfig"
	unset PKG_CONFIG_PATH
fi

toolchain=$(echo "$DIR/sdk/android-ndk-${v_ndk}/toolchains/llvm/prebuilt/"*)
if [ -d "$toolchain" ]; then
	ccache_wrappers="$DIR/ccache-wrappers"
	if [ -d "$ccache_wrappers" ]; then
		export CCACHE_PATH="$toolchain/bin:$PATH${CCACHE_PATH:+:$CCACHE_PATH}"
		export PATH="$ccache_wrappers:$toolchain/bin:$DIR/sdk/android-ndk-${v_ndk}:$DIR/sdk/bin:$PATH"
	else
		export PATH="$toolchain/bin:$DIR/sdk/android-ndk-${v_ndk}:$DIR/sdk/bin:$PATH"
	fi
fi
export ANDROID_HOME="$DIR/sdk/android-sdk-$os"
unset ANDROID_SDK_ROOT ANDROID_NDK_ROOT
