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
# The older Xyce package could silently pick up FFTW from the system.
ldd "$prefix/bin/Xyce" > "$work/xyce-linkage.txt"
fftw=$(awk '$1 == "libfftw3.so.3" && $2 == "=>" { print $3 }' "$work/xyce-linkage.txt")
if [[ ! -f "$prefix/lib/libfftw3.so.3" || ! -f "$fftw" ||
      $(readlink -f "$fftw") != "$(readlink -f "$prefix/lib/libfftw3.so.3")" ]]; then
    cat "$work/xyce-linkage.txt"
    echo 'Xyce must load FFTW from the bundled eda environment.' >&2
    exit 1
fi
(
    cd "$work"
    cp "$repo/installer/mixed-signal.tools/test-data/voltage-divider.cir" .
    Xyce voltage-divider.cir
    python - <<'PY'
import csv
import math

with open("voltage-divider.cir.csv", newline="") as stream:
    values = [float(row["V(OUT)"]) for row in csv.DictReader(stream) if row.get("V(OUT)")]
assert len(values) == 3 and all(math.isclose(a, b, abs_tol=1e-9)
                                for a, b in zip(values, [0, 0.5, 1])), values
PY
)
python "$repo/ci/check-glibc.py" "$base"
python "$repo/ci/check-glibc.py" "$prefix"

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
    python "$repo/ci/check-glibc.py" "$CONDA_PREFIX"
    python "$repo/sim/openems/smoke.py"
    ldd -r "$CONDA_PREFIX/bin/AppCSXCAD" > "$work/viewer-linkage.txt"
    grep -Fq 'libvtkGUISupportQt-openems' "$work/viewer-linkage.txt"
    if grep -E 'not found|undefined symbol' "$work/viewer-linkage.txt"; then exit 1; fi
)

if [[ ${INCLUDE_LIBRELANE:-0} == 1 ]]; then
    cd "$work"
    "$prefix/bin/python" -c 'from libparse import LibertyParser; from importlib.metadata import version; assert version("librelane") == "3.0.17"'
    test "$(command -v perl)" = "$prefix/bin/perl"
    "$prefix/bin/verilator" --version
    "$prefix/bin/yosys" -Q -m eqy_partition -p 'help eqy_partition'
    "$prefix/bin/librelane" --smoke-test --pdk sky130A
fi
