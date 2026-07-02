#!/bin/bash
# ----------------------------------------------------------------------------------------
# Generates SSL keys used by jupyterlab & traefik
# ----------------------------------------------------------------------------------------

# host-based routing: lab.<project>.localhost and traefik.<project>.localhost are both
# covered by the *.<project>.localhost wildcard SAN; LAB_NAME carries the project name
CERTS_DIR="/mnt/certs"
CERT_CN="lab.${LAB_NAME:-stellars-jupyterlab-ds}.localhost"
CERT_SAN="DNS:localhost,DNS:*.localhost,DNS:*.${LAB_NAME:-stellars-jupyterlab-ds}.localhost,IP:127.0.0.1,IP:::1"

# (re)generate when no certificate exists yet, or when the existing one lacks the
# per-project wildcard SAN (pre-SAN certificate, or the project was renamed)
CERT_FILE=$(find $CERTS_DIR -name '*.crt' | head -n 1)
if [[ -z "$CERT_FILE" ]] || ! openssl x509 -in "$CERT_FILE" -noout -ext subjectAltName 2>/dev/null | grep -qF "*.${LAB_NAME:-stellars-jupyterlab-ds}.localhost"; then
	log_info "generating self-signed certificate CN=$CERT_CN"
	/mkcert.sh "$CERTS_DIR" "$CERT_CN" "server" "$CERT_SAN" # params: certs_dir, common_name, file_prefix, san_list
fi


# EOF
