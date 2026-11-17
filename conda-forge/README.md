# conda-forge recipes (drafts for staged-recipes PRs)

Draft v1 (`recipe.yaml`, rattler-build format) recipes to submit to
[conda-forge/staged-recipes](https://github.com/conda-forge/staged-recipes).
One folder per package; copy the folder into a fork of staged-recipes under
`recipes/<name>/` and open a PR.

Verified locally with the official `build-locally.py` harness
(branch `cf-local-test` of a staged-recipes clone, config `linux64`).

## Status (final — verified end-to-end with build-locally.py on 2026-11-15)

Full `build-locally.py linux64` run: **exit 0, all four packages built, all four test phases passed.**

Recipes updated per the conda-forge linter feedback on the first PR
(maintainers added; `${{ stdlib('c') }}` added per the stdlib migration;
`pkg-config` → `pkgconf`), mirroring the conventions of the recently
accepted klayout-feedstock. Final artifact hashes reflect the updated
recipes:

| Package | Artifact (linux-64) | Test |
|---|---|---|
| gaw | `gaw-2026.11.10-hb10341f_0.conda` (161 KB) | ✔ all tests passed |
| qucs-s | `qucs-s-26.1.1-ha3b8bf7_0.conda` (9.3 MB) | ✔ all tests passed |
| xschem | `xschem-3.4.7-hc2efd7c_0.conda` (12 MB) | ✔ all tests passed (`XSCHEM V3.4.7`) |
| xyce | `xyce-7.10.0-hfb44c7f_0.conda` (41 MB) | ✔ all tests passed (`Xyce Release 7.10.0-opensource`) |

Artifacts: `/home/admin/staged-recipes/build_artifacts/linux-64/`.

## Hard-won conda-forge packaging facts (learned during local runs)

These are the quirks an agent would never guess:

1. **Runtime packages ship no `.pc` files** on conda-forge: `libzlib` has no
   `zlib.pc`, `libexpat` no `expat.pc`. Any `Requires.private:` in a
   dependency chain needs the meta-packages `zlib` / `expat` in `host`.
2. **`glibconfig.h` ships in the `glib` package**, not `libglib` (both
   2.86.4 and 2.90.1 libglib lack it — verified by unpacking the payloads).
   Anything compiling glib headers needs `glib` in `host`.
3. **`xorg-libx11` does not ship X protocol headers** (`X11/X.h`, ...);
   those live in `xorg-xorgproto`.
4. **CMake 4 rejects pre-3.5 projects** (`CMP0048 OLD`,
   `cmake_minimum_required(2.6)`): pass
   `-DCMAKE_POLICY_VERSION_MINIMUM=3.5`.
5. **qucs-s release tags exclude git submodules** (`qucsator_rf`, `rxcalc`,
   `qucs-s-spar-viewer`) but its CMake requires them; add them as extra
   pinned sources (SHAs taken from the release tag's git tree via the
   GitHub API).
6. **qucsator_rf's CMake hardcodes bison's search path** (`NO_DEFAULT_PATH`);
   pass `-DBISON_DIR=$BUILD_PREFIX/bin`. gperf also required in PATH.
7. **ADMS (admsXml) is only needed by Xyce when `Xyce_PLUGIN_SUPPORT=ON`**;
   with plugin support off it can be dropped entirely — important because
   ADMS runs `mkelements.pl` at build time and needs perl `XML::LibXML`,
   which has no conda-forge package (`perl-xml-sax`/`perl-xml-parser` exist;
   `perl-xml-libxml` does not). Enabling plugin support later requires a
   `perl-xml-libxml` staged-recipes PR first.
8. **conda-forge Qt6 is consolidated**: `qt6-main` (+ `qt6-charts` for the
   Charts module). No need to bundle qtcharts, unlike the hdl recipe.
9. Rootless-Docker notes for `build-locally.py`: host python must be >= 3.7
   (system 3.6 too old); `docker run -it` needs a pseudo-tty (`script -qec`);
   build_artifacts must be writable by the container user (`chmod -R a+rwX`).
10. **conda-forge `suitesparse` nests headers under `include/suitesparse/`**;
    Trilinos's AMD TPL needs
    `-DTPL_AMD_INCLUDE_DIRS=$PREFIX/include/suitesparse` and
    `-DCMAKE_CXX_FLAGS="-I$PREFIX/include/suitesparse"`.
11. **Cross-build `find_path()` can't see `$BUILD_PREFIX/include`** (FIND_ROOT_PATH
    re-rooting hides it): Xyce's FlexLexer.h lookup fails unless
    `-DFLEX_INCLUDE_DIR=$BUILD_PREFIX/include` is passed explicitly.
