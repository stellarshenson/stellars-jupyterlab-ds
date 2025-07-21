#!/bin/bash

TIMESTAMP_FILE="$HOME/.last_message_timestamp"

# Get the current date
CURRENT_DATE=$(date +%Y-%m-%d)

# render message differently depending if hub or standalone jl
if [[ -n ${JUPYTERHUB_USER} ]]; then
    BASE_URL=${JUPYTERHUB_SERVICE_PREFIX}
    BASE_URL=$(echo ${BASE_URL} | sed 's/\/$//g' | sed 's/^\///g' | sed 's/\//\\\//g' )
    MESSAGE=$(cat /welcome-message.txt | sed "s/@LAB_NAME@/${BASE_URL}/g")
else
    MESSAGE=$(cat /welcome-message.txt | sed "s/@LAB_NAME@/${LAB_NAME}\/jupyterlab/g")
fi

# Check if the timestamp file exists
if [ -f "$TIMESTAMP_FILE" ]; then
    LAST_DATE=$(cat "$TIMESTAMP_FILE")
else
    LAST_DATE=""
fi

# If the message hasn't been displayed today, display it and update the timestamp file
if [ "$CURRENT_DATE" != "$LAST_DATE" ]; then
    echo "$MESSAGE"
    echo "$CURRENT_DATE" > "$TIMESTAMP_FILE"
fi

#EOF
