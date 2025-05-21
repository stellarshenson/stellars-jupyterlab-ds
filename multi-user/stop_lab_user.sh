#!/bin/bash
# --------------------------------------------------------------------------------------------------
#   Stellars JupyterLab DS Platform Shutdown Script
#
#   Author      : Stellars Henson                   
#   Script Name : stop_lab_user.sh
#   Description : 
#     Interactive shell script to gracefully stop and optionally clean up a deployed 
#     JupyterLab data science environment managed by Docker Compose.
#
#     Features:
#       - Uses 'dialog' interface for selection of target environment
#       - Automatically detects available .env configurations
#       - Prompts user to confirm project shutdown
#       - Offers optional volume deletion with confirmation
#       - Handles missing compose file by downloading from canonical repo if necessary
#       - Uses environment variables to identify the Docker Compose project
#
#   Prerequisites:
#       - 'dialog' CLI tool must be installed (sudo apt install dialog)
#       - Docker and Docker Compose must be installed and in the system PATH
#
#   Output:
#       - Graceful teardown of Docker services and containers
#       - Optional deletion of persistent volumes
#
#   Project Home : https://github.com/stellarshenson/stellars-jupyterlab-ds
#   License      : MIT
# --------------------------------------------------------------------------------------------------

set -e

# 1. Check if 'dialog' is available
if ! command -v dialog &>/dev/null; then
  echo "Error: 'dialog' is not installed." >&2
  exit 1
fi

# check for resources
RESOURCES_DIR="resources"
if [[ ! -d "${RESOURCES_DIR}" ]]; then
  echo "No saved environments directory '$RESOURCES_DIR' found to stop"
  exit 1
fi


# 2. Check for compose file and download if needed
clear
COMPOSE_FILE="resources/compose.yml"
REPO_BASE_URL="https://raw.githubusercontent.com/stellarshenson/stellars-jupyterlab-ds/main"
if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "Downloading $COMPOSE_FILE from $REPO_BASE_URL..."
  curl -fsSL "$REPO_BASE_URL/$COMPOSE_FILE" -o "$COMPOSE_FILE"
  if [[ $? -ne 0 ]]; then
    echo "Failed to download $COMPOSE_FILE. Aborting."
    exit 1
  fi
fi

# check if file downloaded 
if [ ! -f $COMPOSE_FILE ]; then
  dialog --msgbox "No '$COMPOSE_FILE' found." 10 50
  clear
  exit 1
fi


# 3. Locate .env files
mapfile -t ENV_FILES < <(find ./resources -maxdepth 1 -name "*.env" | sort)
if [ ${#ENV_FILES[@]} -eq 0 ]; then
  dialog --msgbox "No .env files found." 10 50
  clear
  exit 1
fi

# 4. Dialog menu to select env file
MENU_OPTS=()
for f in "${ENV_FILES[@]}"; do
  fname=$(basename "$f")
  MENU_OPTS+=("$fname" "")
done

CHOICE=$(dialog --menu "Select an env file to use:" 15 60 6 "${MENU_OPTS[@]}" 3>&1 1>&2 2>&3)
clear
ENV_FILE="resources/$CHOICE"

# 5. Extract project name and user
COMPOSE_PROJECT_NAME=$(grep -E '^COMPOSE_PROJECT_NAME=' "$ENV_FILE" | cut -d '=' -f2-)
LAB_USER=$(grep -E '^LAB_USER=' "$ENV_FILE" | cut -d '=' -f2-)
COMPOSE_PERSONAL_FILE="compose-override-${LAB_USER}.yml"
if [[ -f $COMPOSE_PERSONAL_FILE ]]; then
    COMPOSE_FILES_OPTS="-f ${COMPOSE_FILE} -f ${COMPOSE_PERSONAL_FILE}"
else
    COMPOSE_FILES_OPTS="-f ${COMPOSE_FILE}"
fi

# 6. Confirm shutdown
CONFIRM_TEXT="Shut down Compose project?\n\nCOMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME\nLAB_USER=$LAB_USER\n\nEnv File: $ENV_FILE"
dialog --yesno "$CONFIRM_TEXT" 12 60 || {
  clear
  echo "Shutdown aborted by user."
  exit 0
}
clear

# 7. Ask about volume deletion, isolate return code
VOLUME_CONFIRM=0  # default to YES
dialog --defaultno --yesno "Also remove volumes for project '$COMPOSE_PROJECT_NAME'?\nThis cannot be undone." 10 60 || {
    clear
    echo "Volumes will be retained."
    VOLUME_CONFIRM=1
}
clear

# 8. Shutdown the compose project
echo "Shutting down project '$COMPOSE_PROJECT_NAME' using env file '$ENV_FILE'..."
COMPOSE_COMMAND="docker compose --env-file "${ENV_FILE}" ${COMPOSE_FILES_OPTS} down --remove-orphans"
echo "Executing: $COMPOSE_COMMAND"
$COMPOSE_COMMAND

# 9. clean networks
echo "Removing unused networks"
yes | docker network prune 2>/dev/null

# 10. Remove volumes if confirmed
if [ "$VOLUME_CONFIRM" -eq 0 ]; then
  echo "Removing volumes associated with '$COMPOSE_PROJECT_NAME'..."
  docker volume ls --filter "label=com.docker.compose.project=$COMPOSE_PROJECT_NAME" -q | xargs -r docker volume rm
fi

# 10. Finished 
echo "Shutdown complete."

