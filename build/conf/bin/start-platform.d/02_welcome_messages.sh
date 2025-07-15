#!/bin/bash
# ----------------------------------------------------------------------------------------
# Generates welcome message and welcome.html
# ----------------------------------------------------------------------------------------

# execute render-info.py script to display info box
BUILD_NAME=$(cat /build-name.txt)
BUILD_DATE=$(cat /build-date.txt)
conda run -n base python /render-info.py "$LAB_NAME" "$BUILD_NAME" "$BUILD_DATE" "$JUPYTERLAB_SERVER_TOKEN"

# update welcome.html with LAB_NAME or JUPYTERHUB_SERVICE_PREFIX
# jupyterhub config
if [[ -n ${JUPYTERHUB_USER} ]]; then
    /usr/bin/sed "s/@LAB_NAME@\/jupyterlab/${JUPYTERHUB_SERVICE_PREFIX:-stellars-jupyterlab-ds}/g" /welcome.html | \
    > /tmp/welcome.html.new

# standalone jupyterlab
else
    /usr/bin/sed "s/@LAB_NAME@/${LAB_NAME:-stellars-jupyterlab-ds}/g" /welcome.html | \
    > /tmp/welcome.html.new
fi

truncate /welcome.html --size 0
cat /tmp/welcome.html.new >> /welcome.html
rm /tmp/welcome.html.new


# EOF

