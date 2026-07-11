#!/bin/bash

# load and export env variables from system config
set -a
. /etc/default/platform.env
set +a

# normalize the deployment switches ONCE for every consumer (this shell and all
# start-platform.d hooks inherit the exports): a whitespace-padded "0 " from a
# hand-edited .env or hub spawner config must still switch OFF - the Python
# layers (menu.switch_off / envman.store_locked) trim the same way, so the
# enforcement below can never disagree with the menu/applet about the lock state
export JUPYTERLAB_USER_ENV_ENABLE="${JUPYTERLAB_USER_ENV_ENABLE//[[:space:]]/}"
export JUPYTERLAB_SUDO_ENABLE="${JUPYTERLAB_SUDO_ENABLE//[[:space:]]/}"

# load and export the user's central env store DIRECTLY - the server (and thus
# every notebook kernel and platform service) must not depend on ~/.profile,
# which stays a shell-only concern (login shells source the same store there).
# One store, two readers: start-platform.sh for the server, .profile for shells.
# JUPYTERLAB_USER_ENV_ENABLE=0 locks the store: skipping it HERE is the actual
# enforcement - whatever a user writes into the file can no longer reach the
# server, kernels or services (the menu/applet/set-profile-var refusals are
# convenience on top). ~/.profile remains the manual, shell-only channel.
# Logged by the 05_lock_user_env.sh hook (log helpers load below this line).
#
# The store is PARSED as data, never sourced as shell: `. file` executes
# arbitrary shell, so a hand-edited compound line
# (`X=1; export JUPYTERLAB_SUDO_ENABLE=1`) would smuggle a protected assignment
# past any per-line filter and override deployment env (re-arm sudo on the next
# recreate, re-expose mlflow via MLFLOW_HOST, inject LD_PRELOAD) for this shell
# and every start-platform.d hook. envman.iter_store_exports drops the
# PROTECTED_NAMES / *_PREFIXES set (JUPYTERLAB_TERMINAL_SHELL exempt) on the
# PARSED key and emits NUL-delimited KEY=VALUE pairs; each value is assigned as
# literal data. This covers the server and every start-platform.d hook. Login
# shells (terminals) still source the store raw via ~/.profile - the accepted
# shell-only channel: a poisoned store there only alters that terminal's own
# env (and the menu/applet lock predicate the terminal reads), never the
# server, kernels or services.
# one-time migration BEFORE the store is applied: the pre-store Default Shell
# selector wrote `export JUPYTERLAB_TERMINAL_SHELL=...` into ~/.profile, which
# the boot (deliberately) no longer sources - without this MOVE into the store
# a choice stranded there never reaches terminado and the terminal silently
# falls back to bash. Prints the migrated value on stdout; diagnostics land on
# stderr - both captured here and logged below once the log helpers exist
# (a crashed or refused migration must be visible, not a silent no-op).
_migrate_err=$(mktemp)
_migrated_shell=$(/opt/conda/bin/python3 -c 'from duoptimum_lab_utils.envman import migrate_legacy_shell
v = migrate_legacy_shell()
if v:
    print(v)' 2>"${_migrate_err}") || _migrate_failed=1

if [[ ${JUPYTERLAB_USER_ENV_ENABLE:-1} != 0 && -f "${HOME}/.local/environment.env" ]]; then
    _store_err=$(mktemp) # capture stderr; log helpers load below, so warn later
    while IFS= read -r -d '' _pair; do
        export "${_pair%%=*}=${_pair#*=}"
    done < <(/opt/conda/bin/python3 -c 'import sys
from duoptimum_lab_utils.envman import iter_store_exports
for k, v in iter_store_exports():
    sys.stdout.buffer.write((k + "=" + v + "\0").encode("utf-8", "surrogateescape"))' 2>"${_store_err}")
    unset _pair
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

# surface a failed store load now that the log helpers exist (the export loop
# above ran before them). Non-empty stderr = the store applied zero vars; the
# fail-safe direction is correct (better empty than a raw source), but a silent
# degrade reads to the user as "my env vars vanished" with no diagnostic.
if [[ -n ${_store_err:-} ]]; then
    [[ -s ${_store_err} ]] && log_warn "user env store not applied: $(tr '\n' ' ' < "${_store_err}")"
    rm -f "${_store_err}"
    unset _store_err
fi

# surface the legacy default-shell migration outcome (ran before the helpers):
# a migrated value is worth a line; a crashed or refused migration must never
# be silent - stderr is single-lined so a traceback stays one log record
if [[ -n ${_migrate_err:-} ]]; then
    if [[ -n ${_migrate_failed:-} || -s ${_migrate_err} ]]; then
        log_warn "legacy default-shell migration: $(tr '\n' ' ' < "${_migrate_err}")"
    elif [[ -n ${_migrated_shell:-} ]]; then
        log_info "Migrated legacy default shell '${_migrated_shell}' from ~/.profile into the env store"
    fi
    rm -f "${_migrate_err}"
fi
unset _migrated_shell _migrate_failed _migrate_err


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

