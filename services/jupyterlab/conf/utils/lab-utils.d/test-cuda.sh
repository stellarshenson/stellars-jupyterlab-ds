#!/bin/bash
## Executes CUDA test with tensorflow and torch
CURRENT_FILE=`readlink -f $0`
CURRENT_DIR=`dirname $CURRENT_FILE`
cd $CURRENT_DIR

CONDA_CMD=${CONDA_CMD:-/opt/conda/bin/conda} # image ENV wins when set - one name, one binary

# Check if tensorflow environment exists (exact match on the name column)
if ${CONDA_CMD} env list | awk '{print $1}' | grep -qx "tensorflow"; then
    /conda-run.sh "CONDA_DEFAULT_ENV=tensorflow python ${CURRENT_DIR}/test-cuda.py"
else
    echo "TensorFlow environment not found. Install it using lab-utils > Install Extra Environments"
    echo ""
fi

# Check if torch environment exists (exact match on the name column)
if ${CONDA_CMD} env list | awk '{print $1}' | grep -qx "torch"; then
    /conda-run.sh "CONDA_DEFAULT_ENV=torch python ${CURRENT_DIR}/test-cuda.py"
else
    echo "Torch environment not found. Install it using lab-utils > Install Extra Environments"
    echo ""
fi

echo ""
