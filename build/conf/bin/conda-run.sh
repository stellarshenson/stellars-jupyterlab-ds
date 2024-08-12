#!/bin/bash
# COPY conda_run.sh /conda_run.sh
# Usage in Dockerfile:
# RUN chmod +x /conda_run.sh
# SHELL ["/conda_run.sh"]
# CONDA_DEFAULT_ENV=FOO <<-EOF
#   command
#   multi-line command
# EOF

# fail if BASH_VERSION is not set
if [ -z "$BASH_VERSION" ]; then
  echo "Error: This script must be run in Bash."
  exit 1
fi

# Read the entire input as a single string
COMMAND="${1}"

# Setup conda - it will overwrite all conda variables
__conda_setup="$($CONDA_CMD 'shell.bash' 'hook' 2> /dev/null)"
eval "$__conda_setup"
unset __conda_setup

# Decide the value of CONDA_ENV to be either
# CONDA_DEFAULT_ENV or value of CONDA_DEFAULT_ENV from input
if [[ "${COMMAND}" =~ ^CONDA_DEFAULT_ENV=([^[:space:]]+)[[:space:]]*(.*) ]]; then
  CONDA_ENV=${BASH_REMATCH[1]}
  EXEC_COMMAND=${BASH_REMATCH[2]}
else
  CONDA_ENV=${CONDA_DEFAULT_ENV:-base}
  EXEC_COMMAND="${COMMAND}"
fi

# Logging, this is just for debugging, you can enable this to sanity check or see what is happening
#>&2 echo "ENV: ${CONDA_ENV}"
#>&2 echo "COMMAND: ${EXEC_COMMAND}"

# Activate the conda environment
# and remove the CONDA_ENV variable
conda activate "${CONDA_ENV}"
unset CONDA_ENV

# Execute the command(s)
eval "${EXEC_COMMAND}"

# EOF
