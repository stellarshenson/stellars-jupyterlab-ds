#!/bin/sh
CURRENT_FILE=`readlink -f $0`
CURRENT_DIR=`dirname $CURRENT_FILE`
cd $CURRENT_DIR

docker compose --env-file .env -f compose.yml down

# EOF
