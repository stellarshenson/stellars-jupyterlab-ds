#!/bin/bash
# Wrapper to launch lab-utils with proper terminal initialization
# This ensures the terminal has correct dimensions before running dialog-based interface
#
# Environment variables:
#   LAB_UTILS_MODE - Set to "yaml" to use YAML-driven menu system (default: legacy)

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

# Select menu system based on mode
if [[ "${LAB_UTILS_MODE}" == "yaml" ]]; then
    # Run YAML-driven menu system
    lab-utils-yaml
else
    # Run legacy bash-based menu system
    lab-utils
fi

# Pause before exit with info about manual tab closure
echo ""
echo "Press Enter to close..."
echo -e "\033[1;35mYou will need to close this tab manually\033[0m"
read

# Exit terminal session to prevent shell prompt
exit
