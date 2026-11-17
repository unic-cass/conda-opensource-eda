# Adding xschem

## Summary

Adds [xschem](https://github.com/StefanSchippers/xschem) 3.4.7 — a schematic
capture and netlisting EDA tool — to conda-forge.

- Source: official release-tag tarball
  (`https://github.com/StefanSchippers/xschem/archive/refs/tags/3.4.7.tar.gz`,
  sha256 `8f6c7165c38f528b6cbae8f9fae72cde3b765652df90597011a5f7b5e7fdb273`)
- License: GPL-2.0-or-later; `LICENSE` file packaged
- v1 `recipe.yaml`; build number 0
- Test: `xschem -v` → verified output `XSCHEM V3.4.7`

## Notes for reviewers

- **No vendored libraries.** An earlier packaging effort (hdl/conda-eda)
  bundled libXpm; this recipe instead uses conda-forge's `xorg-libxpm`.
  All other deps (`tk`, `cairo`, `xorg-libx11`, `xorg-xorgproto`) come from
  conda-forge.
- **Platform scope:** linux-64 + linux-aarch64 for now (`skip` win/osx).
  Upstream supports macOS/Windows; adding those platforms is planned as a
  follow-up to the feedstock once linux CI is green.
- **Maintainer:** @duyhieubui (confirmation comment to follow).

## Verification

Built and tested locally with the official staged-recipes harness
(`build-locally.py linux64`, upstream CI image
`quay.io/condaforge/linux-anvil-x86_64:alma10`):

- full run exit code 0 for this recipe set
- package produced: `xschem-3.4.7-h96e492c_0.conda` (12 MB)
- test phase passed: `✔ all tests passed!` with `XSCHEM V3.4.7`
- final artifact verified: 0 static libraries shipped

Two build details worth noting (both handled inside the recipe):

1. xschem's build system is `scconfig`, which ignores the environment
   `CFLAGS`/`LDFLAGS`; they are passed as configure args instead.
2. `xorg-xorgproto` is required in `host`: conda-forge's `xorg-libx11`
   does not ship the X protocol headers (`X11/X.h`, ...), which scconfig's
   compile probes need.

## Checklist

- [x] Title of this PR is meaningful: e.g. "Adding my_nifty_package", not "updated recipe".
- [x] Recipe uses the v1 `recipe.yaml` format, or this PR explains the exceptional requirement for deprecated v0.
- [x] License file is packaged (see the [v1 example recipe](https://github.com/conda-forge/staged-recipes/blob/main/recipes/example-v1/recipe.yaml) for an example).
- [x] Source is from official source.
- [x] Package does not vendor other packages. (If a package uses the source of another package, they should be separate packages or the licenses of all packages need to be packaged). *(No bundled third-party code; libXpm comes from conda-forge's `xorg-libxpm`.)*
- [x] If static libraries are linked in, the license of the static library is packaged. *(n/a — no static libraries are built or shipped; verified from the produced artifact.)*
- [x] Package does not ship static libraries. If static libraries are needed, [follow CFEP-18](https://github.com/conda-forge/cfep/blob/main/cfep-18.md). *(Verified: the artifact contains no `.a`/`.la` files.)*
- [x] Build number is 0.
- [x] A tarball (`url`) rather than a repo (e.g. `git_url`) is used in your recipe (see [here](https://conda-forge.org/docs/maintainer/adding_pkgs.html#build-from-tarballs-not-repos) for more details).
- [ ] GitHub users listed in the maintainer section have posted a comment confirming they are willing to be listed there. *(@duyhieubui will post the confirmation comment.)*
- [x] When in trouble, please check our [knowledge base documentation](https://conda-forge.org/docs/maintainer/knowledge_base.html) before pinging a team.
