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

clear
echo -e "\033[32mConda Environment Installation Successful\033[0m"
echo ""
echo -e "Environment: \033[1;34m$ENV_NAME\033[0m"
echo ""
echo -e "Typical Usage:"
echo -e "1. Activate the environment: '\033[1;34mconda activate $ENV_NAME\033[0m'"
echo -e "2. The environment is available as a Jupyter kernel"
echo ""

# EOF
