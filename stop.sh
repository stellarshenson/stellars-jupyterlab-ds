#!/bin/sh
CURRENT_FILE=$(readlink -f "$0")
CURRENT_DIR=$(dirname "$CURRENT_FILE")
cd "$CURRENT_DIR" || exit 1

# fail early with a clear message when docker is not up - compose errors are cryptic
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: docker is not running or not reachable - start Docker (or Docker/Rancher Desktop) and re-run." >&2
    exit 1
fi

[ -f .env ] || touch .env # compose errors on a missing env-file
docker compose --env-file .env.default --env-file .env -f compose.yml down

# EOF
