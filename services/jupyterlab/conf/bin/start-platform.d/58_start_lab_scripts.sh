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
                # Check if jupyter-notify command exists and JupyterLab is responding
                if command -v jupyter-notify &>/dev/null; then
                    # Try to send a test notification (silent, auto-close 0)
                    if jupyter-notify -m "test" --auto-close 0 2>/dev/null; then
                        echo "JupyterLab is ready (waited ${elapsed}s)"
                        break
                    fi
                fi
                sleep $wait_interval
                elapsed=$((elapsed + wait_interval))
            done

            # Send notification based on results
            if [[ $elapsed -ge $max_wait ]]; then
                echo "Timeout waiting for JupyterLab - skipping notification"
            elif [[ ${#failed_scripts[@]} -eq 0 ]]; then
                # All scripts succeeded
                jupyter-notify \
                    -m "All ${total_scripts} startup script(s) completed successfully" \
                    -t success \
                    --auto-close 8000
                echo "Sent success notification"
            else
                # Some scripts failed
                jupyter-notify \
                    -m "Startup scripts: ${#failed_scripts[@]} of ${total_scripts} failed (${failed_scripts[*]})" \
                    -t warning \
                    --no-auto-close \
                    --action "View Log"
                echo "Sent warning notification"
            fi

        ' _ "${scripts[@]}" > "${LOCAL_SCRIPTS_LOG}" 2>&1 &
    fi
fi

# EOF
