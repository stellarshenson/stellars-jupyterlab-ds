#!/bin/bash

# find if running with nvidia GPU support
if [[ $GPU_SUPPORT_ENABLED == 1 ]]; then
    /usr/bin/nvidia-smi
fi

# copy template home directory to /root, dump warnings to /dev/null
HOME_TEMPLATE=/mnt/home
cp -rf --no-preserve=mode,ownership $HOME_TEMPLATE/. $HOME 2>/dev/null

# and make sure home permissions are as they should
find $HOME -type d -print "'%p'\n" | xargs chmod og-rwx
find $HOME -type f -print "'%p'\n" | xargs chmod og-rwx

# output build info and banners
BUILD_DATE=`cat /build-date.txt`
BUILD_NAME=`cat /build-name.txt`

cat /build-info.txt | sed "s/@BUILD_NAME@/$BUILD_NAME/g" | sed "s/@BUILD_DATE@/$BUILD_DATE/g" 

# run tensorboard in the background
mkdir /tmp/tensorboard 2>/dev/null
tensorboard --bind_all --logdir /tmp/tf_logs --port 6006 &

# run jupyterlab
jupyter-lab --ip='*' --no-browser --IdentityProvider.token='' --IdentityProvider.password=''

# EOF
