## Tools-only installer

Standalone mixed-signal EDA tools for Linux x86-64: Xschem, Magic, ngspice,
Netgen, Yosys, OpenROAD, KLayout, and Xyce. All tools, openEMS, and Conda
share a single Python 3.15.2 environment. The installer includes neither
LibreLane nor a PDK.
Both installers are tested on AlmaLinux 8 (glibc 2.28), Ubuntu 22.04, 24.04,
26.04 and 26.10, and Debian 12 and 13.

```bash
sha256sum -c mixed-signal-tools-0-Linux-x86_64.sh.sha256
bash mixed-signal-tools-0-Linux-x86_64.sh -b -p "$HOME/unic-cass-eda"
source "$HOME/unic-cass-eda/bin/activate" "$HOME/unic-cass-eda"
yosys -V
openroad -version
```

The Xschem build was selected for compatibility with the bundle's Tcl/Tk 8.6.
The bundled OpenROAD includes its executables and Python bindings; the C/C++
development files are available in the regular OpenROAD Conda package.

## openEMS (both installers)

Both installers include openEMS 0.37.0, the `openEMS` and `CSXCAD` Python
bindings, and AppCSXCAD. AppCSXCAD shares Qt 5 with OpenROAD and KLayout,
and the NumPy stack uses OpenBLAS. From an activated installation:

```bash
python -c 'from openEMS import openEMS; from CSXCAD import ContinuousStructure'
```

AppCSXCAD requires a graphical session.

## Updating Conda (both installers)

Conda and OpenROAD share the conda-forge `spdlog` 1.17 ABI. To update Conda
without replacing the installed EDA packages, activate the installation and run:

```bash
conda update --name base conda --freeze-installed
```

Choose a fresh install directory with `-p` when migrating from an older installer
with separate environments.
