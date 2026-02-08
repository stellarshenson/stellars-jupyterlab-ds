#!/bin/bash
# ----------------------------------------------------------------------------------------
# Run auxiliary startup scripts from external path
#
# Executes scripts from JUPYTERLAB_AUX_SCRIPTS_PATH (e.g. /mnt/shared/start-platform.d)
# Admins can place scripts on a shared volume accessible to all containers
# Runs in foreground - blocks until all scripts complete
# Use for campaign-specific setup: AWS keys, repo credentials, hackathon config, etc.
# ----------------------------------------------------------------------------------------

# check if path is set
if [[ -z "${JUPYTERLAB_AUX_SCRIPTS_PATH}" ]]; then
    exit 0
fi

# silently skip if path doesn't exist (e.g. shared volume not mounted)
if [[ ! -d "${JUPYTERLAB_AUX_SCRIPTS_PATH}" ]]; then
    exit 0
fi

# collect executable scripts
scripts=()
for file in "${JUPYTERLAB_AUX_SCRIPTS_PATH}"/*; do
    if [[ -f "${file}" ]] && [[ -x "${file}" ]]; then
        scripts+=("${file}")
    fi
done

if [[ ${#scripts[@]} -eq 0 ]]; then
    echo "No executable scripts in ${JUPYTERLAB_AUX_SCRIPTS_PATH}"
    exit 0
fi

echo "Running ${#scripts[@]} auxiliary script(s) from ${JUPYTERLAB_AUX_SCRIPTS_PATH}"

failed=0
for script in "${scripts[@]}"; do
    script_name=$(basename "$script")
    echo "  running: ${script_name}"
    if ! bash "${script}"; then
        echo "  FAILED: ${script_name} (exit code: $?)"
        failed=$((failed + 1))
    fi
done

if [[ $failed -gt 0 ]]; then
    echo "Auxiliary scripts: ${failed}/${#scripts[@]} failed"
else
    echo "Auxiliary scripts: all ${#scripts[@]} completed"
fi

# EOF
