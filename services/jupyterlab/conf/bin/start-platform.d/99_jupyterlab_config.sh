#!/bin/bash
# ----------------------------------------------------------------------------------------
# Forces the predefined jupyterlab config: links the user config to the baked template
# unless the user placed their own regular file there
# ----------------------------------------------------------------------------------------

log_info "Forcing predefined jupyterlab config file"

JUPYTERLAB_CONFIG_FILE_USER="${HOME}/.jupyter/jupyter_lab_config.py"
JUPYTERLAB_CONFIG_FILE_TEMPLATE="/opt/conda/etc/jupyter/jupyter_lab_config.py"

if [[ ! -f "${JUPYTERLAB_CONFIG_FILE_USER}" ]]; then
    rm -f ${JUPYTERLAB_CONFIG_FILE_USER} # may be absent or a dangling symlink - stay quiet
    ln -s ${JUPYTERLAB_CONFIG_FILE_TEMPLATE} ${JUPYTERLAB_CONFIG_FILE_USER}
fi

# EOF

