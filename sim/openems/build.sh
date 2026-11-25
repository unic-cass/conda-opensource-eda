#!/usr/bin/env bash
set -ex

: "${CC:?Conda C compiler is not activated}" "${CXX:?Conda C++ compiler is not activated}"
[[ $(command -v "$CC") == "$BUILD_PREFIX"/* ]]
[[ $(command -v "$CXX") == "$BUILD_PREFIX"/* ]]

# CGAL compilation is memory-intensive, particularly on GitHub-hosted runners.
jobs=${CPU_COUNT:-2}
if (( jobs > 2 )); then jobs=2; fi

export VTK_INSTALL_DIR="$SRC_DIR/vtk-install"
bash "$RECIPE_DIR/build-vtk.sh"

# TinyXML is private to this package. Statically link the PIC library into the
# upstream shared libraries instead of installing a generic libtinyxml.so.
mkdir -p build/tinyxml
for source in tinyxml tinyxmlerror tinyxmlparser; do
    "$CXX" ${CXXFLAGS} -fPIC -DTIXML_USE_STL -c "tinyxml/$source.cpp" -o "build/tinyxml/$source.o"
done
"$AR" rcs build/tinyxml/libtinyxml.a build/tinyxml/*.o

# This header is only used by an already-commented-out POV export example.
sed -i '/^#include <vtkPOVExporter.h>/d' QCSXCAD/QCSXCAD.cpp

for component in fparser CSXCAD openEMS QCSXCAD AppCSXCAD; do
    cmake ${CMAKE_ARGS} -G Ninja -S "$component" -B "build/$component" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$PREFIX" \
        -DCMAKE_PREFIX_PATH="$PREFIX" \
        -DCMAKE_INSTALL_RPATH="$PREFIX/lib;$PREFIX/lib/openems" \
        -DENABLE_RPATH=OFF \
        -DFPARSER_ROOT_DIR="$PREFIX" \
        -DCSXCAD_ROOT_DIR="$PREFIX" \
        -DQCSXCAD_ROOT_DIR="$PREFIX" \
        -DHDF5_ROOT="$PREFIX" \
        -DCGAL_DIR="$SRC_DIR/cgal" \
        -DVTK_DIR="$VTK_INSTALL_DIR/lib/cmake/vtk-9.7" \
        -DTinyXML_INCLUDE_DIR="$SRC_DIR/tinyxml" \
        -DTinyXML_LIBRARY="$SRC_DIR/build/tinyxml/libtinyxml.a"
    cmake --build "build/$component" --parallel "$jobs"
    cmake --install "build/$component"
done

mkdir -p "$PREFIX/lib/openems" "$PREFIX/share/licenses/openems"
cp -a "$VTK_INSTALL_DIR/lib/"*.so* "$PREFIX/lib/openems/"
cp -a "$VTK_INSTALL_DIR/share/licenses/VTK" "$PREFIX/share/licenses/openems/"

export OPENEMS_INSTALL_PATH="$PREFIX" CSXCAD_INSTALL_PATH="$PREFIX"
export OPENEMS_NOSCM=1 CSXCAD_NOSCM=1
export LD_LIBRARY_PATH="$PREFIX/lib:$PREFIX/lib/openems${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
"$PYTHON" -m pip install --no-build-isolation --no-deps ./CSXCAD/python
"$PYTHON" -m pip install --no-build-isolation --no-deps ./openEMS/python
