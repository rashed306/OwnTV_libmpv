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

# bionic has pthread_create in libc and no libpthread; zvbi's configure insists on linking one. An
# empty archive satisfies -lpthread (here and in zvbi-0.2.pc, which FFmpeg links with).
mkdir -p "$prefix_dir/lib"
[ -f "$prefix_dir/lib/libpthread.a" ] || $AR rcs "$prefix_dir/lib/libpthread.a"

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
