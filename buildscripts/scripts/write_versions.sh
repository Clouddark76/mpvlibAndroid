# Credit goes to jmir1
# get versions from source code
. buildscripts/include/depinfo.sh

case "$1" in
	"") prefix_name=armv7l ;;
	-arm64) prefix_name=arm64 ;;
	-x86) prefix_name=x86 ;;
	-x64) prefix_name=x86_64 ;;
	*) prefix_name=armv7l ;;
esac

MPV_VERSION=$(grep "#define VERSION" "buildscripts/deps/mpv/_build$1/common/version.h" | cut -d '"' -f 2)
if [ -f "buildscripts/deps/libplacebo/_build$1/src/version.h" ]; then
	LIBPLACEBO_VERSION=$(grep "#define BUILD_VERSION" "buildscripts/deps/libplacebo/_build$1/src/version.h" | cut -d '"' -f 2)
elif [ -f "buildscripts/prefix/$prefix_name/lib/pkgconfig/libplacebo.pc" ]; then
	LIBPLACEBO_VERSION=$(sed -n 's/^Version: //p' "buildscripts/prefix/$prefix_name/lib/pkgconfig/libplacebo.pc")
else
	LIBPLACEBO_VERSION=unknown
fi
if [ -d buildscripts/deps/ffmpeg/.git ]; then
	FFMPEG_VERSION=$(cd buildscripts/deps/ffmpeg/ && git rev-parse --short HEAD)
else
	FFMPEG_VERSION=$v_ci_ffmpeg
fi
YTDLP_VERSION=$v_ytdlp
# get build date from compiled object file
START_RODATA=0x$(readelf "buildscripts/deps/mpv/_build$1/libmpv.so.p/common_version.c.o" -S | grep .rodata | cut -d ' ' -f 27)
START=0x$(readelf "buildscripts/deps/mpv/_build$1/libmpv.so.p/common_version.c.o" -s | grep mpv_builddate | cut -d ' ' -f 7)
SIZE=$(readelf "buildscripts/deps/mpv/_build$1/libmpv.so.p/common_version.c.o" -s | grep mpv_builddate | cut -d ' ' -f 11)
SKIP=$(($START_RODATA + $START - 1))
dd if=buildscripts/deps/mpv/_build$1/libmpv.so.p/common_version.c.o of=date.txt bs=1 skip=$SKIP count=$SIZE
DATE=$(cat date.txt)
rm date.txt
# write versions to Utils.kt
sed -i "s/%MPV_VERSION%/$MPV_VERSION/g" app/src/main/java/is/xyz/mpv/Utils.kt
sed -i "s/%LIBPLACEBO_VERSION%/$LIBPLACEBO_VERSION/g" app/src/main/java/is/xyz/mpv/Utils.kt
sed -i "s/%FFMPEG_VERSION%/$FFMPEG_VERSION/g" app/src/main/java/is/xyz/mpv/Utils.kt
sed -i "s/%DATE%/$DATE/g" app/src/main/java/is/xyz/mpv/Utils.kt
sed -i "s/%YTDLP_VERSION%/$YTDLP_VERSION/g" app/src/main/java/is/xyz/mpv/Utils.kt
