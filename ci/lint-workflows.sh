#!/usr/bin/env bash
set -euo pipefail

tools_dir=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/actionlint.XXXXXX")
trap 'rm -rf "$tools_dir"' EXIT
archive="$tools_dir/actionlint.tar.gz"
curl --fail --silent --show-error --location --retry 2 --max-time 60 \
    -o "$archive" https://github.com/rhysd/actionlint/releases/download/v1.7.11/actionlint_1.7.11_linux_amd64.tar.gz
echo "900919a84f2229bac68ca9cd4103ea297abc35e9689ebb842c6e34a3d1b01b0a  $archive" | sha256sum -c -
tar -xzf "$archive" -C "$tools_dir" actionlint
"$tools_dir/actionlint" -color -shellcheck= -pyflakes= \
    .github/workflows/Build.yml .github/workflows/Upload.yml
