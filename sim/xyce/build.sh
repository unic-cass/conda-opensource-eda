#!/bin/bash


# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -ex

# echo manual | perl -mCPAN::FirstTime -e 'CPAN::FirstTime->init(autoconfig => 1)'
# yes | cpan install Alien::Libxml2 XML::SAX XML::NamespaceSupport

# cd $SRC_DIR/perl-xml-libxml
# perl Makefile.PL
# make
# make install

echo "Build dependencies for xyce"
cmake --version
cd $SRC_DIR/adms
cmake -B build -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=$PREFIX .
cmake --build build -j $CPU_COUNT --target install

cd $SRC_DIR/blas
cmake -B build -DCMAKE_INSTALL_PREFIX=$PREFIX .
cmake --build build -j $CPU_COUNT --target install

cd $SRC_DIR/lapack
cmake -B build -DCMAKE_INSTALL_PREFIX=$PREFIX .
cmake --build build -j $CPU_COUNT --target install

cd $SRC_DIR/amd
cmake -B build -DSuiteSparsePath=. -DCMAKE_INSTALL_PREFIX=$PREFIX $SRC_DIR/cmake/trilinos/AMD
cmake --build build -j $CPU_COUNT --target install

cd $SRC_DIR/Trilinos
FLAGS="-O3" cmake -B build -DCMAKE_INSTALL_PREFIX=$PREFIX \
     -DCMAKE_CXX_FLAGS="$FLAGS" \
     -DCMAKE_C_FLAGS="$FLAGS" \
     -DCMAKE_Fortran_FLAGS="$FLAGS" \
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
     -DTPL_AMD_INCLUDE_DIRS=$PREFIX/include \
     -DTPL_ENABLE_BLAS=ON \
     -DTPL_ENABLE_LAPACK=ON \
     -DTPL_BLAS_LIBRARIES="$PREFIX/lib/libblas.a;gfortran;m" \
     -DTPL_LAPACK_LIBRARIES="$PREFIX/lib/liblapack.a;gfortran;m" \
     -DBUILD_SHARED_LIBS=ON \
     -D HAVE_dggsvd3_POST=1 . 

cmake --build build -j $CPU_COUNT --target install

cd $SRC_DIR
cmake -B build -DCMAKE_FIND_ROOT_PATH="$BUILD_PREFIX;$PREFIX" \
      -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
      -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
      -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=ONLY \
      -D Xyce_PLUGIN_SUPPORT=ON \
      -DCMAKE_INSTALL_PREFIX=$PREFIX .

cmake --build build -j $CPU_COUNT --target install
