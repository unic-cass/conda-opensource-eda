#!/usr/bin/env bash
set -euo pipefail

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
prefix="$work/tools"
bash "$1" -b -p "$prefix"

export PATH="$prefix/bin:$PATH"
export QT_QPA_PLATFORM=offscreen
"$prefix/bin/python" - <<'PY'
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
assert not any(name in ("librelane", "open_pdks") or name.startswith("open_pdks.") for name in packages)
PY
"$prefix/bin/xschem" -v
"$prefix/bin/magic" -dnull -noconsole --version
"$prefix/bin/ngspice" --version
"$prefix/bin/netgen" -batch quit
"$prefix/bin/yosys" -V
"$prefix/bin/openroad" -version
"$prefix/bin/klayout" -v
"$prefix/bin/Xyce" -v
