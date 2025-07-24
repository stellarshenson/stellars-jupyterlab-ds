#!/bin/bash
# ----------------------------------------------------------------------------------------
# Copies useful shortcuts to user workspace
# ----------------------------------------------------------------------------------------
CONDA_USER_WORKSPACE=${CONDA_USER_WORKSPACE:-/home/lab/workspace}

echo "Creating useful shortcuts in the workspace"
if [[ ! -d "${CONDA_USER_WORKSPACE}/@shared" ]]; then
    ln -s /mnt/shared ${CONDA_USER_WORKSPACE}/@shared 
fi

if [[ ! -d "${CONDA_USER_WORKSPACE}/@cache" ]]; then
    ln -s /home/lab/.cache ${CONDA_USER_WORKSPACE}/@cache 
fi

# EOF

