#! /bin/bash

set -e
set -x

cd $BUILD_PREFIX/bin
ln -s "$AR" ar
cd -

unset VERILATOR_ROOT
autoconf
./configure \
  --prefix=$PREFIX \

make -j$CPU_COUNT
make install

# Keep the debug-mode executables, but omit DWARF from the offline installer.
if [[ "$PKG_BUILD_STRING" == *_installer ]]; then
    : "${STRIP:?Conda binutils must be activated}"
    "$STRIP" --strip-debug "$PREFIX/bin/"{verilator_bin,verilator_bin_dbg,verilator_coverage_bin_dbg}
fi

# Fix hard coded paths in verilator
sed -i -e 's-/.*_build_env/bin/--' $PREFIX/share/verilator/include/verilated.mk
