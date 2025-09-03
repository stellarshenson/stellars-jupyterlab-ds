#!/bin/bash
## Executes CUDA test with tensorflow and torch
CURRENT_FILE=`readlink -f $0`
CURRENT_DIR=`dirname $CURRENT_FILE`
cd $CURRENT_DIR

/conda-run.sh "CONDA_DEFAULT_ENV=tensorflow python ${CURRENT_DIR}/test-cuda-tensorflow-torch.py"
/conda-run.sh "CONDA_DEFAULT_ENV=torch python ${CURRENT_DIR}/test-cuda-tensorflow-torch.py"
echo ""
