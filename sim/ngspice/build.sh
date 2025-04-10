#!/bin/bash

set -e
set -x

./autogen.sh
./configure --prefix="${PREFIX}" --disable-debug --with-readline=no --enable-osdi
make V=1 -j$CPU_COUNT
make V=1 install
