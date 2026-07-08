#!/bin/bash

# load and export env variables from system config
set -a
. /etc/default/platform.env
set +a

# load and export the user's central env store DIRECTLY - the server (and thus
# every notebook kernel and platform service) must not depend on ~/.profile,
# which stays a shell-only concern (login shells source the same store there).
# One store, two readers: start-platform.sh for the server, .profile for shells.
if [[ -f "${HOME}/.local/environment.env" ]]; then
    set -a
    . "${HOME}/.local/environment.env"
    set +a
fi

# self-heal PATH: the store is user-managed, so a hand-edited PATH must not
# brick the platform start (conda/jupyter unresolvable, crash loop persisted by
# the home volume). ~/.local/bin leads so pip --user installs reach kernels;
# appending the platform dirs keeps them reachable regardless of user order.
PATH="${HOME}/.local/bin:${PATH}:/opt/utils:/opt/conda/bin:/opt/conda/condabin:/usr/local/bin:/usr/bin:/bin"
export PATH

# shared logging helpers - exported so every start-platform.d/*.sh child inherits
# log_info / log_warn / log_error / log_pipe (see /lib-logging.sh)
source /lib-logging.sh
export -f _log log_info log_warn log_error log_pipe


# mlflow clients (kernels, services) reach the tracking server via this URI -
# derived here from the port knobs so a port override (compose or hub env)
# propagates everywhere; a compose/hub-provided MLFLOW_TRACKING_URI wins
export MLFLOW_TRACKING_URI="${MLFLOW_TRACKING_URI:-http://localhost:${MLFLOW_SERVER_PORT:-${MLFLOW_PORT:-5000}}}"

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
        "${file}" || log_warn "startup hook ${file##*/} failed (exit $?)"
    fi
done

# The server is exec'd directly (conda env activated in-shell, no `conda run`
# wrapper): as PID 1 it must RECEIVE docker's SIGTERM itself - behind the
# bash -> conda-run-python -> bash chain the signal never arrived and every
# stop (docker stop, compose down, hub spawner stop) timed out into SIGKILL,
# killing kernels and the mlflow sqlite mid-write.
source /opt/conda/etc/profile.d/conda.sh
conda activate base

# if jupyterhub
if [[ -n ${JUPYTERHUB_USER} ]]; then
    log_info "Starting jupyterlab under jupyterhub"
    exec jupyter-labhub "$@"

# standalone jupyterlab
else
    log_info "Starting standalone jupyterlab server"
    # token passed via JUPYTER_TOKEN env, not argv - /proc/<pid>/cmdline is world-readable
    # (also on the host), /proc/<pid>/environ is not
    export JUPYTER_TOKEN="$JUPYTERLAB_SERVER_TOKEN"
    exec jupyter-lab \
	--autoreload \
	--ip="$JUPYTERLAB_SERVER_IP" \
	--ServerApp.base_url="$JUPYTERLAB_BASE_URL" \
	--no-browser \
	"$@"
fi

# EOF

