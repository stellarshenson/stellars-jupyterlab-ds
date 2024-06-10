#!/bin/sh 
CURRENT_FILE=`readlink -f $0`
CURRENT_DIR=`dirname $CURRENT_FILE`
cd $CURRENT_DIR

if [ "$1" = "-d" ]; then
    docker-compose -p stellars-jupyterlab-ds -f ../docker-compose-nvidia.yml up --no-recreate --no-build &
else
    docker-compose -p stellars-jupyterlab-ds -f ../docker-compose-nvidia.yml up --no-recreate --no-build 
fi
