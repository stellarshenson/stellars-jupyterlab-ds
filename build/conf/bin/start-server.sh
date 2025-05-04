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
/conda-run.sh 'CONDA_DEFAULT_ENV=tensorflow tensorboard --bind_all --logdir /tmp/tf_logs --port 6006 &' 

# run glances system monitor in the background
/conda-run.sh 'CONDA_DEFAULT_ENV=base glances -w &' 

# generate ssl keys if don't exist yet (happens first time the script is run)
CERTS_DIR="/mnt/certs"
if [ ! -e "$CERTS_DIR/jupyterlab.crt" ]; then
	/generate-jupyterlab-ssl.sh "$CERTS_DIR"
fi

# run jupyterlab, env params are configured in Dockerfile and docker-compose yml 
jupyter-lab --autoreload --ip=$JUPYTERLAB_SERVER_IP --IdentityProvider.token=$JUPYTERLAB_SERVER_TOKEN \
    --no-browser 

# EOF

