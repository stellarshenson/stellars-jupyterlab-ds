#!/bin/bash

# find if running with nvidia GPU support
if [[ $GPU_SUPPORT_ENABLED == 1 ]]; then
    /usr/bin/nvidia-smi
fi

# output build info and banners
BUILD_DATE=`cat /build-date.txt`
BUILD_NAME=`cat /build-name.txt`
cat /build-info.txt | sed "s/@BUILD_NAME@/$BUILD_NAME/g" | sed "s/@BUILD_DATE@/$BUILD_DATE/g" 

# run tensorboard in the background
mkdir /tmp/tensorboard 2>/dev/null
tensorboard --bind_all --logdir /tmp/tf_logs --port 6006 &

# generate ssl keys if don't exist yet (happens first time the script is run)
CERTS_DIR="/mnt/certs"
if [ ! -e "$CERTS_DIR/jupyterlab.crt" ]; then
	/generate_jupyterlab_ssl.sh "$CERTS_DIR"
fi

# run jupyterlab, env params are configured in Dockerfile and docker-compose yml 
jupyter-lab --ip=$JUPYTERLAB_SERVER_IP --IdentityProvider.token=$JUPYTERLAB_SERVER_TOKEN \
    --IdentityProvider.password=$JUPYTERLAB_SERVER_PASSWORD --no-browser 

# EOF
