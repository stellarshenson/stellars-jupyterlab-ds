#!/bin/bash
## R environment with R kernel for statistical computing

set -e

ENV_NAME="r_base"
CONDA_CMD=${CONDA_CMD:-/opt/conda/bin/conda} # image ENV wins when set - one name, one binary


# already installed (e.g. re-run via lab-utils Run on Start)? A listed name is
# NOT proof of a complete install: `conda create` registers the env before any
# package lands, so an interrupted install would be skipped forever. Complete =
# sentinel present (written after the last install step below) or the canary
# R binary works (covers healthy envs installed before the sentinel existed).
ENV_PREFIX=$(${CONDA_CMD} env list | awk -v n="${ENV_NAME}" '$1==n{print $NF}')
if [[ -n "${ENV_PREFIX}" ]]; then
    if [[ -f "${ENV_PREFIX}/.lab-utils-install-complete" ]] \
       || ${CONDA_CMD} run -n ${ENV_NAME} R --version >/dev/null 2>&1; then
        touch "${ENV_PREFIX}/.lab-utils-install-complete" 2>/dev/null || true
        echo "Conda environment '${ENV_NAME}' already exists - skipping installation"
        exit 0
    fi
    echo "Conda environment '${ENV_NAME}' exists but is incomplete (interrupted install) - removing and reinstalling"
    ${CONDA_CMD} env remove --name ${ENV_NAME} -y
fi

echo "Creating conda environment: ${ENV_NAME}"

# Create R environment
echo "Creating ${ENV_NAME} with R kernel"
${CONDA_CMD} create --name ${ENV_NAME} -y
${CONDA_CMD} env update -v --name ${ENV_NAME} --file=/environment_r.yml
${CONDA_CMD} clean -a -y

# mark the install complete - the guard above rebuilds envs missing this sentinel
touch "$(${CONDA_CMD} env list | awk -v n="${ENV_NAME}" '$1==n{print $NF}')/.lab-utils-install-complete"

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
