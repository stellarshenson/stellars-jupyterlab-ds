#!/bin/bash
# ----------------------------------------------------------------------------------------
# Rebrand "stellars-jupyterlab-ds" to JUPYTERLAB_SYSTEM_NAME if set.
# Substitutes literal text in /welcome.html and /welcome-message.txt.
# render-info.py reads the env var directly, no rewrite needed there.
# ----------------------------------------------------------------------------------------

if [[ -z "${JUPYTERLAB_SYSTEM_NAME}" ]]; then
    exit 0
fi

echo "Rebranding welcome files to ${JUPYTERLAB_SYSTEM_NAME}"

# Drop the upstream GitHub link from welcome-message.txt - the URL would point
# to a non-existent repo once the system name is rebranded
sudo sed -i '/^For more information visit:/d' /welcome-message.txt

sudo sed -i "s/stellars-jupyterlab-ds/${JUPYTERLAB_SYSTEM_NAME}/g" \
    /welcome.html \
    /welcome-message.txt \
    /etc/motd

# EOF
