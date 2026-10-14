#!/bin/bash -e

# OwnTVnew: GNU libiconv, static. zvbi converts teletext character sets with iconv(), which bionic
# only provides from API 28; this build targets API 26.

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

mkdir -p $build
cd $build

../configure \
	--host=$ndk_triple --with-pic \
	--enable-static --disable-shared --disable-nls

make -j$cores
make DESTDIR="$prefix_dir" install
