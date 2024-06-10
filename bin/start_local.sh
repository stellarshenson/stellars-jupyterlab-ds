#!/bin/sh 
CURRENT_FILE=`readlink -f $0`
CURRENT_DIR=`dirname $CURRENT_FILE`
cd $CURRENT_DIR

if [ "$1" = "-d" ]; then
    docker-compose -f ../local/docker-compose.yml up  --no-recreate --no-build &
else
    docker-compose -f ../local/docker-compose.yml up  --no-recreate --no-build 
fi

# EOF
