#!/bin/bash
# ----------------------------------------------------------------------------------------
# Generates links to utils scripts in the Workspace
# Even if user deletes them, they will come back
# ----------------------------------------------------------------------------------------
UTILS_PATH="/opt/utils"
CONDA_USER_WORKSPACE=${CONDA_USER_WORKSPACE:-/home/lab/workspace}

echo "Copying workspace helpful scripts"
for x in `ls ${UTILS_PATH}/*.sh`; do
    ln -s $x ${CONDA_USER_WORKSPACE}/`basename $x` >/dev/null 2>&1
done

# EOF

