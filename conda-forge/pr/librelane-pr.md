# Adding librelane

## Summary

Adds **librelane 3.0.17** — the LibreLane chip-design flow infrastructure
(successor of OpenLane 2) — to conda-forge as a noarch Python package.

- Source: PyPI sdist (sha256
  `e6b915b0fe09b1c22abb74437a51164d5486939f942000742e90f4440e9b0aaa`).
- License: Apache-2.0; the sdist ships no license file, so the upstream
  `License` at the 3.0.17 tag is vendored in the recipe directory.
- Build backend: `poetry-core` (>=2.0.0), which is in `host`.
- All run dependencies exist on conda-forge **except** the three packages
  from the prerequisite staged-recipe PRs (ciel, yamlcore, lln-libparse).

## ⚠️ Prerequisite PRs (please review/merge first)

| Package | Why librelane needs it | PR |
|---|---|---|
| `ciel >=2.3.1,<3` | PDK manager (sky130/gf180mcu fetch+build) | staged-recipes PR: "Adding ciel and yamlcore" |
| `yamlcore >=0.0.2,<0.1.0` | YAML 1.2 core schema for PyYAML | same PR |
| `lln-libparse ==0.56.*` | liberty-file parser (pybind11 ext) | staged-recipes PR: "Adding lln-libparse" |

The `recipe.yaml` in this PR includes those three in `run` — remove them or
reorder PRs as the team prefers.

## External tool binaries (please read)

LibreLane is a Python driver that invokes EDA tool binaries found in PATH at
runtime: `openroad`, `yosys`, `klayout` (the binary application), `magic`,
`netgen` (the OpenCircuitDesign LVS tool — ⚠️ note conda-forge's existing
`netgen` package is a *different* tool, the mesh generator), `verilator`,
`iverilog`, `sta` (standalone OpenSTA), `sby`/`eqy`, plus PDK data.

This recipe deliberately does **not** pin most of them as run dependencies:

- `openroad` is not on conda-forge yet (it is a large build with a bundled
  Trilinos-style dependency set; a staged-recipe PR would be a separate,
  heavyweight effort).
- the conda-forge `yosys` (0.71) is newer than the version librelane 3.0.17
  documents as tested (`0.62`), and its bundled-plugins set differs.

Instead the recipe pins the runtime deps that exist and are unambiguous
(`magic`, `verilator`, `iverilog`) and documents the rest. If reviewers
prefer, we can add `yosys` as a run dep, or split a `librelane-meta`
package later once `openroad` lands. Feedback welcome.

The full documented tool set for 3.0.17 is in upstream's release asset
`tool_versions.txt`:
https://github.com/librelane/librelane/releases/tag/3.0.17

## Notes for reviewers

- v1 `recipe.yaml`, build number 0, tarball source with sha256.
- Tests: `librelane --version`, `python -c "import librelane"`.
- Maintainer: @duyhieubui (confirmation comment to follow).

## Verification

Built and tested locally in the `condaforge/linux-anvil-x86_64:alma10`
container: package produced; an environment with the package + tools
resolved from a private channel ran `librelane --version` → `LibreLane
v3.0.17` and `librelane.env_info` → `supported: True`.
