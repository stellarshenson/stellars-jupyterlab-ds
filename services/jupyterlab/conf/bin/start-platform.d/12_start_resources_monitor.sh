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
#   - loopback-only on :7681 (-i lo), reachable via the authenticated jupyter proxy /rmonitor
#   - ttyd -W flag enables write mode for interactivity
# ----------------------------------------------------------------------------------------

# check if enabled
if [[ ${ENABLE_SERVICE_RESOURCES_MONITOR} != 1 ]]; then
    exit 0
fi

log_info "Launching btop resources monitor via ttyd"
# Terminal sizing inside the launcher iframe is fixed client-side: the rmonitor
# server-proxy entry (jupyter_lab_config.py) injects a script into ttyd's HTML
# that re-fits the xterm terminal after font metrics settle and on panel
# resizes. No server-side SIGWINCH wrapper is needed.
#
# -d 3 lowers libwebsockets verbosity (default 7 = ERR|WARN|NOTICE) to ERR|WARN,
# dropping the unattributed 'N:' NOTICE banner. Remaining ttyd output is piped
# through log_pipe so any line is tagged to this script instead of arriving raw.
# -i lo: loopback only - ttyd is write-enabled (a live shell); it must be
# reachable solely through the authenticated jupyter-server-proxy, never from
# the docker network (other instances, or other users' containers under a hub)
ttyd -d 3 -W -i lo -p 7681 -t titleFixed="Resources Monitor" btop --utf-force 2>&1 | log_pipe INFO &

# EOF
