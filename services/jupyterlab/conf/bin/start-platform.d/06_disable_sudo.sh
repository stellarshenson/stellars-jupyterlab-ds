#!/bin/bash
# ----------------------------------------------------------------------------------------
# Disable sudo for this container when JUPYTERLAB_SUDO_ENABLE=0 (default 1).
#
# The hub (or compose) decides at spawn time whether the lab user keeps root
# escalation. When disabled, this hook uses sudo one last time to remove the
# NOPASSWD sudoers entry and strip the setuid bit from the sudo binary, making
# sudo unusable for everyone. The change lands in the container's writable
# layer, so it survives restarts - only recreating the container (possibly
# with JUPYTERLAB_SUDO_ENABLE=1) brings sudo back.
# ----------------------------------------------------------------------------------------

if [[ ${JUPYTERLAB_SUDO_ENABLE:-1} == 0 ]]; then
    echo "Disabling sudo for this container (JUPYTERLAB_SUDO_ENABLE=0)"
    sudo -n /bin/sh -c 'rm -f /etc/sudoers.d/conda && chmod 0000 /usr/bin/sudo' 2>/dev/null \
        || echo "sudo already disabled"
fi

# EOF
