#!/bin/bash
# Wrapper to launch lab-utils with proper terminal initialization
# This ensures the terminal has correct dimensions before running dialog-based interface

# Wait for terminal to initialize
sleep 0.5

# Get terminal size and ensure it's reasonable
while true; do
    read rows cols < <(stty size 2>/dev/null || echo "0 0")

    # Check if we have valid dimensions (at least 20x80)
    if [ "$rows" -ge 20 ] && [ "$cols" -ge 80 ]; then
        break
    fi

    # Wait a bit longer for terminal to initialize
    sleep 0.2
done

# Clear screen for clean interface
clear

# Run lab-utils
lab-utils

# Pause before exit
echo ""
echo "Press Enter to close..."
read

# Inform user about manual tab closure
echo -e "\n\033[1;33m[INFO]\033[0m You will need to close this tab manually"

# Exit terminal session to prevent shell prompt
exit
