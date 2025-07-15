#!/bin/bash

# run series of start scripts
# (services will need to run in background)
START_PLATFORM_DIR='/start-platform.d'
for file in $START_PLATFORM_DIR/*; do
    if [ -f "$file" ] && [ -x "$file" ]; then
        "$file" 
    fi
done

# run jupyterlab, env params are configured in Dockerfile and docker-compose yml 
if [[ -z ${JUPYTERLAB_STARTUP_MODE} ||  ${JUPYTERLAB_STARTUP_MODE} == 'jupyterlab' ]]; then
    echo "starting jupyterlab server"
    jupyter-lab \
	--autoreload \
	--ip=$JUPYTERLAB_SERVER_IP \
	--IdentityProvider.token=$JUPYTERLAB_SERVER_TOKEN \
	--ServerApp.base_url=$JUPYTERLAB_BASE_URL \
	--no-browser \
	"$@"
# run in jupyterhub mode
elif [[ ${JUPYTERLAB_STARTUP_MODE} == 'jupyterhub' ]]; then 
    echo "starting jupyterhub-singleuser server"
    jupyterhub-singleuser "$@"
fi

# EOF

