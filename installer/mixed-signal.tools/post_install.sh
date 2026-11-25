#!/bin/bash

set -e
cat > "$PREFIX/envs/eda/.condarc" <<'EOF'
channels:
  - unic-cass
  - conda-forge
  - defaults
channel_priority: flexible
EOF
cat > "$PREFIX/envs/openems/.condarc" <<'EOF'
channels:  #!final
  - defaults
channel_priority: strict
EOF
