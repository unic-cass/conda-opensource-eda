## Installer with LibreLane 3.0.17

Choose `mixed-signal-librelane-3.0.17-Linux-x86_64.sh` for the same EDA tools
plus LibreLane, Verilator, SymbiYosys, and EQY in the same Python 3.15.2
environment.
The bundled Verilator supports debug mode but omits debugger symbols.
PDKs are downloaded separately. The Sky130A smoke test downloads its PDK
through Ciel if it is not already available.

```bash
sha256sum -c mixed-signal-librelane-3.0.17-Linux-x86_64.sh.sha256
bash mixed-signal-librelane-3.0.17-Linux-x86_64.sh -b -p "$HOME/unic-cass-librelane"
source "$HOME/unic-cass-librelane/bin/activate" "$HOME/unic-cass-librelane"
librelane --smoke-test --pdk sky130A
```
