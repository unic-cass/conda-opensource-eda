Standalone mixed-signal EDA tools for Linux x86-64: Xschem, Magic, ngspice,
Netgen, Yosys, OpenROAD, KLayout, and Xyce. Yosys, OpenROAD, and KLayout use
the Python 3.15 builds. The installer includes neither LibreLane nor a PDK.

```bash
sha256sum -c mixed-signal-tools-0-Linux-x86_64.sh.sha256
bash mixed-signal-tools-0-Linux-x86_64.sh -b -p "$HOME/unic-cass-eda"
export PATH="$HOME/unic-cass-eda/bin:$PATH"
yosys -V
openroad -version
```

The Xschem build was selected for compatibility with the bundle's Tcl/Tk 8.6.
