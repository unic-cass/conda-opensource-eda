#!/bin/bash

set -e
set -x

CMAKE_PLATFORM_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE="${RECIPE_DIR}/cross-linux.cmake")

cd $SRC_DIR/qtcharts
LDFLAGS="-Wl,--allow-multiple-definition" cmake -DQT_UNITY_BUILD=OFF -B build -DCMAKE_BUILD_TYPE=RELEASE \
      -DCMAKE_INSTALL_PREFIX=$PREFIX
cmake --build build -j $CPU_COUNT --target install

# export LD_LIBRARY_PATH=$BUILD_PREFIX/lib:$PREFIX/lib

## add bison executable because it is not found by default
cd $SRC_DIR
LDFLAGS="-Wl,--allow-multiple-definition" cmake -B build -DCMAKE_FIND_ROOT_PATH="$BUILD_PREFIX;$PREFIX" \
      -DBISON_EXECUTABLE=$BUILD_PREFIX/bin/bison \
      -DCMAKE_INSTALL_PREFIX=$PREFIX .
cmake --build build -j $CPU_COUNT --target install

