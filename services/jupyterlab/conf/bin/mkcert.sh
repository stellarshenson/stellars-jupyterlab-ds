#!/bin/bash

# Validate input arguments
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "Usage: $0 <certificate_directory> <common_name> <certificate_prefix> [subject_alt_names]"
  echo "Example: $0 /etc/ssl/mycerts mydomain server 'DNS:mydomain,DNS:*.mydomain'"
  exit 1
fi

# Directory where the certificates will be stored is provided as 1st argument#
CERT_DIR="$1"
CERT_CN="$2"
CERT_PREFIX="$3"
CERT_SAN="${4:-DNS:$2}" # subjectAltName list, defaults to the common name
mkdir -p $CERT_DIR

# Certificate details
COMMON_NAME=${CERT_CN}

# Certificate file names
CERT_FILE="${CERT_DIR}/${CERT_PREFIX}.crt"
KEY_FILE="${CERT_DIR}/${CERT_PREFIX}.key"

# Generate the key and the self-signed certificate in one step; browsers ignore the CN
# and require the hostnames to be listed in subjectAltName
openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
    -keyout $KEY_FILE -out $CERT_FILE \
    -subj "/CN=$COMMON_NAME" \
    -addext "subjectAltName=$CERT_SAN"

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
