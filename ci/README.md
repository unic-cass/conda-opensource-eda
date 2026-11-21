# Continuous Integration utilities

GitHub Actions scripts for the native Conda packages published to `unic-cass`.

## Build and channel policy

`Build.yml` validates the workflow and the active recipe layout before running
package jobs. Each package job then uses `conda-build-prepare` and `conda-build`
to render, build, test and install its `meta.yaml` recipe. The drafts under
`conda-forge/` are outside this workflow.

For recipes that specify `condarc` (or `condarc_linux` on Linux), its channels
and priority policy are used after the CI channels. The default without a file
is `defaults`. CI prepends the package channel (`ANACONDA_USER`, or `unic-cass`
when unset) and, for publishing builds, the same-run label ahead of it. Add
`conda-forge` to a recipe's own `condarc` only when it needs that channel. The
prepare step prints the effective channel order and priority.

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

## Setting up Github Actions for your own fork

To use any of the conda-* repositories in Github Actions you must meet the following requirements:

* create an account on https://anaconda.org/
* create an access token on https://anaconda.org/{your-account}/settings/access
* follow https://docs.github.com/en/free-pro-team@latest/actions/reference/encrypted-secrets#creating-encrypted-secrets-for-an-environment to add two encrypted secrets:
  * `ANACONDA_USER` - set to your anaconda username
  * `ANACONDA_TOKEN` - set to the value of the token you created
