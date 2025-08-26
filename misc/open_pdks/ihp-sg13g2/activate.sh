_PDK_=ihp-sg13g2
_PDK_ROOT_=$CONDA_PREFIX/share/pdk
[[ ! -z "${PDK_ROOT}" ]] && echo "PDK_ROOT is defined as $PDK_ROOT. Overwrite it to $_PDK_ROOT_"
export PDK_ROOT=$_PDK_ROOT_

[[ ! -z "${PDK}" ]] && echo "PDK is defined as $PDK. Overwrite it to $_PDK_"
export PDK=$_PDK_
[[ ! -z "${SPICE_SCRIPTS}" ]] && echo "SPICE_SCRIPT is defined as $SPICE_SCRIPTS. Overwrite it to $PDK_ROOT/$PDK/libs.tech/ngspice"
export SPICE_SCRIPTS=$PDK_ROOT/$PDK/libs.tech/ngspice
