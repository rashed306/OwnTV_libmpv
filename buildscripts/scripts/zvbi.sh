#!/bin/bash -e

# OwnTVnew: libzvbi, static — the decoder behind FFmpeg's libzvbi_teletext (DVB teletext subtitles).
# Only the library (src/) and its pkg-config file are built: the capture drivers (V4L, DVB, bktr) and
# the proxy daemon are not needed to decode a transport stream, and use pthread cancellation, which
# bionic lacks.

. ../../include/depinfo.sh
. ../../include/path.sh

build=_build$ndk_suffix

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf $build
	exit 0
else
	exit 255
fi

[ -f configure ] || autoreconf -fi

mkdir -p $build
cd $build

../configure \
	--host=$ndk_triple --with-pic \
	--enable-static --disable-shared \
	--disable-v4l --disable-dvb --disable-bktr --disable-proxy --disable-nls \
	--disable-examples --disable-tests --without-doxygen --without-x \
	CPPFLAGS="$CPPFLAGS -I$prefix_dir/include" LDFLAGS="$LDFLAGS -L$prefix_dir/lib"

make -C src -j$cores
make -C src DESTDIR="$prefix_dir" install
make DESTDIR="$prefix_dir" install-pkgconfigDATA
