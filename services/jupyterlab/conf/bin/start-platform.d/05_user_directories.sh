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

# Create symlink to README.md if it doesn't exist
if [[ ! -e "/home/lab/.local/conda-env.d/README.md" ]]; then
    ln -s /opt/utils/conda-env.d/README.md /home/lab/.local/conda-env.d/README.md
    echo "Created symlink to conda-env.d README.md"
fi

# EOF
