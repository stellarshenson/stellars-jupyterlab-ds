#!/bin/sh 
export DOCKER_DEFAULT_PLATFORM=linux/amd64
export COMPOSE_BAKE=false
docker compose -f ../compose.yml build 
