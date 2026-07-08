#!/bin/bash
# ----------------------------------------------------------------------------------------
# Permission layer of the user env store lock (JUPYTERLAB_USER_ENV_ENABLE=0, default 1).
#
# The DESIGN layer lives in start-platform.sh: when locked, the store
# (~/.local/environment.env) is not sourced at start, so nothing in it can reach
# the server, kernels or services; the menu hides the env-writing Settings
# entries and the applet / set-profile-var refuse. This hook adds the PERMISSIONS
# layer: root-own the store read-only so manual edits fail loudly instead of
# silently doing nothing. The user owns ~/.local, so this is friction, not a
# boundary - the file can be deleted and recreated, but a locked start never
# reads it, so that changes nothing.
#
# Sorts BEFORE 06_disable_sudo.sh - both branches need root, and an env change
# requires a container recreate, which also restores the sudo grant in the fresh
# writable layer. The store lives on the home volume, so a lock from a previous
# run persists - the unlock branch hands the file back when the switch returns
# to 1. Ownership (not writability) drives both branches, so a user's own
# permission choices on an unlocked store are never touched.
# ----------------------------------------------------------------------------------------

store="${HOME}/.local/environment.env"

if [[ ${JUPYTERLAB_USER_ENV_ENABLE:-1} == 0 ]]; then
    log_info "User env store locked (JUPYTERLAB_USER_ENV_ENABLE=0) - store not applied to the platform"
    # the lock holds only against a non-root user: with sudo the user can rewrite
    # any of this (the store, the hooks, the sudoers policy) - state it loudly
    if [[ ${JUPYTERLAB_SUDO_ENABLE:-1} != 0 ]]; then
        log_warn "env store lock is bypassable while sudo is enabled - pair it with JUPYTERLAB_SUDO_ENABLE=0"
    fi
    # NEVER run the privileged chown/chmod through a symlink: ~/.local is
    # user-owned, so a planted link would let the user aim a root file op at
    # any path (CWE-59). A symlinked store is left alone - the design-level
    # lock does not read the store either way.
    if [[ -L "${store}" ]]; then
        log_warn "store ${store} is a symlink - leaving it untouched (the design-level lock still applies)"
    elif [[ -f "${store}" && $(stat -c %u "${store}") != 0 ]]; then
        if sudo -n true 2>/dev/null; then
            # root:<user group> 640 keeps the store readable for login shells
            # (~/.profile sources it - the manual, shell-only channel stays
            # intact) without exposing user-stored values world-readable
            sudo -n chown "root:$(id -g)" "${store}" && sudo -n chmod 640 "${store}" \
                && log_info "Store ${store} set root-owned read-only" \
                || log_warn "Could not root-own ${store} - the design-level lock still applies"
        else
            log_info "sudo unavailable - store stays user-owned; the design-level lock still applies"
        fi
    fi
elif [[ -f "${store}" && ! -L "${store}" && $(stat -c %u "${store}") == 0 ]]; then
    # switch back on: hand a previously locked store back to the user
    if sudo -n true 2>/dev/null; then
        sudo -n chown "$(id -u):$(id -g)" "${store}" && sudo -n chmod 600 "${store}" \
            && log_info "User env store unlocked - returned to user ownership" \
            || log_warn "Could not return ${store} to user ownership"
    else
        log_warn "User env store ${store} is root-owned from a previous lock but sudo is unavailable to unlock it"
    fi
fi

# EOF
