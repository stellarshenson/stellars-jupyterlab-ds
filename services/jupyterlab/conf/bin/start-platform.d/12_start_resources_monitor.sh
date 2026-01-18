#!/bin/bash
# ----------------------------------------------------------------------------------------
# Resources Monitor Launch Script
#
# This script launches btop via ttyd web server, providing real-time system
# monitoring through a browser interface.
#
# btop is a modern resource monitor showing CPU, memory, disk, network, and
# process information in a beautiful terminal UI, served via ttyd web terminal.
#
# USAGE:
#   ./12_start_resources_monitor.sh
#
# REQUIREMENTS:
#   - ttyd installed (web terminal server)
#   - btop installed (resource monitor)
#
# CONFIGURATION:
#   - Accessible via http://<host>:7681 by default
#   - ttyd -W flag enables write mode for interactivity
# ----------------------------------------------------------------------------------------

# check if enabled
if [[ ${ENABLE_SERVICE_RESOURCES_MONITOR} != 1 ]]; then
    exit 0
fi

echo "Launching btop resources monitor via ttyd"
ttyd -W -p 7681 btop &

# EOF
