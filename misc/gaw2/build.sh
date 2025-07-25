#!/bin/bash

set -e
set -x

export PKG_CONFIG_PATH=$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config
./configure --prefix $PREFIX

make V=1 -j$CPU_COUNT
make V=1 install
