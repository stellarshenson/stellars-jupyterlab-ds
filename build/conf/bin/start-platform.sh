#!/bin/bash

# run series of start scripts
# (services will need to run in background)
START_PLATFORM_DIR='/start-server.d'
for file in $START_PLATFORM_DIR/*; do
    if [ -f "$file" ] && [ -x "$file" ]; then
        "$file" 
    fi
done

# run jupyterlab, env params are configured in Dockerfile and docker-compose yml 
jupyter-lab \
    --autoreload \
    --ip=$JUPYTERLAB_SERVER_IP \
    --IdentityProvider.token=$JUPYTERLAB_SERVER_TOKEN \
    --ServerApp.base_url=$JUPYTERLAB_BASE_URL \
    --no-browser 

# EOF

