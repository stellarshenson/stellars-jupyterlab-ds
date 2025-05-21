#!/bin/bash
# --------------------------------------------------------------------------------------------------
#   Stellars JupyterLab DS Platform Deployment Script
#
#   Author      : Stellars Henson                   
#   Script Name : start_lab_user.sh
#   Description : 
#     Interactive shell script to deploy a personalized JupyterLab data science environment
#     using Docker Compose. Supports both GPU and non-GPU configurations. 
#
#     Features:
#       - Prompts for LAB_USER and authentication token
#       - Auto-generates a unique environment with dedicated URLs
#       - Allows selection between CPU-only and GPU-enabled compose setups
#       - Auto-fetches missing compose files from remote repository
#       - Configures override for external traefik network if traefik is active
#       - Outputs deployment summary and confirms execution
#       - Generates environment-specific `.env` file
#       - Launches containers with Docker Compose and profiles
#
#   Prerequisites:
#       - 'dialog' CLI tool must be installed (sudo apt install dialog)
#       - Docker and Docker Compose must be installed and available in PATH
#
#   Output:
#       - Deployment summary with service URLs
#       - Environment file for future reference
#
#   Project Home : https://github.com/stellarshenson/stellars-jupyterlab-ds
#   License      : MIT
# --------------------------------------------------------------------------------------------------

# Generare override file for traefik, watchtower and network
cat << EOF > compose-override.yml
# --------------------------------------------------------------------------------------------------
#
#   Stellars Jupyterlab DS Platform 
#   Project Home: https://github.com/stellarshenson/stellars-jupyterlab-ds
#   This compose disables traefik, watchtower and makes proxy network 'external'
#
# --------------------------------------------------------------------------------------------------

services:

  ## disable traefik using profiles
  traefik:
    profiles: [disabled]

  ## disable watchtower using profiles
  watchtower:
    profiles: [disabled]

networks:
  ## mark proxy-network as external
  proxy-network:
    name: traefik-network
    driver: bridge
    external: true

# EOF
EOF

# Check for dialog
if ! command -v dialog &> /dev/null; then
  echo "dialog command not found. Install it with: sudo apt install dialog"
  exit 1
fi

TMPFILE=$(mktemp)

# ---- Step 1: Prompt LAB_USER ----
dialog --title "JupyterLab Environment Setup" --inputbox "
Enter the LAB_USER name.

This name will:
- Uniquely identify the user.
- Be used in service URLs (e.g., /<LAB_USER>/jupyterlab).
- Isolate each user's data science environment.
- Be stripped of spaces and special characters.

Each user gets their own dedicated environment and a private URL.
" 15 80 2> "$TMPFILE"
LAB_USER=$(<"$TMPFILE")
rm "$TMPFILE"

# Sanitize LAB_USER
LAB_USER=$(echo "$LAB_USER" | sed 's/\./-/g' | tr -cd '[:alnum:]-_')
if [[ -z "$LAB_USER" ]]; then
  echo "Invalid LAB_USER. Must contain at least one alphanumeric character."
  exit 1
fi

# Generate Personal override compose file
COMPOSE_PERSONAL_FILE="compose-${LAB_USER}-override.yml"
[[ -f $COMPOSE_PERSONAL_FILE ]] || cat << EOF > $COMPOSE_PERSONAL_FILE
# --------------------------------------------------------------------------------------------------
#
#   Stellars Jupyterlab DS Platform 
#   Project Home: https://github.com/stellarshenson/stellars-jupyterlab-ds
#   This compose adds user specific configurable overrides  like extra services, volumes etc
#
# --------------------------------------------------------------------------------------------------

# EOF
EOF

# ---- Step 2: Prompt JUPYTERLAB_SERVER_TOKEN ----
dialog --title "JupyterLab Server Token" --inputbox "
Set the JupyterLab server token.

This token will act as the login password.
" 10 80 2> "$TMPFILE"
JUPYTERLAB_SERVER_TOKEN=$(<"$TMPFILE")
rm "$TMPFILE"

if [[ -z "$JUPYTERLAB_SERVER_TOKEN" ]]; then
  echo "Server token cannot be empty."
  exit 1
fi

