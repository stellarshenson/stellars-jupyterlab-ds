#!/bin/bash
# ----------------------------------------------------------------------------------------
# Run Local Scripts from user home
#
# This script runs all available scripts in user home directory
# ----------------------------------------------------------------------------------------

# check if enabled
if [[ ${ENABLE_LOCAL_SCRIPTS} != 1 ]]; then
    exit 0
fi

# run series of local start scripts
# (services will need to run in background)
LOCAL_SCRIPTS_DIR="${LOCAL_SCRIPTS_DIR:-${HOME}/.local/start-platform.d}"
if [[ -d "${LOCAL_SCRIPTS_DIR}" ]]; then
    echo "Executing user startup scripts from ${LOCAL_SCRIPTS_DIR}"
    for file in ${LOCAL_SCRIPTS_DIR}/*.sh; do
	if [ -f "${file}" ] && [ -x "${file}" ]; then
	    nohup "${file}" &
	fi
    done
fi

# EOF
