# Development

GitHub Actions builds the native Conda packages using
{ghsrc}`.github/workflows/Build.yml`. After a successful publishing build, the
packages are available from the [`unic-cass` channel](https://anaconda.org/unic-cass/repo):

```bash
conda install -c unic-cass PACKAGE_NAME
```

## Testing a Conda build locally

Use a fresh Linux x86-64 container or VM so that installed tools and libraries
do not affect the build. The documentation test runs the following two command
blocks on Ubuntu 22.04 LTS, 24.04 LTS, 26.04 LTS, and 26.10, and on Debian 12
and 13.

### Prerequisites

<!-- name="install-prerequisites" -->
```bash
# Run these two APT commands as root (or with sudo).
apt-get update
apt-get install -y --no-install-recommends ca-certificates git wget

git clone "${REPO_URL:-https://github.com/unic-cass/conda-opensource-eda.git}" conda-opensource-eda
cd conda-opensource-eda
```

### Prepare, build, and test

The example builds `yamlcore`, a small, pure-Python package. These scripts
bootstrap Miniconda and use `conda-build-prepare` to render the recipe and set
up the Python 3.12 build environment in `workdir/conda-env`. The recipe's own
requirements control the Python version of the package. Build numbers and
strings are derived from the checkout's commit timestamp in UTC.

<!-- name="prepare-and-build" -->
```bash
export OS_NAME=linux
export PACKAGE="${PACKAGE:-misc/yamlcore}"
export CI_SCRIPTS_PATH="$PWD/ci"
export CONDA_ANACONDA_UPLOAD=false
bash ci/install.sh
bash ci/script.sh
```

`ci/script.sh` builds the prepared recipe, runs the recipe's tests, and checks
that the resulting package installs into a fresh environment. For another
package, set `PACKAGE` to its recipe directory and check the corresponding job
in {ghsrc}`.github/workflows/Build.yml` for additional system dependencies and
variables such as `PYTHON_VERSION`. See {ghsrc}`ci/README.md` for channel
selection and how to run a complete job locally with `act`.

Linux x86-64 mixed-signal installers target EL8 (glibc 2.28). Build native
Python extensions from source with Conda's activated compiler and a compatible
sysroot. `CI_CHECK_EL8_ABI=true` makes `ci/script.sh` reject newer glibc symbol
requirements in the installed package. The installer workflow checks the
bundled environments and runs the smoke tests on AlmaLinux 8 before release.
