#!/bin/bash
# ----------------------------------------------------------------------------------------
# Cleanup LD_LIBRARY_PATH Pollution
#
# Removes old LD_LIBRARY_PATH settings that were added in earlier versions
# to fix libmamba solver (libxml2.so.16) but caused system tools like curl to break.
#
# This cleanup runs on startup to fix existing user configs.
# ----------------------------------------------------------------------------------------

BASHRC="${HOME}/.bashrc"
BASH_PROFILE="${HOME}/.bash_profile"
PROFILE="${HOME}/.profile"
FISH_CONFIG="${HOME}/.config/fish/config.fish"

cleanup_file() {
    # only the line pair the old platform version wrote (marker comment + the
    # assignment directly under it) is removed - a user's OWN LD_LIBRARY_PATH
    # lines mentioning conda/lib must survive every boot
    local file="$1"
    if [[ -f "${file}" ]] && grep -q '# Include conda lib for libmamba solver' "${file}"; then
        log_info "Cleaning up legacy libmamba LD_LIBRARY_PATH lines from ${file}"
        sed -i '/# Include conda lib for libmamba solver/{N;/LD_LIBRARY_PATH/d}' "${file}"
        sed -i '/# Include conda lib for libmamba solver/d' "${file}" # marker without assignment underneath
    fi
}

# Cleanup bash user configs
cleanup_file "${BASHRC}"
cleanup_file "${BASH_PROFILE}"
cleanup_file "${PROFILE}"

# Cleanup fish user config
cleanup_file "${FISH_CONFIG}"

# EOF
