#!/bin/bash

set -e
source "$CI_SCRIPTS_PATH/common.sh"

$SPACER

start_section "info.conda.package" "Info on ${YELLOW}conda package${NC}"
conda render $CONDA_BUILD_ARGS
end_section "info.conda.package"

$SPACER

start_section "conda.check" "${GREEN}Checking...${NC}"
conda build --check $CONDA_BUILD_ARGS
end_section "conda.check"

$SPACER

start_section "conda.build" "${GREEN}Building..${NC}"
if [[ $OS_NAME != 'windows' && $KEEP_ALIVE == 'true' ]]; then
    ci_wait "$CI_MAX_TIME" conda build $CONDA_BUILD_ARGS
else
    conda build $CONDA_BUILD_ARGS
fi
end_section "conda.build"

$SPACER

start_section "conda.install" "${GREEN}Installing..${NC}"
# Exercise a downstream install without trying to change the build runner's Python.
# Installing archive paths directly bypasses dependency solving in newer Conda.
artifacts=($CONDA_OUT)
channel_dir=$(dirname "$(dirname "${artifacts[0]}")")
conda index "$channel_dir"
channel_url=$(python -c 'import sys; from conda.common.url import path_to_url; print(path_to_url(sys.argv[1]))' "$channel_dir")
channels=(-c "$channel_url")
# Preserve the recipe's configured channels when adding the local build channel.
configured_channels=$(conda config --show channels --json | python -c 'import json, sys; print("\n".join(json.load(sys.stdin)["channels"]))')
while IFS= read -r channel; do
    [[ -z "$channel" ]] || channels+=(-c "$channel")
done <<< "$configured_channels"
specs=()
for artifact in "${artifacts[@]}"; do
    filename=${artifact##*/}
    build=${filename%.conda}
    build=${build##*-}
    name_version=${filename%-*}
    specs+=("$channel_url::${name_version%-*}==${name_version##*-}=$build")
done
check_el8_abi() {
    if [[ ${CI_CHECK_EL8_ABI:-false} == true ]]; then
        python "$CI_SCRIPTS_PATH/check-glibc.py" "$1" --package "${PACKAGE##*/}"
    fi
}
if [[ -n ${CI_INSTALL_PYTHONS:-} ]]; then
    for version in $CI_INSTALL_PYTHONS; do
        prefix="$PWD/workdir/install-test-${version//./}"
        conda create --yes --no-default-packages --prefix "$prefix" \
            "${channels[@]}" "${specs[@]}" "python=$version"
        check_el8_abi "$prefix"
    done
else
    conda create --yes --no-default-packages --prefix "$PWD/workdir/install-test" \
        "${channels[@]}" "${specs[@]}"
    check_el8_abi "$PWD/workdir/install-test"
fi
end_section "conda.install"

$SPACER

start_section "conda.du" "${GREEN}Disk usage..${NC}"
du -h $CONDA_OUT
end_section "conda.du"

$SPACER

start_section "conda.clean" "${GREEN}Cleaning up..${NC}"
#conda clean -s --dry-run
end_section "conda.clean"

$SPACER
