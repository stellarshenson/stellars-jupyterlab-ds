#!/bin/bash

MESSAGE=$(cat /welcome-message.txt | sed s/@LAB_NAME@/${LAB_NAME}/g)
TIMESTAMP_FILE="$HOME/.last_message_timestamp"

# Get the current date
CURRENT_DATE=$(date +%Y-%m-%d)

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
