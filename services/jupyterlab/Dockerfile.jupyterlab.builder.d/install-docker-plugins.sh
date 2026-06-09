#!/usr/bin/env bash
# Install all bundled Docker CLI plugins from upstream GitHub release binaries.
#
# Usage:
#   install-docker-plugins.sh <BUILD_DIR> <EXPORT_DIR>
#
# Args:
#   BUILD_DIR    working directory for downloads
#   EXPORT_DIR   output directory; binaries land in $EXPORT_DIR/docker-cli-plugins/
#
# To add or update a plugin, edit the PLUGINS list below.
# Format: "name|download-url|kind"
#   kind: "raw"             -> downloaded file is the binary itself
#         "tarball:<inner>" -> tarball; extract and pick file named <inner>
#
# Versions are pinned for reproducibility. Bump by replacing the URL.
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
    "mcp|https://github.com/docker/mcp-gateway/releases/download/v0.41.0/docker-mcp-linux-amd64.tar.gz|tarball:docker-mcp"
    "buildx|https://github.com/docker/buildx/releases/download/v0.33.0/buildx-v0.33.0.linux-amd64|raw"
    "compose|https://github.com/docker/compose/releases/download/v5.1.3/docker-compose-linux-x86_64|raw"
)

mkdir -p "${OUT_DIR}"

for entry in "${PLUGINS[@]}"; do
    IFS='|' read -r name url kind <<< "${entry}"
    output="${OUT_DIR}/docker-${name}"
    workdir="${BUILD_DIR}/docker-plugin-${name}"
    mkdir -p "${workdir}"

    echo "downloading docker-${name} from ${url}"
    case "${kind}" in
        raw)
            curl -sSL --fail -o "${output}" "${url}"
            chmod 755 "${output}"
            ;;
        tarball:*)
            inner="${kind#tarball:}"
            archive="${workdir}/$(basename "${url}")"
            curl -sSL --fail -o "${archive}" "${url}"
            tar -xzf "${archive}" -C "${workdir}"
            mv "${workdir}/${inner}" "${output}"
            chmod 755 "${output}"
            ;;
        *)
            echo "unknown kind: ${kind}" >&2
            exit 1
            ;;
    esac

    echo "installed ${output}"
done
