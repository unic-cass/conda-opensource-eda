# Adding ciel and yamlcore

## Summary

Two small pure-Python packages needed by `librelane` (the successor of
OpenLane 2), proposed as one PR because they are tiny and independent:

1. **ciel 3.2.0** — a fork of `open_pdks` using LibreLane's build
   infrastructure; builds/installs open-source PDKs (sky130, gf180mcu, ...).
   - Source: PyPI sdist
     `https://files.pythonhosted.org/packages/26/72/.../ciel-3.2.0.tar.gz`
     (sha256 `96d8faa5330f4f8a23ca10c76470ecf6f8a46b5dd85bbcbc25698872d919e1e8`)
   - License: Apache-2.0; the sdist ships no license file, so the upstream
     `License` file at tag `3.2.0` is vendored in the recipe directory.
   - noarch: python; build backend is `poetry-core`.

2. **yamlcore 0.0.4** — YAML 1.2 Core schema support for PyYAML
   (librelane pins `yamlcore>=0.0.2,<0.1.0`, which is why 0.0.4 is the
   newest eligible version — 0.1.x is excluded).
   - Source: PyPI sdist (sha256
     `c2b1a08dd117cf76a70ee124e936b3c568b0b5c4e5131e69b513f4a877a44881`)
   - License: MIT; `LICENSE` is shipped in the sdist.
   - noarch: python; build backend is `setuptools`.

Both are maintained by the LibreLane project (same maintainers as
`librelane`).

## Why these are needed

`librelane` 3.0.17 declares both packages as hard runtime dependencies, and
neither exists on any conda-forge-compatible channel today. They are being
submitted ahead of the `librelane` staged-recipe PR so that its run
dependencies can resolve.

## Notes for reviewers

- v1 `recipe.yaml`, build number 0, tarball sources with sha256.
- Tests: `ciel --help`; `python -c "import yamlcore, yaml"`.
- Maintainer: @duyhieubui (confirmation comment to follow).

## Verification

Both recipes were built and their tests passed in the
`condaforge/linux-anvil-x86_64:alma10` container (same base as the CI
image): packages produced and smoke tests green.
