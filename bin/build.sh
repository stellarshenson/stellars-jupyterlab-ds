#!/bin/sh 
export DOCKER_DEFAULT_PLATFORM=linux/amd64
export COMPOSE_BAKE=true
docker-compose -f ../compose.yml build 
