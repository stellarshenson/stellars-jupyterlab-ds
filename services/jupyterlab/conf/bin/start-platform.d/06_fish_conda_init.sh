#!/bin/bash
# ----------------------------------------------------------------------------------------
# Fish Shell Conda Initialization
#
# Checks if fish shell has been properly initialized with conda.
# If ~/.config/fish/config.fish doesn't contain conda initialization, runs `conda init fish`.
# ----------------------------------------------------------------------------------------

FISH_CONFIG="${HOME}/.config/fish/config.fish"

# Check if fish config exists and contains conda initialization
if [[ -f "${FISH_CONFIG}" ]]; then
    if grep -q "conda" "${FISH_CONFIG}"; then
        echo "Fish shell already initialized with conda"
        exit 0
    fi
fi

# Initialize fish with conda
echo "Initializing fish shell with conda..."
conda init fish

# EOF
