#!/bin/bash
set -ex

# Packaged yosys-config --build points at the compiler in Yosys's old build
# environment. Keep its plugin flags, but use the compiler from this build.
cat > eqy-yosys-config <<'EOF'
#!/bin/bash
if [[ "$1" == --build ]]; then
    output=$2
    shift 2
    set -- --exec "$CXX" --cxxflags --ldflags -o "$output" -shared "$@" --libs
fi
exec "$PREFIX/bin/yosys-config" "$@"
EOF
chmod +x eqy-yosys-config

make -j"${CPU_COUNT}" PREFIX="${PREFIX}" YOSYS_CONFIG=./eqy-yosys-config install
