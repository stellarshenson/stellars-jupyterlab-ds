#!/bin/bash
# ----------------------------------------------------------------------------------------
# Generates welcome message and welcome.html
# ----------------------------------------------------------------------------------------

# execute render-info.py script to display info box
conda run -n base python /render-info.py


# update welcome.html with LAB_USER
# it is a bit tricky because we can only do inplace changes
cat /welcome.html | \
    sed "s/@LAB_USER@/${LAB_USER:-default}/g" \
    sed "s/@LAB_NAME@/${LAB_NAME:-stellars-jupyterlab-ds}/g" \
    > /tmp/welcome.html.new

truncate /welcome.html --size 0
cat /tmp/welcome.html.new >> /welcome.html
rm /tmp/welcome.html.new


# EOF