12. **Xyce installs a static `libxyce.a` by default** — a CFEP-18 violation on
    conda-forge; the recipe removes it post-install (final artifact verified:
    0 static files). A `xyce-static` feedstock split can be added later.

## Checksums (computed from downloaded tarballs)

| Tarball | sha256 |
|---|---|
| xschem 3.4.7 | `8f6c7165c38f528b6cbae8f9fae72cde3b765652df90597011a5f7b5e7fdb273` |
| qucs_s 26.1.1 | `bf4ccff9e975680129ba850c5045145ad121f4e0f7eef86799398abe2f68eb24` |
| qucs-s-spar-viewer @f231999a | `156c679b896fbc6540463d58074ee97b6c66d482c4a3ae66265cd96e0b92bdde` |
| qucsator_rf @3971737d | `6cde86f95a428af8b2cabfe6bb38f4a6612e4b994538c6c99c33e0a966735a9f` |
| rxcalc @8ece6c48 | `5e4c1bdda397e824d16f65c94e5af875e367ca60ec7ca24b7b323946d2859807` |
| gaw @731be0d9 | `958e4dabc000b60c71cccebfc3b9da213ede3f92b223ade963841ce93a9022a1` |
| Xyce Release-7.10.0 | `b5a883196f0a2b3972fd13c541fecf04735bfabc7d124d7c7e17de707204f4e2` |

Tarball cache: `/tmp/opencode/cf-tarballs`.

## Open items before submitting

1. **xyce:** uses bundled Trilinos 14.4.0 (conda-forge's trilinos 16.2
   verifiably lacks every classic component Xyce needs — Amesos, Epetra,
   EpetraExt, Ifpack, NOX, Teuchos, Sacado, Triutils, AztecOO, Belos,
   TrilinosCouplings). Be ready to defend the bundled build in the PR, or
   propose a separate `trilinos-14` feedstock.
2. **xyce BLAS:** pinned to `libopenblas` — the `blas`/`lapack` metapackages
   let the test env resolve a different provider than the build linked
   against (hit live: linked libblis, test env resolved openblas).
3. **gaw versioning:** if reviewers object to the calendar-snapshot version,
   ask upstream (StefanSchippers) for a release tag.
4. **Other platforms:** all four `skip` win+osx; aarch64 should work but is
   untested locally (run `build-locally.py linux_aarch64` before or in CI).
5. **Maintainer confirmation:** the recipes list `duyhieubui` as maintainer;
   the staged-recipes checklist requires them to post a confirmation
   comment on each PR.

## PR descriptions

Ready-to-paste PR descriptions live in [`pr/`](pr/), one per package:
`xschem-pr.md`, `qucs-s-pr.md`, `gaw-pr.md`, `xyce-pr.md`. Each one is
written against the official staged-recipes PR checklist and includes the
verification evidence and the reviewer discussion points.

## How to rerun locally

```bash
# working staged-recipes clone already exists at /home/admin/staged-recipes
# (branch cf-local-test, recipes copied into recipes/)
cd /home/admin/staged-recipes
script -qec "/home/admin/mamba-root/envs/py311/bin/python build-locally.py linux64" /dev/null \
  > /tmp/opencode/build-locally.log 2>&1
```

PR checklist (from staged-recipes README):
- New recipes **must** be v1 `recipe.yaml` (v0 `meta.yaml` deprecated).
- Build runs on Linux/macOS/Windows CI; use `build.skip` selectors
  (all four drafts skip win+osx to start).
- Ping `@conda-forge/help-c-cpp` for review (first-time contributors can use
  the `@conda-forge-admin, please ping team` bot command).
- After merge, a feedstock is auto-created and you become its maintainer.
