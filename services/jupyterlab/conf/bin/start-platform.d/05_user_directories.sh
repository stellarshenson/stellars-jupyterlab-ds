#!/bin/bash
# ----------------------------------------------------------------------------------------
# Creates user directories for custom configurations
# ----------------------------------------------------------------------------------------

log_info "Ensuring user configuration directories exist"

# Create ~/.local/conda-env.d for user's custom conda environment definitions
if [[ ! -d "${HOME}/.local/conda-env.d" ]]; then
    mkdir -p ${HOME}/.local/conda-env.d
    log_info "Created ${HOME}/.local/conda-env.d"
fi

# Create symlink to README.md if it doesn't exist
if [[ ! -e "${HOME}/.local/conda-env.d/README.md" ]]; then
    ln -s /opt/utils/conda-env.d/README.md "${HOME}/.local/conda-env.d/README.md"
    log_info "Created symlink to conda-env.d README.md"
fi

# Ensure ~/.profile sources the user environment store (~/.local/environment.env,
# managed by lab-utils > Settings > Environment Variables) for LOGIN SHELLS. The platform
# start reads the store directly (start-platform.sh) - this wiring only gives
# terminals instant values. Fresh homes get it from the template .profile; this
# migrates homes initialised before the store existed. Deliberately hands-off
# when the user already wired environment.env themselves.
# NOTE: the heredoc below mirrors templates/home/.profile - keep the two in sync.
if [[ -f "${HOME}/.profile" ]] && ! grep -qs 'environment\.env' "${HOME}/.profile"; then
    log_info "Wiring ~/.local/environment.env into ~/.profile (shell-only wiring)"
    cat >> "${HOME}/.profile" <<'PROFILE_EOF'

# user environment variables (lab-utils > Settings > Environment Variables) - shells read the
# central store here at login; the platform start sources the SAME file directly
# (start-platform.sh), so this block is shell-only wiring
if [ -f "$HOME/.local/environment.env" ]; then
    set -a
    . "$HOME/.local/environment.env"
    set +a
fi
PROFILE_EOF
fi

# EOF
