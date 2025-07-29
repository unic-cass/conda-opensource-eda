#! /bin/bash

set -e
set -x

export CC_FOR_BUILD=$CC

sh ./autoconf.sh
CFLAGS="-I$BUILD_PREFIX/include" LDFLAGS="-L$BUILD_PREFIX/lib" ./configure --prefix=$PREFIX

make -j$CPU_COUNT
make install
