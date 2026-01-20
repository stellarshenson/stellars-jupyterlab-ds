#!/bin/bash
# ----------------------------------------------------------------------------------------
# Fish Shell Initialization
#
# Initializes fish shell for Stellars JupyterLab DS:
# - Conda initialization (if not already done)
# - Stellars powerline-style prompt (conda/venv, PWD, git branch)
# - Disables default fish greeting
# - Adds welcome message, MOTD, and gpustat (like bash.bashrc)
# - Sets up Docker MCP environment variable
# ----------------------------------------------------------------------------------------

FISH_CONFIG="${HOME}/.config/fish/config.fish"
FISH_CONFIG_DIR="${HOME}/.config/fish"
STELLARS_MARKER="# >>> stellars initialize >>>"

# Ensure fish config directory exists
mkdir -p "${FISH_CONFIG_DIR}"

# Add LD_LIBRARY_PATH at top of config.fish (before conda init) to fix libmamba solver
if [[ -f "${FISH_CONFIG}" ]]; then
    if ! grep -q "LD_LIBRARY_PATH.*conda/lib" "${FISH_CONFIG}"; then
        echo "Adding LD_LIBRARY_PATH to fish config (before conda init)..."
        # Prepend to config.fish so it runs before conda init
        { echo '# Include conda lib for libmamba solver (must be before conda init)'
          echo 'set -gx LD_LIBRARY_PATH "/opt/conda/lib:$LD_LIBRARY_PATH"'
          cat "${FISH_CONFIG}"
        } > /tmp/fish_config_tmp && mv /tmp/fish_config_tmp "${FISH_CONFIG}"
    fi
else
    # Create new config.fish with LD_LIBRARY_PATH
    echo '# Include conda lib for libmamba solver (must be before conda init)' > "${FISH_CONFIG}"
    echo 'set -gx LD_LIBRARY_PATH "/opt/conda/lib:$LD_LIBRARY_PATH"' >> "${FISH_CONFIG}"
fi

# Initialize conda for fish if not already done
if [[ -f "${FISH_CONFIG}" ]]; then
    if ! grep -q "conda initialize" "${FISH_CONFIG}"; then
        echo "Initializing fish shell with conda..."
        conda init fish
    fi
else
    echo "Initializing fish shell with conda..."
    conda init fish
fi

# Check if stellars customizations already added
if [[ -f "${FISH_CONFIG}" ]] && grep -q "${STELLARS_MARKER}" "${FISH_CONFIG}"; then
    echo "Fish shell already configured with stellars customizations"
    exit 0
fi

# Append stellars customizations to fish config
echo "Adding stellars customizations to fish config..."
cat >> "${FISH_CONFIG}" << 'FISH_CONFIG_EOF'

# >>> stellars initialize >>>
# Stellars JupyterLab DS customizations

# Load stellars prompt (powerline-style with conda/venv, PWD, git branch)
source /etc/fish/functions/fish_prompt.fish

# Disable default fish greeting
function fish_greeting
    # Empty function disables the default greeting
end

# Docker MCP gateway environment variable
set -gx DOCKER_MCP_IN_CONTAINER 1

# Fix CUDA loading for running nvidia-smi
ldconfig 2>/dev/null

# Show welcome and MOTD only for top-level shells (SHLVL <= 3)
# Note: SHLVL is 3 when JupyterLab is launched via 'conda run' (adds extra shell level)
if test "$SHLVL" -le 3
    # Display welcome message (shown once a day)
    if test -f /welcome-message.sh
        /welcome-message.sh
    end

    # Display message of the day
    if test -f /etc/motd
        cat /etc/motd
    end

    # Display gpustat if GPU support enabled
    if test "$ENABLE_GPU_SUPPORT" = 1; and test "$ENABLE_GPUSTAT" = 1
        conda run --no-capture-output -n base gpustat --no-color --no-header --no-processes
        echo
    end

    # Brief delay to prevent terminal init race conditions
    sleep 0.3
end
# <<< stellars initialize <<<
FISH_CONFIG_EOF

echo "Fish shell configured successfully"

# EOF
