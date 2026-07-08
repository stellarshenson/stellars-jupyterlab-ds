#!/bin/bash
# ----------------------------------------------------------------------------------------
# Copies useful shortcuts to user workspace
# ----------------------------------------------------------------------------------------
CONDA_USER_WORKSPACE=${CONDA_USER_WORKSPACE:-${HOME}/workspace}

log_info "Creating useful shortcuts in the workspace"
# -sfn: a dangling leftover symlink would otherwise fail ln on every boot
if [[ ! -d "${CONDA_USER_WORKSPACE}/@shared" ]]; then
    ln -sfn /mnt/shared "${CONDA_USER_WORKSPACE}/@shared"
fi

if [[ ! -d "${CONDA_USER_WORKSPACE}/@cache" ]]; then
    ln -sfn "${HOME}/.cache" "${CONDA_USER_WORKSPACE}/@cache"
fi

# EOF

