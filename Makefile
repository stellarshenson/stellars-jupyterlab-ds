# This makefile helps build, push and run the jupyterlab

#################################################################################
# GLOBALS                                                                       #
#################################################################################
.DEFAULT_GOAL := help
.PHONY: help preflight build build_verbose rebuild rebuild_increment_version _rebuild_impl push pull start stop clean increment_version maybe_increment_version tag

# Use bash so we can use `set -o pipefail` to propagate docker's exit code through tee (DEBUG=1)
SHELL := /bin/bash

# ── Preflight: tools, services, and files required end-to-end ──
# Covers versioning (python3 + tomllib + awk + sed), build (docker), push (git),
# start/clean (docker compose plugin + reachable daemon), and the project files
# those targets read. Run `make preflight` before build/push to catch missing
# prerequisites early; failures print OK / MISSING per item and exit 1.
PREFLIGHT_TOOLS := python3 awk sed bash docker git
PREFLIGHT_FILES := pyproject.toml compose.yml services/jupyterlab/Dockerfile.jupyterlab

# ── Project metadata extracted from pyproject.toml ──
# Parse-time extraction: the empty-string + $(error) idiom fails loud if any
# of the required tools or pyproject.toml are missing, instead of silently
# producing an empty VERSION/TAG that would show up later as a broken docker tag.
PROJECT_META := $(shell python3 -c 'import tomllib;d=tomllib.load(open("pyproject.toml","rb"));print(d["project"]["name"], d["project"]["version"], d["tool"]["stellars"]["cuda"], d["tool"]["stellars"]["jupyterlab"])' 2>/dev/null)
ifeq ($(PROJECT_META),)
$(error pyproject.toml read failed - need python3 >=3.11 with stdlib tomllib, plus a valid pyproject.toml at repo root)
endif
PROJECT_NAME    := $(word 1,$(PROJECT_META))
PROJECT_VERSION := $(word 2,$(PROJECT_META))
CUDA_VERSION    := $(word 3,$(PROJECT_META))
JL_VERSION      := $(word 4,$(PROJECT_META))
VERSION         := $(PROJECT_VERSION)_cuda-$(CUDA_VERSION)_jl-$(JL_VERSION)
TAG             := $(VERSION)

# The bundled duoptimum-lab-utils package reads its version from this file
# (setuptools dynamic version). increment_version keeps it in sync with the
# platform version so the committed package version is never stale.
LAB_UTILS_VERSION_FILE := services/jupyterlab/duoptimum-lab-utils/src/duoptimum_lab_utils/_version.txt

## verify tools, python tomllib, docker compose, docker daemon, and key project files
preflight:
	@rc=0; \
	printf "%-28s %s\n" "Tool" "Status"; \
	printf "%-28s %s\n" "----" "------"; \
	for t in $(PREFLIGHT_TOOLS); do \
		if p=$$(command -v $$t 2>/dev/null); then \
			printf "  %-26s OK   %s\n" "$$t" "$$p"; \
		else \
			printf "  %-26s MISSING\n" "$$t"; rc=1; \
		fi; \
	done; \
	if python3 -c 'import tomllib' 2>/dev/null; then \
		printf "  %-26s OK   %s\n" "python3 stdlib tomllib" "$$(python3 --version)"; \
	else \
		printf "  %-26s MISSING (need python3 >=3.11)\n" "python3 stdlib tomllib"; rc=1; \
	fi; \
	if v=$$(docker compose version --short 2>/dev/null); then \
		printf "  %-26s OK   v%s\n" "docker compose plugin" "$$v"; \
	else \
		printf "  %-26s MISSING (install docker-compose-plugin)\n" "docker compose plugin"; rc=1; \
	fi; \
	if docker info >/dev/null 2>&1; then \
		printf "  %-26s OK   reachable\n" "docker daemon"; \
	else \
		printf "  %-26s MISSING (daemon not reachable)\n" "docker daemon"; rc=1; \
	fi; \
	echo; \
	printf "%-28s %s\n" "File" "Status"; \
	printf "%-28s %s\n" "----" "------"; \
	for f in $(PREFLIGHT_FILES); do \
		if [ -f "$$f" ]; then \
			printf "  %-26s OK\n" "$$f"; \
		else \
			printf "  %-26s MISSING\n" "$$f"; rc=1; \
		fi; \
	done; \
	echo; \
	if [ $$rc -eq 0 ]; then \
		printf '%s%sPreflight passed%s - all required tools, services, and files are available.\n\n' "$(GREEN)" "$(BOLD)" "$(RESET)"; \
	else \
		printf '%s%sPreflight FAILED%s - install / start the missing items above.\n\n' "$(RED)" "$(BOLD)" "$(RESET)"; \
	fi; \
	exit $$rc

