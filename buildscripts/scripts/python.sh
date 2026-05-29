#!/bin/bash -e
set -e

. ../../include/path.sh
. ../../include/depinfo.sh

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf _build$ndk_suffix
	exit 0
else
	exit 255
fi

abi=armeabi-v7a
if [[ "$ndk_triple" == "aarch64"* ]]; then
	abi=arm64-v8a
elif [[ "$ndk_triple" == "x86_64"* ]]; then
	abi=x86_64
elif [[ "$ndk_triple" == "i686"* ]]; then
	abi=x86
fi

hostpy=python${v_python:0:4}
if ! command -v $hostpy >/dev/null; then
	if command -v python3 >/dev/null && python3 -c "import sys; raise SystemExit(0 if sys.version_info[:2] == tuple(map(int, '${v_python:0:4}'.split('.'))) else 1)"; then
		hostpy=python3
	else
		echo "compatible Python ($hostpy) is required to build"
		exit 1
	fi
fi

recompile_py () {
	find . -name '*.pyc' -delete
	$hostpy -OO -m compileall -b -j4 .
	find . -name "__pycache__" -print0 | xargs -0 -- rm -rf
}

prune_stdlib () {
	local delete=(
		pydoc_data turtledemo
		tkinter sqlite3 venv ensurepip dbm
		idlelib multiprocessing unittest
	)
	rm -r "${delete[@]}"
}

export READELF=llvm-readelf
export CFLAGS="-Os -I$prefix_dir/include"
export LDFLAGS="-L$prefix_dir/lib"

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
out="$repo_root/app/src/main/assets/py.$abi"

mkdir -p _build$ndk_suffix "$out"
pushd _build$ndk_suffix >/dev/null

ac_cv_file__dev_ptmx=no ac_cv_file__dev_ptc=no \
MODULE_BUILDTYPE=static \
../configure --host=$ndk_triple --build=${ndk_triple%%-*} \
	--enable-ipv6 --disable-shared --without-ensurepip \
	--disable-test-modules --with-build-python
make -j$cores

rm -rf dest
make DESTDIR="$PWD/dest" install
inst=$PWD/dest/usr/local

rm -f "$out"/python*

cp -v python "$out/python3"
llvm-strip -s "$out/python3"

# Verify that python installation directory exists and contains correct python structure
target_lib_dir="$inst/lib/python${v_python:0:4}"
if [ ! -d "$target_lib_dir" ]; then
	echo "Error: Python installation directory not found at $target_lib_dir" >&2
	echo "Checking $inst/lib contents:" >&2
	ls -la "$inst/lib" || true
	exit 1
fi

pushd "$target_lib_dir" >/dev/null
prune_stdlib
recompile_py
zip -9 "$out/python3${v_python:2:2}.zip" -R '*.pyc'
popd >/dev/null
popd >/dev/null
