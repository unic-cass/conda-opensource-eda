# Adding xyce

## Summary

Adds [Xyce](https://github.com/Xyce/Xyce) 7.10.0 — Sandia National
Laboratories' SPICE-compatible parallel electronic simulator (serial build)
— to conda-forge.

- Source: official release-tag tarball
  (`https://github.com/Xyce/Xyce/archive/refs/tags/Release-7.10.0.tar.gz`,
  sha256 `b5a883196f0a2b3972fd13c541fecf04735bfabc7d124d7c7e17de707204f4e2`)
- License: GPL-3.0-or-later (Xyce, `COPYING` packaged) — the bundled
  Trilinos (BSD-family, see below) `LICENSE` is packaged as well
- v1 `recipe.yaml`; build number 0
- Test: `Xyce -v` → verified output `Xyce Release 7.10.0-opensource`
- Package size: 56 MB (dominated by the bundled Trilinos shared libraries)

## ⚠️ Discussion point: bundled Trilinos 14.4.0

This recipe bundles and builds **Trilinos 14.4.0** inside the package, using
conda-forge's `libopenblas` and `suitesparse` instead of bundled
netlib/SuiteSparse sources. I know bundling a dependency of this size
crosses a conda-forge guideline, so here is the full evidence for why:

1. **Xyce requires the classic (Epetra-era) Trilinos stack**: Amesos,
   Epetra, EpetraExt, Ifpack, NOX, Teuchos, Sacado, Triutils, AztecOO,
   Belos, TrilinosCouplings (+ Amesos2/KLU2, Kokkos, Stokhos, complex
   double). This is exactly the module set documented in Xyce's
   INSTALL.md.
2. **conda-forge's `trilinos` (16.2) does not provide any of them.** I
   verified this live: pointing Xyce 7.10 at conda-forge trilinos 16.2,
   `TrilinosConfig.cmake` reports
   `ERROR: Could not find component 'Amesos'!` (and the same for every
   component listed above).
3. **Upstream recommends Trilinos 14.4** ("versions after 14.4 have not
   been rigorously tested with Xyce" — Xyce 7.10 INSTALL.md), and 14.4 is
   the release that still ships/works with AztecOO, Triutils, Basker, etc.
4. The bundled-build approach and exact CMake flag set come from a
   working existing packaging (hdl/conda-eda `sim/xyce`), adapted to use
   conda-forge BLAS/LAPACK/SuiteSparse.

**Alternatives I considered and would pursue on request:**

- A separate `trilinos-14` feedstock (or adding a 14.4 build to the
  existing `trilinos` feedstock), with `xyce` depending on it. I'm happy
  to do this first if reviewers prefer — it's the cleaner long-term
  arrangement, at the cost of one more PR before this one.
- Pinning `trilinos <15` doesn't help: the conda-forge feedstock only
  publishes 16.x.

The single Trilinos patch (`trilinos-14.4.0.patch`, from the hdl packaging)
fixes a kokkos-kernels header issue (`sort_option` member in
`KokkosSparse_spadd_handle.hpp`).

## Other notes for reviewers

- **No ADMS / plugin support off.** `Xyce_PLUGIN_SUPPORT=OFF` for the first
  package. ADMS (`admsXml`) is only used when plugin support is enabled,
  and it requires perl `XML::LibXML` at build time — which has no
  conda-forge package (`perl-xml-sax` and `perl-xml-parser` exist;
  `perl-xml-libxml` does not). Enabling plugin support later needs a
  `perl-xml-libxml` staged-recipes PR first.
- **BLAS provider pinned:** host uses `libopenblas` rather than the
  `blas`/`lapack` metapackages. With the metapackages, the build linked
  `libblis` while the test environment resolved the metapackage to
  openblas — `Xyce: error while loading shared libraries: libblis.so.4`.
  (Learned live; fix verified.)
- **Cross-build specifics** (linux-aarch64): `FlexLexer.h` lives in
  `$BUILD_PREFIX/include`, which `find_path()` cannot see under
  FIND_ROOT_PATH re-rooting; the recipe passes
  `-DFLEX_INCLUDE_DIR=$BUILD_PREFIX/include` explicitly. conda-forge's
  `suitesparse` nests headers under `include/suitesparse/`, handled via
  `TPL_AMD_INCLUDE_DIRS` and `CMAKE_CXX_FLAGS`.
- **Platform scope:** linux-64 + linux-aarch64 for now (`skip` win/osx).
  Xyce officially supports macOS; that can be added on the feedstock.
- **Maintainer:** @duyhieubui (confirmation comment to follow).

## Verification

Built and tested locally with the official staged-recipes harness
(`build-locally.py linux64`, upstream CI image
`quay.io/condaforge/linux-anvil-x86_64:alma10`):

- full run exit code 0 (four recipes, including this one)
- package produced: `xyce-7.10.0-hdd82c38_0.conda` (56 MB)
- test phase passed: `✔ all tests passed!`, `Xyce -v` →
  `Xyce Release 7.10.0-opensource`
- final artifact verified: 141 shared libraries, **0 static libraries**
  (the static `libxyce.a` that Xyce installs by default is removed per
  CFEP-18)

## Checklist

- [x] Title of this PR is meaningful: e.g. "Adding my_nifty_package", not "updated recipe".
- [x] Recipe uses the v1 `recipe.yaml` format, or this PR explains the exceptional requirement for deprecated v0.
- [x] License file is packaged (see the [v1 example recipe](https://github.com/conda-forge/staged-recipes/blob/main/recipes/example-v1/recipe.yaml) for an example). *(Xyce `COPYING` — GPL-3.0-or-later — plus the bundled Trilinos `LICENSE`.)*
- [x] Source is from official source.
- [x] Package does not vendor other packages. (If a package uses the source of another package, they should be separate packages or the licenses of all packages need to be packaged). *(Trilinos is bundled because conda-forge's trilinos 16.2 verifiably lacks every component Xyce needs — see the discussion point above. Licenses of the bundled code are packaged. Open to splitting into a `trilinos-14` feedstock first if reviewers prefer.)*
- [x] If static libraries are linked in, the license of the static library is packaged. *(Trilinos is built with `BUILD_SHARED_LIBS=ON`; Xyce links its shared libraries.)*
- [x] Package does not ship static libraries. If static libraries are needed, [follow CFEP-18](https://github.com/conda-forge/cfep/blob/main/cfep-18.md). *(Xyce installs a static `libxyce.a` by default; the recipe removes it. Verified: the artifact ships no `.a`/`.la` files. A `xyce-static` split can be added later if there is demand.)*
- [x] Build number is 0.
- [x] A tarball (`url`) rather than a repo (e.g. `git_url`) is used in your recipe (see [here](https://conda-forge.org/docs/maintainer/adding_pkgs.html#build-from-tarballs-not-repos) for more details). *(Both Xyce and Trilinos are URL tarballs with sha256.)*
- [ ] GitHub users listed in the maintainer section have posted a comment confirming they are willing to be listed there. *(@duyhieubui will post the confirmation comment.)*
- [x] When in trouble, please check our [knowledge base documentation](https://conda-forge.org/docs/maintainer/knowledge_base.html) before pinging a team.
