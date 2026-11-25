#!/usr/bin/env bash
set -euo pipefail

# Build the sdist using the Conda compilers and the host's build backend.
: "${CC:?Conda C compiler is not activated}" "${CXX:?Conda C++ compiler is not activated}"
[[ $(command -v "$CC") == "$BUILD_PREFIX"/* ]]
[[ $(command -v "$CXX") == "$BUILD_PREFIX"/* ]]
"$PYTHON" -m pip install . --no-build-isolation --no-deps --ignore-installed -vv
