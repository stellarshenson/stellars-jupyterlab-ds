#!/bin/bash
# ----------------------------------------------------------------------------------------
# Copies useful shortcuts to user workspace
# ----------------------------------------------------------------------------------------
CONDA_USER_WORKSPACE=${CONDA_USER_WORKSPACE:-/home/lab/workspace}

echo "Creating useful shortcuts in the workspace"
ln -s /mnt/shared /home/lab/workspace/@shared 2>&1 >/dev/null
ln -s /home/lab/.cache /home/lab/workspace/@cache 2>&1 >/dev/null

# EOF

