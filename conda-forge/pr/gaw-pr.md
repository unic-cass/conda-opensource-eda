# Adding gaw

## Summary

Adds [gaw](https://github.com/StefanSchippers/xschem-gaw) — the GTK3
waveform viewer for analog simulation output maintained alongside xschem —
to conda-forge.

- Source: commit-pinned tarball of `main`
  (`https://github.com/StefanSchippers/xschem-gaw/archive/731be0d9c99e33d66ab6ba074fcf598c940fa02d.tar.gz`,
  sha256 `958e4dabc000b60c71cccebfc3b9da213ede3f92b223ade963841ce93a9022a1`)
- License: GPL-2.0-or-later; `COPYING` file packaged
- v1 `recipe.yaml`; build number 0
- Test: `test -f ${PREFIX}/bin/gaw` → `✔ all tests passed!`

## Notes for reviewers

### Version is a commit snapshot — upstream has no release tags

**Please read:** `xschem-gaw` has no tags/releases at all (verified via the
GitHub API). The version used here, `2026.11.10`, is the snapshot date of
the pinned commit `731be0d9` (the current `main` head at packaging time).
`glib`'s `configure.ac` calls the project `gaw3`, version `1.0`, with
`VERSION=20250128` baked in — I deliberately used the commit date instead
of `1.0` to make snapshot provenance obvious and keep future sorting sane.

I can ask upstream (StefanSchippers) for a release tag and re-submit with a
real version if reviewers prefer that route.

### Dependency notes (conda-forge packaging quirks)

The pkg-config chain of gtk3 requires three conda-forge packages that would
not be guessed from a normal dependency analysis:

- `zlib` — `libzlib` does not ship `zlib.pc`, but `gio-2.0.pc` has
  `Requires.private: zlib`
- `expat` — `libexpat` does not ship `expat.pc`, but `fontconfig.pc` needs it
- `glib` — `glibconfig.h` ships in the `glib` package, not `libglib`
  (verified by unpacking `libglib` 2.86.4/2.90.1 payloads)

### Related projects

This is the GTK3 successor of the original `gaw` (gaw.tuxfamily.org, GTK2).
The xschem ecosystem on conda-forge (xschem recipe in this same PR wave)
pairs naturally with it: xschem's "simulate" flow launches gaw for waveform
viewing.

### Maintainer

@duyhieubui (confirmation comment to follow).

## Verification

Built and tested locally with the official staged-recipes harness
(`build-locally.py linux64`, upstream CI image
`quay.io/condaforge/linux-anvil-x86_64:alma10`):

- full run exit code 0
- package produced: `gaw-2026.11.10-h2c7ebb2_0.conda` (161 KB)
- test phase passed: `✔ all tests passed!`
- final artifact verified: 0 static libraries shipped

## Checklist

- [x] Title of this PR is meaningful: e.g. "Adding my_nifty_package", not "updated recipe".
- [x] Recipe uses the v1 `recipe.yaml` format, or this PR explains the exceptional requirement for deprecated v0.
- [x] License file is packaged (see the [v1 example recipe](https://github.com/conda-forge/staged-recipes/blob/main/recipes/example-v1/recipe.yaml) for an example). *(`COPYING` — GPL-2.0-or-later.)*
- [x] Source is from official source. *(Official upstream GitHub repository; commit-pinned tarball because no release tags exist — see above.)*
- [x] Package does not vendor other packages. (If a package uses the source of another package, they should be separate packages or the licenses of all packages need to be packaged). *(No bundled third-party code; GTK3 and friends come from conda-forge.)*
- [x] If static libraries are linked in, the license of the static library is packaged. *(n/a — no static libraries are built or shipped; verified from the produced artifact.)*
- [x] Package does not ship static libraries. If static libraries are needed, [follow CFEP-18](https://github.com/conda-forge/cfep/blob/main/cfep-18.md). *(Verified: the artifact contains no `.a`/`.la` files.)*
- [x] Build number is 0.
- [x] A tarball (`url`) rather than a repo (e.g. `git_url`) is used in your recipe (see [here](https://conda-forge.org/docs/maintainer/adding_pkgs.html#build-from-tarballs-not-repos) for more details). *(Commit-pinned archive tarball with sha256, not `git_url`.)*
- [ ] GitHub users listed in the maintainer section have posted a comment confirming they are willing to be listed there. *(@duyhieubui will post the confirmation comment.)*
- [x] When in trouble, please check our [knowledge base documentation](https://conda-forge.org/docs/maintainer/knowledge_base.html) before pinging a team.
