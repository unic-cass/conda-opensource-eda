# Adding lln-libparse

## Summary

Adds **lln-libparse 0.56.0** — the Python wrapper around Yosys' liberty-file
parser (`libparse.cc`), a pybind11 C++ extension. It is a hard runtime
dependency of `librelane` (which pins `lln-libparse==0.56.*`), proposed
ahead of the `librelane` staged-recipe PR so that its run dependencies can
resolve.

- Source: PyPI sdist
  `https://files.pythonhosted.org/packages/17/28/.../lln_libparse-0.56.0.tar.gz`
  (sha256 `7622424c318e0dfc253a7ee841d2a4fdfd9fbcefd07d7b958347bbfc2ecdda2c`).
  ⚠️ This is the only official source: the project has no public repository
  we could find (the sdist metadata carries no project URLs). The
  predecessor of the same code is `efabless/libparse-python` (tags up to
  0.3.1).
- License: Apache-2.0 (stated in the Readme and PKG-INFO). ⚠️ **The sdist
  ships no LICENSE file** — reviewers: please advise how you'd like this
  handled (options: upstream adding a License file in 0.56.1, or vendoring
  the upstream `License` file from the Readme's reference).
- It is a pybind11 C++ extension: **not** noarch; one build per python
  version (3.10–3.13 supported by upstream wheels).

## Notes for reviewers

- v1 `recipe.yaml`, build number 0, tarball source with sha256.
- Test: `python -c "import libparse; print(libparse.__version__)"`.
- The wrapper links against headers bundled in the sdist
  (`yosys/passes/techmap/libparse.cc` + `wrapper.cpp`) — no external yosys
  dependency.
- Maintainer: @duyhieubui (confirmation comment to follow).

## Verification

Built and tested in the `condaforge/linux-anvil-x86_64:alma10` container
(python 3.12): package produced, test passed (`import libparse`).
