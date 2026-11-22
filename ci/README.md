# Continuous Integration utilities

GitHub Actions scripts for the native Conda packages published to `unic-cass`.

## Build and channel policy

`Build.yml` validates the workflow and the active recipe layout before running
package jobs. Each package job then uses `conda-build-prepare` and `conda-build`
to render, build and test its `meta.yaml` recipe, then installs the package in a
separate environment to check that its runtime dependencies resolve. The drafts
under `conda-forge/` are outside this workflow.

For recipes that specify `condarc` (or `condarc_linux` on Linux), its channels
and priority policy are used after the CI channels. A recipe can override its
Linux config for a variant with `RECIPE_CONDARC_VARIANT`, for example
`py313-plus` selects `condarc_linux_py313-plus`.
The default without a file is `defaults`. CI prepends the package channel
(`ANACONDA_USER`, or `unic-cass` when unset) and, for publishing builds, the
same-run label ahead of it. Add `conda-forge` to a recipe's own `condarc` only
when it needs that channel. The prepare step prints the effective channel order
and priority.

Builds that fail in the `./ci` action attach `prepare.log` and/or `build.log`
under **Artifacts** on the Actions run. APT failures are reported in the job's
APT step. `Upload.yml` promotes run-label packages to `main` only after the
whole master build succeeds.

## Run locally

With Docker and `act` installed, run an individual job from the repo root:

```bash
act push -W .github/workflows/Build.yml -j yamlcore-linux \
    -P ubuntu-22.04=ghcr.io/catthehacker/ubuntu:act-22.04
```

Use `-j validate` for the fast checks only, or add `--dryrun` to inspect the job
plan. Local runs do not need an upload token. Jobs that need unpublished
packages from the same run cannot fetch them from an Anaconda run label under
`act`.

The native Linux build publishes Python 3.13, 3.14, and 3.15 variants of Yosys,
OpenROAD, KLayout, libparse, and SymbiYosys alongside the existing variants.
CI tests the same `noarch` LibreLane package in a fresh environment on each of
those Python versions. The build environment itself uses Python 3.12 to run
the pinned `conda-build`.

To build only one variant locally, select its job ID:

```bash
act push -W .github/workflows/Build.yml -j libparse-linux-py314 \
    -P ubuntu-22.04=ghcr.io/catthehacker/ubuntu:act-22.04
```

## Tools-only GitHub release

Push a `tools-<version>` tag to run `Construct.yml` for the standalone Linux
x86-64 tools installer. It builds from the published package builds pinned in
`installer/mixed-signal.tools/construct.yaml`, smoke-tests a fresh installation,
and publishes the installer and SHA-256 checksum to the tagged release.

To run the same installer build and smoke test locally:

```bash
act workflow_dispatch -W .github/workflows/Construct.yml \
    -j mixed-signal-tools-installer -P ubuntu-22.04=ghcr.io/catthehacker/ubuntu:act-22.04
```

## Setting up Github Actions for your own fork

To use any of the conda-* repositories in Github Actions you must meet the following requirements:

* create an account on https://anaconda.org/
* create an access token on https://anaconda.org/{your-account}/settings/access
* follow https://docs.github.com/en/free-pro-team@latest/actions/reference/encrypted-secrets#creating-encrypted-secrets-for-an-environment to add two encrypted secrets:
  * `ANACONDA_USER` - set to your anaconda username
  * `ANACONDA_TOKEN` - set to the value of the token you created
