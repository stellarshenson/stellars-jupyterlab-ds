#!/bin/bash

set -e

# --- Ensure dialog is available ---
if ! command -v dialog &>/dev/null; then
  echo "Error: 'dialog' is not installed. Please install it to continue." >&2
  exit 1
fi

# --- Ensure compose.yml is present ---
if [ ! -f "compose.yml" ] && [ ! -f "docker-compose.yml" ]; then
  dialog --msgbox "No compose.yml or docker-compose.yml found in this directory." 10 50
  clear
  exit 1
fi

COMPOSE_FILE="compose.yml"
[ -f "docker-compose.yml" ] && COMPOSE_FILE="docker-compose.yml"

# --- Find .env files ---
mapfile -t ENV_FILES < <(find . -maxdepth 1 -name "*.env" | sort)
if [ ${#ENV_FILES[@]} -eq 0 ]; then
  dialog --msgbox "No .env files found in this directory." 10 50
  clear
  exit 1
fi

# --- Prepare dialog menu options (use filenames as both tag and item) ---
MENU_OPTS=()
for f in "${ENV_FILES[@]}"; do
  fname=$(basename "$f")
  MENU_OPTS+=("$fname" "")
done

# --- Show dialog menu to select env file ---
CHOICE=$(dialog --menu "Select an env file to use for shutdown:" 15 60 6 "${MENU_OPTS[@]}" 3>&1 1>&2 2>&3)

clear
ENV_FILE="./$CHOICE"

# --- Read project name and lab user ---
COMPOSE_PROJECT_NAME=$(grep -E '^COMPOSE_PROJECT_NAME=' "$ENV_FILE" | cut -d '=' -f2-)
LAB_USER=$(grep -E '^LAB_USER=' "$ENV_FILE" | cut -d '=' -f2-)

# --- Confirm action ---
CONFIRM_TEXT="Shut down Compose project?\n\nCOMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME\nLAB_USER=$LAB_USER\n\nEnv File: $ENV_FILE"
dialog --yesno "$CONFIRM_TEXT" 12 60
RESPONSE=$?

clear
if [ "$RESPONSE" -eq 0 ]; then
  echo "Shutting down project '$COMPOSE_PROJECT_NAME' using env file '$ENV_FILE'..."
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" down --remove-orphans
  echo "Shutdown complete."
else
  echo "Aborted by user."
fi

