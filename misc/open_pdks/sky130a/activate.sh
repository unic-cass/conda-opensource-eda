_PDK_=sky130A
_PDK_ROOT_=$CONDA_PREFIX/share/pdk
[[ ! -z "${PDK_ROOT}" ]] && echo "PDK_ROOT is defined as $PDK_ROOT. Overwrite it to $_PDK_ROOT_"
export PDK_ROOT=$_PDK_ROOT_

[[ ! -z "${PDK}" ]] && echo "PDK is defined as $PDK. Overwrite it to $_PDK_"
export PDK=$_PDK_
# export SPICE_SCRIPTS=$PDK_ROOT/$PDK/libs.tech/ngspice
