#!/bin/bash

# Validate input arguments
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <certificate_directory> <certificate_prefix>"
  echo "Example: $0 /etc/ssl/mycerts mydomain"
  exit 1
fi

# Directory where the certificates will be stored is provided as 1st argument#
CERT_DIR="$1"
CERT_PREFIX="$2"
mkdir -p $CERT_DIR

# Certificate details
COMMON_NAME=${CERT_PREFIX}

# Certificate file names
CERT_FILE="${CERT_DIR}/${CERT_PREFIX}.crt"
KEY_FILE="${CERT_DIR}/${CERT_PREFIX}.key"

# Generate the private key
openssl genrsa -out $KEY_FILE 2048

# Generate the certificate signing request (CSR)
openssl req -new -key $KEY_FILE -out "${CERT_DIR}/${CERT_PREFIX}.csr" \
    -subj "/CN=$COMMON_NAME"

# Generate the self-signed certificate
openssl x509 -req -days 365 -in "${CERT_DIR}/${CERT_PREFIX}.csr" -signkey $KEY_FILE -out $CERT_FILE

# Clean up the CSR
rm "${CERT_DIR}/${CERT_PREFIX}.csr"

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
