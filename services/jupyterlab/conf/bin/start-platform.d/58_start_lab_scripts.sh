#!/bin/bash
# ----------------------------------------------------------------------------------------
# Run Local Scripts from user home
#
# This script runs all available scripts in user home directory as a bundle
# Output is logged to ~/.local/start-platform.out
# After completion, sends notification via jupyter-notify (waits for JupyterLab to start)
# ----------------------------------------------------------------------------------------

# check if enabled
if [[ ${ENABLE_LOCAL_SCRIPTS} != 1 ]]; then
    exit 0
fi

# run series of local start scripts as a bundle
LOCAL_SCRIPTS_DIR="${LOCAL_SCRIPTS_DIR:-${HOME}/.local/start-platform.d}"
LOCAL_SCRIPTS_LOG="${HOME}/.local/start-platform.out"

if [[ -d "${LOCAL_SCRIPTS_DIR}" ]]; then
    # collect executable files (any extension, must be executable)
    scripts=()
    for file in "${LOCAL_SCRIPTS_DIR}"/*; do
        if [[ -f "${file}" ]] && [[ -x "${file}" ]]; then
            scripts+=("${file}")
        fi
    done

    # run all scripts as a bundle if any found
    if [[ ${#scripts[@]} -gt 0 ]]; then
        echo "Executing user startup scripts from ${LOCAL_SCRIPTS_DIR}"
        echo "Log file: ${LOCAL_SCRIPTS_LOG}"
        nohup bash -c '
            # Track results
            failed_scripts=()
            succeeded_scripts=()
            total_scripts=$#

            # Run each script and track results
            for script in "$@"; do
                script_name=$(basename "$script")
                echo "=== Running: ${script} ==="
                echo "Started: $(date)"

                if "${script}"; then
                    echo "Status: SUCCESS"
                    succeeded_scripts+=("$script_name")
                else
                    exit_code=$?
                    echo "Status: FAILED (exit code: $exit_code)"
                    failed_scripts+=("$script_name")
                fi

                echo "Finished: $(date)"
                echo ""
            done

            # Summary
            echo "=========================================="
            echo "STARTUP SCRIPTS SUMMARY"
            echo "=========================================="
            echo "Total: $total_scripts"
            echo "Succeeded: ${#succeeded_scripts[@]}"
            echo "Failed: ${#failed_scripts[@]}"
            if [[ ${#failed_scripts[@]} -gt 0 ]]; then
                echo "Failed scripts: ${failed_scripts[*]}"
            fi
            echo ""

            # Wait for JupyterLab to be ready before sending notification
            echo "Waiting for JupyterLab to initialize..."
            max_wait=120  # Maximum wait time in seconds
            wait_interval=2
            elapsed=0

            while [[ $elapsed -lt $max_wait ]]; do
                # Check if any Jupyter server is running
                if jupyter server list 2>/dev/null | grep -q "http"; then
                    echo "JupyterLab is ready (waited ${elapsed}s)"
                    break
                fi
                sleep $wait_interval
                elapsed=$((elapsed + wait_interval))
            done

            # Send notification based on results
            if [[ $elapsed -ge $max_wait ]]; then
                echo "Timeout waiting for JupyterLab - skipping notification"
            elif [[ ${#failed_scripts[@]} -eq 0 ]]; then
                # All scripts succeeded
                jupyterlab-notify \
                    -m "Startup: ${#succeeded_scripts[@]} script(s) completed" \
                    -t success \
                    --auto-close 60 \
                    --action "Acknowledged"
                echo "Sent success notification"
            else
                # Some scripts failed
                jupyterlab-notify \
                    -m "Startup: ${#failed_scripts[@]}/${total_scripts} failed - check ~/.local/start-platform.out" \
                    -t warning \
                    --no-auto-close \
                    --action "Acknowledged"
                echo "Sent warning notification"
            fi

        ' _ "${scripts[@]}" > "${LOCAL_SCRIPTS_LOG}" 2>&1 &
    fi
fi

# EOF
