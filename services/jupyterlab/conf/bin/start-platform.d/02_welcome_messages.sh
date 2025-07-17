#!/bin/bash
# ----------------------------------------------------------------------------------------
# Generates welcome message and welcome.html
# ----------------------------------------------------------------------------------------

# execute render-info.py script to display info box
BUILD_NAME=$(cat /build-name.txt)
BUILD_DATE=$(cat /build-date.txt)

if [[ -n ${JUPYTERHUB_USER} ]]; then
    BASE_URL=${JUPYTERHUB_SERVICE_PREFIX}
    BASE_URL=$(echo ${BASE_URL} | sed 's/\/$//g' | sed 's/^\///g')
    conda run -n base python /render-info.py "${BASE_URL}" "$BUILD_NAME" "$BUILD_DATE" "$JUPYTERLAB_SERVER_TOKEN"
else
    conda run -n base python /render-info.py "$LAB_NAME/jupyterlab" "$BUILD_NAME" "$BUILD_DATE" "$JUPYTERLAB_SERVER_TOKEN"
fi


# EOF

