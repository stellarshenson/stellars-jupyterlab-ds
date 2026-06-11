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

# Set the terminal tab title (OSC 0 = icon + window title) so the JupyterLab
# terminal tab reads "⚙  Lab Utils" instead of the default shell path
printf '\033]0;\xe2\x9a\x99  Lab Utils\007'

# Run lab-utils (YAML-driven menu system)
lab-utils
