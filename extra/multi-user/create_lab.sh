#!/bin/bash

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
" 15 70 2> "$TMPFILE"
LAB_USER=$(<"$TMPFILE")
rm "$TMPFILE"

# Sanitize LAB_USER
LAB_USER=$(echo "$LAB_USER" | tr -cd '[:alnum:]-_')
if [[ -z "$LAB_USER" ]]; then
  echo "Invalid LAB_USER. Must contain at least one alphanumeric character."
  exit 1
fi

# ---- Step 2: Prompt JUPYTERLAB_SERVER_TOKEN ----
dialog --title "JupyterLab Server Token" --inputbox "
Set the JupyterLab server token.

This token will act as the login password.
" 10 60 2> "$TMPFILE"
JUPYTERLAB_SERVER_TOKEN=$(<"$TMPFILE")
rm "$TMPFILE"

if [[ -z "$JUPYTERLAB_SERVER_TOKEN" ]]; then
  echo "Server token cannot be empty."
  exit 1
fi

# ---- Step 3: Choose Compose Type ----
dialog --title "Select Environment Type" --menu "Choose your data science deployment platform:" 12 60 2 \
  1 "JupyterLab for CPU Platform (no GPU support)" \
  2 "JupyterLab with NVIDIA GPU Enabled" 2> "$TMPFILE"
CHOICE=$(<"$TMPFILE")
rm "$TMPFILE"

if [[ "$CHOICE" == "1" ]]; then
  COMPOSE_FILE="compose.yml"
  ENV_DESC="JupyterLab for CPU Platform"
elif [[ "$CHOICE" == "2" ]]; then
  COMPOSE_FILE="compose-gpu.yml"
  ENV_DESC="JupyterLab with NVIDIA GPU Enabled"
else
  echo "Invalid selection."
  exit 1
fi

# ---- Step 4: Download Compose File if Missing ----
REPO_BASE_URL="https://raw.githubusercontent.com/stellarshenson/stellars-jupyterlab-ds/main"

clear
if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "Downloading $COMPOSE_FILE from $REPO_BASE_URL..."
  curl -fsSL "$REPO_BASE_URL/$COMPOSE_FILE" -o "$COMPOSE_FILE"
  if [[ $? -ne 0 ]]; then
    echo "Failed to download $COMPOSE_FILE. Aborting."
    exit 1
  fi
fi

# ---- Step 5: Project Name and Summary ----
COMPOSE_PROJECT_NAME="lab-${LAB_USER}"

dialog --title "Deployment Summary" --msgbox "
Environment: $ENV_DESC
Project Name: $COMPOSE_PROJECT_NAME
LAB_USER: $LAB_USER
Server Token: $JUPYTERLAB_SERVER_TOKEN

URLs:
 - https://localhost/$COMPOSE_PROJECT_NAME/jupyterlab
 - https://localhost/$COMPOSE_PROJECT_NAME/tensorboard
 - https://localhost/$COMPOSE_PROJECT_NAME/mlflow
 - https://localhost/$COMPOSE_PROJECT_NAME/glances

Environment will be deployed using Docker Compose.
An env file named 'project.env' will be created.
" 20 70

# ---- Step 6: Confirm Deployment ----
dialog --title "Confirm Deployment" --yesno "
Shall we proceed with deployment of this environment?
" 10 60

if [[ $? -ne 0 ]]; then
  dialog --title "Aborted" --msgbox "Operation cancelled. No changes were made." 6 40
  clear
  exit 0
fi

# ---- Step 7: Create Env File ----
cat <<EOF > project.env
LAB_USER=$LAB_USER
JUPYTERLAB_SERVER_TOKEN=$JUPYTERLAB_SERVER_TOKEN
COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME
EOF

# ---- Step 8: Deploy ----
docker-compose --env-file project.env -f "$COMPOSE_FILE" up -d

# ---- Step 9: Final Message ----
dialog --title "Deployment Complete" --msgbox "
Deployment successful.

Compose Profile: $ENV_DESC
Compose File Used: $COMPOSE_FILE
Env File: project.env

Access: https://localhost/$COMPOSE_PROJECT_NAME/jupyterlab
Token: $JUPYTERLAB_SERVER_TOKEN
" 12 60

clear

