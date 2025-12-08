#!/bin/bash

# load and export env variables
set -a
. /etc/default/platform.env
set +a


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
    jupyter-labhub "$@"

# standalone jupyterlab
else 
    echo "Starting standalone jupyterlab server"
    jupyter-lab \
	--autoreload \
	--ip=$JUPYTERLAB_SERVER_IP \
	--IdentityProvider.token=$JUPYTERLAB_SERVER_TOKEN \
	--ServerApp.base_url=$JUPYTERLAB_BASE_URL \
	--no-browser \
	"$@"
fi

# EOF

