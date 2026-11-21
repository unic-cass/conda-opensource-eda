#!/bin/bash

set -e
source "$CI_SCRIPTS_PATH/common.sh"

# Getting the conda environment
start_section "environment.conda" "Setting up basic ${YELLOW}conda environment${NC}"

mkdir -p $BASE_PATH
$CI_SCRIPTS_PATH/conda-get.sh $CONDA_PATH
hash -r

if [ x$PACKAGE = x"" ]; then
    echo '$PACKAGE not set, skipping the rest of install script'
    exit 0
fi

# Add build variants to the recipe dir (appended keys win in case of any conflict)
cat "$CI_SCRIPTS_PATH/conda_build_config.yaml" >> "$PACKAGE/conda_build_config.yaml"

# Install conda-build-prepare. Its revision can be specified with CONDA_BUILD_PREPARE_REV.
_cbp_rev=${CONDA_BUILD_PREPARE_REV:-v0.1.2}
python -m pip install git+https://github.com/hdl/conda-build-prepare@${_cbp_rev}#egg=conda-build-prepare

# conda-build-prepare prepends these in order (last one highest). The
# recipe's condarc supplies any other channels and its channel priority.
additional_channels=()
recipe_os=${OS_NAME/osx/macos}
if [[ ! -f "$PACKAGE/condarc_$recipe_os" && ! -f "$PACKAGE/condarc" ]]; then
    additional_channels+=(defaults)
fi
package_channel=${ANACONDA_USER:-unic-cass}
additional_channels+=("$package_channel")
if [[ ${CI_USE_RUN_CHANNEL:-false} == true ]]; then
    branch="$(git rev-parse --abbrev-ref HEAD)"
    additional_channels+=("$package_channel/label/ci-$branch-$GITHUB_RUN_ID")
fi

# This is the build runner's Python, not the recipe's PYTHON_VERSION variant.
additional_packages=(conda-build=26.9.1 conda-verify jinja2 pexpect python=3.12)
if [[ "$OS_NAME" != 'windows' ]]; then
    additional_packages+=(ripgrep)
fi

# Prepare the recipe and create workdir/conda-env to be activated
printf 'Channels prepended by CI (highest first):'
for ((i=${#additional_channels[@]}-1; i>=0; i--)); do
    printf ' %s' "${additional_channels[i]}"
done
printf '\n'
python -u -m conda_build_prepare --channels "${additional_channels[@]}" \
    --packages "${additional_packages[@]}" --dir workdir "$PACKAGE"

end_section "environment.conda"

$SPACER

# Output some useful info
start_section "info.conda.config" "Info on ${YELLOW}conda config${NC}"
conda run -p workdir/conda-env conda config --show channels channel_priority
end_section "info.conda.config"

start_section "info.conda.package" "Info on ${YELLOW}conda package${NC}"
# This is the fully rendered metadata file
cat workdir/recipe/meta.yaml
end_section "info.conda.package"
