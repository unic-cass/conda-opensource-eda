#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
base="$work/tools"
prefix="$base/envs/eda"
bash "$1" -b -p "$base"

# Test the activation command from the release notes, using the bundled Conda.
set +u
source "$base/bin/activate" "$prefix"
set -u
test "$CONDA_PREFIX" = "$prefix"
test "$CONDA_EXE" = "$base/bin/conda"
conda --version
(
    conda activate base
    conda update --name base conda --dry-run
)
export QT_QPA_PLATFORM=offscreen
python - "${INCLUDE_LIBRELANE:-0}" "$base" <<'PY'
import json
import sys
from pathlib import Path

import klayout.db

assert sys.version_info[:3] == (3, 15, 2)
klayout.db.Layout()
def records(prefix):
    packages = (json.loads(record.read_text()) for record in Path(prefix, "conda-meta").glob("*.json"))
    return {package["name"]: package["version"] for package in packages}

base = records(sys.argv[2])
packages = records(sys.prefix)
assert "conda" in base and "openroad" not in base
assert "conda" not in packages and "openroad" in packages
assert packages["spdlog"] == "1.15.3"
assert base["spdlog"] != packages["spdlog"]
assert ("librelane" in packages) == (sys.argv[1] == "1")
assert not any(name == "open_pdks" or name.startswith("open_pdks.") for name in packages)
PY
"$prefix/bin/xschem" -v
"$prefix/bin/magic" -dnull -noconsole --version
"$prefix/bin/ngspice" --version
"$prefix/bin/netgen" -batch quit
"$prefix/bin/yosys" -V
openroad -version
"$prefix/bin/klayout" -v
"$prefix/bin/Xyce" -v

(
    conda activate openems
    test "$CONDA_PREFIX" = "$base/envs/openems"
    python - <<'PY'
import json
import sys
from pathlib import Path

assert sys.version_info[:3] == (3, 15, 2)
records = (json.loads(p.read_text()) for p in Path(sys.prefix, "conda-meta").glob("*.json"))
packages = {p["name"]: p for p in records}
assert packages.pop("openems")["build"] == "py315_defaults_1"
assert all(p["url"].startswith("https://repo.anaconda.com/pkgs/") for p in packages.values())
PY
    python "$repo/sim/openems/smoke.py"
    ldd -r "$CONDA_PREFIX/bin/AppCSXCAD" > "$work/viewer-linkage.txt"
    grep -Fq 'libvtkGUISupportQt-openems' "$work/viewer-linkage.txt"
    if grep -E 'not found|undefined symbol' "$work/viewer-linkage.txt"; then exit 1; fi
)

if [[ ${INCLUDE_LIBRELANE:-0} == 1 ]]; then
    cd "$work"
    "$prefix/bin/python" -c 'from importlib.metadata import version; assert version("librelane") == "3.0.17"'
    "$prefix/bin/librelane" --smoke-test --pdk sky130A
fi
