#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
prefix="$work/tools"
bash "$1" -b -p "$prefix"

# Test the activation command from the release notes, using the bundled Conda.
set +u
source "$prefix/bin/activate" "$prefix"
set -u
test "$CONDA_PREFIX" = "$prefix"
test "$CONDA_EXE" = "$prefix/bin/conda"
conda --version
conda update --name base conda --solver libmamba --freeze-installed --dry-run
export QT_QPA_PLATFORM=offscreen
python - "${INCLUDE_LIBRELANE:-0}" "$prefix" <<'PY'
import ctypes
import json
import sys
from pathlib import Path

import klayout.db

assert sys.version_info[:3] == (3, 15, 2)
assert sys.prefix == sys.argv[2]
assert ctypes.CFUNCTYPE(ctypes.c_int)(lambda: 42)() == 42
klayout.db.Layout()
prefix = Path(sys.prefix)
assert not list(prefix.glob("envs/*/conda-meta"))
records = (json.loads(record.read_text()) for record in (prefix / "conda-meta").glob("*.json"))
packages = {package["name"]: package for package in records}
assert {"conda", "openroad", "openems", "yosys"} <= packages.keys()
for name, abi in (("libffi", "3.7."), ("spdlog", "1.17."), ("qt-main", "5.15.15")):
    assert packages[name]["version"].startswith(abi), packages[name]
    assert packages[name]["url"].startswith("https://conda.anaconda.org/conda-forge/")
assert packages["openems"]["build"] == "py315_installer_qt5_2"
assert packages["openroad"]["build"].endswith("_installer_py315")
assert not any(path.startswith("lib/") and path.endswith(".a") for path in packages["openroad"]["files"])
assert packages["libblas"]["build"].endswith("_openblas")
assert not {"qtbase", "qt6-main", "mkl", "intel-openmp"} & packages.keys()
assert ("librelane" in packages) == (sys.argv[1] == "1")
if "librelane" in packages:
    assert packages["verilator"]["build"].endswith("_installer")
assert not any(name == "open_pdks" or name.startswith("open_pdks.") for name in packages)
PY
"$prefix/bin/xschem" -v
"$prefix/bin/magic" -dnull -noconsole --version
"$prefix/bin/ngspice" --version
"$prefix/bin/netgen" -batch quit
"$prefix/bin/yosys" -V
openroad -version
sta -version
printf 'import odb\nassert odb.dbDatabase.create() is not None\n' > "$work/openroad.py"
openroad -python -exit "$work/openroad.py"
ldd "$prefix/bin/openroad" > "$work/openroad-linkage.txt"
for lib in libspdlog.so.1.17 libfmt.so.12 libyaml-cpp.so.0.8; do
    if ! awk -v lib="$lib" -v prefix="$prefix/" \
        '$1 == lib && $2 == "=>" && index($3, prefix) == 1 { found = 1 } END { exit !found }' \
        "$work/openroad-linkage.txt"; then
        cat "$work/openroad-linkage.txt"
        echo "OpenROAD did not load bundled $lib." >&2
        exit 1
    fi
done
"$prefix/bin/klayout" -v
"$prefix/bin/Xyce" -v
# The older Xyce package could silently pick up FFTW from the system.
ldd "$prefix/bin/Xyce" > "$work/xyce-linkage.txt"
fftw=$(awk '$1 == "libfftw3.so.3" && $2 == "=>" { print $3 }' "$work/xyce-linkage.txt")
if [[ ! -f "$prefix/lib/libfftw3.so.3" || ! -f "$fftw" ||
      $(readlink -f "$fftw") != "$(readlink -f "$prefix/lib/libfftw3.so.3")" ]]; then
    cat "$work/xyce-linkage.txt"
    echo 'Xyce must load FFTW from the bundled environment.' >&2
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
python "$repo/ci/check-glibc.py" "$prefix"

python "$repo/sim/openems/smoke.py"
ldd -r "$prefix/bin/AppCSXCAD" > "$work/viewer-linkage.txt"
grep -Fq 'libvtkGUISupportQt-openems' "$work/viewer-linkage.txt"
grep -Fq 'libQt5Core.so.5' "$work/viewer-linkage.txt"
if grep -E 'not found|undefined symbol|libQt6' "$work/viewer-linkage.txt"; then exit 1; fi

if [[ ${INCLUDE_LIBRELANE:-0} == 1 ]]; then
    cd "$work"
    "$prefix/bin/python" -c 'from libparse import LibertyParser; from importlib.metadata import version; assert version("librelane") == "3.0.17"'
    test "$(command -v perl)" = "$prefix/bin/perl"
    "$prefix/bin/verilator" --version
    printf 'module tiny; endmodule\n' > tiny.sv
    "$prefix/bin/verilator" --debug --lint-only tiny.sv > verilator-debug.log 2>&1 || { cat verilator-debug.log; exit 1; }
    "$prefix/bin/yosys" -Q -m eqy_partition -p 'help eqy_partition'
    "$prefix/bin/librelane" --smoke-test --pdk sky130A
fi