# ---- Step 3: Choose Compose Type ----
dialog --title "Select Environment Type" --menu "Choose your data science deployment platform:" 12 60 2 \
  1 "Platform for non-GPU systems" \
  2 "Platform for NVIDIA GPU systems" 2> "$TMPFILE"
CHOICE=$(<"$TMPFILE")
rm "$TMPFILE"

if [[ "$CHOICE" == "1" ]]; then
  COMPOSE_FILES_OPTS="-f compose.yml"
  ENV_DESC="Platform non-GPU systems"
elif [[ "$CHOICE" == "2" ]]; then
  COMPOSE_FILES_OPTS="-f compose.yml -f compose-gpu.yml"
  ENV_DESC="Platform for NVIDIA GPU systems"
else
  echo "Invalid selection."
  exit 1
fi

# ---- Step 4: Download Compose File if Missing ----
REPO_BASE_URL="https://raw.githubusercontent.com/stellarshenson/stellars-jupyterlab-ds/main"

clear
COMPOSE_FILES=$(echo $COMPOSE_FILES_OPTS | sed 's/-f//g')
for COMPOSE_FILE in $COMPOSE_FILES; do
    if [[ ! -f "$COMPOSE_FILE" ]]; then
      echo "Downloading $COMPOSE_FILE from $REPO_BASE_URL..."
      curl -fsSL "$REPO_BASE_URL/$COMPOSE_FILE" -o "$COMPOSE_FILE"
      if [[ $? -ne 0 ]]; then
	echo "Failed to download $COMPOSE_FILE. Aborting."
	exit 1
      fi
    fi
done

# ---- Step 5: Project Name and Summary ----
COMPOSE_PROJECT_NAME="lab-${LAB_USER}"
ENV_FILE="${COMPOSE_PROJECT_NAME}.env"

# check if traefik is running
docker ps --filter ancestor=traefik --format '{{.ID}}' | grep -q .
TRAEFIK_RUNNING=$((! $?))

dialog --title "Deployment Summary" --msgbox "
Environment: $ENV_DESC
Project Name: $COMPOSE_PROJECT_NAME
Server Token: $JUPYTERLAB_SERVER_TOKEN

URLs:
 - https://localhost/$COMPOSE_PROJECT_NAME/jupyterlab
 - https://localhost/$COMPOSE_PROJECT_NAME/tensorboard
 - https://localhost/$COMPOSE_PROJECT_NAME/mlflow
 - https://localhost/$COMPOSE_PROJECT_NAME/glances

Environment will be deployed using Docker Compose.
An env file named '$ENV_FILE' will be created.
" 20 80

# ---- Step 6: Confirm Deployment ----
dialog --title "Confirm Deployment" --yesno "
Shall we proceed with deployment of this environment?
" 10 80

if [[ $? -ne 0 ]]; then
  dialog --title "Aborted" --msgbox "Operation cancelled. No changes were made." 6 40
  clear
  exit 0
fi

# ---- Step 7: Create Env File ----
cat <<EOF > $ENV_FILE
LAB_USER=$LAB_USER
JUPYTERLAB_SERVER_TOKEN=$JUPYTERLAB_SERVER_TOKEN
COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME
EOF

# ---- Step 8: Deploy ----
clear
if [[ $TRAEFIK_RUNNING == 1 ]]; then
    COMPOSE_FILES_OPTS="${COMPOSE_FILES_OPTS} -f compose-override.yml"
fi
if [[ -f $COMPOSE_PERSONAL_FILE ]]; then
    COMPOSE_FILES_OPTS="${COMPOSE_FILES_OPTS} -f ${COMPOSE_PERSONAL_FILE}"
fi

COMPOSE_COMMAND="docker-compose --env-file $ENV_FILE $COMPOSE_FILES_OPTS up  --no-recreate --no-build -d"
echo "Executing command: $COMPOSE_COMMAND"
$COMPOSE_COMMAND
echo "Press ENTER to continue..."
read

# ---- Step 9: Final Message ----
dialog --title "Deployment Complete" --msgbox "
Deployment successful.

Compose Profile: $ENV_DESC
Env File: $ENV_FILE

Access: https://localhost/$COMPOSE_PROJECT_NAME/jupyterlab
Token: $JUPYTERLAB_SERVER_TOKEN
" 12 80

clear

