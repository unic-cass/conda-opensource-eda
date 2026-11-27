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

# Identify OS
UNAME_OUT="$(uname -s)"
case "${UNAME_OUT}" in
    Linux*)     OS=Linux;;
    Darwin*)    OS=Mac;;
    *)          OS="${UNAME_OUT}"
                echo "Unknown OS: ${OS}"
                exit;;
esac

if [[ $OS == "Mac" ]]; then
    export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
    cd $PREFIX
    # This is required because we have an external SDK file. The default
    # Qt build explicitly looks for the SDK in /System/Library/Frameworks/
    # and ignores any attempt to set the SDK root any other way.
    if grep -q _GL_INCDIRS "$PREFIX/lib/cmake/Qt5Gui/Qt5GuiConfigExtras.cmake"; then
        sed '1,11d' < "$PREFIX/lib/cmake/Qt5Gui/Qt5GuiConfigExtras.cmake" | sed '1 s|.*|set(_qt5gui_OPENGL_INCLUDE_DIR "'$CONDA_BUILD_SYSROOT'/System/Library/Frameworks/OpenGL.framework/Headers")|' > "$PREFIX/lib/cmake/Qt5Gui/Qt5GuiConfigExtras.cmake.bak"
        mv "$PREFIX/lib/cmake/Qt5Gui/Qt5GuiConfigExtras.cmake.bak" "$PREFIX/lib/cmake/Qt5Gui/Qt5GuiConfigExtras.cmake"
    fi
fi

CMAKE_PLATFORM_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE="${RECIPE_DIR}/cross-linux.cmake")

# The installer needs the executables and shared libraries, not OpenROAD's
# C/C++ SDK. Record the host files first so only our files are removed.
sdk_files() {
    (set -o pipefail; cd "$PREFIX"; find lib include share -mindepth 1 \( -type f -o -type l \) \
        \( -path 'include/*' -o -path 'lib/cmake/*' -o -path 'lib/pkgconfig/*' \
           -o -path 'share/pkgconfig/*' -o -path 'lib/*.a' -o -path 'lib/*.la' \) \
        -print0 | LC_ALL=C sort -z)
}
if [[ "$PKG_BUILD_STRING" == *_installer_py* ]]; then
    mkdir -p "$PREFIX"/{lib,include,share}
    sdk_files > "$SRC_DIR/sdk-before.list"
fi

cd $SRC_DIR/third_party/lemon
cmake -B build  -DCMAKE_INSTALL_PREFIX=$PREFIX ${CMAKE_PLATFORM_FLAGS[@]} .
cmake --build build -j $CPU_COUNT --target install

cd $SRC_DIR/third_party/cudd
./configure --prefix="${PREFIX}"
make V=1 -j$CPU_COUNT
make V=1 install

cd $SRC_DIR/third_party/or-tools
cmake -B build  -DBUILD_DEPS:BOOL=ON \
      -DBUILD_EXAMPLES:BOOL=OFF \
      -DBUILD_SAMPLES:BOOL=OFF \
      -DBUILD_TESTING:BOOL=OFF  \
      -DCMAKE_CXX_FLAGS="-w" \
      -DCMAKE_C_FLAGS="-w" \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      ${CMAKE_PLATFORM_FLAGS[@]} .
cmake --build build --config Release -j $CPU_COUNT --target install

# CMake 3.31 does not search for Python 3.15 by default. Use the host
# interpreter's headers and shared library rather than searching the build env.
python_flags=()
if [[ $OS == "Linux" ]]; then
    python_include=$("$PYTHON" -c 'import sysconfig; print(sysconfig.get_path("include"))')
    # Conda's Python can report a static LDLIBRARY even when the host provides
    # the shared library that OpenROAD needs to embed Python.
    python_ldversion=$("$PYTHON" -c 'import sysconfig; print(sysconfig.get_config_var("LDVERSION"))')
    python_library="$PREFIX/lib/libpython${python_ldversion}.so"
    test -f "$python_library"
    python_flags=(-DPython3_INCLUDE_DIR="$python_include" -DPython3_LIBRARY="$python_library")
fi

## there is a bug with SPDLOG 1.11 and fmt 0.9
## disable SPDLOG_FMT_EXTERNAL
cd $SRC_DIR
cmake -B build -DTCL_LIB_PATHS="$BUILD_PREFIX;$PREFIX" \
      -DCMAKE_FIND_ROOT_PATH="$BUILD_PREFIX;$PREFIX" \
      -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
      -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
      -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=ONLY \
      -DUSE_SYSTEM_BOOST=ON \
      -DSPDLOG_FMT_EXTERNAL=OFF \
      -DCMAKE_CXX_FLAGS="-I$BUILD_PREFIX/include -I$PREFIX/include -L$BUILD_PREFIX/lib -L$PREFIX/lib -lxcb-glx -lxcb-dri2" \
      -DCMAKE_C_FLAGS="-I$BUILD_PREFIX/include -I$PREFIX/include -L$BUILD_PREFIX/lib -L$PREFIX/lib -lxcb-glx -lxcb-dri2" \
      -DCMAKE_EXE_LINKER_FLAGS="-L$BUILD_PREFIX/lib -L$PREFIX/lib -lxcb-glx -lxcb-dri2" \
      -DENABLE_TESTS=OFF -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DFLEX_INCLUDE_DIR=$BUILD_PREFIX/include \
      "${python_flags[@]}" \
      ${CMAKE_PLATFORM_FLAGS[@]} .

cmake --build build -j $CPU_COUNT --target install

if [[ "$PKG_BUILD_STRING" == *_installer_py* ]]; then
    sdk_files > "$SRC_DIR/sdk-after.list"
    (set -o pipefail; cd "$PREFIX"; LC_ALL=C comm -z -13 "$SRC_DIR/sdk-before.list" "$SRC_DIR/sdk-after.list" \
        | xargs -0 -r rm --)
fi
