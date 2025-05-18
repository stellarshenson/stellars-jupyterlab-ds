#!/bin/bash
# ----------------------------------------------------------------------------------------
# Glances Web Server Launch Script
#
# This script launches Glances in web server mode, providing real-time system
# monitoring through a browser interface. It executes Glances within the 'base'
# Conda environment.
#
# Glances is a cross-platform monitoring tool that presents CPU, memory, disk,
# network, and process information in a unified web UI.
#
# USAGE:
#   ./start_glances.sh
#
# REQUIREMENTS:
#   - Conda installed and available in PATH
#   - 'glances' installed in the 'base' Conda environment
#
# CONFIGURATION:
#   - Web server mode enabled
#   - Refresh interval set to 0.25 seconds
#   - Accessible via http://<host>:61208 by default
# ----------------------------------------------------------------------------------------

# command to execute 
COMMAND=$(cat <<EOF
echo "Launching glances resources monitoring server"
glances -w -t 0.25 
EOF
)

# execute in conda base
conda run -n base "$COMMAND" &

# EOF

