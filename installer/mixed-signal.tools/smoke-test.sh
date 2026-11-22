#!/usr/bin/env bash
set -euo pipefail

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
prefix="$work/tools"
bash "$1" -b -p "$prefix"

export PATH="$prefix/bin:$PATH"
export QT_QPA_PLATFORM=offscreen
"$prefix/bin/python" - "${INCLUDE_LIBRELANE:-0}" <<'PY'
import json
import sys
from pathlib import Path

import klayout.db

assert sys.version_info[:3] == (3, 15, 2)
klayout.db.Layout()
packages = {
    json.loads(record.read_text())["name"]
    for record in Path(sys.prefix, "conda-meta").glob("*.json")
}
assert ("librelane" in packages) == (sys.argv[1] == "1")
assert not any(name == "open_pdks" or name.startswith("open_pdks.") for name in packages)
PY
"$prefix/bin/xschem" -v
"$prefix/bin/magic" -dnull -noconsole --version
"$prefix/bin/ngspice" --version
"$prefix/bin/netgen" -batch quit
"$prefix/bin/yosys" -V
"$prefix/bin/openroad" -version
"$prefix/bin/klayout" -v
"$prefix/bin/Xyce" -v

if [[ ${INCLUDE_LIBRELANE:-0} == 1 ]]; then
    cd "$work"
    "$prefix/bin/python" -c 'from importlib.metadata import version; assert version("librelane") == "3.0.17"'
    "$prefix/bin/librelane" --smoke-test --pdk sky130A
fi
