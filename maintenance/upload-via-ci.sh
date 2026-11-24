#!/usr/bin/env bash
set -eo pipefail

if [[ "$ANACONDA_USER" != unic-cass || -z "$ANACONDA_TOKEN" || -z "$OPENEMS_PENDING" ]]; then
    echo 'Expected pending archives and upload credentials for unic-cass' >&2
    exit 1
fi

export CI_SCRIPTS_PATH="$PWD/ci"
export OS_NAME=linux PACKAGE=sim/openems
export UPLOAD=""
out="$RUNNER_TEMP/openems/conda-bld/linux-64"
mkdir -p "$out"

# Both CI scripts derive the run label from the checked-out branch. The local
# name avoids putting the maintenance branch's slash into the label.
git switch --create openems-defaults
for file in $OPENEMS_PENDING; do
    cp -- "maintenance/artifacts/$file" "$out/$file"
    CONDA_OUT="$out/$file" bash "$CI_SCRIPTS_PATH/after_success.sh"
done

# The promotion script enables xtrace, which would echo the upload token.
BASH_XTRACEFD=9 bash "$CI_SCRIPTS_PATH/upload-packages.sh" 9>/dev/null
