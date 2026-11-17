#!/bin/bash
# Xyce serial build for conda-forge, bundling Trilinos 14.4.0.
# Adapted from hdl/conda-eda sim/xyce/build.sh; BLAS/LAPACK/AMD come from
# conda-forge packages instead of bundled netlib/SuiteSparse sources.
set -ex

# --- Trilinos 14.4.0 with the modules Xyce needs (see hdl recipe flags).
#     BLAS/LAPACK found via the conda env (libopenblas); AMD via suitesparse.
#     conda-forge suitesparse nests headers under include/suitesparse/.
cd Trilinos
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=$PREFIX ${CMAKE_ARGS} \
  -DCMAKE_BUILD_TYPE=Release \
  -DTrilinos_ENABLE_NOX=ON \
  -DNOX_ENABLE_LOCA=ON \
  -DTrilinos_ENABLE_EpetraExt=ON \
  -DEpetraExt_BUILD_BTF=ON \
  -DEpetraExt_BUILD_EXPERIMENTAL=ON \
  -DEpetraExt_BUILD_GRAPH_REORDERINGS=ON \
  -DTrilinos_ENABLE_TrilinosCouplings=ON \
  -DTrilinos_ENABLE_Ifpack=ON \
  -DTrilinos_ENABLE_AztecOO=ON \
  -DTrilinos_ENABLE_Belos=ON \
  -DTrilinos_ENABLE_Teuchos=ON \
  -DTrilinos_ENABLE_COMPLEX_DOUBLE=ON \
  -DTrilinos_ENABLE_Amesos=ON \
  -DAmesos_ENABLE_KLU=ON \
  -DTrilinos_ENABLE_Amesos2=ON \
  -DAmesos2_ENABLE_KLU2=ON \
  -DAmesos2_ENABLE_Basker=ON \
  -DTrilinos_ENABLE_Sacado=ON \
  -DTrilinos_ENABLE_Stokhos=ON \
  -DTrilinos_ENABLE_Kokkos=ON \
  -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF \
  -DTrilinos_ENABLE_CXX11=ON \
  -DTPL_ENABLE_AMD=ON \
  -DAMD_LIBRARY_DIRS=$PREFIX/lib \
  -DTPL_AMD_INCLUDE_DIRS=$PREFIX/include/suitesparse \
  -DCMAKE_CXX_FLAGS="-I$PREFIX/include/suitesparse" \
  -DTPL_ENABLE_BLAS=ON \
  -DTPL_ENABLE_LAPACK=ON \
  -DBUILD_SHARED_LIBS=ON

cmake --build build --parallel ${CPU_COUNT:-4}
cmake --install build
cd ..

# --- Xyce (serial; plugin support off for the first conda-forge package)
# -DFLEX_INCLUDE_DIR: FlexLexer.h lives in $BUILD_PREFIX/include, which the
#   cross-build FIND_ROOT_PATH re-rooting hides from find_path(); pass the
#   cache var explicitly.
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PREFIX ${CMAKE_ARGS} \
  -DXyce_PLUGIN_SUPPORT=OFF \
  -DFLEX_INCLUDE_DIR=$BUILD_PREFIX/include \
  -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF

cmake --build build --parallel ${CPU_COUNT:-4}
cmake --install build

# CFEP-18: conda-forge packages must not ship static libraries. XyceLib's
# static variant is installed by default; drop it (a `xyce-static` split can
# be added later on the feedstock if there is demand).
rm -f $PREFIX/lib/libxyce.a
