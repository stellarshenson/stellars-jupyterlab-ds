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

# Files are made world-writable at build time, but their directories (/ and
# /etc) are root-owned - so no `sed -i` (it replaces the file via a temp file
# in the same directory). Overwrite in place through cat instead, which only
# needs write permission on the file itself. No sudo.
rewrite() {
    local file="$1" expr="$2" tmp
    tmp=$(mktemp)
    sed "${expr}" "${file}" > "${tmp}" && cat "${tmp}" > "${file}"
    rm -f "${tmp}"
}

# Drop the upstream GitHub link from welcome-message.txt - the URL would point
# to a non-existent repo once the system name is rebranded
rewrite /welcome-message.txt '/^For more information visit:/d'

for file in /welcome.html /welcome-message.txt /etc/motd; do
    rewrite "${file}" "s/stellars-jupyterlab-ds/${JUPYTERLAB_SYSTEM_NAME}/g"
done

# EOF
