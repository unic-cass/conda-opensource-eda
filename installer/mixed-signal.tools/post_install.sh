#!/bin/bash

set -e
cat > "$PREFIX/envs/eda/.condarc" <<'EOF'
channels:
  - unic-cass
  - conda-forge
  - defaults
channel_priority: flexible
EOF
