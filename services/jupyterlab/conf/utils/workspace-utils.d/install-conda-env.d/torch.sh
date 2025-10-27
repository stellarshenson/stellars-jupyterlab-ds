#!/bin/bash
## PyTorch environment with CUDA support

set -e

ENV_NAME="torch"
CONDA_CMD=/opt/conda/bin/conda
CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base}

echo "Creating conda environment: ${ENV_NAME}"

# Clone base environment
echo "Cloning ${ENV_NAME} environment from ${CONDA_DEFAULT_ENV}"
${CONDA_CMD} create --name ${ENV_NAME} --clone ${CONDA_DEFAULT_ENV}
${CONDA_CMD} clean -a -y

# Install torch using environment file
echo "Installing torch packages"
${CONDA_CMD} env update -v --name ${ENV_NAME} --file=/environment_torch.yml
${CONDA_CMD} clean -a -y

echo ""
echo "Environment '${ENV_NAME}' installed successfully!"
echo "Activate with: conda activate ${ENV_NAME}"
echo ""

# EOF
