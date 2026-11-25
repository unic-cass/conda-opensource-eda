## Tools-only installer

Standalone mixed-signal EDA tools for Linux x86-64: Xschem, Magic, ngspice,
Netgen, Yosys, OpenROAD, KLayout, and Xyce. The tools use Python 3.15.2 in
the `eda` environment. The installer includes neither LibreLane nor a PDK.

```bash
sha256sum -c mixed-signal-tools-0-Linux-x86_64.sh.sha256
bash mixed-signal-tools-0-Linux-x86_64.sh -b -p "$HOME/unic-cass-eda"
source "$HOME/unic-cass-eda/bin/activate" "$HOME/unic-cass-eda/envs/eda"
yosys -V
openroad -version
```

The Xschem build was selected for compatibility with the bundle's Tcl/Tk 8.6.

## openEMS (both installers)

Both installers include openEMS 0.37.0, its `openEMS` and `CSXCAD` Python
bindings, and AppCSXCAD in a preinstalled `openems` environment. It uses Conda
`defaults` and Python 3.15.2. From an activated installation:

```bash
conda activate openems
python -c 'from openEMS import openEMS; from CSXCAD import ContinuousStructure'
```

AppCSXCAD requires a graphical session. Run `conda activate eda` to return to
the other EDA tools.

## Updating Conda (both installers)

Each installer bundles Conda in `base` so its solver and OpenROAD can use
different versions of `spdlog`. After activating either installation, update
Conda without changing the `eda` environment:

```bash
conda activate base
conda update --name base conda
conda activate eda
```

For an older installer that did not include Conda, choose a fresh install
directory with `-p` instead of installing over the old layout.
