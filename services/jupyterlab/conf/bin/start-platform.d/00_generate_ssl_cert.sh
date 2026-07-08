#!/bin/bash
# ----------------------------------------------------------------------------------------
# Generates SSL keys used by jupyterlab & traefik
# ----------------------------------------------------------------------------------------

# under JupyterHub TLS belongs to the hub's proxy - nothing serves these certs
if [[ -n "${JUPYTERHUB_USER}" ]]; then
    exit 0
fi

# host-based routing: lab.<project>.localhost and traefik.<project>.localhost are both
# covered by the *.<project>.localhost wildcard SAN; LAB_NAME carries the project name
# (hub-mode fallback resolved ONCE so the three uses below cannot drift)
LAB_NAME="${LAB_NAME:-stellars-jupyterlab-ds}"
CERTS_DIR="/mnt/certs"
CERT_CN="lab.${LAB_NAME}.localhost"
CERT_SAN="DNS:localhost,DNS:*.localhost,DNS:*.${LAB_NAME}.localhost,IP:127.0.0.1,IP:::1"

# (re)generate when no certificate exists yet, when the existing one lacks the
# per-project wildcard SAN (pre-SAN certificate, or the project was renamed), or when
# it expires within 30 days (the certs volume outlives every image update - without
# this check an install older than a year serves an expired cert forever)
CERT_FILE=$(find $CERTS_DIR -name '*.crt' | head -n 1)
if [[ -z "$CERT_FILE" ]] \
	|| ! openssl x509 -in "$CERT_FILE" -noout -ext subjectAltName 2>/dev/null | grep -qF "*.${LAB_NAME}.localhost" \
	|| ! openssl x509 -in "$CERT_FILE" -noout -checkend 2592000 >/dev/null 2>&1; then
	log_info "generating self-signed certificate CN=$CERT_CN"
	/mkcert.sh "$CERTS_DIR" "$CERT_CN" "server" "$CERT_SAN" # params: certs_dir, common_name, file_prefix, san_list
fi


# EOF
