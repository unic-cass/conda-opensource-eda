#!/bin/bash

set -e
set -x

# Identify OS
UNAME_OUT="$(uname -s)"
case "${UNAME_OUT}" in
    Linux*)     OS=Linux;;
    Darwin*)    OS=Mac;;
    *)          OS="${UNAME_OUT}"
                echo "Unknown OS: ${OS}"
                exit;;
esac

if [ "$OS" = "Linux" ]; then
    : "${CC:?Conda C compiler is not activated}"
    [[ $(command -v "$CC") == "$BUILD_PREFIX"/* ]]
    # Tcl/Tk and Cairo headers live in the host prefix.
    CFLAGS="${CFLAGS:-} -std=gnu17" CPPFLAGS="${CPPFLAGS:-} -I$PREFIX/include" \
      ./configure --prefix="${PREFIX}" --with-cairo="${PREFIX}/include" \
        --with-tcl="${PREFIX}/lib" --with-tk="${PREFIX}/lib"
elif [ "$OS" = "Mac" ]; then
    ./configure --prefix="${PREFIX}" --without-cairo --without-opengl --without-x
fi

make V=1 -j$CPU_COUNT

make V=1 install
