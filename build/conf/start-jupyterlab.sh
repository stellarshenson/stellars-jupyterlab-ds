#!/bin/bash

# copy template home directory to /root
# dump warnings to /dev/null
HOME_TEMPLATE=/mnt/home
cp -rf $HOME_TEMPLATE/. /root 2>/dev/null

# and make sure /root permissions are as they should
find $HOME -type d | xargs chmod 700
find $HOME -type f | xargs chmod 600

# allow container's git work with imported folders
# git config --global --add safe.directory '*'

# output build info
CONTAINER_BUILD=`cat /build-date.txt`
echo "*** Container Build $CONTAINER_BUILD ***" 

# run jupyterlab
jupyter-lab --ip='*' --port=8888 --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password=''
