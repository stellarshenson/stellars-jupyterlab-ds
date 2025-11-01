#!/bin/bash
# ----------------------------------------------------------------------------------------
# Generates links to utils scripts in the Workspace
# Even if user deletes them, they will come back
# ----------------------------------------------------------------------------------------
UTILS_PATH="/opt/utils"
CONDA_USER_WORKSPACE=${CONDA_USER_WORKSPACE:-/home/lab/workspace}

echo "Adding useful scripts to the user workspace"
for x in ${UTILS_PATH}/*; do
    # Skip directories and README.md files
    if [ -f "$x" ] && [ "$(basename "$x")" != "README.md" ]; then
        ln -s "$x" "${CONDA_USER_WORKSPACE}/$(basename "$x")" >/dev/null 2>&1
    fi
done

# EOF

