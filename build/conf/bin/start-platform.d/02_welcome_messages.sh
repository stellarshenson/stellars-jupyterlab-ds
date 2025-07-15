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

# update welcome.html with LAB_NAME or JUPYTERHUB_SERVICE_PREFIX
# jupyterhub config
if [[ -n ${JUPYTERHUB_USER} ]]; then
    echo "updating welcome.html for jupyterhub"
    REPLACEMENT=${JUPYTERHUB_SERVICE_PREFIX:-stellars-jupyterlab-ds}
    REPLACEMENT=$(echo ${REPLACEMENT} | sed 's/\/$//g' | sed 's/\//\\\//g')
    /usr/bin/sed "s/\/@LAB_NAME@\/jupyterlab/${REPLACEMENT}/g" /welcome.html | \
    /usr/bin/sed "s/\/@LAB_NAME@/${REPLACEMENT}/g" \
    > /tmp/welcome.html.new

# standalone jupyterlab
else
    echo "updating welcome.html"
    REPLACEMENT=${LAB_NAME:-stellars-jupyterlab-ds}
    REPLACEMENT=$(echo ${REPLACEMENT} | sed 's/\/$//g' | sed 's/\//\\\//g')
    /usr/bin/sed "s/@LAB_NAME@/${REPLACEMENT}/g" /welcome.html | \
    > /tmp/welcome.html.new
fi

#truncate /welcome.html --size 0
#cat /tmp/welcome.html.new >> /welcome.html
#rm /tmp/welcome.html.new


# EOF

