#!/bin/bash

# copy template home directory to /root
# and make sure /root permissions are as they should
HOME_TEMPLATE=/mnt/home
find $HOME_TEMPLATE -type d | xargs chmod 700
find $HOME_TEMPLATE -type f | xargs chmod 600
cp -rf $HOME_TEMPLATE/. /root

# allow container's git work with imported folders
# git config --global --add safe.directory '*'


# run jupyterlab
jupyter-lab --ip='*' --port=8888 --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password=''
