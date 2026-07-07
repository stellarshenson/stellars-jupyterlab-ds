#!/bin/sh
CURRENT_FILE=$(readlink -f "$0")
CURRENT_DIR=$(dirname "$CURRENT_FILE")
cd "$CURRENT_DIR" || exit 1

[ -f .env ] || touch .env # compose errors on a missing env-file
docker compose --env-file .env.default --env-file .env -f compose.yml down

# EOF
