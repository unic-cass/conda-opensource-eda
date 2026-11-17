# Adding qucs-s

## Summary

Adds [Qucs-S](https://github.com/ra3xdh/qucs_s) 26.1.1 — a Qt-based circuit
simulator GUI wrapping SPICE-family engines (ngspice, Xyce, qucsator) — to
conda-forge.

- Source: official release-tag tarball
  (`https://github.com/ra3xdh/qucs_s/archive/refs/tags/26.1.1.tar.gz`,
  sha256 `bf4ccff9e975680129ba850c5045145ad121f4e0f7eef86799398abe2f68eb24`)
- License: GPL-2.0-or-later (qucs-s itself), GPL-3.0-or-later
  (qucs-s-spar-viewer, rxcalc); all license files packaged
  (`COPYING`, `qucsator_rf/COPYING`, `rxcalc/LICENSE`,
  `qucs-s-spar-viewer/LICENSE`)
- v1 `recipe.yaml`; build number 0
- Test: `QT_QPA_PLATFORM=offscreen qucs-s --version` → `✔ all tests passed!`

## Notes for reviewers

### Git submodules added as pinned sources (please read)

Qucs-S's CMake hard-requires three git submodules that are **not included in
the release-tag auto-archive tarball**:

| Submodule | Pinned SHA (from the `26.1.1` git tree) | Source |
|---|---|---|
| `qucs-s-spar-viewer` | `f231999a5c83125c3fabe36684c84b0207f476ae` | andresmmera/qucs-s-spar-viewer |
| `qucsator_rf` | `3971737dc6e446f8e3262d20e3087fa392299a7a` | ra3xdh/qucsator_rf |
| `rxcalc` | `8ece6c4876e83771ad65f1b7bdbd938069f95430` | arhiv6/rxcalc |

These are the exact SHAs recorded in the release tag, so the built package
matches the upstream 26.1.1 release bit-for-bit in intent. All three are
built from their own pinned tarballs with sha256 checksums.

**Vendoring discussion point:** the build installs `qucsator_rf` (and the
helper binaries) into the same package, mirroring how upstream's official
AppImage/release binaries ship them (qucs-s invokes `qucsator_rf` as a
simulation backend). If reviewers prefer `qucsator-rf` as a separate
conda-forge package, I'm happy to split it in a follow-up — but note it has
no release tags either, so the same pinning story would apply there.

### Other details

- **Qt6 from conda-forge:** uses `qt6-main` + `qt6-charts` (6.11.3). No
  bundled qtcharts — this replaces a bundled-source workaround used in
  another packaging effort (hdl/conda-eda).
- **qucsator_rf's CMake hardcodes bison's search path**
  (`NO_DEFAULT_PATH`), so the recipe passes `-DBISON_DIR=$BUILD_PREFIX/bin`;
  `gperf` is likewise required by it and included in `build`.
- **Platform scope:** linux-64 + linux-aarch64 for now (`skip` win/osx);
  upstream ships macOS/Windows binaries and those platforms can follow on
  the feedstock.
- **Maintainer:** @duyhieubui (confirmation comment to follow).

## Verification

Built and tested locally with the official staged-recipes harness
(`build-locally.py linux64`, upstream CI image
`quay.io/condaforge/linux-anvil-x86_64:alma10`):

- full run exit code 0
- package produced: `qucs-s-26.1.1-hc506ff8_0.conda` (9.3 MB)
- test phase passed: `✔ all tests passed!`
- final artifact verified: 0 static libraries shipped

## Checklist

- [x] Title of this PR is meaningful: e.g. "Adding my_nifty_package", not "updated recipe".
- [x] Recipe uses the v1 `recipe.yaml` format, or this PR explains the exceptional requirement for deprecated v0.
- [x] License file is packaged (see the [v1 example recipe](https://github.com/conda-forge/staged-recipes/blob/main/recipes/example-v1/recipe.yaml) for an example). *(qucs-s `COPYING`, plus `qucsator_rf/COPYING`, `rxcalc/LICENSE` and `qucs-s-spar-viewer/LICENSE` for the submodule binaries shipped in the package.)*
- [x] Source is from official source.
- [x] Package does not vendor other packages. (If a package uses the source of another package, they should be separate packages or the licenses of all packages need to be packaged). *(The qucs-s release intentionally ships its three companion binaries (qucsator_rf, qucs-s-spar-viewer, rxcalc) as one suite, exactly like upstream's official AppImage — and their licenses are all packaged. If reviewers prefer, I can split `qucsator-rf` out as a separate feedstock in a follow-up.)*
- [x] If static libraries are linked in, the license of the static library is packaged. *(n/a — no static libraries are built or shipped; verified from the produced artifact.)*
- [x] Package does not ship static libraries. If static libraries are needed, [follow CFEP-18](https://github.com/conda-forge/cfep/blob/main/cfep-18.md). *(Verified: the artifact contains no `.a`/`.la` files.)*
- [x] Build number is 0.
- [x] A tarball (`url`) rather than a repo (e.g. `git_url`) is used in your recipe (see [here](https://conda-forge.org/docs/maintainer/adding_pkgs.html#build-from-tarballs-not-repos) for more details). *(All four sources, including the submodule pins, are URL tarballs with sha256.)*
- [ ] GitHub users listed in the maintainer section have posted a comment confirming they are willing to be listed there. *(@duyhieubui will post the confirmation comment.)*
- [x] When in trouble, please check our [knowledge base documentation](https://conda-forge.org/docs/maintainer/knowledge_base.html) before pinging a team.
