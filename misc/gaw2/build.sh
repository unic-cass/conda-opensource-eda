#!/bin/bash

set -e
set -x

export PKG_CONFIG_PATH=$BUILD_PREFIX/x86_64-conda-linux-gnu/sysroot/usr/lib64/pkgconfig:$BUILD_PREFIX/lib/pkgconfig
./configure --prefix $PREFIX

make V=1 -j$CPU_COUNT
make V=1 install
