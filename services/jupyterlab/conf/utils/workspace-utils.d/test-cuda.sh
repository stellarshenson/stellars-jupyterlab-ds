#!/bin/bash
## Executes CUDA test with tensorflow and torch
CURRENT_FILE=`readlink -f $0`
CURRENT_DIR=`dirname $CURRENT_FILE`
cd $CURRENT_DIR

CONDA_CMD=/opt/conda/bin/conda

# Check if tensorflow environment exists
if ${CONDA_CMD} env list | grep -q "^tensorflow "; then
    /conda-run.sh "CONDA_DEFAULT_ENV=tensorflow python ${CURRENT_DIR}/test-cuda.py"
else
    echo "TensorFlow environment not found. Install it using workspace-utils > install-conda-environments"
    echo ""
fi

# Check if torch environment exists
if ${CONDA_CMD} env list | grep -q "^torch "; then
    /conda-run.sh "CONDA_DEFAULT_ENV=torch python ${CURRENT_DIR}/test-cuda.py"
else
    echo "Torch environment not found. Install it using workspace-utils > install-conda-environments"
    echo ""
fi

echo ""
