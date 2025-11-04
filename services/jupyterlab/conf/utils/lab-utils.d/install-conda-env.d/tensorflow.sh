#!/bin/bash
## TensorFlow environment with CUDA support

set -e

ENV_NAME="tensorflow"
CONDA_CMD=/opt/conda/bin/conda
CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-base}

echo "Creating conda environment: ${ENV_NAME}"

# Create fresh environment and apply base packages first
echo "Creating ${ENV_NAME} environment with base packages"
${CONDA_CMD} create --name ${ENV_NAME} -y
${CONDA_CMD} env update -v --name ${ENV_NAME} --file=/environment_base_template.yml
${CONDA_CMD} clean -a -y

# Install tensorflow packages
echo "Installing tensorflow packages"
${CONDA_CMD} env update -v --name ${ENV_NAME} --file=/environment_tensorflow.yml
${CONDA_CMD} clean -a -y

clear
echo -e "\033[32mConda Environment Installation Successful\033[0m"
echo ""
echo -e "Environment: \033[1;36m$ENV_NAME\033[0m"
echo ""
echo -e "Typical Usage:"
echo -e "1. Activate the environment: '\033[1;36mconda activate $ENV_NAME\033[0m'"
echo -e "2. The environment is available as a Jupyter kernel"
echo ""

# EOF
