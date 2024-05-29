#!/bin/bash

# Directory where the certificates will be stored is provided as 1st argument
CERT_DIR="$1"
mkdir -p $CERT_DIR

# Certificate details
COMMON_NAME="stellars-jupyterlab-ds"

# Certificate file names
CERT_FILE="${CERT_DIR}/jupyterlab.crt"
KEY_FILE="${CERT_DIR}/jupyterlab.key"

# Generate the private key
openssl genrsa -out $KEY_FILE 2048

# Generate the certificate signing request (CSR)
openssl req -new -key $KEY_FILE -out "${CERT_DIR}/jupyterlab.csr" \
    -subj "/CN=$COMMON_NAME"

# Generate the self-signed certificate
openssl x509 -req -days 365 -in "${CERT_DIR}/jupyterlab.csr" -signkey $KEY_FILE -out $CERT_FILE

# Clean up the CSR
rm "${CERT_DIR}/jupyterlab.csr"

# Change permissions of private key
chmod 600 $CERT_FILE $KEY_FILE

# Output the paths of the generated certificate and key
echo "Certificate: $CERT_FILE"
echo "Key: $KEY_FILE"

# Instructions for configuring JupyterLab
echo "To configure JupyterLab with these certificates, add the following to your jupyter_notebook_config.py:"
echo "c.ServerApp.certfile = u'$CERT_FILE'"
echo "c.ServerApp.keyfile = u'$KEY_FILE'"

#EOF
