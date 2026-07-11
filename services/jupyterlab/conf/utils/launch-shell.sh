#!/bin/bash
# Terminal launcher for JupyterLab - wired as terminado's shell_command in
# jupyter_lab_config.py. Resolves the user's Default Shell at TERMINAL SPAWN
# time, so a Settings > Default Shell selection applies to the next terminal
# with no server restart. Exec replaces this process with the chosen shell as
# a login shell - the native spawn every shell's own init (motd, welcome,
# prompt) expects.
#
# Resolution order:
#   1. user env store (~/.local/environment.env) - the value the Default Shell
#      selector writes; PARSED as data, never sourced, same discipline as the
#      platform start. Skipped when the deployment locks the store
#      (JUPYTERLAB_USER_ENV_ENABLE=0).
#   2. JUPYTERLAB_TERMINAL_SHELL env - the deployment default baked into the
#      image (DEFAULT_SHELL build arg) or provided by compose/hub.
#   3. /bin/bash.
# Anything that is not an absolute path to an executable falls through to the
# next tier - a stale or hand-mangled store value must never brick terminals.

SHELL_CMD="${JUPYTERLAB_TERMINAL_SHELL:-/bin/bash}"

STORE="${HOME}/.local/environment.env"
_enable="${JUPYTERLAB_USER_ENV_ENABLE//[[:space:]]/}"
if [[ ${_enable:-1} != 0 && -r ${STORE} ]]; then
    # last assignment wins, like a shell; strip one layer of matching quotes
    # (the store's canonical form is single-quoted, legacy edits may differ)
    _line=$(grep -E '^[[:space:]]*(export[[:space:]]+)?JUPYTERLAB_TERMINAL_SHELL=' "${STORE}" | tail -1)
    if [[ -n ${_line} ]]; then
        _val="${_line#*=}"
        _val="${_val#"${_val%%[![:space:]]*}"}"
        _val="${_val%"${_val##*[![:space:]]}"}"
        case ${_val} in
            \'*\') _val="${_val:1:-1}" ;;
            \"*\") _val="${_val:1:-1}" ;;
        esac
        [[ -n ${_val} && ${_val} == /* && -f ${_val} && -x ${_val} ]] && SHELL_CMD="${_val}"
    fi
fi

# final gate on whatever won - fall back to bash rather than a dead terminal
[[ ${SHELL_CMD} == /* && -f ${SHELL_CMD} && -x ${SHELL_CMD} ]] || SHELL_CMD=/bin/bash

exec "${SHELL_CMD}" --login

# EOF
