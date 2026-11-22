## Installer with LibreLane 3.0.17

Choose `mixed-signal-librelane-3.0.17-Linux-x86_64.sh` for the same EDA tools
plus LibreLane, Verilator, SymbiYosys, and EQY. It runs on Python 3.15.2.
PDKs are downloaded separately. The Sky130A smoke test downloads its PDK
through Ciel if it is not already available.

```bash
sha256sum -c mixed-signal-librelane-3.0.17-Linux-x86_64.sh.sha256
bash mixed-signal-librelane-3.0.17-Linux-x86_64.sh -b -p "$HOME/unic-cass-librelane"
export PATH="$HOME/unic-cass-librelane/bin:$PATH"
librelane --smoke-test --pdk sky130A
```
