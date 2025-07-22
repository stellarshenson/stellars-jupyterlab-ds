#!/bin/bash
# ----------------------------------------------------------------------------------------
# Copies useful shortcuts to user workspace
# ----------------------------------------------------------------------------------------
CONDA_USER_WORKSPACE=${CONDA_USER_WORKSPACE:-/home/lab/workspace}

echo "Copying workspace helpful shortcuts"
cp /opt/templates/workspace_shortcuts/* ${CONDA_USER_WORKSPACE}

# EOF

