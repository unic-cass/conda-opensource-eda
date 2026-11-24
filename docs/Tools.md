# Tools

## Synthesis

* [Yosys](https://github.com/YosysHQ/yosys)
* TODO: [GHDL Synthesis](https://github.com/tgingold/ghdlsynth-beta)

## Place and Route

* [arachne](https://github.com/cseed/arachne-pnr)
* [nextpnr (iCE40, ECP5, generic)](https://github.com/YosysHQ/nextpnr)
* [Versatile Place and Route (vpr)](https://github.com/verilog-to-routing/vtr-verilog-to-routing)

## Bitstream

* [Project Icestorm](https://github.com/cliffordwolf/icestorm)
* [Project Trellis](https://github.com/SymbiFlow/prjtrellis)
* TODO: [Project X-Ray](https://github.com/SymbiFlow/prjxray)

## Simulation

* TODO: [GHDL](http://ghdl.free.fr/)
* [Icarus Verilog](http://iverilog.icarus.com/)
* [Verilator](https://www.veripool.org/wiki/verilator)
* [openEMS](https://openems.de/) — FDTD electromagnetic simulation, including
  the AppCSXCAD viewer and the `openEMS` and `CSXCAD` Python modules. Linux x86-64
  builds support Python 3.13, 3.14, and 3.15. See the
  [openEMS recipe](../sim/openems) and the [local build guide](DEVELOPMENT.md).
* [Qucs-S](https://ra3xdh.github.io/) — to use Qt 5 on Linux x86-64, select the
  Qt 5 build of [Qucs-S 24.4.1](https://github.com/ra3xdh/qucs_s/releases/tag/24.4.1):

  ```bash
  conda install -c unic-cass -c conda-forge 'unic-cass::qucs-s=24.4.1=*_qt5'
  ```

  Qucs-S 25.1 and newer require Qt 6.

## Formal

* [Symbiyosys](https://github.com/YosysHQ/SymbiYosys)
