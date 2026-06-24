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

# shared logging helpers - exported so every start-platform.d/*.sh child inherits
# log_info / log_warn / log_error / log_pipe (see /lib-logging.sh)
source /lib-logging.sh
export -f _log log_info log_warn log_error log_pipe


# set container timezone via TZ env (userspace, no root writes needed - glibc
# honours TZ in every child process: terminals, kernels, services)
if [[ -n "${JUPYTERLAB_TIMEZONE}" ]]; then
    if [[ -f "/usr/share/zoneinfo/${JUPYTERLAB_TIMEZONE}" ]]; then
        export TZ="${JUPYTERLAB_TIMEZONE}"
        log_info "Timezone set to ${TZ}"
    else
        log_warn "Invalid timezone '${JUPYTERLAB_TIMEZONE}' - zoneinfo not found"
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
    log_info "Starting jupyterlab under jupyterhub"
    conda run --no-capture-output -n base jupyter-labhub "$@"

# standalone jupyterlab
else
    log_info "Starting standalone jupyterlab server"
    conda run --no-capture-output -n base jupyter-lab \
	--autoreload \
	--ip=$JUPYTERLAB_SERVER_IP \
	--IdentityProvider.token=$JUPYTERLAB_SERVER_TOKEN \
	--ServerApp.base_url=$JUPYTERLAB_BASE_URL \
	--no-browser \
	"$@"
fi

# EOF

