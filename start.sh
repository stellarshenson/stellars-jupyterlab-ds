#!/bin/sh
CURRENT_FILE=`readlink -f $0`
CURRENT_DIR=`dirname $CURRENT_FILE`
cd $CURRENT_DIR

ENV_FILE=".env"

# First start: no auth token in .env yet -> ask for a password and save it.
# Stored as JUPYTERLAB_SERVER_TOKEN, it becomes the password the JupyterLab
# login page asks for (it is never placed in the URL).
if ! grep -q '^JUPYTERLAB_SERVER_TOKEN=' "$ENV_FILE" 2>/dev/null; then
    echo "First start - set the initial password for JupyterLab access."
    echo "This is the initial password; you can change it after you log in."
    printf "Enter a password: "
    stty -echo 2>/dev/null
    read JUPYTERLAB_PASSWORD
    stty echo 2>/dev/null
    echo
    printf 'JUPYTERLAB_SERVER_TOKEN=%s\n' "$JUPYTERLAB_PASSWORD" >> "$ENV_FILE"
    echo "Initial password saved to $ENV_FILE (key JUPYTERLAB_SERVER_TOKEN)."
fi

# Check if nvidia-smi is available
if command -v nvidia-smi &> /dev/null; then
    if nvidia-smi > /dev/null 2>&1; then
        echo "Nvidia GPU found."
        # Run the command for when GPU is available
	docker compose --env-file .env.default --env-file .env \
	    -f compose.yml -f compose-gpu.yml \
	    up --no-recreate --no-build -d
    else
        echo "Nvidia GPU not found."
        # Run the command for when GPU is not available
	docker compose --env-file .env.default --env-file .env \
	    -f compose.yml \
	    up  --no-recreate --no-build -d
    fi
else
    echo "nvidia-smi command not found. Nvidia GPU not available."
    # Run the command for when GPU is not available
    docker compose --env-file .env.default --env-file .env \
	-f compose.yml \
	up  --no-recreate --no-build -d
fi

# Access information: hosts derive from COMPOSE_PROJECT_NAME (.env overrides .env.default)
PROJECT_NAME=`grep '^COMPOSE_PROJECT_NAME=' "$ENV_FILE" 2>/dev/null | cut -d= -f2`
[ -z "$PROJECT_NAME" ] && PROJECT_NAME=`grep '^COMPOSE_PROJECT_NAME=' .env.default 2>/dev/null | cut -d= -f2`
[ -z "$PROJECT_NAME" ] && PROJECT_NAME="stellars-jupyterlab-ds"
LAB_PORT=`grep '^LAB_PORT=' "$ENV_FILE" 2>/dev/null | cut -d= -f2`
[ -z "$LAB_PORT" ] && LAB_PORT=`grep '^LAB_PORT=' .env.default 2>/dev/null | cut -d= -f2`
[ -z "$LAB_PORT" ] && LAB_PORT=443
ACCESS_URL="https://lab.$PROJECT_NAME.localhost"
[ "$LAB_PORT" != "443" ] && ACCESS_URL="$ACCESS_URL:$LAB_PORT"
echo
echo "JupyterLab is starting."
echo "Access URL: $ACCESS_URL"
echo "Log in with the password you set (it is not in the URL)."
echo "The password is stored in $CURRENT_DIR/$ENV_FILE (key JUPYTERLAB_SERVER_TOKEN)."
echo
printf "Press Enter to close this window..."
read dummy

# EOF
