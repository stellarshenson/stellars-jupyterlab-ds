#!/usr/bin/env bash
# Build all bundled Docker CLI plugins from upstream Go source as static binaries.
#
# Usage:
#   build-docker-plugins.sh <BUILD_DIR> <EXPORT_DIR>
#
# Args:
#   BUILD_DIR    working directory for git clones (e.g. /opt/build)
#   EXPORT_DIR   output directory; binaries land in $EXPORT_DIR/docker-cli-plugins/
#
# To add or remove a plugin, edit the PLUGINS list below.
# Format: "name|repo-url|entrypoint|extra-ldflags"
#
# Builder-stage only. Not present in the runtime image.

set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "usage: $0 <BUILD_DIR> <EXPORT_DIR>" >&2
    exit 2
fi

BUILD_DIR="$1"
EXPORT_DIR="$2"
OUT_DIR="${EXPORT_DIR}/docker-cli-plugins"

PLUGINS=(
    "mcp|https://github.com/docker/mcp-gateway.git|./cmd/docker-mcp|"
    "buildx|https://github.com/docker/buildx.git|./cmd/buildx|"
)

mkdir -p "${OUT_DIR}"

for entry in "${PLUGINS[@]}"; do
    IFS='|' read -r name repo entrypoint extra_ldflags <<< "${entry}"
    repo_dir="${BUILD_DIR}/$(basename "${repo}" .git)"
    output="${OUT_DIR}/docker-${name}"
    ldflags="-s -w${extra_ldflags:+ ${extra_ldflags}}"

    echo "cloning ${repo} -> ${repo_dir}"
    git clone "${repo}" "${repo_dir}"

    echo "building docker-${name} from ${entrypoint}"
    (
        cd "${repo_dir}"
        CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
            go build -trimpath -ldflags "${ldflags}" -o "${output}" "${entrypoint}"
    )

    echo "built ${output}"
done
