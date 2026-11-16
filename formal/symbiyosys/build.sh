#!/bin/bash
#****************************************************************************
#* build.sh
#* 
#* Conda package build script for SymbiYosys and supporting solvers
#****************************************************************************

set -e
set -x

# btor2tools/boolector CMakeLists predate CMake 4 (cmake_minimum_required < 3.5);
# the env var form makes every internal cmake invocation accept them
export CMAKE_POLICY_VERSION_MINIMUM=3.5

cwd=`pwd`
CFLAGS_ORIG=${CFLAGS}

cd $BUILD_PREFIX
ln -s "$AR" ar
ln -s "$RANLIB" ranlib
cd -

#********************************************************************
#* Build Boolector
#********************************************************************

unset CFLAGS
# GCC 15 makes -Wincompatible-pointer-types an error; lingeling (pinned by
# boolector's setup scripts) predates the API fix
export CFLAGS="-Wno-error=incompatible-pointer-types"

cd ${cwd}/boolector

echo "CFLAGS=${CFLAGS}"
./contrib/setup-btor2tools.sh
if test $? -ne 0; then exit 1; fi

# --- lingeling: built manually (boolector's setup-lingeling.sh builds the
# pinned source as-is, which fails under GCC 15 / C23 where a parameterless
# 'static void f()' is no longer compatible with the 'void (*)(void *)'
# callback type of lglsetmsglock; we patch the call sites with casts)
LINGELING_SHA=7d5db72420b95ab356c98ca7f7a4681ed2c59c70
mkdir -p deps/lingeling deps/install/lib deps/install/include
curl -sL -o /tmp/lingeling.tar.gz https://github.com/arminbiere/lingeling/archive/${LINGELING_SHA}.tar.gz
tar xzf /tmp/lingeling.tar.gz -C /tmp
cp -r /tmp/lingeling-${LINGELING_SHA}/* deps/lingeling/
cd deps/lingeling
sed -i 's/lglsetmsglock (\(.*\), lockmsg, unlockmsg, 0);/lglsetmsglock (\1, (void (*) (void *)) lockmsg, (void (*) (void *)) unlockmsg, 0);/' treengeling.c
./configure.sh -fPIC
make -j${CPU_COUNT}
cp liblgl.a ../install/lib/
cp lglib.h ../install/include/
cd ../..

echo "CFLAGS=${CFLAGS}"
./configure.sh --prefix ${PREFIX}
if test $? -ne 0; then exit 1; fi

cd build

make -j${CPU_COUNT}
if test $? -ne 0; then exit 1; fi

make install
if test $? -ne 0; then exit 1; fi

CFLAGS=${CFLAGS_ORIG}

#********************************************************************
#* Build Z3
#********************************************************************

# z3 moved from mk_make.py to CMake years ago; use CMake
cd ${cwd}/z3
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${PREFIX} ${CMAKE_ARGS}
cmake --build build -j${CPU_COUNT}
if test $? -ne 0; then exit 1; fi

cmake --install build
if test $? -ne 0; then exit 1; fi

#********************************************************************
#* Build Yices2
#* Note: disabled due to issues finding libgmp
#********************************************************************
#cd ${cwd}
#
#git clone https://github.com/SRI-CSL/yices2.git yices2
#if test $? -ne 0; then exit 1; fi
#
#cd yices2
#autoconf
#if test $? -ne 0; then exit 1; fi
#
#./configure --prefix=${PREFIX}
#if test $? -ne 0; then exit 1; fi
#
#make -j${CPU_COUNT}
#if test $? -ne 0; then exit 1; fi
#
#make install
#if test $? -ne 0; then exit 1; fi

#********************************************************************
#* Build SymbiYosys
#********************************************************************
cd ${cwd}/SymbiYosys
make -j$CPU_COUNT
make PREFIX=${PREFIX} install


