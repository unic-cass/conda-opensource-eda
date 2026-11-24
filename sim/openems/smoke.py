"""Exercise both bindings and the installed command-line solver."""

import os
from importlib.metadata import version
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory

import numpy as np
from CSXCAD import ContinuousStructure
from openEMS.openEMS import openEMS

assert version("openEMS") == "0.37.0"
assert version("CSXCAD") == "0.7.0"

with TemporaryDirectory() as work:
    csx = ContinuousStructure()
    grid = csx.GetGrid()
    grid.SetDeltaUnit(1e-3)
    for axis in "xyz":
        grid.SetLines(axis, np.arange(-5, 6))

    fdtd = openEMS(NrTS=20)
    fdtd.SetCSX(csx)
    fdtd.SetGaussExcite(1e9, 0.5e9)
    fdtd.SetBoundaryCond(["PEC"] * 6)
    fdtd.AddLumpedPort(1, 50, [0, 0, -1], [0, 0, 1], "z", excite=1)
    fdtd.Write2XML(str(Path(work, "smoke.xml")))
    # The Python solver changes the working directory during Run().
    cwd = os.getcwd()
    try:
        fdtd.Run(work, verbose=0, numThreads=1)
    finally:
        os.chdir(cwd)
    probe = Path(work, "port_ut_1")
    assert probe.stat().st_size > 0
    probe.unlink()
    result = subprocess.run(["openEMS", "smoke.xml", "--numThreads=1"], cwd=work,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    print(result.stdout)
    result.check_returncode()
    assert probe.stat().st_size > 0
