#!/bin/bash

# key variables
TENSORBOARD_LOGDIR=${TENSORBOARD_LOGDIR:-/tmp/tensorboard}
CONDA_DEFAULT_ENV=tensorflow

COMMAND=$(cat <<EOF
mkdir $TENSORBOARD_LOGDIR 2>/dev/null 
tensorboard --bind_all --logdir $TENSORBOARD_LOGDIR --port 6006
EOF
)

conda run -n $CONDA_DEFAULT_ENV "$COMMAND"

# EOF
