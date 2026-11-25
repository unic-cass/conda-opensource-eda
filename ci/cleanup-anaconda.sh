#!/bin/bash

source "$CI_SCRIPTS_PATH/common.sh"

set -e

: "${ANACONDA_USER:?ANACONDA_USER not set}" "${ANACONDA_TOKEN:?ANACONDA_TOKEN not set}"
if ! command -v anaconda >/dev/null; then
    echo 'ERROR: Missing `anaconda-client` package!' >&2
    exit 1
fi

#print cleanup summary before exiting
log_file=$GITHUB_WORKSPACE/cleanup.log
echo "RESULT;LABELS;NDOWNLOADS;PACKAGE" >$log_file
function print_log {
    end_section  # in case exiting inside a section
    start_section "Cleanup summary"
    if command -v column >/dev/null; then
        column -t -s ';' < "$log_file"
    else
        cat "$log_file"
    fi
    end_section
}
trap print_log EXIT

#packages will be removed if their label is older than 'ago'
ago="30 days ago"
#packages won't be removed if they were downloaded more than 'download_threshold' times
download_threshold=30

#extract Conda-styled timestamp, i.e., MILLIseconds since the epoch (hence the `%3N`)
limit_date=$(date --date="$ago" +'%s%3N')

echo "[CLEANUP] Checking for CI packages older than $ago with no more than $download_threshold downloads"
if [[ ${CLEANUP_DRY_RUN:-false} == true ]]; then
    echo '[CLEANUP] Preview only: no packages will be deleted.'
fi

# The CLI prints requested data to stderr. Keep failed responses separate from
# parseable output, and retry only read operations.
anaconda_stdout() {
    local output status attempt
    for attempt in 1 2 3; do
        if output=$(anaconda -t "$ANACONDA_TOKEN" "$@" 2>&1); then
            printf '%s\n' "$output" | tr -s ' '
            return
        else
            status=$?
        fi
        printf '[CLEANUP] anaconda %s failed (attempt %s/3, exit %s):\n%s\n' \
            "$*" "$attempt" "$status" "${output//"$ANACONDA_TOKEN"/[redacted]}" >&2
        if (( attempt < 3 )); then
            sleep "$((attempt * 2))"
        fi
    done
    return "$status"
}

# This owner-scoped call is the first read we actually need. Checking the
# caller's implicit `main` label can fail even when this request would work.
label_list=$(anaconda_stdout label -o "$ANACONDA_USER" --list)
remove_failed=0
for label in $(grep -oP '(?<= \+ )ci-[^ ]+' <<< "$label_list")
do
    start_section "Label $label"

    #extra label check
    if [[ "${label:0:3}" != "ci-" ]]
    then
        echo "[CLEANUP] Omitting non-ci label $label."
        end_section
        continue
    fi

    #get label packages
    label_info=$(anaconda_stdout label -o "$ANACONDA_USER" --show "$label")
    packages=$(grep -oP '(?<= \+ )[^ ]+' <<< "$label_info" || true)
    if [[ -z "$packages" ]]; then
        echo "[CLEANUP] No packages on label $label."
        end_section
        continue
    fi

    #check build timestamp of the first package
    package=${packages%%$'\n'*}
    metadata=$(anaconda_stdout show "$package")
    timestamp=$(grep -oP '(?<=timestamp : )[0-9]+' <<< "$metadata")
    label_date=$(date --date=@${timestamp:0:-3})

    if [[ $timestamp -gt $limit_date ]]
    then
        echo "[CLEANUP] Not removing label $label with timestamp $timestamp ($label_date)"
        end_section
        continue
    fi

    echo "[CLEANUP] Removing packages from the old label $label with timestamp $timestamp ($label_date)"
    for package in $packages
    do
        metadata=$(anaconda_stdout show "$package")

        labels=$(echo "$metadata" | grep -oP '(?<=labels : ).+')
        ndownloads=$(echo "$metadata" | grep -oP '(?<=ndownloads : )[0-9]+')
        function print_result {
            # Keep the subdirectory and filename, regardless of archive format.
            local package_dir=${package%/*}
            local pkg_name=${package_dir##*/}/${package##*/}
            echo "$1;$labels;$ndownloads;$pkg_name" >> "$log_file"
            echo "[CLEANUP] $1: $pkg_name"
        }

        #make sure the package doesn't have the 'main' label
        if grep -Fq "'main'" <<< "$labels"
        then
            print_result "On main"
            continue
        fi

        #make sure the package hasn't been downloaded too many times
        if [[ $ndownloads -gt $download_threshold ]]
        then
            print_result "In use"
            continue
        fi

        if [[ $package == "$ANACONDA_USER"/open_pdks*/* ]]; then
            print_result "Protected PDK"
            continue
        fi

        if [[ ${CLEANUP_DRY_RUN:-false} == true ]]; then
            print_result "Would remove"
            continue
        fi

        # The '--force' switch makes package removal non-interactive
        if anaconda -t "$ANACONDA_TOKEN" remove --force "$package"
        then
            print_result "Removed"
        else
            # This might be caused by a simultaneously running cleanup script
            print_result "Rm error"
            remove_failed=1
        fi
    done
    end_section
done
exit "$remove_failed"
