#!/bin/sh 
CURRENT_FILE=`readlink -f $0`
CURRENT_DIR=`dirname $CURRENT_FILE`
cd $CURRENT_DIR

docker-compose -p stellars-jupyterlab-ds -f ../docker-compose-nvidia.yml up --no-recreate --no-build $1

# EOF
