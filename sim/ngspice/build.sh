#!/bin/bash

set -e
set -x
cd $SRC_DIR/third_party/libxaw
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${BUILD_PREFIX}/lib/pkgconfig
CFLAGS="-I${BUILD_PREFIX}/include -L${BUILD_PREFIX}/lib" ./configure --prefix="${BUILD_PREFIX}" --enable-shared=no --enable-static=yes --disable-xaw7

make V=1 -j$CPU_COUNT
make V=1 install
cp -a ${BUILD_PREFIX}/lib/libXaw6.a ${BUILD_PREFIX}/lib/libXaw.a

cd $SRC_DIR
./autogen.sh
./configure --prefix="${PREFIX}" --disable-debug \
	    --with-readline=no \
	    --enable-osdi \
	    --enable-xspice \
	    --enable-cider \
	    --x-includes=$BUILD_PREFIX/include \
	    --x-libraries=$BUILD_PREFIX/lib \
	    --with-x
	    # --enable-openmp
make V=1 -j$CPU_COUNT
make V=1 install
