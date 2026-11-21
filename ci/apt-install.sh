#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
options=(-o Acquire::ForceIPv4=true -o Acquire::Retries=2 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30)
sudo --preserve-env=DEBIAN_FRONTEND apt-get "${options[@]}" -o APT::Update::Error-Mode=any -qy update
sudo --preserve-env=DEBIAN_FRONTEND apt-get "${options[@]}" -qy install "$@"
