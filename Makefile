# This makefile helps build, push and run the jupyterlab

#################################################################################
# GLOBALS                                                                       #
#################################################################################
.DEFAULT_GOAL := help
.PHONY: help build push start clean

#################################################################################
# COMMANDS                                                                      #
#################################################################################

## build docker containers
build:
	@cd ./scripts && ./build.sh

## build docker containers and output logs
build_verbose:
	@cd ./scripts && ./build_verbose.sh

## pull docker image from dockerhub
pull:
	docker pull stellars/stellars-jupyterlab-ds:latest

## push docker containers to repo
push:
	docker push stellars/stellars-jupyterlab-ds:latest

## start jupyterlab (fg)
start:
	@cd ./scripts && ./start.sh

## clean orphaned containers
clean:
	@echo 'removing dangling and unused images, containers, nets and volumes'
	@docker compose --env-file .env -f compose.yml down --remove-orphans
	@yes | docker image prune
	@yes | docker network prune


## prints the list of available commands
help:
	@echo ""
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' 


# EOF
