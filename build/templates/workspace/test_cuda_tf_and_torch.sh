BASEPATH=`dirname $0`
/conda-run.sh "CONDA_DEFAULT_ENV=tensorflow python $BASEPATH/.bin/test_cuda_tf_and_torch.py"
/conda-run.sh "CONDA_DEFAULT_ENV=torch python $BASEPATH/.bin/test_cuda_tf_and_torch.py"
