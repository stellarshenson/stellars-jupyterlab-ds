#!/usr/bin/env bash
# Build llama-cpp-python wheel with CUDA support.
#
# Usage:
#   build-llama-cpp-python.sh <BUILD_DIR> <EXPORT_DIR>
#
# Args:
#   BUILD_DIR    working directory for the pip wheel build
#   EXPORT_DIR   output directory; wheel(s) copied to $EXPORT_DIR/llama*.whl
#
# Additional permissible CMAKE_ARGS for tuning:
#   -DGGML_CUDA_FORCE_CUBLAS=on
#   -DGGML_CUDA_FORCE_MMQ=on
#
# Builder-stage only. Not present in the runtime image.

set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "usage: $0 <BUILD_DIR> <EXPORT_DIR>" >&2
    exit 2
fi

BUILD_DIR="$1"
EXPORT_DIR="$2"

cd "${BUILD_DIR}"

echo "building llama-cpp-python wheel with CUDA support"
CMAKE_ARGS="-DGGML_CUDA=on -DCUDA_ARCHITECTURES=all-major" FORCE_CMAKE=1 \
    pip wheel llama-cpp-python --no-cache-dir

echo "exporting wheel to ${EXPORT_DIR}"
cp llama*.whl "${EXPORT_DIR}"
