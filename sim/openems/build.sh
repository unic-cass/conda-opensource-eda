#!/usr/bin/env bash
set -ex

# CGAL compilation is memory-intensive, particularly on GitHub-hosted runners.
jobs=${CPU_COUNT:-2}
if (( jobs > 2 )); then jobs=2; fi

for component in fparser CSXCAD openEMS QCSXCAD AppCSXCAD; do
    cmake ${CMAKE_ARGS} -G Ninja -S "$component" -B "build/$component" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$PREFIX" \
        -DCMAKE_PREFIX_PATH="$PREFIX" \
        -DCMAKE_INSTALL_RPATH="$PREFIX/lib" \
        -DFPARSER_ROOT_DIR="$PREFIX" \
        -DCSXCAD_ROOT_DIR="$PREFIX" \
        -DQCSXCAD_ROOT_DIR="$PREFIX" \
        -DHDF5_ROOT="$PREFIX" \
        -DTinyXML_ROOT_DIR="$PREFIX"
    cmake --build "build/$component" --parallel "$jobs"
    cmake --install "build/$component"
done

export OPENEMS_INSTALL_PATH="$PREFIX" CSXCAD_INSTALL_PATH="$PREFIX"
export OPENEMS_NOSCM=1 CSXCAD_NOSCM=1
export LD_LIBRARY_PATH="$PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
"$PYTHON" -m pip install --no-build-isolation --no-deps ./CSXCAD/python
"$PYTHON" -m pip install --no-build-isolation --no-deps ./openEMS/python
