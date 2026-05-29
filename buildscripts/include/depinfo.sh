#!/bin/bash -e

## Dependency versions
# Make sure to keep v_ndk and v_ndk_n in sync, both are listed on the NDK download page

v_sdk=14742923_latest
v_ndk=r28c
v_ndk_n=28.2.13676358
v_sdk_platform=36
v_sdk_build_tools=36.0.0

v_lua=5.2.4
v_unibreak=7.0
v_harfbuzz=14.2.0
v_fribidi=1.0.16
v_freetype=2.14.3
v_mbedtls=3.6.5
v_openssl=3.5.5
v_python=3.13.12
v_ytdlp=2026.03.17
v_curl=8.20.0
v_mujs=1.3.9


## Dependency tree
# I would've used a dict but putting arrays in a dict is not a thing

dep_mbedtls=()
dep_dav1d=()
dep_ffmpeg=(mbedtls dav1d)
dep_freetype2=()
dep_fribidi=()
dep_harfbuzz=()
dep_unibreak=()
dep_libass=(freetype2 fribidi harfbuzz unibreak)
dep_lua=()
dep_mujs=()
dep_openssl=()
dep_python=(openssl)
dep_curl=(mbedtls)
dep_shaderc=()
dep_libplacebo=(shaderc)
dep_mpv=(ffmpeg libass lua libplacebo mujs curl)
dep_mpv_android=(mpv python)


## for CI workflow

# pinned ffmpeg revision
v_ci_ffmpeg=n8.1

# filename used to uniquely identify a build prefix
ci_tarball="prefix-all-ndk-${v_ndk}-lua-${v_lua}-mujs-${v_mujs}-unibreak-${v_unibreak}-harfbuzz-${v_harfbuzz}-fribidi-${v_fribidi}-freetype-${v_freetype}-mbedtls-${v_mbedtls}-openssl-${v_openssl}-python-${v_python}-curl-${v_curl}-ffmpeg-${v_ci_ffmpeg}.tgz"
