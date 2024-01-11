#!/bin/bash

# copy template home directory to /root
# dump warnings to /dev/null
HOME_TEMPLATE=/mnt/home
cp -rf --no-preserve=mode,ownership $HOME_TEMPLATE/. /root 2>/dev/null

# and make sure /root permissions are as they should
find $HOME -type d | xargs chmod og-rwx
find $HOME -type f | xargs chmod og-rwx

# output build info and banners
BUILD_DATE=`cat /build-date.txt`
BUILD_NAME=`cat /build-name.txt`
echo "█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█" 
echo "█ Build '$BUILD_NAME' created on $BUILD_DATE    █" 
echo "█ --------------------------------------------  █" 
echo "█ Running JupyterLab on  http://localhost:8888  █"
echo "█ Running Tensorboard on http://localhost:6006  █"
echo "█ Tensorboard watching logs   /tmp/tensorboard  █"
echo "█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█"

# run tensorboard in the background
mkdir /tmp/tensorboard 2>/dev/null
tensorboard --logdir /tmp/tensorboard --port 6006 &
# run jupyterlab
jupyter-lab --ip='*' --port=8888 --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password=''
