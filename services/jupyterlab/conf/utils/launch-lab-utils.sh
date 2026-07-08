#!/bin/bash
# Wrapper to launch lab-utils with proper terminal initialization
# This ensures the terminal has correct dimensions before running dialog-based interface

# Wait for terminal to initialize
sleep 0.5

# Get terminal size and ensure it's reasonable - bounded: a pane that stays
# under 20x80 (e.g. a narrow JupyterLab split) must get a hint, not a blank
# screen and a busy-wait forever. The hint prints ONCE (a repeating line would
# scroll a stack of duplicates); ~2s debounce - a healthy terminal reports its
# size well under a second
TRIES=0
HINTED=0
while true; do
    read rows cols < <(stty size 2>/dev/null || echo "0 0")

    # Check if we have valid dimensions (at least 20x80)
    if [ "$rows" -ge 20 ] && [ "$cols" -ge 80 ]; then
        break
    fi

    TRIES=$((TRIES + 1))
    if [ "$TRIES" -ge 10 ] && [ "$HINTED" -eq 0 ]; then
        echo "Terminal is ${cols}x${rows} - lab-utils needs at least 80x20; widen the terminal pane and it will start."
        HINTED=1
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
