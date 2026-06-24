#!/bin/bash
# ----------------------------------------------------------------------------------------
# Shared logging helpers for the platform startup scripts.
#
# Emits records in the same shape as the JupyterLab server log, so the
# start-platform output reads consistently alongside it:
#
#     <timestamp> [LEVEL] <name>: <message>
#     2026-06-24 15:26:45,123 [INFO] 04_workspace_shortcuts: Creating useful shortcuts
#
# <name> defaults to the running script's basename (minus the .sh suffix), so
# every line is traceable to the script that emitted it - override with LOG_NAME.
#
# start-platform.sh sources this file once and exports the functions, so every
# start-platform.d/*.sh child (and any pipeline subshell, e.g. log_pipe) inherits
# log_info / log_warn / log_error / log_pipe without sourcing it again.
# ----------------------------------------------------------------------------------------

_log() {
    local level="$1"; shift
    local name="${LOG_NAME:-${0##*/}}"
    name="${name%.sh}"
    printf '%s [%s] %s: %s\n' "$(date '+%Y-%m-%d %H:%M:%S,%3N')" "${level}" "${name}" "$*"
}

log_info()  { _log "INFO" "$@"; }
log_warn()  { _log "WARNING" "$@"; }
log_error() { _log "ERROR" "$@" >&2; }

# Read stdin and re-emit each line through the log at the given level (default
# INFO), so output from a wrapped child process (e.g. ttyd) is tagged with the
# source script instead of arriving unattributed.
log_pipe() {
    local level="${1:-INFO}"
    local line
    while IFS= read -r line; do
        _log "${level}" "${line}"
    done
}
