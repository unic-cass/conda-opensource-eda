#!/bin/bash

set -e
set -x

cp $BUILD_PREFIX/share/pkgconfig/*.pc $BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG_PATH="$BUILD_PREFIX/lib/pkgconfig"
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config
$PKG_CONFIG --cflags "gtk+-3.0"
CC="/usr/bin/gcc" ./configure --prefix $PREFIX

make V=1 -j$CPU_COUNT
make V=1 install
