#!/bin/bash

set -e
set -x

which pkg-config

# Identify OS
UNAME_OUT="$(uname -s)"
case "${UNAME_OUT}" in
    Linux*)     OS=Linux;;
    Darwin*)    OS=Mac;;
    *)          OS="${UNAME_OUT}"
                echo "Unknown OS: ${OS}"
                exit;;
esac
echo "Build started for ${OS}..."
echo "PREFIX := $PREFIX" > Makefile.conf
echo "ENABLE_READLINE := 0" >> Makefile.conf
echo "CONFIG := gcc" >> Makefile.conf
echo "ENABLE_TCL := 1" >> Makefile.conf
echo "ENABLE_PLUGINS := 1" >> Makefile.conf

if [[ $OS == "Linux" ]]; then
    ln -sf $GCC $BUILD_PREFIX/bin/gcc
    ln -sf $CXX $BUILD_PREFIX/bin/g++
    make CONFIG=gcc V=1 -j$CPU_COUNT
elif [[ $OS == "Mac" ]]; then
    make config-mac
fi


# make V=1 -j$CPU_COUNT
make install

export LD_LIBRARY_PATH=$PREFIX/lib
$PREFIX/bin/yosys -V
$PREFIX/bin/yosys-abc -v 2>&1 | grep compiled
