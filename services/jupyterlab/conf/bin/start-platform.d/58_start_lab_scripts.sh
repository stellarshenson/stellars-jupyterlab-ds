#!/bin/bash
# ----------------------------------------------------------------------------------------
# Run Local Scripts from user home
#
# This script runs all available scripts in user home directory as a bundle
# Output is logged to ~/.local/start-platform.out
# ----------------------------------------------------------------------------------------

# check if enabled
if [[ ${ENABLE_LOCAL_SCRIPTS} != 1 ]]; then
    exit 0
fi

# run series of local start scripts as a bundle
LOCAL_SCRIPTS_DIR="${LOCAL_SCRIPTS_DIR:-${HOME}/.local/start-platform.d}"
LOCAL_SCRIPTS_LOG="${HOME}/.local/start-platform.out"

if [[ -d "${LOCAL_SCRIPTS_DIR}" ]]; then
    # collect executable scripts
    scripts=()
    for file in "${LOCAL_SCRIPTS_DIR}"/*.sh; do
        if [[ -f "${file}" ]] && [[ -x "${file}" ]]; then
            scripts+=("${file}")
        fi
    done

    # run all scripts as a bundle if any found
    if [[ ${#scripts[@]} -gt 0 ]]; then
        echo "Executing user startup scripts from ${LOCAL_SCRIPTS_DIR}"
        echo "Log file: ${LOCAL_SCRIPTS_LOG}"
        nohup bash -c '
            for script in "$@"; do
                echo "=== Running: ${script} ==="
                echo "Started: $(date)"
                "${script}"
                echo "Finished: $(date)"
                echo ""
            done
        ' _ "${scripts[@]}" > "${LOCAL_SCRIPTS_LOG}" 2>&1 &
    fi
fi

# EOF
