#!/bin/bash
# ----------------------------------------------------------------------------------------
# Rebrand "stellars-jupyterlab-ds" to JUPYTERLAB_SYSTEM_NAME if set.
# Substitutes literal text in /welcome.html and /welcome-message.txt.
# render-info.py reads the env var directly, no rewrite needed there.
# ----------------------------------------------------------------------------------------

if [[ -z "${JUPYTERLAB_SYSTEM_NAME}" ]]; then
    exit 0
fi

log_info "Rebranding welcome files to ${JUPYTERLAB_SYSTEM_NAME}"

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

# Drop the upstream GitHub links - after rebranding the substituted URL
# (github.com/stellarshenson/<new-name>) would point to a non-existent repo.
# In welcome.html the repo link is the ONLY entry of the Documentation section,
# so the whole section goes (deleting just the line leaves an empty heading):
# P;D re-tests each buffered line, the inner block eats div-open through </div>
rewrite /welcome-message.txt '/^For more information visit:/d'
rewrite /welcome.html '/<div class="section">/{ N; /<h2>Documentation<\/h2>/{ :a; N; /<\/div>/!ba; d }; P; D }'

# sed-safe replacement: strip the characters that would break the s||| expression
# (a name with / & \ or | is invalid for URLs and docker naming anyway)
SAFE_NAME=$(printf '%s' "${JUPYTERLAB_SYSTEM_NAME}" | tr -d '/&\\|')
for file in /welcome.html /welcome-message.txt /etc/motd; do
    rewrite "${file}" "s|stellars-jupyterlab-ds|${SAFE_NAME}|g"
done

# EOF
