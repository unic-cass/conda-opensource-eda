#!/usr/bin/env bash
set -euo pipefail

image=${1:?Usage: test-distribution.sh IMAGE INSTALLER}
installer=$(realpath "${2:?Missing installer path}")
repo=$(cd "$(dirname "$0")/../.." && pwd)

# Verify the exact artifact before running it in a clean x86-64 container.
(cd "$(dirname "$installer")" && sha256sum --check "${installer##*/}.sha256")
docker run --rm --platform linux/amd64 \
    -v "$repo:/repo:ro" -v "$installer:/installer.sh:ro" -w /repo \
    -e "INCLUDE_LIBRELANE=${INCLUDE_LIBRELANE:-0}" -e "TEST_IMAGE=$image" \
    "$image" bash -ec '
        source /etc/os-release
        case "$ID" in
          almalinux) actual_image="$ID:${VERSION_ID%%.*}" ;;
          *) actual_image="$ID:$VERSION_ID" ;;
        esac
        if [[ "$actual_image" != "$TEST_IMAGE" ]]; then
            echo "Expected $TEST_IMAGE, got $ID:$VERSION_ID." >&2
            exit 1
        fi
        echo "Testing $PRETTY_NAME ($(getconf GNU_LIBC_VERSION))"
        case "$ID" in
          almalinux)
            test "$(getconf GNU_LIBC_VERSION)" = "glibc 2.28"
            dnf -qy install ca-certificates binutils mesa-libGL mesa-libGLU \
              libXext libXrender libXi libXrandr libXcursor libxkbcommon
            ;;
          ubuntu|debian)
            export DEBIAN_FRONTEND=noninteractive
            apt-get -qq update
            apt-get -qy install --no-install-recommends ca-certificates binutils \
              libgl1 libglu1-mesa libxext6 libxrender1 libxi6 libxrandr2 libxcursor1 libxkbcommon0
            ;;
          *) echo "Unsupported test distribution: $ID" >&2; exit 1 ;;
        esac
        bash installer/mixed-signal.tools/smoke-test.sh /installer.sh
    '
