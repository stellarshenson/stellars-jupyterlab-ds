#!/bin/sh 
CURRENT_FILE=`readlink -f $0`
CURRENT_DIR=`dirname $CURRENT_FILE`
cd $CURRENT_DIR

# Check if nvidia-smi is available
if command -v nvidia-smi &> /dev/null; then
    if nvidia-smi > /dev/null 2>&1; then
        echo "Nvidia GPU found."
        # Run the command for when GPU is available
	docker compose -f ../local/compose-gpu.yml up  --no-recreate --no-build $1
    else
        echo "Nvidia GPU not found."
        # Run the command for when GPU is not available
	docker compose -f ../local/compose.yml up  --no-recreate --no-build $1
    fi
else
    echo "nvidia-smi command not found. Nvidia GPU not available."
    # Run the command for when GPU is not available
    docker compose -f ../local/compose.yml up  --no-recreate --no-build $1
fi

# EOF
