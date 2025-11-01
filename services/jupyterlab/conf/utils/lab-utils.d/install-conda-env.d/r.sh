#!/bin/bash
## R environment with R kernel for statistical computing

set -e

ENV_NAME="r_base"
CONDA_CMD=/opt/conda/bin/conda

echo "Creating conda environment: ${ENV_NAME}"

# Create R environment
echo "Creating ${ENV_NAME} with R kernel"
${CONDA_CMD} create --name ${ENV_NAME} -y
${CONDA_CMD} env update -v --name ${ENV_NAME} --file=/environment_r.yml
${CONDA_CMD} clean -a -y

echo ""
echo "Environment '${ENV_NAME}' installed successfully!"
echo "Activate with: conda activate ${ENV_NAME}"
echo ""

# EOF
