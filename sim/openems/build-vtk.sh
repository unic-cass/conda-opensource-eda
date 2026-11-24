#!/usr/bin/env bash
set -euo pipefail

# Only build the C++ modules used by the solver and geometry editor. A unique
# library suffix allows this VTK build to coexist with a normal vtk install.
modules=(FiltersParallel GUISupportQt IOGeometry IOImage IOLegacy IOPLY IOXML
         InteractionStyle InteractionWidgets RenderingAnnotation RenderingFreeType
         RenderingLOD RenderingOpenGL2)
options=()
for module in "${modules[@]}"; do
    options+=("-DVTK_MODULE_ENABLE_VTK_${module}=YES")
done

cmake ${CMAKE_ARGS:-} -G Ninja -S vtk -B build/vtk \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DCMAKE_INSTALL_PREFIX="$VTK_INSTALL_DIR" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    '-DCMAKE_INSTALL_RPATH=$ORIGIN;$ORIGIN/..' \
    -DBUILD_SHARED_LIBS=ON \
    -DVTK_CUSTOM_LIBRARY_SUFFIX=openems-9.7 \
    -DVTK_BUILD_TESTING=OFF \
    -DVTK_WRAP_PYTHON=OFF \
    -DVTK_ENABLE_WRAPPING=OFF \
    -DVTK_FORBID_DOWNLOADS=ON \
    -DVTK_GROUP_ENABLE_StandAlone=DONT_WANT \
    -DVTK_GROUP_ENABLE_Rendering=DONT_WANT \
    -DVTK_GROUP_ENABLE_Qt=DONT_WANT \
    -DVTK_USE_X=ON \
    -DVTK_QT_VERSION=6 \
    "${options[@]}"
jobs=${CPU_COUNT:-2}
available=$(nproc)
if (( jobs > available )); then jobs=$available; fi
if (( jobs > 16 )); then jobs=16; fi
cmake --build build/vtk --parallel "$jobs"
cmake --install build/vtk
