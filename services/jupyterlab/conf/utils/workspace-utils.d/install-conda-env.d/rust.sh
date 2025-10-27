#!/bin/bash
## Rust environment with Jupyter kernel support

set -e

ENV_NAME="rust"
CONDA_CMD=/opt/conda/bin/conda

echo "Creating conda environment: ${ENV_NAME}"

# Create Rust environment
echo "Creating ${ENV_NAME} environment"
${CONDA_CMD} create --name ${ENV_NAME} -y
${CONDA_CMD} env update -v --name ${ENV_NAME} --file=/environment_rust.yml
${CONDA_CMD} clean -a -y

echo ""
echo "Environment '${ENV_NAME}' installed successfully!"
echo "Activate with: conda activate ${ENV_NAME}"
echo ""

# EOF
