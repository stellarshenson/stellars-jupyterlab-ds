# This makefile helps build, push and run the jupyterlab

#################################################################################
# GLOBALS                                                                       #
#################################################################################
.DEFAULT_GOAL := help
.PHONY: help build push start start_nvidia clean

#################################################################################
# COMMANDS                                                                      #
#################################################################################

## build docker containers
build:
	@cd ./bin && ./build.sh

## push docker containers to repo
push:
	docker push stellars/stellars-jupyterlab-ds:latest

## start jupyterlab (fg)
start:
	@cd ./bin && ./start.sh

## start jupyterlab with nvidia support (fg)
start_nvidia:
	@cd ./bin && ./start_nvidia.sh

## clean orphaned containers
clean:
	docker-compose -f  docker-compose-nvidia.yml -f  docker-compose.yml down --remove-orphans

help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
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
