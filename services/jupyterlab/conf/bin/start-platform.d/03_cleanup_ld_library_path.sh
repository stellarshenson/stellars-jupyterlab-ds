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
    local file="$1"
    if [[ -f "${file}" ]] && grep -q "LD_LIBRARY_PATH.*conda/lib" "${file}"; then
        echo "Cleaning up LD_LIBRARY_PATH from ${file}..."
        sed -i '/# Include conda lib for libmamba solver/d' "${file}"
        sed -i '/LD_LIBRARY_PATH.*conda\/lib.*export/d' "${file}"
        sed -i '/export LD_LIBRARY_PATH.*conda\/lib/d' "${file}"
        sed -i '/set -gx LD_LIBRARY_PATH.*conda\/lib/d' "${file}"
    fi
}

# Cleanup bash user configs
cleanup_file "${BASHRC}"
cleanup_file "${BASH_PROFILE}"
cleanup_file "${PROFILE}"

# Cleanup fish user config
cleanup_file "${FISH_CONFIG}"

# EOF
