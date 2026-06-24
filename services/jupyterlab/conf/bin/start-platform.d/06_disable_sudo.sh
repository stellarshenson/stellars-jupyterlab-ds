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

if [[ ${JUPYTERLAB_SUDO_ENABLE:-1} == 0 ]]; then
    user="$(id -un)"
    log_info "Disabling sudo for ${user} (JUPYTERLAB_SUDO_ENABLE=0)"
    sudo -n /bin/sh -c "printf '%s ALL=(ALL:ALL) !ALL\n' '${user}' > /etc/sudoers.d/conda \
        && chmod 0440 /etc/sudoers.d/conda \
        && visudo -cf /etc/sudoers.d/conda" \
        || log_info "sudo already disabled"
fi

# EOF