# ── Terminal colours (used for status banners; degrade to empty on `dumb` TERM) ──
CYAN  := $(shell tput setaf 6 2>/dev/null)
GREEN := $(shell tput setaf 2 2>/dev/null)
RED   := $(shell tput setaf 1 2>/dev/null)
BOLD  := $(shell tput bold   2>/dev/null)
RESET := $(shell tput sgr0   2>/dev/null)

# Reads pyproject.toml at recipe-shell time so the printed tag reflects the
# file as-of right now (post-bump if maybe_increment_version ran in this
# invocation). Shared by the build/push success banners below.
RUNTIME_TAG_PYTHON_CMD := python3 -c 'import tomllib;d=tomllib.load(open("pyproject.toml","rb"));print(d["project"]["version"]+"_cuda-"+d["tool"]["stellars"]["cuda"]+"_jl-"+d["tool"]["stellars"]["jupyterlab"])'

# Recipe-time read of the bare project version (post-bump). Passed as the
# PKG_VERSION build arg so the duoptimum-lab-utils wheel reports the platform version.
RUNTIME_VERSION_PYTHON_CMD := python3 -c 'import tomllib;print(tomllib.load(open("pyproject.toml","rb"))["project"]["version"])'

# Reusable green/bold success banners. Trailing blank line separates the
# banner from any subsequent shell output for visual breathing room.
PRINT_BUILD_SUCCESS = @V=$$($(RUNTIME_TAG_PYTHON_CMD)); printf '\n%s%sBuild successful: stellars/stellars-jupyterlab-ds:%s%s\n\n' "$(GREEN)" "$(BOLD)" "$$V" "$(RESET)"
PRINT_PUSH_SUCCESS  = @V=$$($(RUNTIME_TAG_PYTHON_CMD)); printf '\n%s%sPush successful:  stellars/stellars-jupyterlab-ds:%s (also :latest)%s\n\n' "$(GREEN)" "$(BOLD)" "$$V" "$(RESET)"

# Build options (e.g., BUILD_OPTS='--no-cache' or BUILD_OPTS='--no-version-increment')
BUILD_OPTS ?=

# Check if --no-version-increment is in BUILD_OPTS
NO_VERSION_INCREMENT := $(findstring --no-version-increment,$(BUILD_OPTS))

# Filter out --no-version-increment from opts passed to docker
DOCKER_BUILD_OPTS := $(filter-out --no-version-increment,$(BUILD_OPTS))

# Conditional version increment target
maybe_increment_version: preflight
ifeq ($(NO_VERSION_INCREMENT),)
	@$(MAKE) increment_version
else
	@printf '%s%sVersion unchanged: %s (--no-version-increment)%s\n' "$(CYAN)" "$(BOLD)" "$(PROJECT_VERSION)" "$(RESET)"
endif

# DEBUG=1 enables --progress=plain and tees full BuildKit output to logs/rebuild.log (gitignored)
DEBUG ?= 0
ifeq ($(DEBUG),1)
    REBUILD_PROGRESS := --progress=plain
    REBUILD_TEE := 2>&1 | tee logs/rebuild.log
else
    REBUILD_PROGRESS :=
    REBUILD_TEE :=
endif

#################################################################################
# COMMANDS                                                                      #
#################################################################################

## increment patch version in pyproject.toml (callers run preflight; sub-make would re-run it)
increment_version:
	@CURRENT='$(PROJECT_VERSION)'; \
	NEW=$$(echo "$$CURRENT" | awk 'BEGIN{FS=OFS="."} {$$NF += 1; print}'); \
	printf '%s%sVersion bumped: %s -> %s%s\n' "$(CYAN)" "$(BOLD)" "$$CURRENT" "$$NEW" "$(RESET)"; \
	sed -i 's/^version = "'"$$CURRENT"'"$$/version = "'"$$NEW"'"/' pyproject.toml; \
	printf '%s' "$$NEW" > $(LAB_UTILS_VERSION_FILE); \
	printf '%s%sSynced duoptimum-lab-utils version -> %s%s\n' "$(CYAN)" "$(BOLD)" "$$NEW" "$(RESET)"

