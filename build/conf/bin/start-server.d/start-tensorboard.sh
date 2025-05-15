#!/bin/bash
# ----------------------------------------------------------------------------------------
# TensorBoard Launch Script
#
# This script initializes a TensorBoard instance using a specified or default log directory.
# It executes TensorBoard within a Conda environment named 'tensorflow'.
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
#   - A Conda environment named 'tensorflow' with TensorBoard installed
#
# BEHAVIOR:
#   - Creates the log directory if it does not exist
#   - Runs TensorBoard bound to all interfaces on port 6006
# ----------------------------------------------------------------------------------------


# key variables
TENSORBOARD_LOGDIR=${TENSORBOARD_LOGDIR:-/tmp/tensorboard}

# command to execute
COMMAND=$(cat <<EOF
mkdir -p $TENSORBOARD_LOGDIR 2>/dev/null
tensorboard --bind_all --logdir $TENSORBOARD_LOGDIR --port 6006
EOF
)

# use conda to execute command
conda run -n tensorflow "$COMMAND"

# EOF
