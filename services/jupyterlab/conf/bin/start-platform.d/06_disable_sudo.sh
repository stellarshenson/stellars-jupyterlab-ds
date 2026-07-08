#!/bin/bash
# ----------------------------------------------------------------------------------------
# Disable sudo for this container when JUPYTERLAB_SUDO_ENABLE=0 (default 1).
#
# The hub (or compose) decides at spawn time whether the lab user keeps root
# escalation. When disabled, this hook uses sudo one last time to replace the
# permissive NOPASSWD grant in /etc/sudoers.d/conda with an explicit deny-all
# rule (`!ALL`). This is more explicit and auditable than stripping the setuid
# bit from the sudo binary: the binary stays intact, but the policy forbids the
# lab user from running any command. `!ALL` is evaluated after the %sudo group
# grant in the main sudoers, so it wins (last match). The change lands in the
# container's writable layer, so it survives restarts - only recreating the
# container (possibly with JUPYTERLAB_SUDO_ENABLE=1) restores escalation.
# ----------------------------------------------------------------------------------------

if [[ ${JUPYTERLAB_SUDO_ENABLE} == 0 ]]; then
    user="$(id -un)"
    # distinguish "escalation already revoked" (expected on restart) from a real
    # failure of the disabling itself - a failed security control must not log as success
    if sudo -n true 2>/dev/null; then
        log_info "Disabling sudo for ${user} (JUPYTERLAB_SUDO_ENABLE=0)"
        sudo -n /bin/sh -c "printf '%s ALL=(ALL:ALL) !ALL\n' '${user}' > /etc/sudoers.d/conda \
            && chmod 0440 /etc/sudoers.d/conda \
            && visudo -cf /etc/sudoers.d/conda" \
            || log_error "failed to disable sudo for ${user} - escalation may still be possible"
    else
        log_info "sudo already disabled"
    fi

    # the welcome files advertise sudo and its default password - drop those so the
    # in-product docs stay truthful when escalation is off. Files are world-writable
    # but their directories are root-owned, so overwrite through cat (see 08)
    if [[ -w /welcome-message.txt ]] && grep -qi 'sudo' /welcome-message.txt; then
        tmp=$(mktemp)
        grep -vi 'sudo' /welcome-message.txt > "${tmp}" && cat "${tmp}" > /welcome-message.txt
        rm -f "${tmp}"
    fi
    # html: remove the whole Access Control section (its opening <div> precedes the
    # matchable <h2>, so buffer one line - plain line-grep would orphan the tags)
    if [[ -w /welcome.html ]] && grep -q '<h2>Access Control</h2>' /welcome.html; then
        tmp=$(mktemp)
        awk '
            hold && /<h2>Access Control<\/h2>/ { skip=1; hold=0; next }
            hold { print buf; hold=0 }
            /<div class="section">/ { buf=$0; hold=1; next }
            skip && /<\/div>/ { skip=0; next }
            skip { next }
            { print }
        ' /welcome.html > "${tmp}" && cat "${tmp}" > /welcome.html
        rm -f "${tmp}"
    fi
fi

# EOF