## build docker containers and the windows + linux installers (BUILD_OPTS='--no-version-increment --no-cache')
build: preflight maybe_increment_version
	@export PKG_VERSION=$$($(RUNTIME_VERSION_PYTHON_CMD)); cd ./scripts && ./build.sh $(DOCKER_BUILD_OPTS)
	$(PRINT_BUILD_SUCCESS)
	@./extra/windows-installer/build.sh
	@./extra/linux-installer/build.sh

## build with verbose output (BUILD_OPTS='--no-version-increment --no-cache')
build_verbose: preflight maybe_increment_version
	@export PKG_VERSION=$$($(RUNTIME_VERSION_PYTHON_CMD)); cd ./scripts && ./build_verbose.sh $(DOCKER_BUILD_OPTS)
	$(PRINT_BUILD_SUCCESS)
	@./extra/windows-installer/build.sh
	@./extra/linux-installer/build.sh

## rebuild 'target' stage without bumping version (default; safe for dev iteration). DEBUG=1 to log
rebuild: preflight _rebuild_impl

## rebuild 'target' stage and bump patch version
rebuild_increment_version: preflight maybe_increment_version _rebuild_impl

# Internal: actual `target` stage rebuild. Reads CURRENT_VERSION at recipe time
# so a preceding maybe_increment_version bump (when invoked via
# rebuild_increment_version) is reflected in the docker tag.
_rebuild_impl:
	$(eval CURRENT_VERSION := $(shell $(RUNTIME_TAG_PYTHON_CMD)))
	$(eval CURRENT_SEMVER := $(shell $(RUNTIME_VERSION_PYTHON_CMD)))
	@echo "Rebuilding 'target' stage (version: $(CURRENT_VERSION))..."
ifeq ($(DEBUG),1)
	@mkdir -p logs
	@echo "DEBUG=1: writing full BuildKit output to logs/rebuild.log"
endif
	@set -o pipefail; docker build \
		$(REBUILD_PROGRESS) \
		--network=host \
		--platform linux/amd64 \
		--target target \
		--build-arg CACHEBUST=$$(date +%s) \
		--build-arg PKG_VERSION=$(CURRENT_SEMVER) \
		$(DOCKER_BUILD_OPTS) \
		--tag stellars/stellars-jupyterlab-ds:latest \
		-f services/jupyterlab/Dockerfile.jupyterlab \
		services/jupyterlab $(REBUILD_TEE)
	$(PRINT_BUILD_SUCCESS)

## pull docker image from dockerhub
pull: preflight
	docker pull stellars/stellars-jupyterlab-ds:latest

## push docker containers to repo
push: preflight tag
	docker push stellars/stellars-jupyterlab-ds:latest
	docker push stellars/stellars-jupyterlab-ds:$(TAG)
	$(PRINT_PUSH_SUCCESS)

tag: preflight
	@if git tag -l | grep -q "^$(TAG)$$"; then \
		echo "Git tag $(TAG) already exists, skipping tagging"; \
	else \
		echo "Creating git tag: $(TAG)"; \
		git tag $(TAG); \
	fi
	@if docker image inspect stellars/stellars-jupyterlab-ds:$(TAG) >/dev/null 2>&1; then \
		echo "Docker tag $(TAG) already exists"; \
	else \
		echo "Creating docker tag: $(TAG)"; \
		docker tag stellars/stellars-jupyterlab-ds:latest stellars/stellars-jupyterlab-ds:$(TAG); \
	fi

## start jupyterlab (fg)
start: preflight
	@./start.sh

## stop jupyterlab
stop: preflight
	@./stop.sh

## clean orphaned containers
clean: preflight
	@echo 'removing dangling and unused images, containers, nets and volumes'
	@docker compose --env-file .env -f compose.yml down --remove-orphans
	@yes | docker image prune
	@yes | docker network prune
	@echo ""

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
		-v indent=27 \
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
