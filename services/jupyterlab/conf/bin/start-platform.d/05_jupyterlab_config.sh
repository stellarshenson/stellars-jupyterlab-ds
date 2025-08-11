#!/bin/bash
# ----------------------------------------------------------------------------------------
# Copies useful shortcuts to user workspace
# ----------------------------------------------------------------------------------------
CONDA_USER_WORKSPACE=${CONDA_USER_WORKSPACE:-/home/lab/workspace}

echo "Forcing predefined jupyterlab config file"

JUPYTERLAB_CONFIG_FILE_USER="${HOME}/.jupyter/jupyter_lab_config.py"
JUPYTERLAB_CONFIG_FILE_TEMPLATE="/opt/etc/jupyter/jupyter_lab_config.py"

if [[ ! -f "${JUPYTERLAB_CONFIG_FILE_USER}" ]]; then
    rm ${JUPYTERLAB_CONFIG_FILE_USER}
    ln -s ${JUPYTERLAB_CONFIG_FILE_TEMPLATE} ${JUPYTERLAB_CONFIG_FILE_USER} 
fi

# EOF

