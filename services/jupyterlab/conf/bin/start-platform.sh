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


# set container timezone via TZ env (userspace, no root writes needed - glibc
# honours TZ in every child process: terminals, kernels, services)
if [[ -n "${JUPYTERLAB_TIMEZONE}" ]]; then
    if [[ -f "/usr/share/zoneinfo/${JUPYTERLAB_TIMEZONE}" ]]; then
        export TZ="${JUPYTERLAB_TIMEZONE}"
        echo "Timezone set to ${TZ}"
    else
        echo "WARNING: Invalid timezone '${JUPYTERLAB_TIMEZONE}' - zoneinfo not found"
    fi
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
    conda run --no-capture-output -n base jupyter-labhub "$@"

# standalone jupyterlab
else
    echo "Starting standalone jupyterlab server"
    conda run --no-capture-output -n base jupyter-lab \
	--autoreload \
	--ip=$JUPYTERLAB_SERVER_IP \
	--IdentityProvider.token=$JUPYTERLAB_SERVER_TOKEN \
	--ServerApp.base_url=$JUPYTERLAB_BASE_URL \
	--no-browser \
	"$@"
fi

# EOF

