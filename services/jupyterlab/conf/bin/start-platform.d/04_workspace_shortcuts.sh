#!/bin/bash
# ----------------------------------------------------------------------------------------
# Copies useful shortcuts to user workspace
# ----------------------------------------------------------------------------------------
CONDA_USER_WORKSPACE=${CONDA_USER_WORKSPACE:-/home/lab/workspace}

echo "Creating useful shortcuts in the workspace"
if [[ ! -f "${CONDA_USER_WORKSPACE}/@shared" ]]; then
    ln -s /mnt/shared ${CONDA_USER_WORKSPACE}/@shared 2>&1 >/dev/null
fi

if [[ ! -f "${CONDA_USER_WORKSPACE}/@cache" ]]; then
    ln -s /home/lab/.cache ${CONDA_USER_WORKSPACE}/@cache 2>&1 >/dev/null
fi

# EOF

