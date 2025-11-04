#!/bin/bash
# ----------------------------------------------------------------------------------------
# Creates user directories for custom configurations
# ----------------------------------------------------------------------------------------

echo "Ensuring user configuration directories exist"

# Create ~/.local/conda-env.d for user's custom conda environment definitions
if [[ ! -d "/home/lab/.local/conda-env.d" ]]; then
    mkdir -p /home/lab/.local/conda-env.d
    echo "Created /home/lab/.local/conda-env.d"
fi

# EOF
