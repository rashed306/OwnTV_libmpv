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
	CPPFLAGS="$CPPFLAGS -I$prefix_dir/include" LDFLAGS="$LDFLAGS -L$prefix_dir/lib" \
	ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes
# ^ a cross build cannot run configure's malloc(0) test, assumes the worst and renames malloc to an
#   rpl_malloc nobody defines; bionic's malloc/realloc are fine.

make -C src -j$cores
make -C src DESTDIR="$prefix_dir" install
make DESTDIR="$prefix_dir" install-pkgconfigDATA

# libtool copies the static libiconv into libzvbi.a as a nested archive, which the linker ignores
# ("neither ET_REL nor LLVM bitcode"). Drop those members and link -liconv the normal way instead.
lib="$prefix_dir/lib/libzvbi.a"
for member in $($AR t "$lib" | grep '\.a$'); do $AR d "$lib" "$member"; done
pc="$prefix_dir/lib/pkgconfig/zvbi-0.2.pc"
sed -i -E 's#[^ ]*libiconv\.(a|la)#-liconv#g' "$pc"
grep -q -- '-liconv' "$pc" || sed -i 's#^Libs: \(.*\)#Libs: \1 -liconv#' "$pc"
echo "zvbi-0.2.pc: $(grep '^Libs' "$pc")"
