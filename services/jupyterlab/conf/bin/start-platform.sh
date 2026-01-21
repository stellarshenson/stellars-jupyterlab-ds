#!/bin/bash

# load and export env variables from system config
set -a
. /etc/default/platform.env
set +a

# load and export env variables from user profile if exists
if [[ -f "${HOME}/.profile" ]]; then
    set -a
    . "${HOME}/.profile"
    set +a
fi


# run series of start scripts
# (services will need to run in background)
START_PLATFORM_DIR='/start-platform.d'
for file in ${START_PLATFORM_DIR}/*.sh; do
    if [ -f "${file}" ] && [ -x "${file}" ]; then
        "${file}" 
    fi
done

# if jupyterhub
if [[ -n ${JUPYTERHUB_USER} ]]; then
    echo "Starting jupyterlab under jupyterhub"
    LD_LIBRARY_PATH=/opt/conda/lib:$LD_LIBRARY_PATH conda run --no-capture-output -n base jupyter-labhub "$@"

# standalone jupyterlab
else
    echo "Starting standalone jupyterlab server"
    LD_LIBRARY_PATH=/opt/conda/lib:$LD_LIBRARY_PATH conda run --no-capture-output -n base jupyter-lab \
	--autoreload \
	--ip=$JUPYTERLAB_SERVER_IP \
	--IdentityProvider.token=$JUPYTERLAB_SERVER_TOKEN \
	--ServerApp.base_url=$JUPYTERLAB_BASE_URL \
	--no-browser \
	"$@"
fi

# EOF

