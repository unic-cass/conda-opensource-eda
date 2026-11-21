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
conda install --yes $CONDA_OUT
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
