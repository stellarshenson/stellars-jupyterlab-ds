#!/bin/bash
# ----------------------------------------------------------------------------------------
# Generates welcome message and welcome.html
# ----------------------------------------------------------------------------------------

# execute render-info.py script to display info box
BUILD_NAME=$(cat /build-name.txt)
BUILD_DATE=$(cat /build-date.txt)
conda run -n base python /render-info.py "$LAB_NAME" "$BUILD_NAME" "$BUILD_DATE" "$JUPYTERLAB_SERVER_TOKEN"

# update welcome.html with LAB_USER
# it is a bit tricky because we can only do inplace changes
cat /welcome.html | \
/usr/bin/sed "s/@LAB_USER@/${LAB_USER:-default}/g" \
/usr/bin/sed "s/@LAB_NAME@/${LAB_NAME:-stellars-jupyterlab-ds}/g" \
> /tmp/welcome.html.new

truncate /welcome.html --size 0
cat /tmp/welcome.html.new >> /welcome.html
rm /tmp/welcome.html.new


# EOF

