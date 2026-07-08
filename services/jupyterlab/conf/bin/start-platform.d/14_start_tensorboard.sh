#!/bin/bash
# ----------------------------------------------------------------------------------------
# TensorBoard Launch Script
#
# This script initializes a TensorBoard instance using a specified or default log directory.
# It executes TensorBoard within a Conda environment named 'base'.
#
# USAGE:
#   ./start_tensorboard.sh
#
# ENVIRONMENT VARIABLES:
#   TENSORBOARD_LOGDIR - Optional. Path to the log directory for TensorBoard.
#                        Defaults to /tmp/tensorboard if not set.
#
# REQUIREMENTS:
#   - Conda must be installed and available in PATH
#   - A Conda environment named 'base' with TensorBoard installed
#
# BEHAVIOR:
#   - Creates the log directory if it does not exist
#   - Runs TensorBoard on loopback port 6006 (reachable via the authenticated jupyter proxy)
# ----------------------------------------------------------------------------------------

# check if enabled
if [[ ${ENABLE_SERVICE_TENSORBOARD} != 1 ]]; then
    exit 0
fi

# key variables
TENSORBOARD_LOGDIR=${TENSORBOARD_LOGDIR:-/tmp/tensorboard}
TENSORBOARD_PORT=${TENSORBOARD_PORT:-6006}

# command to execute
COMMAND=$(cat <<EOF
echo "Launching tensorflow training monitoring and logging server on port $TENSORBOARD_PORT"
mkdir -p $TENSORBOARD_LOGDIR 2>/dev/null
tensorboard --host 127.0.0.1 --logdir $TENSORBOARD_LOGDIR --port $TENSORBOARD_PORT
EOF
)

# ensure log file exists
touch /var/log/tensorboard.log 2>/dev/null || true

# use conda to execute command (same launch shape as mlflow: explicit bash -c,
# unbuffered output, dedicated log file instead of vanishing into conda run's capture);
# announce in the platform log like the other service hooks
log_info "Starting TensorBoard on 127.0.0.1:${TENSORBOARD_PORT}"
conda run -n base --no-capture-output bash -c "$COMMAND" >> /var/log/tensorboard.log 2>&1 &

# EOF
