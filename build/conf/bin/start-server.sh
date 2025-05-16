#!/bin/bash

# find if running with nvidia GPU support
if [[ $GPU_SUPPORT_ENABLED == 1 ]]; then
    /usr/bin/nvidia-smi
fi

# output build info and banners
START_SERVER_DIR='/start-server.d'
BUILD_DATE=`cat /build-date.txt`
BUILD_NAME=`cat /build-name.txt`
cat /build-info.txt | sed "s/@BUILD_NAME@/$BUILD_NAME/g" | sed "s/@BUILD_DATE@/$BUILD_DATE/g" 

# update welcome.html with LAB_USER
# it is a bit tricky because we can only do inplace changes
cat /welcome.html | sed "s/@LAB_USER@/${LAB_USER:-default}/g" > /tmp/welcome.html.new
truncate /welcome.html --size 0
cat /tmp/welcome.html.new >> /welcome.html
rm /tmp/welcome.html.new

# run  servers start scripts in the background
for file in $START_SERVER_DIR/*; do
    if [ -f "$file" ] && [ -x "$file" ]; then
        "$file" &
    fi
done

## Jupyterlab will be launched in the foreground
echo -e "Jupyterlab access token: \e[95m${JUPYTERLAB_SERVER_TOKEN}\e[0m"

# generate ssl keys if don't exist yet (happens first time the script is run)
# skip this step if no certificate dir
CERTS_DIR="/mnt/certs"
if [[ -z $(find $CERTS_DIR -name '*.crt') ]]; then
	/generate-jupyterlab-ssl.sh "$CERTS_DIR" "stellars-jupyterlab-ds"
fi

# run jupyterlab, env params are configured in Dockerfile and docker-compose yml 
jupyter-lab \
    --autoreload \
    --ip=$JUPYTERLAB_SERVER_IP \
    --IdentityProvider.token=$JUPYTERLAB_SERVER_TOKEN \
    --ServerApp.base_url=$JUPYTERLAB_BASE_URL \
    --no-browser 

# EOF

