#!/bin/bash
set -ex

# Qucsator RF searches hardcoded paths for bison unless BISON_DIR is set.
cmake ${CMAKE_ARGS} -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DBISON_DIR="$BUILD_PREFIX/bin" \
    -DWITH_QT6=OFF
cmake --build build --parallel "${CPU_COUNT:-4}"
cmake --install build
