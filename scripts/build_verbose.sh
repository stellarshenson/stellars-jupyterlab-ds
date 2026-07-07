#!/bin/sh
export DOCKER_DEFAULT_PLATFORM=linux/amd64
export COMPOSE_BAKE=false
[ -f ../.env ] || touch ../.env # compose errors on a missing env-file
docker compose --env-file ../.env.default --env-file ../.env -f ../compose.yml build --progress=plain "$@"
