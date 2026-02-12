#!/bin/bash
# ----------------------------------------------------------------------------------------
# Set Container Timezone
#
# Sets timezone from JUPYTERLAB_TIMEZONE env var (IANA format, e.g. Europe/Warsaw).
# Uses symlink to /usr/share/zoneinfo since containers don't have systemd/timedatectl.
# Skips silently if JUPYTERLAB_TIMEZONE is not set.
# ----------------------------------------------------------------------------------------

if [[ -z "${JUPYTERLAB_TIMEZONE}" ]]; then
    exit 0
fi

ZONEINFO="/usr/share/zoneinfo/${JUPYTERLAB_TIMEZONE}"

if [[ ! -f "${ZONEINFO}" ]]; then
    echo "WARNING: Invalid timezone '${JUPYTERLAB_TIMEZONE}' - ${ZONEINFO} not found"
    exit 0
fi

sudo ln -sf "${ZONEINFO}" /etc/localtime
echo "${JUPYTERLAB_TIMEZONE}" | sudo tee /etc/timezone > /dev/null
echo "Timezone set to ${JUPYTERLAB_TIMEZONE}"

# EOF
