#!/bin/bash

# key variables
CONDA_DEFAULT_ENV=base

COMMAND=$(cat <<EOF
glances -w -t 0.25 
EOF
)

conda run -n $CONDA_DEFAULT_ENV "$COMMAND"

# EOF
