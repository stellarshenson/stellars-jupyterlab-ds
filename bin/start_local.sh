#!/bin/sh 
CURRENT_FILE=`readlink -f $0`
CURRENT_DIR=`dirname $CURRENT_FILE`
cd $CURRENT_DIR

docker-compose -f ../local/docker-compose.yml up  --no-recreate --no-build $1

# EOF
